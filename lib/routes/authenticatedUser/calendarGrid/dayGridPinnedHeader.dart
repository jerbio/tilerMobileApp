// DayGrid P1 step 1.7 (C7) — the pinned >=16h / all-day header for grid
// mode.
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
/// excludes (step 1.7, C7).
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.indigo.shade400,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withAlpha(77),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.extendedEventsTitle,
                  style: const TextStyle(
                    fontFamily: TileTextStyles.rubikFontName,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          for (final tile in excluded)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tile.name ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${hm.format(DateTime.fromMillisecondsSinceEpoch(tile.start!))} - ${hm.format(DateTime.fromMillisecondsSinceEpoch(tile.end!))}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(204),
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