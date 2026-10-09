import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/scheduleChipInsets.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listAnchor.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listFlights.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileConnectorLayout.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoff.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridHandoffChip.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/services/scheduleMotion.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

/// Schedule-change motion for one day of the daily list: keeps the anchor
/// tile in place, flies moved tiles from their old row to their new one,
/// and puts an edge chip up for tiles that left the screen or the day.
///
/// A list calls [beforeRows] just before it builds rows for new data and
/// [afterLayout] once those rows are laid out (and any anchor correction is
/// applied), and wraps itself in [ListMotionLayer].
class ListMotion {
  ListMotion({required this.apply});

  /// Runs a state change and rebuilds the owning list (its `setState`).
  final void Function(VoidCallback change) apply;

  final ListAnchorKeeper anchor = ListAnchorKeeper();
  final ListRowRegistry rows = ListRowRegistry();

  /// The Stack the flights and chips are drawn in; rects are measured in it.
  final GlobalKey layerKey = GlobalKey(debugLabel: 'listMotionLayer');

  late final ListFlightPlayer flights = ListFlightPlayer(apply: apply);
  late final GridHandoffQueue handoffs = GridHandoffQueue(apply: apply);

  _Pending? _pending;

  /// Colour cues on rows, by row key.
  final Map<String, ChangeFlash> _rowFlashes = <String, ChangeFlash>{};
  final List<Timer> _flashTimers = <Timer>[];

  /// The colour cue on a row right now, if any.
  ChangeFlash? flashOf(String rowKey) => _rowFlashes[rowKey];

  /// True between [beforeRows] finding a change to show and [afterLayout].
  bool get hasPending => _pending != null;

  /// Wraps a list row so it can be measured, and hidden while its tile's
  /// copy is flying.
  Widget wrapRow(String rowKey, Widget row) {
    final hidden = rowKey.startsWith('tile:') &&
        flights.isHidden(rowKey.substring('tile:'.length));
    return ListRowProbe(
      rowKey: rowKey,
      registry: rows,
      child: _FlashFrame(
        flash: _rowFlashes[rowKey],
        child: Opacity(
            key: ValueKey<String>('list_row_opacity_$rowKey'),
            opacity: hidden ? 0 : 1,
            child: row),
      ),
    );
  }

  /// Kinds that leave their row: these can fly or get a chip.
  static const Set<TileChangeKind> _leaving = {
    TileChangeKind.moved,
    TileChangeKind.movedAndResized,
    TileChangeKind.movedToOtherDay,
  };

  RenderBox? get _layer {
    final box = layerKey.currentContext?.findRenderObject();
    return box is RenderBox && box.hasSize ? box : null;
  }

  static bool _onScreen(Rect rect, Size layer) =>
      rect.bottom > 0 && rect.top < layer.height;

  /// Call after [ListAnchorKeeper.capture] and before building the new
  /// rows. [previousRows] are the rows still on screen.
  void beforeRows(BuildContext context, TileConnectorLayoutResult? previousRows,
      {required bool preview}) {
    _pending = null;
    final change = anchor.takeChange();
    final layer = _layer;
    if (preview ||
        change == null ||
        change.attribution.isRefresh ||
        previousRows == null ||
        layer == null) {
      return;
    }
    final mode = ScheduleMotion.modeFor(context,
        origin: change.attribution.origin, listen: false);
    final subject = change.attribution.subjectId;

    // Tiles that were on screen and are leaving their row.
    final seen = <String, Rect>{};
    for (final c in change.delta.changes) {
      if (!_leaving.contains(c.kind) || c.id == subject) continue;
      final row = previousRows.rowOfTile[c.id];
      if (row == null || row >= previousRows.rowKeys.length) continue;
      final rect = rows.rectOf(previousRows.rowKeys[row], layer);
      if (rect != null && _onScreen(rect, layer.size)) seen[c.id] = rect;
    }
    // Nothing on screen leaves its row: only the colour cues (Detailed) are
    // left to show.
    if (seen.isEmpty && !mode.choreographs) return;

    final steps = mode.choreographs
        ? GridChoreography.plan(change.delta, subjectId: subject)
        : null;
    final flying = <String, (Rect, int)>{
      if (steps != null)
        for (final id in steps.ids)
          if (seen[id] != null &&
              change.delta.changeFor(id)?.after?.start != null)
            id: (seen[id]!, change.delta.changeFor(id)!.after!.start!),
    };
    flights.prepare(flying);
    _pending = _Pending(change, mode, steps, seen);
  }

  /// Call once the new rows are laid out. [rowsNow] are the rows just built
  /// and [visibleRows] the row indexes now on screen (first, last).
  void afterLayout(TileConnectorLayoutResult rowsNow, (int, int)? visibleRows) {
    final pending = _pending;
    _pending = null;
    if (pending == null) return;
    final layer = _layer;
    if (layer == null) {
      flights.stop();
      return;
    }
    // Where each flying tile landed, when that is on screen.
    final targets = <String, Rect>{};
    for (final flight in flights.flights) {
      final rect = rows.rectOf('tile:${flight.tileId}', layer);
      if (rect != null && _onScreen(rect, layer.size)) {
        targets[flight.tileId] = rect;
      }
    }
    final steps = pending.steps;
    if (steps != null) {
      if (flights.flights.isNotEmpty) flights.launch(targets, steps);
      _scheduleFlashes(steps, targets.keys.toSet(), pending.change.delta);
    }

    // Tiles that were on screen and now are not: one chip per destination.
    final earlier = <SubCalendarEvent>[], later = <SubCalendarEvent>[];
    final otherDay = <SubCalendarEvent>[];
    for (final id in pending.seen.keys) {
      final change = pending.change.delta.changeFor(id);
      final after = change?.after;
      if (change == null || after?.start == null) continue;
      if (change.kind == TileChangeKind.movedToOtherDay) {
        otherDay.add(after!);
        continue;
      }
      final rect = rows.rectOf('tile:$id', layer);
      if (rect != null && _onScreen(rect, layer.size)) continue;
      final row = rowsNow.rowOfTile[id];
      final bool below = rect != null
          ? rect.top >= layer.size.height
          : (row != null && visibleRows != null
              ? row > visibleRows.$2
              : after!.start! > change.before!.start!);
      (below ? later : earlier).add(after!);
    }
    int byStart(SubCalendarEvent a, SubCalendarEvent b) =>
        a.start!.compareTo(b.start!);
    // Every tile that left the day shares one chip.
    final days =
        GridHandoff.otherDays(otherDay, pending.change.delta.day.start!);
    final chips = <GridHandoff>[
      if (earlier.isNotEmpty)
        GridHandoff(HandoffDirection.earlier, earlier..sort(byStart)),
      if (later.isNotEmpty)
        GridHandoff(HandoffDirection.later, later..sort(byStart)),
      if (days != null) days,
    ];
    if (chips.isEmpty) return;
    Utility.debugPrint('DailyList::handoff '
        '${chips.map((h) => '${h.direction.name}:${h.tiles.length}').join(' ')}');
    final delay = steps != null && targets.isNotEmpty
        ? steps.end - GridChoreography.ghostLinger
        : (pending.mode.animates
            ? const Duration(milliseconds: 300)
            : Duration.zero);
    if (delay == Duration.zero) {
      apply(() => handoffs.show(chips));
    } else {
      handoffs.show(chips, delay: delay);
    }
  }

  /// Colour cues for a change played in steps: the travel that pushed a
  /// batch (before it lifts), each tile that flew in (as it lands), and the
  /// free time gained (once everything has landed).
  void _scheduleFlashes(
      GridChoreography steps, Set<String> flown, ScheduleDelta delta) {
    for (final batch in steps.batches) {
      for (final id in batch.causeIds) {
        _flashRow('travel:$id', ChangeFlash.travel, batch.causeAt);
      }
      for (final id in batch.ids.where(flown.contains)) {
        _flashRow('tile:$id', ChangeFlash.moved, batch.landAt);
      }
    }
    final landed = steps.batches.last.landAt;
    for (final gap in delta.grownGaps) {
      _flashRow('free:${gap.beforeTileId}', ChangeFlash.freeGained, landed);
    }
  }

  void _flashRow(String rowKey, ChangeFlash flash, Duration at) {
    _flashTimers.add(Timer(at, () => apply(() => _rowFlashes[rowKey] = flash)));
    _flashTimers.add(Timer(at + ChangeFlashStyle.hold,
        () => apply(() => _rowFlashes.remove(rowKey))));
  }

  /// Switches to the day a chip's tiles went to.
  static void openDay(
      BuildContext context, GridHandoff handoff, DateTime? currentDay) {
    final target = Utility.localDateTimeFromMs(handoff.targetStartMs);
    try {
      context.read<UiDateManagerBloc>().add(DateChangeEvent(
            previousSelectedDate: currentDay,
            selectedDate: DateTime(target.year, target.month, target.day),
            dateChangeTrigger: DateChangeTrigger.buttonPress,
          ));
    } on ProviderNotFoundException {
      // Hosts without day navigation only dismiss the chip.
    }
  }

  void dispose() {
    for (final timer in _flashTimers) {
      timer.cancel();
    }
    _flashTimers.clear();
    _rowFlashes.clear();
    flights.stop(notify: false);
    handoffs.stop(notify: false);
  }
}

/// Tints and rings a row while it carries a colour cue.
class _FlashFrame extends StatelessWidget {
  final ChangeFlash? flash;
  final Widget child;

  const _FlashFrame({required this.flash, required this.child});

  @override
  Widget build(BuildContext context) {
    final color = flash?.color(Theme.of(context).colorScheme);
    final radius = BorderRadius.circular(TileDimensions.borderRadius);
    return AnimatedContainer(
      duration: ScheduleMotion.modeFor(context).animates
          ? ChangeFlashStyle.fade
          : Duration.zero,
      decoration: color == null
          ? null
          : BoxDecoration(
              color: color.withValues(alpha: 0.10), borderRadius: radius),
      foregroundDecoration: color == null
          ? null
          : BoxDecoration(
              borderRadius: radius, border: Border.all(color: color, width: 2)),
      child: child,
    );
  }
}

class _Pending {
  final ListChange change;
  final ScheduleUpdateMode mode;
  final GridChoreography? steps;

  /// Tiles that were on screen and are leaving their row, by id: old rect.
  final Map<String, Rect> seen;

  const _Pending(this.change, this.mode, this.steps, this.seen);
}

/// Wraps a day's list so [ListMotion] can draw over it: the flying copies
/// and ghosts, and the edge chips. Always the same Stack, so motion coming
/// and going never remounts the list.
class ListMotionLayer extends StatelessWidget {
  final ListMotion motion;
  final Widget child;

  /// Builds a tile's row as it is now, for its flying copy.
  final Widget Function(String tileId) rowBuilder;

  /// Brings a tile's row into view (for an earlier/later chip).
  final void Function(String tileId) scrollToTile;
  final DateTime? day;

  const ListMotionLayer({
    super.key,
    required this.motion,
    required this.child,
    required this.rowBuilder,
    required this.scrollToTile,
    this.day,
  });

  @override
  Widget build(BuildContext context) {
    final animate = ScheduleMotion.modeFor(context).animates;
    final chips = motion.handoffs.visible;
    Widget chip(GridHandoff handoff) => GridHandoffChip(
          handoff: handoff,
          onTap: () {
            motion.handoffs.dismiss(handoff);
            AnalysticsSignal.send('daily_list_handoff_tapped',
                additionalInfo: {'direction': handoff.direction.name});
            if (handoff.isOtherDay) {
              ListMotion.openDay(context, handoff, day);
            } else {
              scrollToTile(handoff.tiles.first.uniqueId);
            }
          },
        );
    final top =
        chips.where((h) => h.direction == HandoffDirection.earlier).toList();
    final bottom =
        chips.where((h) => h.direction != HandoffDirection.earlier).toList();
    return Stack(
      key: motion.layerKey,
      children: [
        // A single-child wrapper, so when the list swaps itself for a
        // remounted copy the old one is deactivated before the new one
        // mounts (a Stack would mount the new one first, and both would
        // claim the same scroll controller).
        KeyedSubtree(child: child),
        Positioned.fill(
          child: ListFlightOverlay(
            player: motion.flights,
            rowBuilder: rowBuilder,
            animate: animate,
          ),
        ),
        if (top.isNotEmpty)
          Positioned(
            top: 8,
            left: 16,
            right: 16,
            child: Center(child: chip(top.first)),
          ),
        if (bottom.isNotEmpty)
          Positioned(
            bottom: ScheduleChipInsets.bottomBarOf(context) +
                ScheduleChipInsets.edgeChipGap,
            left: 16,
            right: ScheduleChipInsets.fabClearance,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final handoff in bottom)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: chip(handoff),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
