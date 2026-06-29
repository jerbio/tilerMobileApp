import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/completionIndicator.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/todayStats.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Today summary row displaying travel time, completion, and optional alerts.
/// When [alertsWidget] is provided it replaces the tile/block count on the left.
class TodaySummaryRow extends StatelessWidget {
  final TodayStats stats;

  /// When supplied, replaces the "X tiles and Y blocks" left column.
  final Widget? alertsWidget;

  const TodaySummaryRow({
    Key? key,
    required this.stats,
    this.alertsWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Left: alerts widget OR tiles/block count
          Expanded(
            child: alertsWidget ??
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.todayColon,
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      l10n.tilesBlocksCount(stats.tileCount, stats.blockCount),
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
          ),

          // Travel time
          if (stats.travelTime.inMinutes > 0) ...[
            Container(
              height: 30,
              width: 1,
              color: colorScheme.outline.withOpacity(0.2),
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.travelTimeColon,
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      stats.travelTime.toHumanLocalized(context),
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('🚗', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],

          // Travel completion percentage
          Container(
            margin: const EdgeInsets.only(left: 12),
            child: CompletionIndicator(
              percentage: stats.travelCompletionPercentage,
            ),
          ),
        ],
      ),
    );
  }
}
