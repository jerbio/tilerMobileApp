import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';

/// Represents a scheduling conflict between two tiles
class TileConflict {
  final SubCalendarEvent tile1;
  final SubCalendarEvent tile2;
  final Duration overlapDuration;
  final ConflictType type;

  TileConflict({
    required this.tile1,
    required this.tile2,
    required this.overlapDuration,
    required this.type,
  });

  /// Check if two tiles conflict (overlap in time)
  static TileConflict? detect(SubCalendarEvent current, SubCalendarEvent next) {
    if (current.start == null ||
        current.end == null ||
        next.start == null ||
        next.end == null) {
      return null;
    }

    final currentStart = current.start!;
    final currentEnd = current.end!;
    final nextStart = next.start!;
    final nextEnd = next.end!;

    // Check for overlap: tiles conflict if one starts before the other ends
    if (currentStart < nextEnd && nextStart < currentEnd) {
      // Calculate overlap duration
      final overlapStart = currentStart > nextStart ? currentStart : nextStart;
      final overlapEnd = currentEnd < nextEnd ? currentEnd : nextEnd;
      final overlapMs = overlapEnd - overlapStart;

      if (overlapMs > 0) {
        // Determine conflict type
        ConflictType type;
        if (currentStart == nextStart && currentEnd == nextEnd) {
          type = ConflictType.exactOverlap;
        } else if (currentStart <= nextStart && currentEnd >= nextEnd) {
          type = ConflictType.contains;
        } else if (nextStart <= currentStart && nextEnd >= currentEnd) {
          type = ConflictType.containedBy;
        } else {
          type = ConflictType.partialOverlap;
        }

        return TileConflict(
          tile1: current,
          tile2: next,
          overlapDuration: Duration(milliseconds: overlapMs),
          type: type,
        );
      }
    }

    return null;
  }

  /// Detect all conflicts in a list of tiles
  static List<TileConflict> detectAll(List<SubCalendarEvent> tiles) {
    List<TileConflict> conflicts = [];

    // Sort tiles by start time
    final sortedTiles = List<SubCalendarEvent>.from(tiles);
    sortedTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    for (int i = 0; i < sortedTiles.length; i++) {
      for (int j = i + 1; j < sortedTiles.length; j++) {
        final conflict = detect(sortedTiles[i], sortedTiles[j]);
        if (conflict != null) {
          conflicts.add(conflict);
        }
        // Optimization: if next tile starts after current ends, no more conflicts possible
        if (sortedTiles[j].start != null &&
            sortedTiles[i].end != null &&
            sortedTiles[j].start! >= sortedTiles[i].end!) {
          break;
        }
      }
    }

    return conflicts;
  }
}

enum ConflictType {
  partialOverlap, // Tiles partially overlap
  exactOverlap, // Tiles have exact same time
  contains, // First tile contains second
  containedBy, // First tile is contained by second
}

/// Widget that displays a conflict warning between tiles
class ConflictAlertWidget extends StatelessWidget {
  final TileConflict conflict;
  final VoidCallback? onTap;
  final VoidCallback? onResolve;

  const ConflictAlertWidget({
    Key? key,
    required this.conflict,
    this.onTap,
    this.onResolve,
  }) : super(key: key);

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  IconData _getConflictIcon() {
    switch (conflict.type) {
      case ConflictType.exactOverlap:
        return Icons.error_rounded;
      case ConflictType.contains:
      case ConflictType.containedBy:
        return Icons.warning_amber_rounded;
      case ConflictType.partialOverlap:
        return Icons.schedule_rounded;
    }
  }

  Color _getConflictColor(ColorScheme colorScheme) {
    switch (conflict.type) {
      case ConflictType.exactOverlap:
        return colorScheme.error;
      case ConflictType.contains:
      case ConflictType.containedBy:
        return Colors.orange;
      case ConflictType.partialOverlap:
        return Colors.amber.shade700;
    }
  }

  String _getConflictMessage() {
    final tile1Name = conflict.tile1.name ?? 'Event';
    final tile2Name = conflict.tile2.name ?? 'Event';
    final overlapStr = _formatDuration(conflict.overlapDuration);

    switch (conflict.type) {
      case ConflictType.exactOverlap:
        return '"$tile1Name" and "$tile2Name" are scheduled at the same time';
      case ConflictType.contains:
        return '"$tile2Name" is during "$tile1Name" ($overlapStr overlap)';
      case ConflictType.containedBy:
        return '"$tile1Name" is during "$tile2Name" ($overlapStr overlap)';
      case ConflictType.partialOverlap:
        return '"$tile1Name" overlaps with "$tile2Name" by $overlapStr';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conflictColor = _getConflictColor(colorScheme);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: conflictColor.withAlpha(25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: conflictColor.withAlpha(77),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: conflictColor.withAlpha(51),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getConflictIcon(),
                color: conflictColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Schedule Conflict',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: conflictColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getConflictMessage(),
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withAlpha(179),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onResolve != null)
              TextButton(
                onPressed: onResolve,
                style: TextButton.styleFrom(
                  foregroundColor: conflictColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Fix',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Compact inline conflict indicator shown between tiles
class CompactConflictIndicator extends StatelessWidget {
  final TileConflict conflict;
  final VoidCallback? onTap;

  const CompactConflictIndicator({
    Key? key,
    required this.conflict,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.orange,
            ),
            const SizedBox(width: 6),
            Text(
              'Conflict: ${conflict.overlapDuration.inMinutes}m overlap',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Summary banner showing total conflicts for the day
class ConflictSummaryBanner extends StatelessWidget {
  final List<TileConflict> conflicts;
  final VoidCallback? onTap;

  const ConflictSummaryBanner({
    Key? key,
    required this.conflicts,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (conflicts.isEmpty) return const SizedBox.shrink();

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
                    conflicts.length == 1
                        ? '1 Schedule Conflict'
                        : '${conflicts.length} Schedule Conflicts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to review and resolve',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withAlpha(204),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white,
              size: 24,
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

  /// Group conflicts into clusters of overlapping tiles
  static List<ConflictGroup> groupConflicts(List<TileConflict> conflicts) {
    if (conflicts.isEmpty) return [];

    // Collect all unique tiles involved in conflicts
    Map<String, SubCalendarEvent> allTiles = {};
    Map<String, Set<String>> connections = {};

    for (var conflict in conflicts) {
      allTiles[conflict.tile1.uniqueId] = conflict.tile1;
      allTiles[conflict.tile2.uniqueId] = conflict.tile2;

      // Track connections
      connections.putIfAbsent(conflict.tile1.uniqueId, () => {});
      connections.putIfAbsent(conflict.tile2.uniqueId, () => {});
      connections[conflict.tile1.uniqueId]!.add(conflict.tile2.uniqueId);
      connections[conflict.tile2.uniqueId]!.add(conflict.tile1.uniqueId);
    }

    // Find connected components (groups of mutually conflicting tiles)
    Set<String> visited = {};
    List<ConflictGroup> groups = [];

    for (var tileId in allTiles.keys) {
      if (visited.contains(tileId)) continue;

      // BFS to find all connected tiles
      List<SubCalendarEvent> groupTiles = [];
      List<String> queue = [tileId];

      while (queue.isNotEmpty) {
        var currentId = queue.removeAt(0);
        if (visited.contains(currentId)) continue;
        visited.add(currentId);

        groupTiles.add(allTiles[currentId]!);

        for (var connectedId in connections[currentId] ?? {}) {
          if (!visited.contains(connectedId)) {
            queue.add(connectedId);
          }
        }
      }

      // Sort by start time
      groupTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

      // Calculate total overlap for this group
      Duration totalOverlap = Duration.zero;
      for (var conflict in conflicts) {
        if (groupTiles.any((t) => t.uniqueId == conflict.tile1.uniqueId) &&
            groupTiles.any((t) => t.uniqueId == conflict.tile2.uniqueId)) {
          totalOverlap += conflict.overlapDuration;
        }
      }

      groups.add(ConflictGroup(tiles: groupTiles, totalOverlap: totalOverlap));
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

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) return '${duration.inHours}h';
      return '${duration.inHours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
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
                    '${tiles.length} conflicts',
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
                      'Tap to expand',
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
                  '${tiles.length} Conflicting Events',
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
        // Resolve button
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total overlap: ${_formatDuration(widget.conflictGroup.totalOverlap)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: widget.onResolve,
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('Auto-resolve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade600,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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

    return Container(
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
            tile.name ?? 'Untitled Event',
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

    return GestureDetector(
      onTap: () {
        if (widget.onTileTap != null) {
          widget.onTileTap!(tile);
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TileDetail(tileId: tile.id),
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
                    tile.name ?? 'Untitled Event',
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
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: textColor.withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
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
