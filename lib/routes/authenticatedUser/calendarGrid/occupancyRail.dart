import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

/// One stretch of the day not claimed by a block, in epoch ms.
class OccupancySegment {
  final int startMs;
  final int endMs;

  const OccupancySegment(this.startMs, this.endMs);

  int get durationMs => endMs - startMs;

  @override
  bool operator ==(Object other) =>
      other is OccupancySegment &&
      other.startMs == startMs &&
      other.endMs == endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => 'OccupancySegment($startMs, $endMs)';
}

/// Pure interval math behind the grid's occupancy rail (P9, §18): the
/// stretches of a day that are NOT claimed by a BLOCK — free time and
/// tile time alike, i.e. the time Tiler is free to schedule into.
///
/// * Blocks = the day's renderable (parity rule, [DayGridPage.gridTiles])
///   rigid tiles (C37/C39). Tiles never subtract; an all-day block blanks
///   the whole rail.
/// * Travel never counts (C38): a block claims only its own `[start, end]`.
/// * Overlapping / touching blocks merge; the result is the complement
///   inside `[dayStart, dayStart + 24h)`, sorted by start.
abstract final class OccupancyRail {
  static List<OccupancySegment> segments(
    List<TilerEvent> tiles, {
    required DateTime dayStart,
  }) {
    final int dayStartMs = dayStart.millisecondsSinceEpoch;
    final int dayEndMs = dayStartMs + Duration.millisecondsPerDay;

    final List<OccupancySegment> blocks = [];
    for (final SubCalendarEvent tile in DayGridPage.gridTiles(tiles)) {
      if (tile.isRigid != true) continue; // tiles never subtract (C37)
      if (tile.start == null || tile.end == null) continue;
      final int start = tile.start!.clamp(dayStartMs, dayEndMs);
      final int end = tile.end!.clamp(dayStartMs, dayEndMs);
      if (end <= start) continue; // fully outside this day
      blocks.add(OccupancySegment(start, end));
    }
    blocks.sort((a, b) => a.startMs.compareTo(b.startMs));

    // Walk the merged blocks, emitting the gaps between them.
    final List<OccupancySegment> free = [];
    int cursor = dayStartMs;
    for (final OccupancySegment block in blocks) {
      if (block.startMs > cursor) {
        free.add(OccupancySegment(cursor, block.startMs));
      }
      if (block.endMs > cursor) cursor = block.endMs;
    }
    if (cursor < dayEndMs) free.add(OccupancySegment(cursor, dayEndMs));
    return free;
  }

  /// Splits [segment] at [nowMs] into its (past, future) halves for the
  /// past-dimming treatment (C41). Either half is null when empty; with no
  /// `now` (the day is not today) the whole segment is "future".
  static (OccupancySegment?, OccupancySegment?) split(
      OccupancySegment segment, int? nowMs) {
    if (nowMs == null || nowMs <= segment.startMs) return (null, segment);
    if (nowMs >= segment.endMs) return (segment, null);
    return (
      OccupancySegment(segment.startMs, nowMs),
      OccupancySegment(nowMs, segment.endMs),
    );
  }
}
