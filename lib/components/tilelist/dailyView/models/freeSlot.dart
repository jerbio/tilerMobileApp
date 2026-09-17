import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// A contiguous open window between two scheduled tiles in a day.
///
/// Each gap is surfaced in full — from the previous tile's end to the next
/// tile's start (minus travel) — so the window's true start is visible even
/// after part of it has elapsed. Because "now" is always the real wall clock,
/// the same formula handles today, future days, and past days:
///   - future day: gap starts after `now`  -> full window, not live
///   - today:      gap straddles `now`      -> full window, live (scrubber shows
///                 the elapsed portion from the start up to `now`)
///   - past day:   gap ends before `now`    -> dropped
class FreeSlot {
  final int startMs;
  final int endMs;

  /// True when this window is currently live (the wall clock falls inside
  /// `[startMs, endMs]`, i.e. the preceding tile has already ended and the
  /// following tile has not yet begun).
  final bool isLive;

  const FreeSlot({
    required this.startMs,
    required this.endMs,
    required this.isLive,
  });

  Duration get duration => Duration(milliseconds: endMs - startMs);
  DateTime get startTime => DateTime.fromMillisecondsSinceEpoch(startMs);
  DateTime get endTime => DateTime.fromMillisecondsSinceEpoch(endMs);

  /// Tiles at or beyond this duration are treated as all-day/extended and are
  /// excluded from gap detection (mirrors the connector layout's filtering).
  static const int _maxTileDurationMs = 16 * 60 * 60 * 1000;

  /// Detects open windows between consecutive tiles.
  ///
  /// [nowMs] is the real wall-clock time. [minDurationMs] is the smallest gap
  /// worth surfacing. Travel time before the following tile is subtracted so a
  /// window that is really needed for travel is not offered as free.
  static List<FreeSlot> detect({
    required List<TilerEvent> orderedTiles,
    required int nowMs,
    int minDurationMs = 30 * 60 * 1000,
  }) {
    final regular = orderedTiles
        .whereType<SubCalendarEvent>()
        .where((tile) =>
            tile.start != null &&
            tile.end != null &&
            (tile.end! - tile.start!) < _maxTileDurationMs)
        .toList()
      ..sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    final List<FreeSlot> slots = [];
    int? runningEnd;

    for (final tile in regular) {
      final int start = tile.start!;
      final int end = tile.end!;

      if (runningEnd != null && start > runningEnd) {
        final int travel = (tile.travelTimeBefore ?? 0).toInt();
        // Surface the full open window, from the previous tile's end to the
        // next tile's start (minus travel). The elapsed portion is conveyed by
        // the row's scrubber rather than by shrinking the window to "now".
        final int gapStart = runningEnd;
        final int gapEnd = start - travel;
        final int freeMs = gapEnd - gapStart;

        // Drop windows that have already ended (e.g. past days / earlier gaps
        // today); keep future and currently-live windows.
        if (freeMs >= minDurationMs && nowMs <= gapEnd) {
          final bool isLive = nowMs >= gapStart && nowMs <= gapEnd;
          slots.add(FreeSlot(
            startMs: gapStart,
            endMs: gapEnd,
            isLive: isLive,
          ));
        }
      }

      runningEnd = (runningEnd == null || end > runningEnd) ? end : runningEnd;
    }

    return slots;
  }
}
