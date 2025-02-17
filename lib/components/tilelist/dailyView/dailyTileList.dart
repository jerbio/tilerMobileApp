import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatch.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileBatchWithinNow.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DailyTileList extends TileList {
  static final String routeName = '/DailyTileList';
  DailyTileList({Key? key}) : super(key: key);

  @override
  _DailyTileListState createState() => _DailyTileListState();
}

class _DailyTileListState extends TileListState {
  Map? contextParams;
  BoxDecoration previousTileBatchDecoration =
      BoxDecoration(color: Colors.white);
  Key carouselKey = ValueKey(Utility.getUuid);
  Map<String, Map<String, SubCalendarEvent>> statusToSubEvents = {};
  Map<int, List<SubCalendarEvent>> dayIndexToSubEvents = {};
  Map<int, Tuple2<int, Widget>> dayIndexToCarouselIndex = {};
  List<Timeline>? loadedTimeline = [];
  List<SubCalendarEvent>? loadedSubCalendarEvent;
  late Timeline previousTimeline;
  late bool disableDayCarouselSlide = false;
  int? disableDayIndex;
  int _forceRefreshCounter = 0;
  final CarouselSliderController tileListDayCarouselController =
      CarouselSliderController();
  Map<String, ScheduleLoadedState> incrementalIdToMapping = {};

  @override
  void initState() {
    super.initState();
    timeLine = Timeline.fromDateTimeAndDuration(
        Utility.currentTime().dayDate.add(Duration(days: -4)),
        Duration(days: 7));
    incrementalTilerScrollId = "incremental-get-schedule";
    previousTimeline = this.timeLine;
  }

  String _generateIncrementalIdToMapping() {
    return incrementalTilerScrollId + "-" + Utility.msCurrentTime.toString();
  }

  updateDayCarouselSlide({int? universalDayIndex}) {
    setState(() {
      // if (pendingCarouselDisabled != null) {
      //   disableDayCarouselSlide = pendingCarouselDisabled!;
      //   pendingCarouselDisabled = null;
      // }
    });
  }

  reloadSchedule(DateTime dateManageCurrentDate,
      {bool forceRenderingPage = true,
      Timeline? forcedTimeline = null,
      bool incremental = false}) {
    var scheduleSubEventState = this.context.read<ScheduleBloc>().state;
    List<SubCalendarEvent> subEvents = [];
    Timeline todayTimeLine = Utility.todayTimeline();
    Timeline currentTimeline = todayTimeLine;
    DateTime startDateTime = todayTimeLine.startTime;
    DateTime endDateTime = todayTimeLine.endTime;
    List<Timeline> evaluatedDayTimelines = [];
    AuthorizedRouteTileListPage currentPage = AuthorizedRouteTileListPage.Daily;
    ScheduleStatus scheduleStatus = ScheduleStatus();
    Timeline previousTimeLine = timeLine;
    if (scheduleSubEventState is ScheduleLoadedState) {
      subEvents = scheduleSubEventState.subEvents;
      startDateTime = scheduleSubEventState.lookupTimeline.startTime;
      endDateTime = scheduleSubEventState.lookupTimeline.endTime;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.lookupTimeline);
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      scheduleStatus = scheduleSubEventState.scheduleStatus;
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      currentTimeline = scheduleSubEventState.lookupTimeline;
      currentPage = scheduleSubEventState.currentView;
    }
    if (scheduleSubEventState is ScheduleEvaluationState) {
      subEvents = scheduleSubEventState.subEvents;
      startDateTime = scheduleSubEventState.lookupTimeline.startTime;
      endDateTime = scheduleSubEventState.lookupTimeline.endTime;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.lookupTimeline);
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      scheduleStatus = scheduleSubEventState.scheduleStatus;
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      currentTimeline = scheduleSubEventState.lookupTimeline;
      currentPage = scheduleSubEventState.currentView;
    }

    if (scheduleSubEventState is ScheduleLoadingState) {
      subEvents = scheduleSubEventState.subEvents;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.previousLookupTimeline);
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      scheduleStatus = scheduleSubEventState.scheduleStatus;
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      currentTimeline = scheduleSubEventState.previousLookupTimeline;
      currentPage = scheduleSubEventState.currentView;
    }

    int dayDelta = Constants.numberOfDaysToLoad ~/ 2;
    int daySplit = (dayDelta.toDouble()).round();
    startDateTime =
        dateManageCurrentDate.dayDate.add(-Duration(days: daySplit));
    endDateTime =
        startDateTime.add(Duration(days: Constants.numberOfDaysToLoad));
    bool emitOnlyLoadedStated = true;
    if (daySplit == 0) {
      startDateTime = dateManageCurrentDate.dayDate.add(Duration(days: -1));
      ;
      endDateTime = dateManageCurrentDate.dayDate.add(Duration(days: 1));
    }
    if (!previousTimeLine.isDateTimeWithin(dateManageCurrentDate.dayDate)) {
      emitOnlyLoadedStated = false;
      if (forcedTimeline == null) {
        forcedTimeline = Timeline.fromDateTime(startDateTime, endDateTime);
      }
    }
    String? loopIncrementalIdToMapping;
    Timeline newTimeline = Timeline.fromDateTime(startDateTime, endDateTime);
    if (incremental) {
      loopIncrementalIdToMapping = _generateIncrementalIdToMapping();
      if (previousTimeLine.startTime.millisecondsSinceEpoch <=
              newTimeline.startTime.millisecondsSinceEpoch &&
          previousTimeLine.endTime.millisecondsSinceEpoch >=
              newTimeline.endTime.millisecondsSinceEpoch) {
        newTimeline = previousTimeLine;
      }
      startDateTime = newTimeline.startTime;
      endDateTime = newTimeline.endTime;
      if (newTimeline.startTime.millisecondsSinceEpoch <
          previousTimeLine.startTime.millisecondsSinceEpoch) {
        startDateTime = newTimeline.startTime;
        endDateTime = previousTimeLine.startTime;
      }
      if (newTimeline.endTime.millisecondsSinceEpoch >
          previousTimeLine.endTime.millisecondsSinceEpoch) {
        startDateTime = previousTimeLine.endTime;
        endDateTime = newTimeline.endTime;
      }
      if (newTimeline.startTime.millisecondsSinceEpoch <
              previousTimeLine.startTime.millisecondsSinceEpoch &&
          newTimeline.endTime.millisecondsSinceEpoch >
              previousTimeLine.endTime.millisecondsSinceEpoch) {
        startDateTime = newTimeline.startTime;
        endDateTime = newTimeline.endTime;
      }
    }

    if (forcedTimeline != null) {
      startDateTime = forcedTimeline.startTime;
      endDateTime = forcedTimeline.endTime;
    }

    if (forcedTimeline != null) {
      startDateTime = forcedTimeline.startTime;
      endDateTime = forcedTimeline.endTime;
    }

    Timeline queryTimeline = Timeline.fromDateTime(startDateTime, endDateTime);
    this.context.read<ScheduleBloc>().add(GetScheduleEvent(
          previousSubEvents: subEvents,
          previousTimeline: previousTimeLine,
          isAlreadyLoaded: !forceRenderingPage,
          scheduleTimeline: queryTimeline,
        ));
    refreshScheduleSummary(lookupTimeline: queryTimeline);
    if (loopIncrementalIdToMapping != null) {
      setState(() {
        Map<String, ScheduleLoadedState> incrementalIdToMapping_cpy = {};
        incrementalIdToMapping_cpy.addAll(incrementalIdToMapping);
        incrementalIdToMapping_cpy[loopIncrementalIdToMapping!] =
            ScheduleLoadedState(
          lookupTimeline: currentTimeline,
          subEvents: subEvents,
          scheduleStatus: scheduleStatus,
          previousLookupTimeline: previousTimeLine,
          timelines: evaluatedDayTimelines,
          currentView: currentPage,
        );
        incrementalIdToMapping = incrementalIdToMapping_cpy;
      });
    }
  }

  Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> mapTilesToDays(
      List<TilerEvent> tiles, Timeline? todayTimeline) {
    List<TilerEvent> todaySubEvents = [];
    Map<int, List<TilerEvent>> dayIndexToTiles =
        new Map<int, List<TilerEvent>>();
    for (var tile in tiles) {
      DateTime? referenceTime = tile.startTime;
      if (todayTimeline != null) {
        if (todayTimeline.isInterfering(tile)) {
          todaySubEvents.add(tile);
          continue;
        }
        if (todayTimeline.start != null && tile.end != null) {
          if (todayTimeline.start! > tile.end!) {
            referenceTime = tile.endTime;
          }
        }
      }
      var dayIndex = Utility.getDayIndex(referenceTime.dayDate);
      List<TilerEvent>? tilesForDay;
      if (dayIndexToTiles.containsKey(dayIndex)) {
        tilesForDay = dayIndexToTiles[dayIndex];
      } else {
        tilesForDay = [];
        dayIndexToTiles[dayIndex] = tilesForDay;
      }
      tilesForDay!.add(tile);
    }
    Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> retValue =
        new Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>>(
            dayIndexToTiles, todaySubEvents);

    return retValue;
  }

  Timeline getRelevantTimeLine() {
    final currentState = context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadingState) {
      return currentState.previousLookupTimeline;
    }

    if (currentState is ScheduleEvaluationState) {
      return currentState.lookupTimeline;
    }
    if (currentState is ScheduleLoadedState) {
      return currentState.lookupTimeline;
    }
    return timeLine;
  }

  void processUpcomingAndPrecedingTiles(
      Map<int, List<TilerEvent>> dayIndexToTileDict,
      Map<int, TileBatch> upcomingDayTilesDict,
      Map<int, TileBatch> precedingDayTilesDict) {
    Timeline relevantTimeline = getRelevantTimeLine();
    int todayDayIndex = Utility.getDayIndex(Utility.currentTime());
    int startIndex = Utility.getDayIndex(
        DateTime.fromMillisecondsSinceEpoch(relevantTimeline.start!.toInt()));
    int endIndex = Utility.getDayIndex(
        DateTime.fromMillisecondsSinceEpoch(relevantTimeline.end!.toInt()));
    int numberOfDays = (endIndex - startIndex);
    if (numberOfDays <= 0) {
      numberOfDays = 1;
    }
    print('relevantTimeline ' + relevantTimeline.toString());
    List<int> dayIndexes = List.generate(numberOfDays, (index) => index);
    for (int i = 0; i < dayIndexes.length; i++) {
      int dayIndex = dayIndexes[i];
      dayIndex += startIndex;
      dayIndexes[i] = dayIndex;
      if (dayIndex > todayDayIndex) {
        if (!upcomingDayTilesDict.containsKey(dayIndex)) {
          var tiles = <TilerEvent>[];
          if (dayIndexToTileDict.containsKey(dayIndex)) {
            tiles = dayIndexToTileDict[dayIndex]!;
          }
          var allTiles = tiles.toList();
          Key key = Key(dayIndex.toString());
          TileBatch upcomingTileBatch =
              TileBatch(dayIndex: dayIndex, tiles: allTiles, key: key);
          upcomingDayTilesDict[dayIndex] = upcomingTileBatch;
        }
      } else {
        if (!precedingDayTilesDict.containsKey(dayIndex)) {
          var tiles = <TilerEvent>[];
          if (dayIndexToTileDict.containsKey(dayIndex)) {
            tiles = dayIndexToTileDict[dayIndex]!;
          }
          var allTiles = tiles.toList();
          Key key = Key(dayIndex.toString());
          TileBatch precedingDayTileBatch =
              TileBatch(dayIndex: dayIndex, key: key, tiles: allTiles);
          precedingDayTilesDict[dayIndex] = precedingDayTileBatch;
        }
      }
    }
  }

  WithinNowBatch processTodayTiles(List<TilerEvent> todayTiles) {
    DateTime currentTime = Utility.currentTime();
    List<TilerEvent> elapsedTiles = [];
    List<TilerEvent> notElapsedTiles = [];

    for (TilerEvent eachSubEvent in todayTiles) {
      if (eachSubEvent.endTime.millisecondsSinceEpoch >
          currentTime.millisecondsSinceEpoch) {
        notElapsedTiles.add(eachSubEvent);
      } else {
        elapsedTiles.add(eachSubEvent);
      }
    }
    return WithinNowBatch(
      key: ValueKey("_within_upcoming_0"),
      tiles: [...elapsedTiles, ...notElapsedTiles],
    );
  }

  Tuple2<int, List<Widget>> buildCarousel(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    Map<int, TileBatch> precedingDayTilesDict = new Map<int, TileBatch>();
    Map<int, TileBatch> upcomingDayTilesDict = new Map<int, TileBatch>();
    Map<int, Widget> dayIndexToWidget = {};
    List<Timeline> sleepTimelines = tileData!.item1;
    tileData.item2.sort((eachSubEventA, eachSubEventB) =>
        eachSubEventA.start!.compareTo(eachSubEventB.start!));
    Map<int, Timeline> dayToSleepTimeLines = {};
    sleepTimelines.forEach((sleepTimeLine) {
      int dayIndex = Utility.getDayIndex(sleepTimeLine.startTime);
      dayToSleepTimeLines[dayIndex] = sleepTimeLine;
    });
    Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> dayToTiles =
        mapTilesToDays(tileData.item2, todayTimeLine);
    List<TilerEvent> todayTiles = dayToTiles.item2;
    Map<int, List<TilerEvent>> dayIndexToTileDict = dayToTiles.item1;
    processUpcomingAndPrecedingTiles(
        dayIndexToTileDict, upcomingDayTilesDict, precedingDayTilesDict);
    List<TileBatch> precedingDayTiles = precedingDayTilesDict.values.toList();
    precedingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
        eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));
    List<TileBatch> upcomingDayTiles = upcomingDayTilesDict.values.toList();
    upcomingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
        eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));
    List<TileBatch> childTileBatches = <TileBatch>[];
    childTileBatches.addAll(precedingDayTiles);
    precedingDayTiles.forEach((tileBatch) {
      Widget widget = Container(
        height: MediaQuery.of(context).size.height,
        decoration: previousTileBatchDecoration,
        child: tileBatch,
      );
      if (tileBatch.dayIndex != null) {
        dayIndexToWidget[tileBatch.dayIndex!] = widget;
      }
    });

    DateTime currentTime = Utility.currentTime();
    if (todayTiles.length > 0) {
      WithinNowBatch todayBatch = processTodayTiles(todayTiles);
      childTileBatches.add(todayBatch);
      dayIndexToWidget[currentTime.universalDayIndex] = Container(
        child: todayBatch,
      );
    } else {
      DateTime currentTime = Utility.currentTime();
      TileBatch tileBatch = TileBatch(
        dayIndex: currentTime.universalDayIndex,
        tiles: [],
      );
      Widget widget = Container(
        child: tileBatch,
      );
      dayIndexToWidget[currentTime.universalDayIndex] = widget;
      childTileBatches.add(tileBatch);
    }
    childTileBatches.addAll(upcomingDayTiles);
    upcomingDayTiles.forEach(
      (tileBatch) {
        {
          Widget widget = Container(
            height: MediaQuery.of(context).size.height,
            child: tileBatch,
          );
          if (tileBatch.dayIndex != null) {
            dayIndexToWidget[tileBatch.dayIndex!] = widget;
          }
        }
      },
    );

    List<int> sortedDayIndex = dayIndexToWidget.keys.toList();
    sortedDayIndex.sort();
    int currentDayIndex = Utility.currentTime().universalDayIndex;
    var uiManagedDateState = this.context.read<UiDateManagerBloc>().state;
    if (uiManagedDateState is UiDateManagerUpdated) {
      currentDayIndex = uiManagedDateState.currentDate.universalDayIndex;
    }

    int itemCounter = 0;
    int initialCarouselIndex = -1;
    List<Widget> carouselItems = [];
    carouselItems = sortedDayIndex.map<Widget>((dayIndex) {
      if (initialCarouselIndex < 0 && currentDayIndex == dayIndex) {
        initialCarouselIndex = itemCounter;
      }
      dayIndexToCarouselIndex[dayIndex] =
          Tuple2(itemCounter, dayIndexToWidget[dayIndex]!);
      ++itemCounter;
      return dayIndexToWidget[dayIndex]!;
    }).toList();
    if (initialCarouselIndex < 0 && carouselItems.length > 0) {
      initialCarouselIndex = 0;
    }
    return Tuple2(initialCarouselIndex, carouselItems);
  }

  Widget buildDailyRenderSubCalendarTiles(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    Tuple2<int, List<Widget>> carouselData = buildCarousel(tileData);
    int initialCarouselIndex = carouselData.item1;
    List<Widget> carouselItems = carouselData.item2;
    if (tileData == null) {
      return ListView(children: []);
    }

    bool scrollerIsDisabled = disableDayCarouselSlide &&
        disableDayIndex != null &&
        this.context.read<UiDateManagerBloc>().state is UiDateManagerUpdated &&
        (this.context.read<UiDateManagerBloc>().state as UiDateManagerUpdated)
                .currentDate
                .universalDayIndex ==
            disableDayIndex;
    print(this.context.read<UiDateManagerBloc>().state);
    return CarouselSlider(
        key: carouselKey,
        carouselController: tileListDayCarouselController,
        items: carouselItems,
        options: CarouselOptions(
          height: MediaQuery.of(context).size.height,
          viewportFraction: 1,
          initialPage: initialCarouselIndex,
          enableInfiniteScroll: false,
          reverse: false,
          onPageChanged: (pageNumber, carouselData) {
            int? dayIndexOfTileBatch;
            Tuple2<int, Widget>? tileBatchTupleData;
            DateTime currentTime = Utility.currentTime().dayDate;

            this.dayIndexToCarouselIndex.forEach((key, value) {
              if (value.item1 == pageNumber && dayIndexOfTileBatch == null) {
                dayIndexOfTileBatch = key;
                tileBatchTupleData = value;
                currentTime = Utility.getTimeFromIndex(key);
              }
            });

            if (carouselData == CarouselPageChangedReason.manual &&
                dayIndexOfTileBatch != null &&
                tileBatchTupleData != null) {
              var uiDateManagerState =
                  this.context.read<UiDateManagerBloc>().state;
              DateTime previousTime = Utility.currentTime().dayDate;
              currentTime =
                  Utility.getTimeFromIndex(dayIndexOfTileBatch!).dayDate;
              if (previousTime.millisecondsSinceEpoch >
                  currentTime.millisecondsSinceEpoch) {
                AnalysticsSignal.send('DAY_SWIPE_BACK');
              } else {
                AnalysticsSignal.send('DAY_SWIPE_FORWARD');
              }

              if (uiDateManagerState is UiDateManagerUpdated) {
                previousTime = uiDateManagerState.currentDate;
              }
              if (previousTime.millisecondsSinceEpoch !=
                  currentTime.millisecondsSinceEpoch) {
                this.context.read<UiDateManagerBloc>().add(DateChangeEvent(
                    selectedDate: currentTime,
                    previousSelectedDate: previousTime));
              }
            }

            updateDayCarouselSlide(
                universalDayIndex: currentTime.universalDayIndex);
          },
          scrollPhysics:
              (scrollerIsDisabled) ? NeverScrollableScrollPhysics() : null,
          scrollDirection: Axis.horizontal,
        ));
  }

  List<SubCalendarEvent> dedupeAndMergeSubEvents(
      List<SubCalendarEvent> destination, List<SubCalendarEvent> source) {
    Map<String, SubCalendarEvent> destinationResult = {};
    destination.forEach((eachSubEvent) {
      if (eachSubEvent.id != null) {
        destinationResult[eachSubEvent.id!] = eachSubEvent;
      }
    });
    source.forEach((eachSubEvent) {
      if (eachSubEvent.id != null) {
        if (destinationResult.containsKey(eachSubEvent.id)) {
          destinationResult[eachSubEvent.id!] = eachSubEvent;
        }
      }
    });
    return destinationResult.values.toList();
  }

  List<Timeline> dedupeAndMergeTimelines(
      List<Timeline> destination, List<Timeline> source) {
    Map<String, Timeline> destinationResult = {};
    destination.forEach((eachTimeline) {
      if (eachTimeline.id != null) {
        destinationResult[eachTimeline.toString()] = eachTimeline;
      }
    });
    source.forEach((eachTimeline) {
      if (eachTimeline.id != null) {
        if (destinationResult.containsKey(eachTimeline.id)) {
          destinationResult[eachTimeline.toString()] = eachTimeline;
        }
      }
    });
    return destinationResult.values.toList();
  }

  Timeline mergeTimeline(Timeline destination, Timeline source) {
    DateTime start = (destination.start ?? 0) < (source.end ?? 0)
        ? destination.startTime
        : source.endTime;

    DateTime end = (destination.end ?? 0) > (source.end ?? 0)
        ? destination.endTime
        : source.endTime;

    Timeline retValue = new Timeline.fromDateTime(start, end);
    return retValue;
  }

  void augmentLoadedState(
      ScheduleLoadedState augmentedLoadedState, BuildContext context,
      {ScheduleLoadedState? currentLoadedState = null}) {
    List<Timeline> revisedTimelines = augmentedLoadedState.timelines;
    List<SubCalendarEvent> subEvents = augmentedLoadedState.subEvents;
    Timeline lookupTimeline = augmentedLoadedState.lookupTimeline;
    ScheduleStatus scheduleStatus = augmentedLoadedState.scheduleStatus;

    if (currentLoadedState != null &&
        scheduleStatus.analysisId ==
            currentLoadedState.scheduleStatus.analysisId &&
        scheduleStatus.evaluationId ==
            currentLoadedState.scheduleStatus.evaluationId) {
      revisedTimelines = dedupeAndMergeTimelines(
          revisedTimelines, currentLoadedState.timelines);
      subEvents =
          dedupeAndMergeSubEvents(subEvents, currentLoadedState.subEvents);
      lookupTimeline =
          mergeTimeline(lookupTimeline, currentLoadedState.lookupTimeline);
    }

    context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
        lookupTimeline: lookupTimeline,
        scheduleStatus: scheduleStatus,
        subEvents: subEvents,
        previousLookupTimeline: lookupTimeline,
        timelines: revisedTimelines));
  }

  String _generateCarouselKeyId(String sessionId) {
    UiDateManagerState uiDateManagerState =
        this.context.read<UiDateManagerBloc>().state;
    int dayIndex = Utility.currentTime().universalDayIndex;
    if (uiDateManagerState is UiDateManagerUpdated) {
      dayIndex = uiDateManagerState.currentDate.universalDayIndex;
    }
    return sessionId +
        "_" +
        _forceRefreshCounter.toString() +
        "_" +
        dayIndex.toString();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduleBloc, ScheduleState>(listener: (context, state) {
          print("ScheduleBloc state is " + state.toString());

          if (state is ScheduleLoadingState) {
            if (state.message != null) {
              Fluttertoast.showToast(
                  msg: state.message!,
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.SNACKBAR,
                  timeInSecForIosWeb: 1,
                  backgroundColor: Colors.black45,
                  textColor: Colors.white,
                  fontSize: 16.0);
            }
          }
          if (state is ScheduleLoadedState) {
            dayIndexToSubEvents = {};
            String? statusId = state.scheduleStatus.evaluationId;
            Map<String, SubCalendarEvent> idToSubEventByStatus = {};
            bool isNewStatusId = true;
            if (statusId != null) {
              if (statusToSubEvents.containsKey(statusId) &&
                  statusToSubEvents[statusId] != null) {
                idToSubEventByStatus = statusToSubEvents[statusId]!;
                isNewStatusId = false;
              }
              statusToSubEvents[statusId] = idToSubEventByStatus;
            }
            int startIndex = state.lookupTimeline.startTime.universalDayIndex;
            int endIndex = state.lookupTimeline.endTime.universalDayIndex;
            if (startIndex < endIndex - 1) {
              startIndex -= 1;
              if (startIndex < endIndex - 1) {
                endIndex -= 1;
              }
            }
            int currentIndex = startIndex;
            do {
              dayIndexToSubEvents[currentIndex] = [];
              ++currentIndex;
            } while (currentIndex < endIndex);
            List<SubCalendarEvent> subEvents = state.subEvents;
            if (statusId != null &&
                statusToSubEvents[statusId] != null &&
                !isNewStatusId) {
              subEvents = (statusToSubEvents[statusId] ?? {}).values.toList();
            }

            if (state.eventId != null && state.eventId!.isNotEmpty) {
              String eventId = state.eventId!;
              if (eventId.contains(incrementalTilerScrollId) &&
                  incrementalIdToMapping.containsKey(eventId)) {
                augmentLoadedState(state, context,
                    currentLoadedState: incrementalIdToMapping[eventId]);
                incrementalIdToMapping.remove(eventId);
              }
            } else {
              setState(() {
                loadedTimeline = state.timelines;
                loadedSubCalendarEvent = state.subEvents;
                if (state.previousLookupTimeline != null) {
                  previousTimeline = state.previousLookupTimeline!;
                }
                if (statusId != null) {
                  String carouselId = _generateCarouselKeyId(statusId);
                  carouselKey = ValueKey(carouselId);
                }
              });
            }
          }
        }),
        BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
          listener: (context, state) {
            showSubEventModal(state);
          },
        ),
        BlocListener<UiDateManagerBloc, UiDateManagerState>(
          listener: (context, state) {
            if (state is UiDateManagerUpdated) {
              bool forceRenderingPage = true;
              if (dayIndexToCarouselIndex
                  .containsKey(state.currentDate.universalDayIndex)) {
                forceRenderingPage = false;
                tileListDayCarouselController.animateToPage(
                    dayIndexToCarouselIndex[
                            state.currentDate.universalDayIndex]!
                        .item1);
              }
              if (state.dateChangeTrigger == DateChangeTrigger.buttonPress) {
                if (this.mounted) {
                  context
                      .read<TileListCarouselBloc>()
                      .add(EnableCarouselScrollEvent(isImmediate: true));
                }
              }
              reloadSchedule(state.currentDate,
                  forceRenderingPage: forceRenderingPage);
            }
          },
        ),
        BlocListener<TileListCarouselBloc, TileListCarouselState>(
            listener: (context, state) {
          bool isCarouselDisabled = false;
          disableDayIndex = null;

          if (state is TileListCarouselDisabled) {
            isCarouselDisabled = true;
            disableDayIndex = state.dayIndex;
          }

          if (state is TileListCarouselEnable) {
            isCarouselDisabled = false;
          }
          setState(() {
            disableDayCarouselSlide = isCarouselDisabled;
          });
        }),
      ],
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          print("Day tile list refeshing " + state.toString());
          if (state is ScheduleInitialState) {
            context.read<ScheduleBloc>().add(GetScheduleEvent(
                scheduleTimeline: timeLine,
                previousSubEvents: List<SubCalendarEvent>.empty()));
            refreshScheduleSummary(lookupTimeline: timeLine);
            return renderPending();
          }

          if (state is ScheduleLoadedState) {
            if (!(state is DelayedScheduleLoadedState)) {
              handleNotificationsAndNextTile(state.subEvents);
            }
            List<Timeline> scheduleTimelines = state.timelines;
            List<SubCalendarEvent> scheduleSubCalendarEvent = state.subEvents;
            if (loadedTimeline != null) {
              scheduleTimelines = loadedTimeline!;
            }

            if (loadedSubCalendarEvent != null) {
              scheduleSubCalendarEvent = loadedSubCalendarEvent!;
            }
            return Stack(
              children: [
                buildDailyRenderSubCalendarTiles(
                    Tuple2(scheduleTimelines, scheduleSubCalendarEvent))
              ],
            );
          }

          if (state is ScheduleLoadingState) {
            bool showPendingUI = !state.isAlreadyLoaded;
            final dateMangerBloc = this.context.read<UiDateManagerBloc>().state;
            if (dateMangerBloc is UiDateManagerUpdated &&
                state.currentView == AuthorizedRouteTileListPage.Daily) {
              showPendingUI = showPendingUI ||
                  !state.previousLookupTimeline
                      .isDateTimeWithin(dateMangerBloc.currentDate);
            }
            if (showPendingUI) {
              return renderPending();
            }
            return Stack(children: [
              buildDailyRenderSubCalendarTiles(
                  Tuple2(state.timelines, state.subEvents))
            ]);
          }

          if (state is ScheduleEvaluationState) {
            return Stack(
              children: [
                buildDailyRenderSubCalendarTiles(
                    Tuple2(state.timelines, state.subEvents)),
                PendingWidget(
                  imageAsset: TileStyles.evaluatingScheduleAsset,
                ),
              ],
            );
          }

          return Text(AppLocalizations.of(context)!.retrievingDataIssue);
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
