// The pinned >=16h / all-day header for the day grid.
//
// DayGridWidget excludes >=16h tiles from the timeline
// (`_renderableInTimeline`). The pinned header keeps those tiles visible in
// grid mode: pinned above the grid, not on the timeline. It renders no
// content (but stays mounted) when there are no excluded tiles.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Pinned header showing the >=16h / all-day tiles that the grid timeline
/// excludes.
class DayGridPinnedHeader extends StatelessWidget {
  /// The grid's parity-filtered tile set. The excluded subset shown in the
  /// header is computed with [excludedTiles].
  final List<SubCalendarEvent> tiles;

  const DayGridPinnedHeader({
    super.key,
    this.tiles = const <SubCalendarEvent>[],
  });

  /// Tiles that belong in the pinned header instead of the grid timeline:
  /// duration >= 16h (boundary inclusive — matches
  /// `DayGridWidget.extendedTileDuration`). Tiles with null start/end are
  /// dropped (the `duration` getter throws on null bounds).
  static List<SubCalendarEvent> excludedTiles(List<SubCalendarEvent> tiles) {
    const int minDurationMs = 16 * 60 * 60 * 1000;
    return tiles.where((tile) {
      if (tile.start == null || tile.end == null) return false;
      return (tile.end! - tile.start!) >= minDurationMs;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final excluded = excludedTiles(tiles);
    if (excluded.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final hm = DateFormat.Hm();
    final colorScheme = Theme.of(context).colorScheme;
    // Pinned card: tertiary-tinted, calendar glyph, one row per extended
    // tile with "All day" (or the time range) trailing.
    return Container(
      key: const Key('daygrid_pinned_card'),
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.tertiary,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.tertiary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.calendar_today_rounded,
              color: colorScheme.onTertiary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.extendedEventsTitle,
                  style: TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onTertiary,
                  ),
                ),
                for (final tile in excluded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tile.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: TileTextStyles.rubikFontName,
                              fontSize: 13,
                              color: colorScheme.onTertiary.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tile.isAllDay
                              ? l10n.dayGridAllDay
                              : '${hm.format(DateTime.fromMillisecondsSinceEpoch(tile.start!))} - ${hm.format(DateTime.fromMillisecondsSinceEpoch(tile.end!))}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onTertiary.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
