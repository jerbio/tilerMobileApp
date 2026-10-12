import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/util.dart';

/// Where tiles went when they left what the user was looking at.
enum HandoffDirection {
  /// Earlier the same day, above the visible part of the grid.
  earlier,

  /// Later the same day, below the visible part of the grid.
  later,
  previousDay,
  nextDay,
}

/// Tiles that were on screen and moved out of view (later or earlier the
/// same day) or to other days, reported as edge chips so they never just
/// vanish: one for earlier, one for later, and one for every tile that left
/// the day, wherever it went.
class GridHandoff {
  final HandoffDirection direction;

  /// The tiles, in time order, as they are now.
  final List<SubCalendarEvent> tiles;

  const GridHandoff(this.direction, this.tiles);

  bool get isOtherDay =>
      direction == HandoffDirection.previousDay ||
      direction == HandoffDirection.nextDay;

  /// The first tile's new start: where tapping the chip should take the
  /// user (a time on this day, or the earliest destination day).
  int get targetStartMs => tiles.first.start!;

  /// The tiles went to more than one day.
  bool get spansSeveralDays {
    final days = {
      for (final t in tiles)
        (() {
          final d = Utility.localDateTimeFromMs(t.start!);
          return DateTime(d.year, d.month, d.day);
        })(),
    };
    return days.length > 1;
  }

  /// One chip for every tile that left the day ([tiles] as they are now),
  /// pointing at the earliest destination; null when there are none.
  static GridHandoff? otherDays(List<SubCalendarEvent> tiles, int dayStartMs) {
    if (tiles.isEmpty) return null;
    final sorted = [...tiles]..sort((a, b) => a.start!.compareTo(b.start!));
    return GridHandoff(
        sorted.first.start! < dayStartMs
            ? HandoffDirection.previousDay
            : HandoffDirection.nextDay,
        sorted);
  }

  /// Builds the chips for [delta].
  ///
  /// [place] says where a time range sits relative to the visible part of
  /// the grid: -1 above it, 0 at least partly visible, 1 below it. Only
  /// tiles that were visible before the change count; [skipId] (the tile
  /// the user moved themselves) never does.
  static List<GridHandoff> fromDelta(
    ScheduleDelta delta, {
    required int Function(int startMs, int endMs) place,
    String? skipId,
  }) {
    final earlier = <SubCalendarEvent>[];
    final later = <SubCalendarEvent>[];
    final otherDay = <SubCalendarEvent>[];
    for (final change in delta.changes) {
      final before = change.before, after = change.after;
      if (before == null || after == null || change.id == skipId) continue;
      if (place(before.start!, before.end!) != 0) continue;
      switch (change.kind) {
        case TileChangeKind.moved:
        case TileChangeKind.movedAndResized:
          final now = place(after.start!, after.end!);
          if (now < 0) earlier.add(after);
          if (now > 0) later.add(after);
        case TileChangeKind.movedToOtherDay:
          otherDay.add(after);
        case TileChangeKind.resized:
        case TileChangeKind.movedFromOtherDay:
        case TileChangeKind.added:
        case TileChangeKind.removed:
          break;
      }
    }
    int byStart(SubCalendarEvent a, SubCalendarEvent b) =>
        a.start!.compareTo(b.start!);
    final days = otherDays(otherDay, delta.day.start!);
    return [
      if (earlier.isNotEmpty)
        GridHandoff(HandoffDirection.earlier, earlier..sort(byStart)),
      if (later.isNotEmpty)
        GridHandoff(HandoffDirection.later, later..sort(byStart)),
      if (days != null) days,
    ];
  }
}

/// Shows edge chips after the tiles they describe have moved, and hides
/// them a few seconds later.
///
/// The grid reads [visible] while building and passes [apply] its
/// `setState`.
class GridHandoffQueue {
  GridHandoffQueue({
    required this.apply,
    this.visibleFor = const Duration(seconds: 3),
  });

  final void Function(VoidCallback change) apply;
  final Duration visibleFor;

  List<GridHandoff> _visible = const <GridHandoff>[];
  final List<Timer> _timers = <Timer>[];

  List<GridHandoff> get visible => _visible;

  /// Replaces any chips with [handoffs], shown after [delay].
  ///
  /// Called while the owner is about to rebuild (its `didUpdateWidget`),
  /// so changes made right away are not wrapped in [apply].
  void show(List<GridHandoff> handoffs, {Duration delay = Duration.zero}) {
    stop(notify: false);
    if (handoffs.isEmpty) return;
    void hideLater() =>
        _timers.add(Timer(visibleFor, () => apply(() => _visible = const [])));
    if (delay == Duration.zero) {
      _visible = handoffs;
      hideLater();
      return;
    }
    _timers.add(Timer(delay, () {
      apply(() => _visible = handoffs);
      hideLater();
    }));
  }

  void dismiss(GridHandoff handoff) =>
      apply(() => _visible = [..._visible]..remove(handoff));

  /// Drops every chip and pending reveal. [notify] rebuilds the owner; pass
  /// false from build or dispose.
  void stop({bool notify = true}) {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    if (_visible.isEmpty) return;
    if (notify) {
      apply(() => _visible = const []);
    } else {
      _visible = const [];
    }
  }
}
