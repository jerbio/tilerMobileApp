import 'dart:async';
import 'dart:ui' show VoidCallback;

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/changeFlash.dart';
import 'package:tiler_app/services/scheduleDelta.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/gridChoreography.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/moveGhost.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/moveRail.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/motion/tileMotionEmphasis.dart';

/// Plays a [GridChoreography] for the day grid: which tiles wait at their
/// old time, which are lifted, and the outlines left behind, advanced on
/// timers.
///
/// The grid reads it while building and passes [apply] its `setState`, so
/// every step rebuilds the grid.
class GridStepPlayer {
  GridStepPlayer({required this.apply});

  /// Runs a state change and rebuilds the owner (its `setState`).
  final void Function(VoidCallback change) apply;

  GridChoreography? _steps;
  final List<Timer> _timers = <Timer>[];

  /// Tiles waiting at their old time until their batch moves, by uniqueId.
  final Map<String, SubCalendarEvent> _held = <String, SubCalendarEvent>{};

  /// Tiles currently raised (their batch is moving).
  final Set<String> _lifted = <String>{};

  /// Outlines left at a moving tile's old spot, by uniqueId.
  final Map<String, MoveGhost> _ghosts = <String, MoveGhost>{};

  /// Gutter lines from each moving tile's old time to its new one.
  final Map<String, MoveRail> _rails = <String, MoveRail>{};

  // Colour cues; they run on their own timers and may outlast the moves.
  final Map<String, ChangeFlash> _tileFlashes = <String, ChangeFlash>{};
  final Set<String> _travelFlashes = <String>{};

  /// Free gaps the change opened up, and whether each is fading out.
  final Map<FreeGap, bool> _gapFlashes = <FreeGap, bool>{};

  bool get isPlaying => _steps != null;

  /// The old version of a tile still waiting to move; draw it (and its
  /// travel bands) from this instead of the new data.
  SubCalendarEvent? heldTile(String id) => _held[id];

  /// The outlines to draw under the tiles, by uniqueId.
  Map<String, MoveGhost> get ghosts => _ghosts;

  /// The gutter lines to draw, by uniqueId.
  Map<String, MoveRail> get rails => _rails;

  /// A landed tile's colour cue.
  ChangeFlash? flashFor(String id) => _tileFlashes[id];

  /// Whether the travel into this tile is being shown changing.
  bool travelFlashing(String id) => _travelFlashes.contains(id);

  /// Free gaps to highlight, with whether each is fading out.
  Iterable<MapEntry<FreeGap, bool>> get gapFlashes => _gapFlashes.entries;

  TileMotionEmphasis emphasisFor(String id) {
    if (_lifted.contains(id)) return TileMotionEmphasis.lifted;
    return isPlaying ? TileMotionEmphasis.receded : TileMotionEmphasis.none;
  }

  /// The slide duration for a tile in the sequence; null for the rest.
  Duration? moveDurationFor(String id) =>
      (_steps?.ids.contains(id) ?? false) ? GridChoreography.move : null;

  /// Starts [steps], replacing any sequence already running.
  ///
  /// [before] / [after] are the tiles by uniqueId in the previous and the
  /// new frame; [layoutOf] gives a tile's previous (left, width) for its
  /// outline. Moving tiles are held from the very next frame.
  void start(
    GridChoreography steps, {
    required Map<String, SubCalendarEvent> before,
    required Map<String, SubCalendarEvent> after,
    required (double, double) Function(String id) layoutOf,
    List<FreeGap> grownGaps = const <FreeGap>[],
  }) {
    stop(notify: false);
    _steps = steps;
    for (final id in steps.ids) {
      final old = before[id];
      if (old != null) _held[id] = old;
    }
    for (final batch in steps.batches) {
      if (batch.causeIds.isNotEmpty) {
        // Cause first: the changed travel is shown before anything lifts.
        _after(batch.causeAt, () => _travelFlashes.addAll(batch.causeIds));
        _after(batch.causeAt + ChangeFlashStyle.hold,
            () => _travelFlashes.removeAll(batch.causeIds));
      }
      _after(batch.liftAt, () {
        _lifted.addAll(batch.ids);
        String? longest;
        var longestMs = -1;
        for (final id in batch.ids) {
          final from = _held[id]?.start, to = after[id]?.start;
          if (from == null || to == null) continue;
          final ms = (to - from).abs();
          if (ms > longestMs) {
            longestMs = ms;
            longest = id;
          }
        }
        for (final id in batch.ids) {
          final old = _held[id];
          final now = after[id];
          if (old == null || now?.start == null) continue;
          final (left, width) = layoutOf(id);
          _ghosts[id] = MoveGhost(old, now!.start!, left, width);
          _rails[id] =
              MoveRail(old.start!, now.start!, labelled: id == longest);
        }
      });
      _after(batch.moveAt,
          () => _held.removeWhere((id, _) => batch.ids.contains(id)));
      _after(batch.landAt, () {
        _lifted.removeAll(batch.ids);
        for (final id in batch.ids) {
          _ghosts[id]?.fading = true;
          _rails[id]?.fading = true;
          _tileFlashes[id] = ChangeFlash.moved;
        }
      });
      _after(batch.landAt + ChangeFlashStyle.hold,
          () => _tileFlashes.removeWhere((id, _) => batch.ids.contains(id)));
    }
    if (grownGaps.isNotEmpty) {
      // What the change gained, once everything has landed.
      final landed = steps.batches.last.landAt;
      _after(landed, () {
        for (final gap in grownGaps) {
          _gapFlashes[gap] = false;
        }
      });
      _after(landed + ChangeFlashStyle.hold,
          () => _gapFlashes.updateAll((_, __) => true));
      _after(landed + ChangeFlashStyle.hold + ChangeFlashStyle.fade,
          _gapFlashes.clear);
    }
    _after(steps.end, () {
      _ghosts.clear();
      _rails.clear();
      _steps = null;
    });
  }

  /// Ends any running sequence at once: every tile at its real time.
  /// [notify] rebuilds the owner; pass false from build or dispose.
  void stop({bool notify = true}) {
    if (_steps == null && _timers.isEmpty && _gapFlashes.isEmpty) return;
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    _tileFlashes.clear();
    _travelFlashes.clear();
    _gapFlashes.clear();
    _held.clear();
    _lifted.clear();
    _ghosts.clear();
    _rails.clear();
    _steps = null;
    if (notify) apply(() {});
  }

  void _after(Duration delay, VoidCallback change) {
    _timers.add(Timer(delay, () => apply(change)));
  }
}
