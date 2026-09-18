import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/quickActionChipsRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/todayStats.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/util.dart';

/// The Daily quick actions — **Show route** and **Re-optimize** on the left,
/// the **All / Blocks / Tiles** content filter (P7, a chip-styled
/// segmented pill driving [DayContentFilterCubit]) on the right — plus the schedule
/// loading bar, laid out in the shared Daily chrome (under the day strip)
/// so BOTH layouts (list and grid) get them from ONE place.
///
/// Always present (constant height), so swiping between days never changes
/// the height of the chrome above the content. Show route opens
/// [TodaysRoutePage] for the SHOWN day's viable tiles (read from
/// [ScheduleBloc]); Re-optimize dispatches [ReviseScheduleEvent] — the same
/// actions the list's sticky header used to carry.
class DayQuickActionsRow extends StatelessWidget {
  static const Key showRouteKey = ValueKey('dayQuickActions_showRoute');
  static const Key reOptimizeKey = ValueKey('dayQuickActions_reOptimize');
  static const Key filterAllKey = ValueKey('dayQuickActions_filter_all');
  static const Key filterBlocksKey = ValueKey('dayQuickActions_filter_blocks');
  static const Key filterTilesKey = ValueKey('dayQuickActions_filter_tiles');

  /// The collapsed filter chip (shown by default; tap to expand).
  static const Key filterToggleKey =
      ValueKey('dayQuickActions_filter_toggle');

  /// The whole filter pill.
  static const Key filterKey = ValueKey('dayQuickActions_filter');

  /// The day the route is built for.
  final DateTime currentDate;

  /// Read-only hosts (TileCast preview) render the chips disabled.
  final bool preview;

  const DayQuickActionsRow({
    super.key,
    required this.currentDate,
    this.preview = false,
  });

  /// The chips row (~48) + the 3px loading bar.
  static const double height = QuickActionChipsRow.height + 3;

  /// The shown day's viable tiles from the schedule state (pure so it can
  /// be unit-tested): any state that carries sub-events, filtered to
  /// [dayIndex].
  static List<SubCalendarEvent> tilesForDay(ScheduleState state, int dayIndex) {
    List<SubCalendarEvent>? subEvents;
    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
    } else if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
    }
    if (subEvents == null) return const <SubCalendarEvent>[];
    return subEvents.where((tile) {
      final int? start = tile.start;
      if (start == null) return false;
      if (!(tile.isViable ?? true)) return false;
      return Utility.localDateTimeFromMs(start).universalDayIndex == dayIndex;
    }).toList();
  }

  void _showRoute(BuildContext context) {
    final tiles = tilesForDay(
        context.read<ScheduleBloc>().state, currentDate.universalDayIndex);
    final stats = TodayStats.fromTiles(tiles);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodaysRoutePage(
          tiles: tiles,
          timeSaved: stats.travelTime > Duration.zero ? stats.travelTime : null,
        ),
      ),
    );
  }

  void _reOptimize(BuildContext context) {
    context.read<ScheduleBloc>().add(ReviseScheduleEvent());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        // Stretch so the chips row spans the width and its chips sit LEFT
        // (a shrink-wrapped row would centre them).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QuickActionChipsRow(
            preview: preview,
            showRouteKey: showRouteKey,
            reOptimizeKey: reOptimizeKey,
            onShowRoute: () => _showRoute(context),
            onReOptimize: () => _reOptimize(context),
            // The content filter, right-aligned. Hidden on read-only
            // surfaces (C36), where the filter is also forced to `all`.
            trailing: preview ? null : _FilterSegments(currentDate: currentDate),
          ),
          BlocBuilder<ScheduleBloc, ScheduleState>(
            buildWhen: (previous, current) =>
                _isLoading(previous) != _isLoading(current),
            builder: (context, state) => AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _isLoading(state)
                  ? LinearProgressIndicator(
                      key: const ValueKey('schedule-loading-indicator'),
                      minHeight: 3,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      color: colorScheme.tertiary,
                    )
                  : const SizedBox(
                      key: ValueKey('schedule-loading-hidden'),
                      height: 3,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isLoading(ScheduleState state) =>
      state is ScheduleLoadingState || state is ScheduleEvaluationState;
}

/// All / Blocks / Tiles as a **collapsible** segmented pill bound to
/// [DayContentFilterCubit] (C33). It is collapsed by default to a single
/// filter chip (showing the active selection) so the Show route / Re-optimize
/// chips on the left have full room. Tapping the chip expands the three
/// segments; picking one applies it and collapses again, and the pill
/// auto-collapses after [_FilterSegmentsState._collapseAfter] if left open.
///
/// Styled like [TilerActionChip] (same surface, radius, outline and type) so
/// it reads as part of the chips row; the selected segment is filled in
/// `primary`.
class _FilterSegments extends StatefulWidget {
  final DateTime currentDate;
  const _FilterSegments({required this.currentDate});

  static const double _radius = 20;

  @override
  State<_FilterSegments> createState() => _FilterSegmentsState();
}

class _FilterSegmentsState extends State<_FilterSegments> {
  /// How long the pill stays expanded before it reverts to the collapsed chip.
  static const Duration _collapseAfter = Duration(seconds: 5);

  bool _expanded = false;
  Timer? _collapseTimer;

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _select(BuildContext context, DayContentFilter next) {
    DailyViewLayout? layout;
    try {
      layout = context.read<DailyViewLayoutCubit>().state;
    } catch (_) {
      layout = null; // not provided (isolated hosts): analytics only
    }
    context.read<DayContentFilterCubit>().set(
          next,
          dayIndex: widget.currentDate.universalDayIndex,
          layout: layout?.name,
        );
    _collapse();
  }

  void _expand() {
    _scheduleCollapse();
    setState(() => _expanded = true);
  }

  void _collapse() {
    _collapseTimer?.cancel();
    _collapseTimer = null;
    if (!_expanded) return;
    setState(() => _expanded = false);
  }

  void _scheduleCollapse() {
    _collapseTimer?.cancel();
    _collapseTimer = Timer(_collapseAfter, _collapse);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final DayContentFilter selected =
        context.watch<DayContentFilterCubit>().state;
    final segments = <(DayContentFilter, String, Key, IconData?)>[
      (
        DayContentFilter.all,
        l10n.dayFilterAll,
        DayQuickActionsRow.filterAllKey,
        null
      ),
      (
        DayContentFilter.blocks,
        l10n.dayFilterBlocks,
        DayQuickActionsRow.filterBlocksKey,
        Icons.lock_outline
      ),
      (
        DayContentFilter.tiles,
        l10n.dayFilterTiles,
        DayQuickActionsRow.filterTilesKey,
        null
      ),
    ];
    return Tooltip(
      message: l10n.dayFilterTooltip,
      child: Semantics(
        container: true,
        label: l10n.dayFilterTooltip,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.centerRight,
          child: Container(
            key: DayQuickActionsRow.filterKey,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_FilterSegments._radius),
              border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.2)),
            ),
            child: _expanded
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final (filter, label, key, icon) in segments)
                        _Segment(
                          key: key,
                          label: label,
                          icon: icon,
                          selected: filter == selected,
                          onTap: () => _select(context, filter),
                        ),
                    ],
                  )
                : _FilterToggle(
                    key: DayQuickActionsRow.filterToggleKey,
                    label: _labelFor(selected, segments),
                    active: selected != DayContentFilter.all,
                    onTap: _expand,
                  ),
          ),
        ),
      ),
    );
  }

  String _labelFor(
      DayContentFilter selected,
      List<(DayContentFilter, String, Key, IconData?)> segments) {
    for (final (filter, label, _, _) in segments) {
      if (filter == selected) return label;
    }
    return segments.first.$2;
  }
}

class _Segment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Optional leading glyph — the `Blocks` segment carries the lock so the
  /// control doubles as the legend for the lock on block cards (P8/A).
  final IconData? icon;

  const _Segment({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(_FilterSegments._radius - 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 12,
                    color:
                        selected ? colorScheme.onPrimary : colorScheme.onSurface),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected ? colorScheme.onPrimary : colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The collapsed form of [_FilterSegments]: a single filter chip showing the
/// active selection. Tapping it expands the three segments. When a
/// non-default filter (Blocks / Tiles) is active the chip is filled in
/// `primary` so the applied filter is visible at a glance.
class _FilterToggle extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  /// A non-default (Blocks / Tiles) filter is active.
  final bool active;

  const _FilterToggle({
    super.key,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = active ? colorScheme.onPrimary : colorScheme.onSurface;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(_FilterSegments._radius - 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
