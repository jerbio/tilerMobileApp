import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/util.dart';

/// Helper class for today's statistics
class TodayStats {
  final int tileCount;
  final int blockCount;
  final int completedCount;
  final int travelCompletionPercentage;
  final Duration travelTime;
  final Duration elapsedTravelTime;

  const TodayStats({
    required this.tileCount,
    required this.blockCount,
    required this.completedCount,
    required this.travelCompletionPercentage,
    required this.travelTime,
    required this.elapsedTravelTime,
  });

  /// Factory to create empty stats
  factory TodayStats.empty() {
    return const TodayStats(
      tileCount: 0,
      blockCount: 0,
      completedCount: 0,
      travelCompletionPercentage: 0,
      travelTime: Duration.zero,
      elapsedTravelTime: Duration.zero,
    );
  }

  /// Calculate today's statistics from a list of tiles
  factory TodayStats.fromTiles(List<TilerEvent> tiles) {
    int tileCount = 0;
    int blockCount = 0;
    int completedCount = 0;
    Duration totalTravelTime = Duration.zero;
    Duration elapsedTravelTime = Duration.zero;

    for (var tile in tiles) {
      if (tile is SubCalendarEvent) {
        // Count as block if isRigid flag is true
        final isBlock = tile.isRigid == true;

        if (isBlock) {
          blockCount++;
        } else {
          tileCount++;
        }

        if (tile.isComplete) {
          completedCount++;
        }

        // Sum up travel time
        if (tile.travelTimeBefore != null && tile.travelTimeBefore! > 0) {
          final travelDuration =
              Duration(milliseconds: tile.travelTimeBefore!.toInt());
          totalTravelTime += travelDuration;

          // Add to elapsed if tile is complete or has started
          final now = Utility.currentTime().millisecondsSinceEpoch;
          if (tile.isComplete || (tile.start != null && tile.start! <= now)) {
            elapsedTravelTime += travelDuration;
          }
        }
      }
    }

    // Calculate travel completion percentage
    final travelCompletionPercentage = totalTravelTime.inMinutes > 0
        ? (elapsedTravelTime.inMilliseconds /
                totalTravelTime.inMilliseconds *
                100)
            .round()
        : 0;

    return TodayStats(
      tileCount: tileCount,
      blockCount: blockCount,
      completedCount: completedCount,
      travelCompletionPercentage: travelCompletionPercentage,
      travelTime: totalTravelTime,
      elapsedTravelTime: elapsedTravelTime,
    );
  }

  /// Total number of items (tiles + blocks)
  int get totalCount => tileCount + blockCount;

  /// Completion percentage based on completed vs total
  int get completionPercentage =>
      totalCount > 0 ? ((completedCount / totalCount) * 100).round() : 0;
}
