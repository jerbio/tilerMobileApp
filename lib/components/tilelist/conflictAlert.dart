import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

/// Summary banner showing total conflicts for the day
class ConflictSummaryBanner extends StatelessWidget {
  final List<ConflictGroup> conflictGroups;
  final VoidCallback? onTap;

  const ConflictSummaryBanner({
    Key? key,
    required this.conflictGroups,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (conflictGroups.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    // Calculate total number of conflicts (tiles involved - 1 per group)
    int conflictCount =
        conflictGroups.fold(0, (sum, group) => sum + (group.tiles.length));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade400,
              Colors.deepOrange.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withAlpha(77),
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
                Icons.warning_rounded,
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
                    conflictCount == 1
                        ? l10n.oneScheduleConflict
                        : l10n.countScheduleConflicts(conflictCount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A group of conflicting tiles that can be displayed as stacked cards
class ConflictGroup {
  final List<SubCalendarEvent> tiles;
  final Duration totalOverlap;

  ConflictGroup({
    required this.tiles,
    required this.totalOverlap,
  });

  /// Detect all conflict groups in a list of tiles
  static List<ConflictGroup> detectGroups(List<SubCalendarEvent> tiles) {
    List<ConflictGroup> groups = [];

    // Use Utility.getConflictingEvents to find clusters of conflicts
    final conflictResult = Utility.getConflictingEvents(tiles);
    final blobs = conflictResult.item1;
    print(blobs.length.toString() + ' blobs found');

    for (var blob in blobs) {
      final blobTiles = blob.AllTiles.whereType<SubCalendarEvent>().toList();

      // Skip if less than 2 tiles (no conflict)
      if (blobTiles.length < 2) continue;

      // Sort by start time
      blobTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
      print('Blob tiles: ${blobTiles.map((t) => t.name).toList()}');

      final blobDuration =
          Duration(milliseconds: (blob.end ?? 0) - (blob.start ?? 0));

      groups.add(ConflictGroup(tiles: blobTiles, totalOverlap: blobDuration));
    }

    return groups;
  }
}

/// Stacked conflict cards that expand when tapped
class StackedConflictCards extends StatefulWidget {
  final ConflictGroup conflictGroup;
  final Function(SubCalendarEvent)? onTileTap;
  final VoidCallback? onResolve;

  const StackedConflictCards({
    Key? key,
    required this.conflictGroup,
    this.onTileTap,
    this.onResolve,
  }) : super(key: key);

  @override
  State<StackedConflictCards> createState() => _StackedConflictCardsState();
}

class _StackedConflictCardsState extends State<StackedConflictCards>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  String? _expandedActionsForTileId;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  String _formatTime(DateTime time, BuildContext context) {
    return MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(time));
  }

  String _formatDuration(BuildContext context, Duration duration) {
    final l10n = AppLocalizations.of(context)!;
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return l10n.durationHoursMinutesShort(duration.inHours, minutes);
      }
      return l10n.durationHoursShort(duration.inHours);
    }
    return l10n.durationMinutesShort(duration.inMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final tiles = widget.conflictGroup.tiles;

    if (tiles.isEmpty) return const SizedBox.shrink();
    if (tiles.length == 1) {
      return _buildSingleTileCard(tiles.first, context, 0);
    }

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        return Column(
          children: [
            // Stacked cards container
            GestureDetector(
              onTap: _toggleExpanded,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: _isExpanded
                    ? _buildExpandedView(context)
                    : _buildStackedView(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStackedView(BuildContext context) {
    final tiles = widget.conflictGroup.tiles;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Show max 3 cards stacked, with the rest hidden
    final visibleCount = tiles.length.clamp(0, 3);
    const stackOffset = 8.0;
    const rotationAngle = 0.02;

    return SizedBox(
      height: 120 + (visibleCount - 1) * stackOffset,
      child: Stack(
        children: [
          // Background cards (stacked effect)
          for (int i = visibleCount - 1; i >= 0; i--)
            Positioned(
              top: i * stackOffset,
              left: i * 2.0,
              right: i * 2.0,
              child: Transform.rotate(
                angle: (i - 1) * rotationAngle,
                child: _buildCompactTileCard(
                  tiles[i],
                  context,
                  i,
                  isTop: i == 0,
                ),
              ),
            ),
          // Conflict badge overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withAlpha(100),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.countConflicts(tiles.length),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Tap to expand hint
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withAlpha(230),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(50),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 14,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.tapToExpand,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withAlpha(179),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView(BuildContext context) {
    final tiles = widget.conflictGroup.tiles;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header with collapse button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: Colors.orange.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context)!.conflictingTiles(tiles.length),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.unfold_less_rounded,
                    size: 18,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Expanded cards
        ...tiles.asMap().entries.map((entry) {
          final index = entry.key;
          final tile = entry.value;
          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return FadeTransition(
                opacity: _expandAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0, -0.2 * (index + 1)),
                    end: Offset.zero,
                  ).animate(_expandAnimation),
                  child: _buildExpandedTileCard(tile, context, index),
                ),
              );
            },
          );
        }),
        // Footer with total overlap
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            AppLocalizations.of(context)!.totalOverlap(
                _formatDuration(context, widget.conflictGroup.totalOverlap)),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(153),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactTileCard(
    SubCalendarEvent tile,
    BuildContext context,
    int index, {
    bool isTop = false,
  }) {
    // Get tile colors
    final redColor = tile.colorRed ?? 127;
    final greenColor = tile.colorGreen ?? 127;
    final blueColor = tile.colorBlue ?? 127;
    final tileColor = Color.fromRGBO(redColor, greenColor, blueColor, 1);

    final hslColor = HSLColor.fromColor(tileColor);
    final isLightBackground = hslColor.lightness > 0.6;
    final textColor = isLightBackground ? Colors.black87 : Colors.white;

    return GestureDetector(
      onTap: () {
        if (widget.onTileTap != null) {
          widget.onTileTap!(tile);
        } else {
          if (!(tile.isReadOnly ?? true)) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditTile(
                  tileId:
                      (tile.isFromTiler ? tile.id : tile.thirdpartyId) ?? "",
                  tileSource: tile.thirdpartyType,
                  thirdPartyUserId: tile.thirdPartyUserId,
                ),
              ),
            );
          }
        }
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              tileColor,
              hslColor
                  .withLightness((hslColor.lightness - 0.1).clamp(0, 1))
                  .toColor(),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: tileColor.withAlpha(isTop ? 100 : 50),
              blurRadius: isTop ? 8 : 4,
              offset: Offset(0, isTop ? 4 : 2),
            ),
          ],
          border: Border.all(
            color: Colors.orange.withAlpha(isTop ? 150 : 100),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time range
            Text(
              '${_formatTime(tile.startTime, context)} - ${_formatTime(tile.endTime, context)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            // Title
            Text(
              tile.name ?? AppLocalizations.of(context)!.untitledTile,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedTileCard(
    SubCalendarEvent tile,
    BuildContext context,
    int index,
  ) {
    // Get tile colors
    final redColor = tile.colorRed ?? 127;
    final greenColor = tile.colorGreen ?? 127;
    final blueColor = tile.colorBlue ?? 127;
    final tileColor = Color.fromRGBO(redColor, greenColor, blueColor, 1);

    final hslColor = HSLColor.fromColor(tileColor);
    final isLightBackground = hslColor.lightness > 0.6;
    final textColor = isLightBackground ? Colors.black87 : Colors.white;
    final secondaryTextColor =
        isLightBackground ? Colors.black54 : Colors.white70;

    final location = tile.addressDescription ?? tile.address;
    final duration = tile.duration;
    final isActionsExpanded = _expandedActionsForTileId == tile.uniqueId;

    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (!(tile.isReadOnly ?? true)) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTile(
                    tileId:
                        (tile.isFromTiler ? tile.id : tile.thirdpartyId) ?? "",
                    tileSource: tile.thirdpartyType,
                    thirdPartyUserId: tile.thirdPartyUserId,
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(top: 1),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  tileColor,
                  hslColor
                      .withLightness((hslColor.lightness - 0.1).clamp(0, 1))
                      .toColor(),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                left: BorderSide(color: Colors.orange.shade200),
                right: BorderSide(color: Colors.orange.shade200),
              ),
            ),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time range
                      Text(
                        '${_formatTime(tile.startTime, context)} - ${_formatTime(tile.endTime, context)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Title
                      Text(
                        tile.name ?? AppLocalizations.of(context)!.untitledTile,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (location != null && location.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                location,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: secondaryTextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Duration badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _formatDuration(context, duration),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Arrow - toggles playback actions (only for Tiler tiles)
                if (tile.isFromTiler)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        if (_expandedActionsForTileId == tile.uniqueId) {
                          _expandedActionsForTileId = null;
                        } else {
                          _expandedActionsForTileId = tile.uniqueId;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isActionsExpanded
                            ? textColor.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AnimatedRotation(
                        turns: isActionsExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: textColor.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Expandable playback actions (only for Tiler tiles)
        if (tile.isFromTiler)
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            child: isActionsExpanded
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border(
                        left: BorderSide(color: Colors.orange.shade200),
                        right: BorderSide(color: Colors.orange.shade200),
                        bottom: BorderSide(color: Colors.orange.shade200),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: PlayBack(tile),
                  )
                : const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildSingleTileCard(
    SubCalendarEvent tile,
    BuildContext context,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: _buildExpandedTileCard(tile, context, index),
    );
  }
}
