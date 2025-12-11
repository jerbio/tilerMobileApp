import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/components.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/models.dart';
import 'package:tiler_app/components/tilelist/proactiveAlertBanner.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';

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
  List<ConflictGroup> _detectedConflicts = [];

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

  /// Navigate to today's route page
  void _navigateToTodaysRoute() {
    // Get all tiles that have location info
    final allTiles = widget.tiles ?? [];
    final tilesWithLocations = allTiles
        .whereType<SubCalendarEvent>()
        .where((tile) => tile.isViable ?? true)
        .toList();

    final stats = TodayStats.fromTiles(tilesWithLocations);

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

  /// Build the appropriate tile widget with expandable playback controls
  Widget _buildTileWidget(TilerEvent tile) {
    if (tile is SubCalendarEvent) {
      // EnhancedTileCard handles all tile types including procrastinate/break tiles
      return EnhancedTileCard(subEvent: tile);
    }
    return TileWidget(tile);
  }

  /// Build tiles list with travel connectors and conflict handling
  List<Widget> _buildTilesWithConnectors(List<TilerEvent> orderedTiles) {
    List<Widget> widgets = [];
    final now = DateTime.now();
    Set<int> displayedHours = {};

    // Filter out extended tiles (they're shown in the ExtendedTilesBanner)
    const int minDurationMs = 16 * 60 * 60 * 1000; // 16 hours in milliseconds
    final regularTiles = orderedTiles.where((tile) {
      if (tile is SubCalendarEvent && tile.start != null && tile.end != null) {
        final duration = tile.end! - tile.start!;
        return duration < minDurationMs;
      }
      return true;
    }).toList();

    // Detect conflicts (only from regular tiles)
    final subCalendarEvents =
        regularTiles.whereType<SubCalendarEvent>().toList();
    final conflictGroups = ConflictGroup.detectGroups(subCalendarEvents);
    _detectedConflicts = conflictGroups;

    // Track tiles in conflict groups
    Set<String> tilesInConflictGroups = {};
    for (var group in conflictGroups) {
      for (var tile in group.tiles) {
        tilesInConflictGroups.add(tile.uniqueId);
      }
    }

    Set<int> renderedConflictGroups = {};

    for (int i = 0; i < regularTiles.length; i++) {
      final tile = regularTiles[i];
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
            TileRowWithHourMarker(
              hour: tileHour,
              showHourMarker: showHourMarker,
              isCurrentHour: isCurrentHour,
              hourMarkerWidth: _hourMarkerWidth,
              child: StackedConflictCards(
                conflictGroup: group,
                onTileTap: (tile) {
                  // Handle tile tap
                },
              ),
            ),
          );
        }
        continue;
      }

      // Regular tile
      widgets.add(
        TileRowWithHourMarker(
          hour: tileHour,
          showHourMarker: showHourMarker,
          isCurrentHour: isCurrentHour,
          hourMarkerWidth: _hourMarkerWidth,
          child: _buildTileWidget(tile),
        ),
      );

      // Add travel connector
      if (i < regularTiles.length - 1) {
        TilerEvent? nextTile;
        for (int j = i + 1; j < regularTiles.length; j++) {
          final candidate = regularTiles[j];
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
            widgets.add(
              ConnectorRowWithHourMarker(
                connector: connector,
                hourMarkerWidth: _hourMarkerWidth,
              ),
            );
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
        if (tile.id != null) {
          final subEvent = tile as SubCalendarEvent?;
          final isViable = subEvent?.isViable ?? true;
          final isFromTiler = tile.isFromTiler;
          final rsvpStatus = subEvent?.rsvp;

          // Show tile if:
          // 1. It's a Tiler tile and is viable, OR
          // 2. It's a third-party tile (always show unless declined)
          final isDeclined = rsvpStatus == RsvpStatus.declined;

          if ((isFromTiler && isViable) || (!isFromTiler && !isDeclined)) {
            viableTiles[tile.uniqueId] = tile;
          }
        }
      }
    }

    // Calculate stats
    final stats = TodayStats.fromTiles(viableTiles.values.toList());

    // Update dayData with non-viable tiles for display in header
    if (dayData != null && widget.tiles != null) {
      dayData!.nonViable = widget.tiles!
          .where((tile) => !((tile as SubCalendarEvent).isViable ?? true))
          .toList();
    }

    // Build scrollable content widgets (below the sticky header)
    List<Widget> scrollableContent = [];

    // 1. Today summary row
    scrollableContent.add(TodaySummaryRow(stats: stats));

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

    // 2b. Extended tiles banner
    if (viableTiles.isNotEmpty) {
      final extendedTiles =
          ExtendedTilesBanner.detectExtendedTiles(viableTiles.values.toList());

      if (extendedTiles.isNotEmpty) {
        scrollableContent.add(
          ExtendedTilesBanner(
            extendedTiles: extendedTiles,
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
            delegate: StickyDayHeaderDelegate(
              dayData: dayData,
              onShowRoute: _navigateToTodaysRoute,
              onReOptimize: _triggerRevise,
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
