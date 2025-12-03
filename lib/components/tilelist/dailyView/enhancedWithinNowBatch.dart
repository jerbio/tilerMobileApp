import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/components/tilelist/proactiveAlertBanner.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:intl/intl.dart';

/// Enhanced WithinNowBatch matching the screen 1 design with:
/// - Optimization card showing daily insights
/// - Quick action chips (Focus Mode, Show Route, Re-optimize)
/// - Today summary with task/meeting counts and time saved
/// - Hour markers on the left side
/// - Enhanced tile cards with travel connectors
/// - Proactive departure alerts
class EnhancedWithinNowBatch extends TileBatch {
  EnhancedWithinNowBatchState? _state;

  EnhancedWithinNowBatch({
    List<TilerEvent>? tiles,
    TimelineSummary? dayData,
    Timeline? sleepTimeline,
    Key? key,
  }) : super(
          key: key,
          tiles: tiles,
          dayData: dayData,
          sleepTimeline: sleepTimeline,
          dayIndex: Utility.currentTime().universalDayIndex,
        );

  @override
  EnhancedWithinNowBatchState createState() {
    _state = EnhancedWithinNowBatchState();
    return _state!;
  }
}

class EnhancedWithinNowBatchState extends TileBatchState {
  // UI Configuration
  static const double _heightMargin = 262;
  static const double _hourMarkerWidth = 55;

  // Controllers
  final ScrollController _scrollController = ScrollController();

  // State
  double _emptyDayOpacity = 0;
  bool _isEmptyDay = false;
  List<TileConflict> _detectedConflicts = [];

  // Theming
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToCurrentTime();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to show current/upcoming tiles
  void _scrollToCurrentTime() {
    if (!_scrollController.hasClients) return;

    final currentTimeMs = Utility.currentTime().millisecondsSinceEpoch;
    bool hasPrecedingTiles = false;
    bool hasCurrentTile = false;

    if (widget.tiles != null) {
      for (var tile in widget.tiles!) {
        if (tile is SubCalendarEvent) {
          if (tile.end != null && tile.end! < currentTimeMs) {
            hasPrecedingTiles = true;
          }
          if (tile.start != null &&
              tile.start! <= currentTimeMs &&
              tile.end != null &&
              tile.end! > currentTimeMs) {
            hasCurrentTile = true;
          }
        }
      }
    }

    if (hasPrecedingTiles) {
      // Scroll past the optimization card to show current tiles
      final offset = hasCurrentTile ? 150.0 : 200.0;
      if (_scrollController.position.maxScrollExtent >= offset) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  /// Calculate today's statistics
  _TodayStats _calculateTodayStats(List<TilerEvent> tiles) {
    int tileCount = 0;
    int blockCount = 0;
    int completedCount = 0;
    Duration totalTravelTime = Duration.zero;
    Duration elapsedTravelTime = Duration.zero;

    for (var tile in tiles) {
      if (tile is SubCalendarEvent) {
        // Count as block if it has multiple participants (shared tile)
        final isBlock = tile.tileShareDesignatedId?.isNotEmpty == true;

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

    return _TodayStats(
      tileCount: tileCount,
      blockCount: blockCount,
      completedCount: completedCount,
      travelCompletionPercentage: travelCompletionPercentage,
      travelTime: totalTravelTime,
      elapsedTravelTime: elapsedTravelTime,
    );
  }

  /// Build day summary header that replaces the ribbon for today's view
  Widget _buildDaySummaryHeader() {
    final now = Utility.currentTime();
    final dayOfWeek = DateFormat('EEEE').format(now); // e.g., "Monday"
    final monthDay = DateFormat('MMMM d').format(now); // e.g., "December 1"
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Date information
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.today,
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dayOfWeek,
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                monthDay,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 15,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  /// Build quick action chips row
  Widget _buildQuickActionChips() {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colorScheme.surface,
      child: Row(
        children: [
          _buildActionChip(
            icon: Icons.route,
            label: l10n.showRouteChip,
            onTap: () {
              _navigateToTodaysRoute();
            },
          ),
          const SizedBox(width: 8),
          _buildActionChip(
            icon: Icons.refresh,
            label: l10n.reOptimizeChip,
            onTap: () {
              _triggerRevise();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navigate to today's route page
  void _navigateToTodaysRoute() {
    // Get all tiles that have location info
    final allTiles = widget.tiles ?? [];
    final tilesWithLocations = allTiles
        .whereType<SubCalendarEvent>()
        .where((tile) => tile.isViable ?? true)
        .toList();

    final stats = _calculateTodayStats(tilesWithLocations);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodaysRoutePage(
          tiles: tilesWithLocations,
          timeSaved: stats.travelTime > Duration.zero ? stats.travelTime : null,
        ),
      ),
    );
  }

  /// Build today summary row with stats
  Widget _buildTodaySummaryRow(_TodayStats stats) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Today stats
          Expanded(
            child: Column(
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
                      _formatDuration(stats.travelTime),
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
            child: _buildCompletionIndicator(stats.travelCompletionPercentage),
          ),
        ],
      ),
    );
  }

  /// Build circular completion indicator
  Widget _buildCompletionIndicator(int percentage) {
    return SizedBox(
      width: 45,
      height: 45,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: colorScheme.outline.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage >= 70
                  ? TileColors.completedTeal
                  : percentage >= 40
                      ? TileColors.progressMedium
                      : colorScheme.primary,
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Format duration for display
  String _formatDuration(Duration duration) {
    final l10n = AppLocalizations.of(context)!;
    if (duration.inHours >= 1) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return l10n.durationHoursMinutesShort(hours, minutes);
      }
      return l10n.durationHoursShort(hours);
    }
    return l10n.durationMinutesShort(duration.inMinutes);
  }

  /// Get the next tile requiring departure
  SubCalendarEvent? _getNextDepartureRequiredTile(List<TilerEvent> tiles) {
    final now = Utility.currentTime().millisecondsSinceEpoch;

    for (var tile in tiles) {
      if (tile is SubCalendarEvent) {
        if (tile.start != null && tile.start! > now) {
          if ((tile.travelTimeBefore ?? 0) > 0 ||
              (tile.address?.isNotEmpty ?? false)) {
            return tile;
          }
        }
      }
    }
    return null;
  }

  /// Format hour for display
  String _formatHour(int hour) {
    final l10n = AppLocalizations.of(context)!;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    if (hour >= 12) {
      return l10n.hourPm(displayHour);
    }
    return l10n.hourAm(displayHour);
  }

  /// Build a tile row with hour marker on the left
  Widget _buildTileRowWithHourMarker(
    TilerEvent tile, {
    bool showHourMarker = true,
    bool isCurrentHour = false,
  }) {
    final tileStartTime = tile.startTime;
    final hour = tileStartTime.hour;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour marker column
        Container(
          width: _hourMarkerWidth,
          padding: const EdgeInsets.only(top: 12, right: 8),
          child: showHourMarker
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatHour(hour),
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 12,
                        fontWeight:
                            isCurrentHour ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrentHour
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                    if (isCurrentHour)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // Tile content
        Expanded(
          child: _buildTileWidget(tile),
        ),
      ],
    );
  }

  /// Build the appropriate tile widget with expandable playback controls
  Widget _buildTileWidget(TilerEvent tile) {
    if (tile is SubCalendarEvent) {
      // Check for procrastinate/break tiles using the isProcrastinate flag
      if (tile.isProcrastinate == true) {
        return LunchTileCard(subEvent: tile);
      }
      // Use EnhancedTileCard which now includes expandable playback controls
      return EnhancedTileCard(subEvent: tile);
    }
    return TileWidget(tile);
  }

  /// Build travel connector row with optional hour marker
  Widget _buildConnectorRowWithHourMarker(Widget connector) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: _hourMarkerWidth),
        Expanded(child: connector),
      ],
    );
  }

  /// Build tiles list with travel connectors and conflict handling
  List<Widget> _buildTilesWithConnectors(List<TilerEvent> orderedTiles) {
    List<Widget> widgets = [];
    final now = DateTime.now();
    Set<int> displayedHours = {};

    // Detect conflicts
    final subCalendarEvents =
        orderedTiles.whereType<SubCalendarEvent>().toList();
    _detectedConflicts = TileConflict.detectAll(subCalendarEvents);
    final conflictGroups = ConflictGroup.groupConflicts(_detectedConflicts);

    // Track tiles in conflict groups
    Set<String> tilesInConflictGroups = {};
    for (var group in conflictGroups) {
      for (var tile in group.tiles) {
        tilesInConflictGroups.add(tile.uniqueId);
      }
    }

    Set<int> renderedConflictGroups = {};

    for (int i = 0; i < orderedTiles.length; i++) {
      final tile = orderedTiles[i];
      final tileHour = tile.startTime.hour;
      final isCurrentHour = tile.startTime.day == now.day &&
          tile.startTime.month == now.month &&
          tile.startTime.year == now.year &&
          tileHour == now.hour;

      final showHourMarker = !displayedHours.contains(tileHour);
      if (showHourMarker) {
        displayedHours.add(tileHour);
      }

      // Handle conflict groups
      if (tile is SubCalendarEvent &&
          tilesInConflictGroups.contains(tile.uniqueId)) {
        int groupIndex = conflictGroups.indexWhere(
            (group) => group.tiles.any((t) => t.uniqueId == tile.uniqueId));

        if (groupIndex >= 0 && !renderedConflictGroups.contains(groupIndex)) {
          renderedConflictGroups.add(groupIndex);
          final group = conflictGroups[groupIndex];

          widgets.add(
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: _hourMarkerWidth,
                  padding: const EdgeInsets.only(top: 12, right: 8),
                  child: showHourMarker
                      ? Text(
                          _formatHour(tileHour),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.5),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  child: StackedConflictCards(
                    conflictGroup: group,
                    onTileTap: (tile) {
                      // Handle tile tap
                    },
                  ),
                ),
              ],
            ),
          );
        }
        continue;
      }

      // Regular tile
      widgets.add(_buildTileRowWithHourMarker(
        tile,
        showHourMarker: showHourMarker,
        isCurrentHour: isCurrentHour,
      ));

      // Add travel connector
      if (i < orderedTiles.length - 1) {
        TilerEvent? nextTile;
        for (int j = i + 1; j < orderedTiles.length; j++) {
          final candidate = orderedTiles[j];
          if (candidate is SubCalendarEvent &&
              tilesInConflictGroups.contains(candidate.uniqueId)) {
            continue;
          }
          nextTile = candidate;
          break;
        }

        if (nextTile != null &&
            tile is SubCalendarEvent &&
            nextTile is SubCalendarEvent) {
          final travelTime = nextTile.travelTimeBefore;
          final hasTravel = travelTime != null && travelTime > 0;

          Widget? connector;
          if (hasTravel) {
            connector = TravelConnector(
              fromTile: tile,
              toTile: nextTile,
            );
          } else if (nextTile.address?.isNotEmpty == true) {
            connector = CompactTravelIndicator(
              travelTimeMs: nextTile.travelTimeBefore?.toDouble(),
              travelMode: nextTile.travelDetail?.before?.travelMedium,
              startLocation: nextTile.travelDetail?.before?.startLocation,
              endLocation: nextTile.travelDetail?.before?.endLocation,
              destinationAddress: nextTile.address,
            );
          }

          if (connector != null) {
            widgets.add(_buildConnectorRowWithHourMarker(connector));
          }
        }
      }
    }

    return widgets;
  }

  /// Trigger schedule revise (re-optimize)
  void _triggerRevise() {
    context.read<ScheduleBloc>().add(ReviseScheduleEvent());
  }

  /// Trigger schedule refresh
  void _triggerRefresh() {
    final currentState = context.read<ScheduleBloc>().state;

    if (currentState is ScheduleEvaluationState) {
      context.read<ScheduleBloc>().add(GetScheduleEvent(
            isAlreadyLoaded: true,
            previousSubEvents: currentState.subEvents,
            scheduleTimeline: currentState.lookupTimeline,
            previousTimeline: currentState.lookupTimeline,
            forceRefresh: true,
          ));
      _refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
    } else if (currentState is ScheduleLoadedState) {
      context.read<ScheduleBloc>().add(GetScheduleEvent(
            isAlreadyLoaded: true,
            previousSubEvents: currentState.subEvents,
            scheduleTimeline: currentState.lookupTimeline,
            previousTimeline: currentState.lookupTimeline,
            forceRefresh: true,
          ));
      _refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
    } else if (currentState is ScheduleLoadingState) {
      context.read<ScheduleBloc>().add(GetScheduleEvent(
            isAlreadyLoaded: true,
            previousSubEvents: currentState.subEvents,
            scheduleTimeline: currentState.previousLookupTimeline,
            previousTimeline: currentState.previousLookupTimeline,
            forceRefresh: true,
          ));
      _refreshScheduleSummary(
          lookupTimeline: currentState.previousLookupTimeline);
    }
  }

  void _refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentState = context.read<ScheduleSummaryBloc>().state;

    if (currentState is ScheduleSummaryInitial ||
        currentState is ScheduleDaySummaryLoaded ||
        currentState is ScheduleDaySummaryLoading) {
      context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  /// Render empty day state
  Widget _renderEmptyDayTile() {
    _isEmptyDay = true;

    if (_emptyDayOpacity == 0) {
      Timer(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _emptyDayOpacity = 1;
          });
        }
      });
    }

    if (widget.dayIndex != null) {
      return AnimatedOpacity(
        opacity: _emptyDayOpacity,
        duration: const Duration(milliseconds: 500),
        child: Container(
          height: MediaQuery.of(context).size.height - _heightMargin,
          child: EmptyDayTile(
            deadline: Utility.getTimeFromIndex(widget.dayIndex!).endOfDay,
            dayIndex: widget.dayIndex!,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    // Process tiles
    Map<String, TilerEvent> viableTiles = {};

    if (widget.tiles != null) {
      for (var tile in widget.tiles!) {
        if (tile.id != null &&
            (((tile) as SubCalendarEvent?)?.isViable ?? true)) {
          viableTiles[tile.uniqueId] = tile;
        }
      }
    }

    // Calculate stats
    final stats = _calculateTodayStats(viableTiles.values.toList());

    // Build scrollable content widgets (below the sticky header)
    List<Widget> scrollableContent = [];

    // 1. Today summary row
    scrollableContent.add(_buildTodaySummaryRow(stats));

    // 2. Proactive alert banner
    if (viableTiles.isNotEmpty) {
      final orderedTiles = Utility.orderTiles(viableTiles.values.toList());
      final nextDepartureTile = _getNextDepartureRequiredTile(orderedTiles);

      if (nextDepartureTile != null) {
        scrollableContent.add(
          ProactiveAlertBanner(
            nextTileWithTravel: nextDepartureTile,
            onDismiss: () {},
          ),
        );
      }
    }

    // 3. Sleep tile if present
    if (widget.sleepTimeline != null) {
      scrollableContent.add(SleepTileWidget(widget.sleepTimeline!));
    }

    // 4. Build tiles list or empty state
    Widget tilesContent;
    if (viableTiles.isNotEmpty) {
      final orderedTiles = Utility.orderTiles(viableTiles.values.toList());
      final tilesWithConnectors = _buildTilesWithConnectors(orderedTiles);

      tilesContent = Column(
        children: [
          ...tilesWithConnectors,
          MediaQuery.of(context).orientation == Orientation.landscape
              ? TileDimensions.bottomLandScapePaddingForTileBatchListOfTiles
              : TileDimensions.bottomPortraitPaddingForTileBatchListOfTiles,
        ],
      );
    } else {
      tilesContent = _renderEmptyDayTile();
    }

    // Use CustomScrollView with SliverAppBar for sticky action chips
    return RefreshIndicator(
      color: colorScheme.tertiary,
      onRefresh: () async {
        _triggerRefresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        physics: _isEmptyDay
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Sticky header with date and action chips
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickyActionChipsDelegate(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDaySummaryHeader(),
                  _buildQuickActionChips(),
                ],
              ),
              minHeight: 160,
              maxHeight: 160,
            ),
          ),

          // Rest of the content
          SliverToBoxAdapter(
            child: Column(
              children: [
                ...scrollableContent,
                const SizedBox(height: 8),
                tilesContent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for today's statistics
class _TodayStats {
  final int tileCount;
  final int blockCount;
  final int completedCount;
  final int travelCompletionPercentage;
  final Duration travelTime;
  final Duration elapsedTravelTime;

  const _TodayStats({
    required this.tileCount,
    required this.blockCount,
    required this.completedCount,
    required this.travelCompletionPercentage,
    required this.travelTime,
    required this.elapsedTravelTime,
  });
}

/// Delegate for sticky action chips header
class _StickyActionChipsDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minHeight;
  final double maxHeight;

  _StickyActionChipsDelegate({
    required this.child,
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => maxHeight;

  @override
  double get minExtent => minHeight;

  @override
  bool shouldRebuild(_StickyActionChipsDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
