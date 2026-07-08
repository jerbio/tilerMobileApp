import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// A contiguous open window between two scheduled tiles in a day.
///
/// Detection is deterministic and clamps every gap's start to "now" so
/// elapsed time is never surfaced. Because "now" is always the real wall
/// clock, the same formula handles today, future days, and past days:
///   - future day: gap starts after `now`  -> full window
///   - today:      gap straddles `now`      -> only the remaining portion
///   - past day:   gap ends before `now`    -> dropped
class FreeSlot {
  final int startMs;
  final int endMs;

  /// True when this window is currently live (its clamped start equals `now`
  /// because the preceding tile has already ended).
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
        final int gapStart = runningEnd > nowMs ? runningEnd : nowMs;
        final int gapEnd = start - travel;
        final int freeMs = gapEnd - gapStart;

        if (freeMs >= minDurationMs) {
          final bool isLive = gapStart == nowMs && runningEnd <= nowMs;
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
