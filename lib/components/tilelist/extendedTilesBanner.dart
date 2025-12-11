import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/util.dart';

/// Summary banner showing extended/all-day tiles (tiles with over 16 hours duration)
class ExtendedTilesBanner extends StatelessWidget {
  final List<SubCalendarEvent> extendedTiles;

  const ExtendedTilesBanner({
    Key? key,
    required this.extendedTiles,
  }) : super(key: key);

  /// Detect all-day or extended tiles (over 16 hours duration)
  static List<SubCalendarEvent> detectExtendedTiles(List<TilerEvent> tiles) {
    const int minDurationMs = 16 * 60 * 60 * 1000; // 16 hours in milliseconds
    
    return tiles
        .whereType<SubCalendarEvent>()
        .where((tile) {
          if (tile.start == null || tile.end == null) return false;
          final duration = tile.end! - tile.start!;
          return duration >= minDurationMs;
        })
        .toList();
  }

  void _showExtendedTilesModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ExtendedTilesModal(extendedTiles: extendedTiles),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (extendedTiles.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => _showExtendedTilesModal(context),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.shade400,
              Colors.indigo.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withAlpha(77),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    extendedTiles.length == 1
                        ? (l10n.extendedEventSingular)
                        : (l10n.extendedEventsPlural(extendedTiles.length)),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.extendedEventsTapToView,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal showing list of extended tiles
class ExtendedTilesModal extends StatelessWidget {
  final List<SubCalendarEvent> extendedTiles;

  const ExtendedTilesModal({
    Key? key,
    required this.extendedTiles,
  }) : super(key: key);

  String _formatDuration(BuildContext context, Duration duration) {
    return Utility.toHuman(duration, abbreviations: true, context: context);
  }

  void _navigateToEditTile(BuildContext context, SubCalendarEvent tile) {
    Navigator.pop(context); // Close modal first
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTile(
          tileId: (tile.isFromTiler ? tile.id : tile.thirdpartyId) ?? "",
          tileSource: tile.thirdpartyType,
          thirdPartyUserId: tile.thirdPartyUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withAlpha(77),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.extendedEventsTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        l10n.extendedEventsSubtitle(extendedTiles.length),
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // List of extended tiles
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: extendedTiles.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final tile = extendedTiles[index];
                final duration = Duration(
                  milliseconds: (tile.end ?? 0) - (tile.start ?? 0),
                );
                final startTime = tile.startTime;
                final endTime = tile.endTime;

                return InkWell(
                  onTap: () => _navigateToEditTile(context, tile),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Color indicator
                        Container(
                          width: 4,
                          height: 48,
                          decoration: BoxDecoration(
                            color: tile.color ?? colorScheme.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        
                        // Tile info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tile.name ?? l10n.untitledEvent,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat('MMM d, h:mm a').format(startTime)} - ${DateFormat('MMM d, h:mm a').format(endTime)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface.withAlpha(153),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Duration badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _formatDuration(context, duration),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        
                        // Chevron
                        Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurface.withAlpha(102),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}
