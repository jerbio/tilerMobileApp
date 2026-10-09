import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:super_sliver_list/super_sliver_list.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tileUI/tileDetailBottomSheet.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/components.dart';
import 'package:tiler_app/components/tilelist/dailyView/models/models.dart';
import 'package:tiler_app/components/tilelist/dailyView/motion/listMotion.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileConnectorLayout.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/freeSlotRow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/services/scheduleMotion.dart';
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
  final String? selectedActionEntityId;
  final bool preview;
  final DateTime? endOfDayTime;
  final VoidCallback? onEndOfDayUpdated;

  /// Whether to pin the day-summary header (date + counts, action chips,
  /// loading bar) at the top of the list. `false` when hosted under the
  /// Daily top bar, whose shared chrome carries all of it for both layouts.
  final bool showDaySummaryHeader;

  /// Whether travel connectors (incl. the return-home connector) render.
  /// `false` while the Daily content filter (P7) is active.
  final bool showTravelConnectors;

  /// Whether free-time gaps render between tiles. `false` while the Daily
  /// content filter (P7) is active (gaps from a filtered set mislead).
  final bool showFreeSlots;
  EnhancedWithinNowBatch({
    List<TilerEvent>? tiles,
    TimelineSummary? dayData,
    Timeline? sleepTimeline,
    this.preview = false,
    this.selectedActionEntityId,
    this.endOfDayTime,
    this.onEndOfDayUpdated,
    this.showDaySummaryHeader = true,
    this.showTravelConnectors = true,
    this.showFreeSlots = true,
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
  final ListController _listController = ListController();

  // State
  double _emptyDayOpacity = 0;
  bool _isEmptyDay = false;
  bool _isAutoScrolled = false;
  List<ConflictGroup> _detectedConflicts = [];

  /// Schedule-change motion for today: keeps the tile the user is looking
  /// at in place, flies moved tiles, and shows edge chips.
  late final ListMotion _motion = ListMotion(apply: (change) {
    if (mounted) {
      setState(change);
    }
  });

  /// The rows of the last build (keys and where each tile sits).
  TileConnectorLayoutResult? _rowLayout;

  /// The tiles of the last build, by uniqueId, for flying copies.
  Map<String, TilerEvent> _tilesById = const <String, TilerEvent>{};

  // Theming
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  @override
  void dispose() {
    _motion.dispose();
    _scrollController.dispose();
    _listController.dispose();
    super.dispose();
  }

  /// Auto-scroll the today batch so the active card (the tile happening now,
  /// else the live free slot, else the next upcoming tile) is brought into
  /// view. Runs once per mount, after the SuperSliverList has laid out.
  void _autoScrollToFocus(int focusIndex) {
    if (_isAutoScrolled) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listController.isAttached || !_scrollController.hasClients) return;
      _isAutoScrolled = true;
      _listController.jumpToItem(
        index: focusIndex,
        scrollController: _scrollController,
        alignment: 0.15,
      );
    });
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
      final isTutorialCurrent = tile.id != null &&
          tile.id!.startsWith('tutorial-tile-') &&
          tile.isCurrent;
      final preview = (widget as EnhancedWithinNowBatch).preview;
      // Compact, fixed-height list tile for the live daily list (not the
      // TileCast preview and not the tour's current tile, which keeps the full
      // expandable card). Tapping the compact tile opens the detail bottom
      // sheet (playback + the time scrub when the tile is active).
      final useCompact = !preview && !isTutorialCurrent;
      final card = EnhancedTileCard(
        subEvent: tile,
        initiallyExpanded: isTutorialCurrent,
        preview: preview,
        compact: useCompact,
        onTileTap: useCompact
            ? () => showTileDetailBottomSheet(context, tile,
                preview: preview)
            : null,
        hasDottedBorder:
            (widget as EnhancedWithinNowBatch).selectedActionEntityId != null &&
                tile.id?.contains((widget as EnhancedWithinNowBatch)
                        .selectedActionEntityId!) ==
                    true,
      );
      if (isTutorialCurrent) {
        return Container(
          key: TutorialKeys.currentTileKey,
          child: card,
        );
      }
      return card;
    }
    return TileWidget(tile,
        preview: (widget as EnhancedWithinNowBatch).preview);
  }

  /// Build tiles list with travel connectors and conflict handling
  (List<Widget>, int?, int?) _buildTilesWithConnectors(
      List<TilerEvent> orderedTiles) {
    final withinNow = widget as EnhancedWithinNowBatch;
    final result = buildTileListWithConnectors(
      orderedTiles: orderedTiles,
      showTravelConnectors: withinNow.showTravelConnectors,
      showConflictAlerts: true,
      excludeDeclinedFromConflicts: true,
      now: DateTime.now(),
      selectedActionEntityId: withinNow.selectedActionEntityId,
      endOfDayTime: withinNow.endOfDayTime,
      onEndOfDayUpdated: withinNow.onEndOfDayUpdated,
      buildTile: (tile,
          {required hour, required showHourMarker, required isCurrentHour}) {
        return TileRowWithHourMarker(
          hour: hour,
          showHourMarker: showHourMarker,
          isCurrentHour: isCurrentHour,
          hourMarkerWidth: _hourMarkerWidth,
          child: _buildTileWidget(tile),
        );
      },
      buildConflictGroup: (group,
          {required hour, required showHourMarker, required isCurrentHour}) {
        return TileRowWithHourMarker(
          hour: hour,
          showHourMarker: showHourMarker,
          isCurrentHour: isCurrentHour,
          hourMarkerWidth: _hourMarkerWidth,
          child: StackedConflictCards(
            conflictGroup: group,
            preview: withinNow.preview,
            onTileTap: (tile) {
              // Handle tile tap
            },
          ),
        );
      },
      wrapConnector: (connector) => ConnectorRowWithHourMarker(
        connector: connector,
        hourMarkerWidth: _hourMarkerWidth,
      ),
      buildFreeSlot: !withinNow.showFreeSlots
          ? null
          : (slot) => ConnectorRowWithHourMarker(
                connector:
                    FreeSlotRow(slot: slot, preview: withinNow.preview),
                hourMarkerWidth: _hourMarkerWidth,
              ),
    );

    _detectedConflicts = result.conflictGroups;
    _rowLayout = result;
    return (result.keyedRows, result.selectedTileIndex, result.currentFocusIndex);
  }

  /// Notes where the anchor tile sits before rows for a new schedule
  /// revision are built.
  void _captureAnchor(List<TilerEvent> orderedTiles) {
    final withinNow = widget as EnhancedWithinNowBatch;
    if (withinNow.preview ||
        !_listController.isAttached ||
        !_scrollController.hasClients) {
      return;
    }
    final range = _listController.visibleRange;
    final layout = _rowLayout;
    if (range == null || layout == null) return;
    final position = _scrollController.position;
    double? alignmentOf(int row) => row < layout.rowKeys.length
        ? _motion.rows.alignmentOf(layout.rowKeys[row], position)
        : null;
    final dayStart = Utility.currentTime().dayDate;
    _motion.anchor.capture(
      context,
      tiles: orderedTiles.whereType<SubCalendarEvent>().toList(),
      day: Timeline.fromDateTime(dayStart,
          DateTime(dayStart.year, dayStart.month, dayStart.day + 1)),
      visibleRows: [
        for (var row = range.$1; row <= range.$2; row++)
          if ((alignmentOf(row) ?? -1) >= 0) row,
      ],
      alignmentOf: alignmentOf,
    );
    // Moved tiles that were on screen: hold them for their flight.
    _motion.beforeRows(context, layout, preview: withinNow.preview);
  }

  /// Scrolls the anchor back to its old spot once the new rows are laid
  /// out, when rows above it came or went.
  void _restoreAnchor(List<TilerEvent> orderedTiles) {
    final layout = _rowLayout;
    if (layout == null) return;
    final restore = _motion.anchor.resolve(
        orderedTiles.whereType<SubCalendarEvent>().toList(), layout.rowOfTile);
    if (_motion.hasPending) {
      // Measure where the moved tiles landed once the new rows are laid
      // out and the anchor correction (itself after a frame) has applied.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _motion.afterLayout(layout, _listController.visibleRange);
          }
        });
        WidgetsBinding.instance.scheduleFrame();
      });
    }
    if (restore == null || !restore.moved) return;
    Utility.debugPrint('DailyList::anchor ${restore.tileId} row '
        '${restore.previousRow} -> ${restore.row} '
        'at ${restore.alignment.toStringAsFixed(2)}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_listController.isAttached ||
          !_scrollController.hasClients) {
        return;
      }
      _listController.jumpToItem(
        index: restore.row,
        scrollController: _scrollController,
        alignment: restore.alignment,
      );
    });
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
    // With schedule-update motion off the empty state shows at once.
    final emptyFades = ScheduleMotion.modeFor(context).animates;
    if (!emptyFades) _emptyDayOpacity = 1;

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
        duration:
            emptyFades ? const Duration(milliseconds: 500) : Duration.zero,
        child: Container(
          height: MediaQuery.of(context).size.height - _heightMargin,
          child: EmptyDayTile(
            deadline: Utility.getTimeFromIndex(widget.dayIndex!).endOfDay,
            dayIndex: widget.dayIndex!,
            preview: (widget as EnhancedWithinNowBatch).preview,
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
    List<SubCalendarEvent> pendingRsvpTiles = [];
    List<SubCalendarEvent> declinedTiles = [];
    final now = Utility.currentTime().millisecondsSinceEpoch;

    if (widget.tiles != null) {
      for (var tile in widget.tiles!) {
        if (tile.id != null) {
          final subEvent = tile as SubCalendarEvent?;
          final isViable = subEvent?.isViable ?? true;
          final isFromTiler = tile.isFromTiler;
          final rsvpStatus = subEvent?.rsvp;

          // Check if this is a pending RSVP tile (needs action or tentative)
          final isPendingRsvp = !isFromTiler &&
              (rsvpStatus == RsvpStatus.needsAction ||
                  rsvpStatus == RsvpStatus.tentative);

          // Check if this is a declined tile
          final isDeclined = !isFromTiler && rsvpStatus == RsvpStatus.declined;

          // Track pending RSVP tiles separately (exclude past events)
          if (isPendingRsvp && subEvent != null) {
            pendingRsvpTiles.add(subEvent);
          }

          // Track declined tiles separately (exclude old events)
          if (isDeclined && subEvent != null) {
            declinedTiles.add(subEvent);
          }

          // Show tile if it's not pending RSVP and not declined
          final shouldShowInMainList = !isPendingRsvp && !isDeclined;

          if (shouldShowInMainList && isViable) {
            viableTiles[tile.uniqueId] = tile;
          }
        }
      }
    }

    // Sort pending RSVP and declined tiles by start time
    pendingRsvpTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
    declinedTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    // Calculate stats
    final stats = TodayStats.fromTiles(viableTiles.values.toList());

    // Update dayData with non-viable tiles for display in header. Only
    // nonViable is derivable from widget.tiles; the completed/tardy lists
    // never appear in widget.tiles and come solely from the daySummarys web
    // request, surfaced by DaySummaryHeader via its retrieval cache.
    if (dayData != null && widget.tiles != null) {
      dayData!.nonViable = widget.tiles!
          .whereType<SubCalendarEvent>()
          .where((tile) => !(tile.isViable ?? true))
          .toList();
    }

    // Detect all alert data before building content
    SubCalendarEvent? nextDepartureTile;
    List<SubCalendarEvent> extendedTiles = [];

    if (viableTiles.isNotEmpty) {
      final orderedTilesForAlerts =
          Utility.orderTiles(viableTiles.values.toList());
      nextDepartureTile = _getNextDepartureRequiredTile(orderedTilesForAlerts);
      extendedTiles =
          ExtendedTilesBanner.detectExtendedTiles(viableTiles.values.toList());
    }

    final withinNow = widget as EnhancedWithinNowBatch;

    // Build scrollable content widgets (below the sticky header)
    List<Widget> scrollableContent = [];

    // 1. Merged summary row: travel time + completion on the right;
    //    alert chips (conflict, RSVP, extended, departure) on the left.
    scrollableContent.add(TodaySummaryRow(
      stats: stats,
      alertsWidget: CombinedAlertsBanner(
        inline: true,
        nextTileWithTravel: nextDepartureTile,
        onTravelTap: () {},
        onTravelDismiss: () {},
        conflictGroups: _detectedConflicts,
        onConflictTap: () {},
        extendedTiles: extendedTiles,
        onExtendedTap: () {
          CombinedAlertsBannerHelpers.showExtendedTilesModal(
              preview: withinNow.preview, context, extendedTiles);
        },
        pendingRsvpTiles: pendingRsvpTiles,
        declinedTiles: declinedTiles,
        onRsvpTap: () {
          CombinedAlertsBannerHelpers.showPendingRsvpModal(
            preview: withinNow.preview,
            context,
            pendingRsvpTiles,
            declinedTiles: declinedTiles,
            onRsvpUpdated: () => _triggerRefresh(),
          );
        },
        onRsvpUpdated: () => _triggerRefresh(),
      ),
    ));

    // 3. Sleep tile if present
    if (widget.sleepTimeline != null) {
      scrollableContent.add(SleepTileWidget(widget.sleepTimeline!));
    }

    // 4. Build tiles list or empty state
    Widget tilesContent;
    _tilesById = viableTiles;
    if (viableTiles.isNotEmpty) {
      final orderedTiles = Utility.orderTiles(viableTiles.values.toList());
      _captureAnchor(orderedTiles);
      final (tilesWithConnectors, targetScrollIndex, focusIndex) =
          _buildTilesWithConnectors(orderedTiles);
      _restoreAnchor(orderedTiles);
      final rowLayout = _rowLayout;

      // All tiles may have been filtered out (e.g. only all-day events which
      // are ≥16h and excluded from the timeline). Show EmptyDayTile so the
      // chips at the top handle alerting and the body stays familiar.
      if (tilesWithConnectors.isEmpty) {
        tilesContent = SliverToBoxAdapter(
          child: _renderEmptyDayTile(),
        );
      } else {
        if (withinNow.preview && targetScrollIndex != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _listController.jumpToItem(
              index: targetScrollIndex,
              scrollController: _scrollController,
              alignment: 0.15,
            );
          });
        } else if (!withinNow.preview && focusIndex != null) {
          _autoScrollToFocus(focusIndex);
        }

        tilesContent = SuperSliverList(
          listController: _listController,
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == tilesWithConnectors.length)
                return MediaQuery.of(context).orientation ==
                        Orientation.landscape
                    ? TileDimensions
                        .bottomLandScapePaddingForTileBatchListOfTiles
                    : TileDimensions
                        .bottomPortraitPaddingForTileBatchListOfTiles;
              final row = tilesWithConnectors[index];
              return rowLayout == null || index >= rowLayout.rowKeys.length
                  ? row
                  : _motion.wrapRow(rowLayout.rowKeys[index], row);
            },
            childCount: tilesWithConnectors.length + 1,
            // Rows follow their key, so a row keeps its state (and its
            // running animations) when rows above it come and go.
            findChildIndexCallback: rowLayout?.indexOfKey,
          ),
        );
      }
    } else {
      tilesContent = SliverToBoxAdapter(
        child: _renderEmptyDayTile(),
      );
    }

    // Use CustomScrollView with SliverAppBar for sticky action chips
    final Widget list = RefreshIndicator(
      color: colorScheme.tertiary,
      onRefresh: () async {
        _triggerRefresh();
      },
      child: CustomScrollView(
        controller: _scrollController,
        shrinkWrap: true,
        physics: _isEmptyDay
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Sticky header with date, action chips, and loading indicator.
          // Omitted under the Daily top bar: the bar carries the day +
          // summary entry and the shared DayQuickActionsRow carries the
          // chips + loading bar for both layouts.
          if (withinNow.showDaySummaryHeader)
          BlocBuilder<ScheduleBloc, ScheduleState>(
            buildWhen: (previous, current) {
              final wasLoading = previous is ScheduleLoadingState ||
                  previous is ScheduleEvaluationState;
              final isLoading = current is ScheduleLoadingState ||
                  current is ScheduleEvaluationState;
              return wasLoading != isLoading;
            },
            builder: (context, state) {
              final isLoading = state is ScheduleLoadingState ||
                  state is ScheduleEvaluationState;
              return SliverPersistentHeader(
                pinned: true,
                delegate: StickyDayHeaderDelegate(
                  dayData: dayData,
                  onShowRoute: _navigateToTodaysRoute,
                  onReOptimize: _triggerRevise,
                  isLoading: isLoading,
                  preview: withinNow.preview,
                ),
              );
            },
          ),

          // Rest of the content
          SliverToBoxAdapter(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ...scrollableContent,
                const SizedBox(height: 8),
              ],
            ),
          ),
          tilesContent,
        ],
      ),
    );
    return ListMotionLayer(
      motion: _motion,
      day: Utility.currentTime().dayDate,
      rowBuilder: _buildFlightRow,
      scrollToTile: _scrollToTile,
      child: list,
    );
  }

  /// A tile's row as it is now, for its flying copy.
  Widget _buildFlightRow(String tileId) {
    final tile = _tilesById[tileId];
    if (tile == null) return const SizedBox.shrink();
    return TileRowWithHourMarker(
      hour: tile.startTime.hour,
      showHourMarker: false,
      isCurrentHour: false,
      hourMarkerWidth: _hourMarkerWidth,
      child: _buildTileWidget(tile),
    );
  }

  /// Brings a tile's row a third of the way down the list.
  void _scrollToTile(String tileId) {
    final row = _rowLayout?.rowOfTile[tileId];
    if (row == null ||
        !_listController.isAttached ||
        !_scrollController.hasClients) {
      return;
    }
    if (ScheduleMotion.modeFor(context, listen: false).animates) {
      _listController.animateToItem(
        index: row,
        scrollController: _scrollController,
        alignment: 0.3,
        duration: (_) => const Duration(milliseconds: 450),
        curve: (_) => Curves.easeInOutCubic,
      );
    } else {
      _listController.jumpToItem(
          index: row, scrollController: _scrollController, alignment: 0.3);
    }
  }
}
