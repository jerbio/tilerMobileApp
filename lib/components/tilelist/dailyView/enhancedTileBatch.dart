import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tilelist/proactiveAlertBanner.dart';
import 'package:tiler_app/components/tilelist/conflictAlert.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileConnectorLayout.dart';
import 'package:tiler_app/components/tilelist/extendedTilesBanner.dart';
import 'package:tiler_app/components/tilelist/pendingRsvpBanner.dart';
import 'package:tiler_app/components/tilelist/combinedAlertsBanner.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// Enhanced tile batch that shows travel time connectors between tiles
/// and proactive departure alerts for today's view.
class EnhancedTileBatch extends StatefulWidget {
  final List<TilerEvent>? tiles;
  final Timeline? sleepTimeline;
  final int? dayIndex;
  final TimelineSummary? dayData;
  final ConnectionState? connectionState;
  final bool showEnhancedCards;
  final bool showTravelConnectors;
  final bool showProactiveAlerts;
  final bool showTimelineMarkers;
  final bool showConflictAlerts;
  final bool preview;
  final String? selectedActionEntityId;
  const EnhancedTileBatch({
    this.dayIndex,
    this.tiles,
    this.sleepTimeline,
    this.connectionState,
    this.dayData,
    this.showEnhancedCards = true,
    this.showTravelConnectors = true,
    this.showProactiveAlerts = true,
    this.showTimelineMarkers = false,
    this.showConflictAlerts = true,
    this.preview = false,
    this.selectedActionEntityId,
    Key? key,
  }) : super(key: key);

  @override
  EnhancedTileBatchState createState() => EnhancedTileBatchState();
}

class EnhancedTileBatchState extends State<EnhancedTileBatch> {
  String uniqueKey = Utility.getUuid;
  Map<String, TilerEvent> renderedTiles = {};
  Map<String, TilerEvent>? pendingRenderedTiles;
  Map<String, TilerEvent> latestBuildTiles = {};
  Map<String, Tuple3<TilerEvent, int?, int?>>? orderedTiles;
  List<ConflictGroup> _detectedConflicts = [];
  List<Widget> childrenColumnWidgets = [];
  double _emptyDayOpacity = 0;
  final double daySummaryToHeightBuffer = 245;
  late ThemeData theme;
  late ColorScheme colorScheme;

  Timeline? sleepTimeline;
  TimelineSummary? _dayData;
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    if (_dayData == null && widget.dayIndex != null) {
      _dayData = TimelineSummary();
      _dayData!.dayIndex = widget.dayIndex;
    }
    if (widget.dayData != null) {
      _dayData = widget.dayData!;
    }
  }

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  TimelineSummary? get dayData => _dayData;

  bool get _isToday =>
      widget.dayIndex == Utility.currentTime().universalDayIndex;

  /// Get the next tile that requires departure
  SubCalendarEvent? _getNextDepartureRequiredTile(List<TilerEvent> tiles) {
    final now = Utility.currentTime().millisecondsSinceEpoch;

    for (var tile in tiles) {
      if (tile is SubCalendarEvent) {
        if (tile.start != null && tile.start! > now) {
          // Check if this tile has travel time before it
          if (tile.travelTimeBefore != null && tile.travelTimeBefore! > 0) {
            return tile;
          }
          // Check if tile has location (implying travel needed)
          if (tile.address != null && tile.address!.isNotEmpty) {
            return tile;
          }
        }
      }
    }
    return null;
  }

  /// Build the appropriate tile widget based on settings
  Widget _buildTileWidget(TilerEvent tile) {
    if (widget.showEnhancedCards && tile is SubCalendarEvent) {
      final isTutorialCurrent = tile.id != null &&
          tile.id!.startsWith('tutorial-tile-') &&
          tile.isCurrent;
      final card = EnhancedTileCard(
        subEvent: tile,
        initiallyExpanded: isTutorialCurrent,
        preview: widget.preview,
        hasDottedBorder: widget.selectedActionEntityId != null &&
            tile.id?.contains(widget.selectedActionEntityId!) == true,
      );
      if (isTutorialCurrent) {
        return Container(
          key: TutorialKeys.currentTileKey,
          child: card,
        );
      }
      return card;
    }
    return TileWidget(tile, preview: widget.preview);
  }

  /// Format hour for display (e.g., "7 AM", "12 PM")
  String _formatHour(int hour) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour $period';
  }

  /// Build a tile row with hour marker on the left
  Widget _buildTileRowWithHourMarker(TilerEvent tile,
      {bool showHourMarker = true, bool isCurrentHour = false}) {
    final tileStartTime = tile.startTime;
    final hour = tileStartTime.hour;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour marker column (fixed width)
        if (widget.showTimelineMarkers)
          Container(
            width: 55,
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: showHourMarker
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatHour(hour),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isCurrentHour ? FontWeight.w700 : FontWeight.w400,
                          color: isCurrentHour
                              ? colorScheme.primary
                              : colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        // Tile content (expanded)
        Expanded(
          child: _buildTileWidget(tile),
        ),
      ],
    );
  }

  /// Build a connector row with optional hour marker
  Widget _buildConnectorRowWithHourMarker(Widget connector,
      {int? hour, bool showHourMarker = false, bool isCurrentHour = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour marker column (fixed width)
        if (widget.showTimelineMarkers)
          Container(
            width: 55,
            padding: const EdgeInsets.only(right: 8),
            child: showHourMarker && hour != null
                ? Text(
                    _formatHour(hour),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isCurrentHour ? FontWeight.w700 : FontWeight.w400,
                      color: isCurrentHour
                          ? colorScheme.primary
                          : colorScheme.onSurface.withAlpha(153),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        // Connector content (expanded)
        Expanded(child: connector),
      ],
    );
  }

  /// Build a list of widgets with travel connectors between tiles
  /// Groups conflicting tiles into stacked cards
  (List<Widget>, int?) _buildTilesWithConnectors(
      List<TilerEvent> orderedTiles) {
    final result = buildTileListWithConnectors(
      orderedTiles: orderedTiles,
      showTravelConnectors: widget.showTravelConnectors,
      showConflictAlerts: widget.showConflictAlerts,
      excludeDeclinedFromConflicts: false,
      now: DateTime.now(),
      selectedActionEntityId: widget.selectedActionEntityId,
      buildTile: (tile,
          {required hour, required showHourMarker, required isCurrentHour}) {
        if (widget.showTimelineMarkers) {
          return _buildTileRowWithHourMarker(
            tile,
            showHourMarker: showHourMarker,
            isCurrentHour: isCurrentHour,
          );
        }
        return _buildTileWidget(tile);
      },
      buildConflictGroup: (group,
          {required hour, required showHourMarker, required isCurrentHour}) {
        if (widget.showTimelineMarkers && showHourMarker) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 55,
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: Text(
                  _formatHour(hour),
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isCurrentHour ? FontWeight.w700 : FontWeight.w400,
                    color: isCurrentHour
                        ? colorScheme.primary
                        : colorScheme.onSurface.withAlpha(153),
                  ),
                ),
              ),
              Expanded(
                child: StackedConflictCards(
                  conflictGroup: group,
                  preview: widget.preview,
                  onResolve: () {
                    // TODO: Implement auto-resolve
                  },
                ),
              ),
            ],
          );
        }
        return StackedConflictCards(
          conflictGroup: group,
          onResolve: () {
            // TODO: Implement auto-resolve
          },
        );
      },
      wrapConnector: (connector) {
        if (widget.showTimelineMarkers) {
          return _buildConnectorRowWithHourMarker(connector);
        }
        return connector;
      },
    );

    return (result.widgets, result.selectedTileIndex);
  }

  void evaluateTileDelta(Iterable<TilerEvent>? tiles) {
    if (orderedTiles == null) {
      orderedTiles = {};
    }

    if (tiles == null) {
      tiles = <TilerEvent>[];
    }
    List<TilerEvent> orderedByTimeTiles = tiles.toList();
    orderedByTimeTiles
        .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

    Map<String, TilerEvent> allFoundTiles = {};

    for (var eachTile in orderedTiles!.values) {
      allFoundTiles[eachTile.item1.uniqueId] = eachTile.item1;
    }

    for (int i = 0; i < orderedByTimeTiles.length; i++) {
      TilerEvent eachTile = orderedByTimeTiles[i];
      int? currentIndexPosition;
      if (orderedTiles!.containsKey(eachTile.uniqueId)) {
        currentIndexPosition = orderedTiles![eachTile.uniqueId]!.item2;
      }
      orderedTiles![eachTile.uniqueId] =
          Tuple3(eachTile, currentIndexPosition, i);
      allFoundTiles.remove(eachTile.uniqueId);
    }

    for (TilerEvent eachTile in allFoundTiles.values) {
      orderedTiles![eachTile.uniqueId] =
          Tuple3(eachTile, orderedTiles![eachTile.uniqueId]!.item2, null);
    }
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentScheduleSummaryState =
        context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    const double heightMargin = 262;
    renderedTiles = {};

    // Track tiles with pending RSVP and declined separately
    List<SubCalendarEvent> pendingRsvpTiles = [];
    List<SubCalendarEvent> declinedTiles = [];
    final now = Utility.currentTime().millisecondsSinceEpoch;

    if (widget.tiles != null) {
      widget.tiles!.forEach((eachTile) {
        if (eachTile.id != null) {
          final subEvent = eachTile as SubCalendarEvent?;
          final isViable = subEvent?.isViable ?? true;
          final isFromTiler = eachTile.isFromTiler;
          final rsvpStatus = subEvent?.rsvp;

          // Check if this is a pending RSVP tile (needs action or tentative)
          final isPendingRsvp = !isFromTiler &&
              (rsvpStatus == RsvpStatus.needsAction ||
                  rsvpStatus == RsvpStatus.tentative);

          // Check if this is a declined tile
          final isDeclined = !isFromTiler && rsvpStatus == RsvpStatus.declined;

          // Track pending RSVP tiles separately (exclude past events)
          if (isPendingRsvp && subEvent != null) {
            // Only include tiles that haven't ended yet
            pendingRsvpTiles.add(subEvent);
          }

          // Track declined tiles separately (exclude old events)
          if (isDeclined && subEvent != null) {
            declinedTiles.add(subEvent);
          }

          // Show tile in main list if not pending RSVP and not declined
          final shouldShowInMainList = !isPendingRsvp && !isDeclined;

          if (shouldShowInMainList && isViable) {
            renderedTiles[eachTile.uniqueId] = eachTile;
          }
        }
      });
    }

    // Sort pending RSVP and declined tiles by start time
    pendingRsvpTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));
    declinedTiles.sort((a, b) => (a.start ?? 0).compareTo(b.start ?? 0));

    childrenColumnWidgets = [];

    // Day summary header - match original TileBatch margins (bottom margin only)
    if (dayData != null && widget.tiles != null) {
      _dayData!.nonViable = widget.tiles!
          .where(
              (eachTile) => !((eachTile as SubCalendarEvent).isViable ?? true))
          .toList();
      childrenColumnWidgets.add(Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
        child:
            DaySummary(dayTimelineSummary: _dayData!, preview: widget.preview),
      ));
    }

    // Detect alerts data
    SubCalendarEvent? nextDepartureTile;
    List<ConflictGroup> conflictGroups = [];
    List<SubCalendarEvent> extendedTiles = [];

    // Get travel alert data (only for today)
    if (widget.showProactiveAlerts && _isToday && widget.tiles != null) {
      final orderedTilesList =
          Utility.orderTiles(renderedTiles.values.toList());
      nextDepartureTile = _getNextDepartureRequiredTile(orderedTilesList);
    }

    // Detect conflicts (excluding extended tiles and declined events)
    if (widget.showConflictAlerts && renderedTiles.isNotEmpty) {
      const int minDurationMs = 16 * 60 * 60 * 1000;
      final regularTiles = renderedTiles.values.where((tile) {
        if (tile is SubCalendarEvent &&
            tile.start != null &&
            tile.end != null) {
          final duration = tile.end! - tile.start!;
          return duration < minDurationMs;
        }
        return true;
      }).toList();

      // Exclude declined events from conflict detection
      final subCalendarEvents = regularTiles
          .whereType<SubCalendarEvent>()
          .where((tile) => tile.rsvp != RsvpStatus.declined)
          .toList();
      conflictGroups = ConflictGroup.detectGroups(subCalendarEvents);
      _detectedConflicts = conflictGroups;
    }

    // Detect extended tiles
    if (renderedTiles.isNotEmpty) {
      extendedTiles = ExtendedTilesBanner.detectExtendedTiles(
          renderedTiles.values.toList());
    }

    // Count active alerts to decide between combined or individual banners
    int activeAlertCount = 0;
    if (nextDepartureTile != null) activeAlertCount++;
    if (conflictGroups.isNotEmpty) activeAlertCount++;
    if (extendedTiles.isNotEmpty) activeAlertCount++;
    if (pendingRsvpTiles.isNotEmpty || declinedTiles.isNotEmpty)
      activeAlertCount++;

    // Use combined banner if more than 1 alert, otherwise show individual banners
    if (activeAlertCount > 1) {
      childrenColumnWidgets.add(
        CombinedAlertsBanner(
          nextTileWithTravel: nextDepartureTile,
          onTravelTap: () {
            // Navigate to the tile or show details
          },
          onTravelDismiss: () {
            // Handle dismiss if needed
          },
          conflictGroups: conflictGroups,
          onConflictTap: () {
            // Could show a modal with all conflicts
          },
          extendedTiles: extendedTiles,
          onExtendedTap: () {
            CombinedAlertsBannerHelpers.showExtendedTilesModal(
                preview: widget.preview, context, extendedTiles);
          },
          pendingRsvpTiles: pendingRsvpTiles,
          declinedTiles: declinedTiles,
          onRsvpTap: () {
            CombinedAlertsBannerHelpers.showPendingRsvpModal(
              preview: widget.preview,
              context,
              pendingRsvpTiles,
              declinedTiles: declinedTiles,
              onRsvpUpdated: () => refreshScheduleSummary(),
            );
          },
          onRsvpUpdated: () => refreshScheduleSummary(),
        ),
      );
    } else {
      // Show individual banners when only 0 or 1 alert is active
      if (nextDepartureTile != null) {
        childrenColumnWidgets.add(
          ProactiveAlertBanner(
            nextTileWithTravel: nextDepartureTile,
            preview: widget.preview,
            onDismiss: () {
              // Handle dismiss if needed
            },
          ),
        );
      }

      if (conflictGroups.isNotEmpty) {
        childrenColumnWidgets.add(
          ConflictSummaryBanner(
            preview: widget.preview,
            conflictGroups: conflictGroups,
            onTap: () {
              // Could show a modal with all conflicts
            },
          ),
        );
      }

      if (extendedTiles.isNotEmpty) {
        childrenColumnWidgets.add(
          ExtendedTilesBanner(
            preview: widget.preview,
            extendedTiles: extendedTiles,
          ),
        );
      }

      if (pendingRsvpTiles.isNotEmpty || declinedTiles.isNotEmpty) {
        childrenColumnWidgets.add(
          PendingRsvpBanner(
            preview: widget.preview,
            pendingTiles: pendingRsvpTiles,
            declinedTiles: declinedTiles,
            onRsvpUpdated: () {
              refreshScheduleSummary();
            },
          ),
        );
      }
    }

    // Sleep widget
    Widget? sleepWidget;
    if (sleepTimeline != null) {
      sleepWidget = SleepTileWidget(sleepTimeline!);
      childrenColumnWidgets.add(sleepWidget);
    }

    evaluateTileDelta(renderedTiles.values);
    late Widget dayContent;

    if (renderedTiles.length > 0) {
      final orderedTilesList =
          Utility.orderTiles(renderedTiles.values.toList());

      final (tilesWithConnectors, targetScrollIndex) =
          _buildTilesWithConnectors(
        orderedTilesList,
      );

      if (widget.preview && targetScrollIndex != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemScrollController.isAttached) {
            _itemScrollController.jumpTo(
              index: targetScrollIndex!,
              alignment: 0.15,
            );
          }
        });
      }

      dayContent = Container(
        height: MediaQuery.sizeOf(context).height - daySummaryToHeightBuffer,
        width: MediaQuery.sizeOf(context).width,
        child: ScrollablePositionedList.builder(
          itemScrollController: _itemScrollController,
          itemPositionsListener: _itemPositionsListener,
          itemCount: tilesWithConnectors.length + 1,
          itemBuilder: (context, index) {
            if (index == tilesWithConnectors.length) {
              return MediaQuery.of(context).orientation == Orientation.landscape
                  ? TileDimensions.bottomLandScapePaddingForTileBatchListOfTiles
                  : TileDimensions.bottomPortraitPaddingForTileBatchListOfTiles;
            }
            return tilesWithConnectors[index];
          },
        ),
      );
    } else {
      // Empty day
      orderedTiles = null;
      DateTime? endOfDayTime;
      if (widget.dayIndex != null) {
        DateTime evaluatedEndOfTime =
            Utility.getTimeFromIndex(widget.dayIndex!).endOfDay;
        if (Utility.utcEpochMillisecondsFromDateTime(evaluatedEndOfTime) >
            Utility.msCurrentTime) {
          endOfDayTime = evaluatedEndOfTime;
        }
      }
      if (widget.dayIndex != null) {
        dayContent = Flex(
          direction: Axis.vertical,
          children: [
            AnimatedOpacity(
              opacity: _emptyDayOpacity,
              duration: const Duration(milliseconds: 500),
              child: Container(
                height: MediaQuery.of(context).size.height - heightMargin,
                child: EmptyDayTile(
                  preview: widget.preview,
                  deadline: endOfDayTime,
                  dayIndex: widget.dayIndex!,
                ),
              ),
            ),
          ],
        );
      }
      if (_emptyDayOpacity == 0) {
        Timer(Duration(milliseconds: 200), () {
          if (mounted) {
            setState(() {
              _emptyDayOpacity = 1;
            });
          }
        });
      }
    }

    childrenColumnWidgets.add(
      RefreshIndicator(
        color: colorScheme.tertiary,
        onRefresh: () async {
          final currentState = context.read<ScheduleBloc>().state;
          if (currentState is ScheduleEvaluationState) {
            context.read<ScheduleBloc>().add(
                  GetScheduleEvent(
                    isAlreadyLoaded: true,
                    previousSubEvents: currentState.subEvents,
                    scheduleTimeline: currentState.lookupTimeline,
                    previousTimeline: currentState.lookupTimeline,
                    forceRefresh: true,
                  ),
                );
            refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
          }

          if (currentState is ScheduleLoadedState) {
            context.read<ScheduleBloc>().add(
                  GetScheduleEvent(
                    isAlreadyLoaded: true,
                    previousSubEvents: currentState.subEvents,
                    scheduleTimeline: currentState.lookupTimeline,
                    previousTimeline: currentState.lookupTimeline,
                    forceRefresh: true,
                  ),
                );
            refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
          }

          if (currentState is ScheduleLoadingState) {
            context.read<ScheduleBloc>().add(
                  GetScheduleEvent(
                    isAlreadyLoaded: true,
                    previousSubEvents: currentState.subEvents,
                    scheduleTimeline: currentState.previousLookupTimeline,
                    previousTimeline: currentState.previousLookupTimeline,
                    forceRefresh: true,
                  ),
                );
            refreshScheduleSummary(
                lookupTimeline: currentState.previousLookupTimeline);
          }
        },
        child: dayContent,
      ),
    );

    return Column(
      children: childrenColumnWidgets,
    );
  }

  bool isAllNewEntries(
      Map<String, Tuple3<TilerEvent, int?, int?>> timeSectionTiles) {
    return !timeSectionTiles.values.any((element) => element.item2 != null);
  }
}
