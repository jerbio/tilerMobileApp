import 'dart:async';
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';

import 'package:tiler_app/components/tileUI/newTileUIPreview.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/components/tilelist/tileBatchWithinNow.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/constants.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../../../constants.dart' as Constants;
import 'package:flutter/src/painting/gradient.dart' as paintGradient;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// This renders the list of tiles on a given day
class TileList extends StatefulWidget {
  final ScheduleApi scheduleApi = new ScheduleApi();
  static final String routeName = '/TileList';
  TileList({Key? key}) : super(key: key);

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  SubCalendarEvent? notificationSubEvent;
  SubCalendarEvent? concludingSubEvent;
  final Duration autorefreshDuration = const Duration(minutes: 5);
  StreamSubscription? autoRefreshList;
  DateTime lastUpdate = Utility.currentTime();
  Map? contextParams;
  Timeline timeLine = Timeline.fromDateTimeAndDuration(
      Utility.currentTime().dayDate.add(Duration(days: -4)), Duration(days: 7));
  // Timeline? oldTimeline;
  ScrollController _scrollController = new ScrollController();
  late final LocalNotificationService localNotificationService;
  BoxDecoration previousTileBatchDecoration =
      BoxDecoration(color: Colors.white);

  BoxDecoration upcomingTileBatchDecoration =
      BoxDecoration(color: Colors.white);
  Key carouselKey = ValueKey(Utility.getUuid);
  Map<int, Widget> dayIndexToWidget = {};
  Map<int, Tuple2<int, Widget>> dayIndexToCarouselIndex = {};
  List<Widget> carouselItems = [];
  final CarouselController tileListDayCarouselController = CarouselController();
  final String incrementalTilerScrollId = "incremental-get-schedule";
  late String updatedIncrementalTilerScrollId;
  Map<String, ScheduleLoadedState> incrementalIdToMapping = {};
  List<Timeline> loadedTimeline = [];
  List<SubCalendarEvent> loadedSubCalendarEvent = [];
  late Timeline previousTimeline;

  @override
  void initState() {
    localNotificationService = LocalNotificationService();
    super.initState();
    updatedIncrementalTilerScrollId = incrementalTilerScrollId;
    previousTimeline = this.timeLine;
    _scrollController.addListener(() {
      double minScrollLimit = _scrollController.position.minScrollExtent + 1500;
      double maxScrollLimit = _scrollController.position.maxScrollExtent - 1500;
      List<SubCalendarEvent> renderedSubEvents = [];
      Timeline updatedTimeline = Utility.todayTimeline();
      if (_scrollController.position.pixels >= maxScrollLimit &&
          _scrollController.position.userScrollDirection.index == 2) {
        final currentState = this.context.read<ScheduleBloc>().state;
        updatedTimeline = new Timeline(timeLine.start!,
            (timeLine.end! + Utility.sevenDays.inMilliseconds));
        previousTimeline = this.timeLine;
        if (currentState is ScheduleLoadedState) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          setState(() {
            timeLine = updatedTimeline;
            lastUpdate = Utility.currentTime();
          });
          previousTimeline = currentTimeline;
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: updatedTimeline));
          refreshScheduleSummary(lookupTimeline: updatedTimeline);
        }

        if (currentState is ScheduleEvaluationState) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          previousTimeline = timeLine;
          setState(() {
            previousTimeline = this.timeLine;
            timeLine = updatedTimeline;
            lastUpdate = Utility.currentTime();
          });
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
          refreshScheduleSummary(lookupTimeline: this.timeLine);
        }

        if (currentState is ScheduleLoadingState &&
            !currentState.loadingTime
                .isAfter(currentState.loadingTime.add(Duration(minutes: 1)))) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          setState(() {
            previousTimeline = this.timeLine;
            timeLine = updatedTimeline;
          });
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
          refreshScheduleSummary(lookupTimeline: this.timeLine);
        }
      } else if (_scrollController.position.pixels <= minScrollLimit &&
          _scrollController.position.userScrollDirection.index == 1) {
        final currentState = this.context.read<ScheduleBloc>().state;
        updatedTimeline = new Timeline(
            (timeLine.start!.toInt() - Utility.sevenDays.inMilliseconds)
                .toInt(),
            timeLine.end!.toInt());
        if (currentState is ScheduleLoadedState) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          setState(() {
            previousTimeline = this.timeLine;
            timeLine = updatedTimeline;
            lastUpdate = Utility.currentTime();
          });
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
          refreshScheduleSummary(lookupTimeline: this.timeLine);
        }

        if (currentState is ScheduleEvaluationState) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          setState(() {
            previousTimeline = this.timeLine;
            timeLine = updatedTimeline;
            lastUpdate = Utility.currentTime();
          });
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
          refreshScheduleSummary(lookupTimeline: this.timeLine);
        }

        if (currentState is ScheduleLoadingState &&
            !currentState.loadingTime
                .isAfter(currentState.loadingTime.add(Duration(minutes: 1)))) {
          renderedSubEvents = currentState.subEvents;
          final currentTimeline = this.timeLine;
          previousTimeline = this.timeLine;
          setState(() {
            previousTimeline = this.timeLine;
            timeLine = updatedTimeline;
          });
          this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              previousSubEvents: renderedSubEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
          refreshScheduleSummary(lookupTimeline: this.timeLine);
        }
      }
      localNotificationService.initialize(this.context);
    });
    autoRefreshTileList(autorefreshDuration);
  }

  Timeline get _todayTimeLine {
    return Utility.todayTimeline();
  }

  void autoRefreshTileList(Duration duration) {
    Future onTileExpiredCallBack =
        Future.delayed(duration, callScheduleRefresh);
    // ignore: cancel_subscriptions
    autoRefreshList = onTileExpiredCallBack.asStream().listen((_) {});
  }

  void callScheduleRefresh() {
    if (this.mounted) {
      final currentState = this.context.read<ScheduleBloc>().state;
      Timeline? lookupTimeline;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        lookupTimeline = currentState.lookupTimeline;
        refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
      }

      if (currentState is ScheduleLoadedState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        lookupTimeline = currentState.lookupTimeline;
        refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
      }

      if (currentState is ScheduleLoadingState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.previousLookupTimeline,
              previousTimeline: currentState.previousLookupTimeline,
            ));
        lookupTimeline = currentState.previousLookupTimeline;
        refreshScheduleSummary(
            lookupTimeline: currentState.previousLookupTimeline);
      }
      final currentScheduleSummaryState =
          this.context.read<ScheduleSummaryBloc>().state;

      if (currentScheduleSummaryState is ScheduleSummaryInitial ||
          currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
          currentScheduleSummaryState is ScheduleDaySummaryLoading) {
        this.context.read<ScheduleSummaryBloc>().add(
              GetScheduleDaySummaryEvent(
                timeline: lookupTimeline,
              ),
            );
      }
    }
    autoRefreshTileList(
        Duration(minutes: autoRefreshSubEventDurationInMinutes));
  }

  void handleRenderingOfNewTile(SubCalendarEvent subEvent) {
    int redColor = subEvent.colorRed == null ? 125 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 125 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 125 : subEvent.colorGreen!;
    double opacity = subEvent.colorOpacity == null ? 1 : subEvent.colorOpacity!;
    var nameColor = Color.fromRGBO(redColor, greenColor, blueColor, opacity);

    var hslColor = HSLColor.fromColor(nameColor);
    Color bgroundColor =
        hslColor.withLightness(hslColor.lightness).toColor().withOpacity(0.7);
    showModalBottomSheet<void>(
      context: context,
      constraints: BoxConstraints(
        maxWidth: 400,
      ),
      builder: (BuildContext context) {
        var future = new Future.delayed(
            const Duration(milliseconds: Constants.autoHideInMs));
        future.asStream().listen((input) {
          Navigator.pop(context);
        });
        return Container(
          padding: const EdgeInsets.all(20),
          height: 250,
          width: 300,
          decoration: BoxDecoration(
            color: bgroundColor,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NewTileSheet(subEvent: subEvent),
              ],
            ),
          ),
        );
      },
    );
  }

  Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> mapTilesToDays(
      List<TilerEvent> tiles, Timeline? todayTimeline) {
    Map<int, List<TilerEvent>> dayIndexToTiles =
        new Map<int, List<TilerEvent>>();
    List<TilerEvent> todaySubEvents = [];

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

  Widget renderSubCalendarTiles(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    Map<int, TileBatch> preceedingDayTilesDict = new Map<int, TileBatch>();
    Map<int, TileBatch> upcomingDayTilesDict = new Map<int, TileBatch>();
    Widget retValue = Container();
    if (tileData != null) {
      List<Timeline> sleepTimelines = tileData.item1;
      tileData.item2.sort((eachSubEventA, eachSubEventB) =>
          eachSubEventA.start!.compareTo(eachSubEventB.start!));

      Map<int, Timeline> dayToSleepTimeLines = {};
      sleepTimelines.forEach((sleepTimeLine) {
        int dayIndex = Utility.getDayIndex(sleepTimeLine.startTime);
        dayToSleepTimeLines[dayIndex] = sleepTimeLine;
      });

      Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> dayToTiles =
          mapTilesToDays(tileData.item2, _todayTimeLine);

      List<TilerEvent> todayTiles = dayToTiles.item2;
      Map<int, List<TilerEvent>> dayIndexToTileDict = dayToTiles.item1;

      int todayDayIndex = Utility.getDayIndex(DateTime.now());
      Timeline relevantTimeline = this.previousTimeline ?? this.timeLine;
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleLoadingState) {
        if (currentState.previousLookupTimeline != null) {
          relevantTimeline = currentState.previousLookupTimeline!;
        }
      }

      if (currentState is ScheduleLoadedState) {
        relevantTimeline = currentState.lookupTimeline;
      }

      int startIndex = Utility.getDayIndex(
          DateTime.fromMillisecondsSinceEpoch(relevantTimeline.start!.toInt()));
      int endIndex = Utility.getDayIndex(
          DateTime.fromMillisecondsSinceEpoch(relevantTimeline.end!.toInt()));
      int numberOfDays = (endIndex - startIndex);
      if (numberOfDays <= 0) {
        numberOfDays = 1;
      }
      List<int> dayIndexes = List.generate(numberOfDays, (index) => index);
      dayIndexToTileDict.keys.toList();
      dayIndexes.sort();

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
            String headerString = Utility.getTimeFromIndex(dayIndex).humanDate;
            Key key = Key(dayIndex.toString());
            TileBatch upcomingTileBatch = TileBatch(
                header: headerString,
                dayIndex: dayIndex,
                tiles: allTiles,
                key: key);
            upcomingDayTilesDict[dayIndex] = upcomingTileBatch;
          }
        } else {
          String dayBatchDate = Utility.getTimeFromIndex(dayIndex).humanDate;
          if (!preceedingDayTilesDict.containsKey(dayIndex)) {
            var tiles = <TilerEvent>[];
            if (dayIndexToTileDict.containsKey(dayIndex)) {
              tiles = dayIndexToTileDict[dayIndex]!;
            }
            var allTiles = tiles.toList();
            Key key = Key(dayIndex.toString());
            TileBatch preceedingDayTileBatch = TileBatch(
                header: dayBatchDate,
                dayIndex: dayIndex,
                key: key,
                tiles: allTiles);
            preceedingDayTilesDict[dayIndex] = preceedingDayTileBatch;
          }
        }
      }

      var timeStamps = dayIndexes
          .map((eachDayIndex) => Utility.getTimeFromIndex(eachDayIndex));

      List<TileBatch> preceedingDayTiles =
          preceedingDayTilesDict.values.toList();
      preceedingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
          eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));
      List<TileBatch> upcomingDayTiles = upcomingDayTilesDict.values.toList();
      upcomingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
          eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));

      List<TileBatch> childTileBatchs = <TileBatch>[];
      childTileBatchs.addAll(preceedingDayTiles);
      preceedingDayTiles.forEach((tileBatch) {
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
        List<TileBatch> todayTileBatches = <TileBatch>[];
        WithinNowBatch todayBatch = WithinNowBatch(
          key: ValueKey("_within_upcoming_0"),
          tiles: [...elapsedTiles, ...notElapsedTiles],
        );

        todayTileBatches.add(todayBatch);
        childTileBatchs.addAll(todayTileBatches);
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
        childTileBatchs.add(tileBatch);
      }
      childTileBatchs.addAll(upcomingDayTiles);
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
      if (uiManagedDateState is UiDateManagerInitial) {
        currentDayIndex = uiManagedDateState.currentDate.universalDayIndex;
      }

      int itemCounter = 0;
      int initialCarouselIndex = -1;
      bool isCarouselKeyRefreshed = false;
      carouselItems = sortedDayIndex.map<Widget>((dayIndex) {
        if (initialCarouselIndex < 0 && currentDayIndex == dayIndex) {
          initialCarouselIndex = itemCounter;
        }
        if (!isCarouselKeyRefreshed &&
            !dayIndexToCarouselIndex.containsKey(dayIndex)) {
          carouselKey = ValueKey(Utility.getUuid);
          isCarouselKeyRefreshed = true;
        }
        dayIndexToCarouselIndex[dayIndex] =
            Tuple2(itemCounter, dayIndexToWidget[dayIndex]!);
        ++itemCounter;
        return dayIndexToWidget[dayIndex]!;
      }).toList();

      if (initialCarouselIndex < 0 && carouselItems.length > 0) {
        initialCarouselIndex = 0;
      }

      retValue = CarouselSlider(
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

              this.dayIndexToCarouselIndex.forEach((key, value) {
                if (value.item1 == pageNumber && dayIndexOfTileBatch == null) {
                  dayIndexOfTileBatch = key;
                  tileBatchTupleData = value;
                }
              });

              if (carouselData == CarouselPageChangedReason.manual &&
                  dayIndexOfTileBatch != null &&
                  tileBatchTupleData != null) {
                var currentState = this.context.read<UiDateManagerBloc>().state;
                DateTime previousTime = Utility.currentTime().dayDate;
                DateTime currentTime =
                    Utility.getTimeFromIndex(dayIndexOfTileBatch!).dayDate;
                if (previousTime.millisecondsSinceEpoch >
                    currentTime.millisecondsSinceEpoch) {
                  AnalysticsSignal.send('DAY_SWIPE_BACK');
                } else {
                  AnalysticsSignal.send('DAY_SWIPE_FORWARD');
                }
                if (currentState is UiDateManagerInitial) {
                  previousTime = currentState.currentDate;
                }
                if (currentState is UiDateManagerUpdated) {
                  previousTime = currentState.currentDate;
                }
                if (previousTime.millisecondsSinceEpoch !=
                    currentTime.millisecondsSinceEpoch) {
                  this.context.read<UiDateManagerBloc>().add(DateChangeEvent(
                      selectedDate: currentTime,
                      previousSelectedDate: previousTime));
                }
                // List<int> allDayIndexes = dayIndexToCarouselIndex.keys.toList();
                // allDayIndexes.sort();

                // if (pageNumber == 1) {
                //   int earliestDayIndex = allDayIndexes.first - 1;
                //   if (earliestDayIndex < 0) {
                //     earliestDayIndex = 0;
                //   }
                //   reloadSchedule(
                //       Utility.getTimeFromIndex(earliestDayIndex)
                //           .dayDate
                //           .add(Duration(days: -12)),
                //       forceRenderingPage: false);
                // }

                // if (pageNumber > carouselItems.length - 5) {
                //   int latestDayIndex = allDayIndexes.last + 1;
                //   if (latestDayIndex < 0) {
                //     latestDayIndex = 0;
                //   }
                //   reloadSchedule(
                //       Utility.getTimeFromIndex(latestDayIndex)
                //           .dayDate
                //           .add(Duration(days: 12)),
                //       forceRenderingPage: false);
                // }
              }
            },
            scrollDirection: Axis.horizontal,
          ));
    } else {
      retValue = ListView(children: []);
    }

    return retValue;
  }

  void createConclusionTileNotification(SubCalendarEvent concludingTile) {
    if (this.concludingSubEvent != null &&
        this.concludingSubEvent!.id == concludingTile.id &&
        this.concludingSubEvent!.isStartAndEndEqual(concludingTile)) {
      return;
    }

    String notificationMessage = AppLocalizations.of(context)!.concludesAtTime(
        (concludingTile.isProcrastinate ?? false
            ? AppLocalizations.of(context)!.procrastinateBlockOut
            : concludingTile.name!));

    this.localNotificationService.concludingTileNotification(
        tile: concludingTile,
        context: this.context,
        title: notificationMessage);
    this.concludingSubEvent = concludingTile;
  }

  void createNextTileNotification(SubCalendarEvent nextTile) {
    if (this.notificationSubEvent != null &&
        this.notificationSubEvent!.id == nextTile.id &&
        this.notificationSubEvent!.isStartAndEndEqual(nextTile)) {
      return;
    }
    this
        .localNotificationService
        .nextTileNotification(tile: nextTile, context: this.context);
    this.notificationSubEvent = nextTile;
  }

  void handleNotifications(List<SubCalendarEvent> tiles) {
    double currentTimeMs = Utility.msCurrentTime.toDouble();
    List<TilerEvent> orderedByStartTiles = tiles
        .where((eachTile) =>
            (eachTile.isViable ?? true) && eachTile.start! > currentTimeMs)
        .toList();
    orderedByStartTiles = Utility.orderTiles(orderedByStartTiles);
    List<TilerEvent> orderedByEndTiles = tiles
        .where((eachTile) =>
            (eachTile.isViable ?? true) && eachTile.end! > currentTimeMs)
        .toList();
    orderedByEndTiles.sort((tileA, tileB) {
      int retValue = tileA.end! - tileB.end!;
      return retValue.toInt();
    });

    TilerEvent? earliestByStartSubTile;
    if (orderedByStartTiles.isNotEmpty) {
      earliestByStartSubTile = orderedByStartTiles.first;
    }

    TilerEvent? earliestByEndSubTile;
    if (orderedByEndTiles.isNotEmpty) {
      earliestByEndSubTile = orderedByEndTiles.first;
    }

    this.localNotificationService.cancelAllNotifications();

    if (earliestByStartSubTile != null && earliestByEndSubTile != null) {
      if (earliestByStartSubTile.start! < earliestByEndSubTile.end!) {
        createNextTileNotification(earliestByStartSubTile as SubCalendarEvent);
        return;
      }
      createConclusionTileNotification(
          earliestByEndSubTile as SubCalendarEvent);
      return;
    }

    if (earliestByStartSubTile != null) {
      createNextTileNotification(earliestByStartSubTile as SubCalendarEvent);
      return;
    }
    if (earliestByEndSubTile != null) {
      createConclusionTileNotification(
          earliestByEndSubTile as SubCalendarEvent);
    }
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(
                timeline: lookupTimeline, requestId: incrementalTilerScrollId),
          );
    }
  }

  void handleAutoRefresh(List<SubCalendarEvent> tiles) {
    List<TilerEvent> orderedTiles = Utility.orderTiles(tiles);
    double currentTime = Utility.msCurrentTime.toDouble();
    List<SubCalendarEvent> subSequentTiles = orderedTiles
        .where((eachTile) => eachTile.end! > currentTime)
        .map((eachTile) => eachTile as SubCalendarEvent)
        .toList();
  }

  Widget renderPending({String? message}) {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
        child: CircularProgressIndicator(),
        height: 200.0,
        width: 200.0,
      )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    if (message != null && message.isNotEmpty) {
      centerElements.add(Center(
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 120, 0, 0),
          child: Text(message),
        ),
      ));
    }
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
  }

  handleNotificationsAndNextTile(List<SubCalendarEvent> tiles) {
    handleNotifications(tiles);
    handleAutoRefresh(tiles);
  }

  String _generateIncrementalIdToMapping() {
    return incrementalTilerScrollId + "-" + Utility.msCurrentTime.toString();
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
    ScheduleStatus scheduleStatus = ScheduleStatus();
    Timeline previousTimeLine = this.previousTimeline;

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
    }

    if (scheduleSubEventState is ScheduleLoadingState) {
      subEvents = scheduleSubEventState.subEvents;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.previousLookupTimeline);
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      scheduleStatus = scheduleSubEventState.scheduleStatus;
      evaluatedDayTimelines = scheduleSubEventState.timelines;
      currentTimeline = scheduleSubEventState.previousLookupTimeline;
    }

    int dayDelta = Constants.numberOfDaysToLoad ~/ 2;
    int daySplit = (dayDelta.toDouble() / 2).round();
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
        // if new timeline is within previous timeline
        newTimeline = previousTimeLine;
      }

      startDateTime = newTimeline.startTime;
      endDateTime = newTimeline.endTime;

      if (newTimeline.startTime.millisecondsSinceEpoch <
          previousTimeLine.startTime.millisecondsSinceEpoch) {
        // if new timeline is earlier than previous
        startDateTime = newTimeline.startTime;
        endDateTime = previousTimeLine.startTime;
      }

      if (newTimeline.endTime.millisecondsSinceEpoch >
          previousTimeLine.endTime.millisecondsSinceEpoch) {
        // if new timeline is earlier than previous
        startDateTime = previousTimeLine.endTime;
        endDateTime = newTimeline.endTime;
      }

      if (newTimeline.startTime.millisecondsSinceEpoch <
              previousTimeLine.startTime.millisecondsSinceEpoch &&
          newTimeline.endTime.millisecondsSinceEpoch >
              previousTimeLine.endTime.millisecondsSinceEpoch) {
        // if new timeline is within previous timeline
        startDateTime = newTimeline.startTime;
        endDateTime = newTimeline.endTime;
      }
    }

    if (forcedTimeline != null) {
      startDateTime = forcedTimeline.startTime;
      endDateTime = forcedTimeline.endTime;
    }

    Timeline queryTimeline = Timeline.fromDateTime(startDateTime, endDateTime);
    print("previous timeline " + previousTimeLine.toString());
    print("     new timeline " + queryTimeline.toString());

    this.context.read<ScheduleBloc>().add(GetScheduleEvent(
        previousSubEvents: subEvents,
        previousTimeline: previousTimeLine,
        isAlreadyLoaded: !forceRenderingPage,
        emitOnlyLoadedStated: emitOnlyLoadedStated,
        scheduleTimeline: queryTimeline,
        eventId: loopIncrementalIdToMapping));
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
                timelines: evaluatedDayTimelines);
        incrementalIdToMapping = incrementalIdToMapping_cpy;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ScheduleBloc, ScheduleState>(listener: (context, state) {
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
              });
            }
          }
        }),
        BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
          listener: (context, state) {
            if (state is NewSubCalendarTilesLoadedState) {
              if (state.subEvent != null) {
                SubCalendarEvent subEvent = state.subEvent!;
                int redColor =
                    subEvent.colorRed == null ? 125 : subEvent.colorRed!;
                int blueColor =
                    subEvent.colorBlue == null ? 125 : subEvent.colorBlue!;
                int greenColor =
                    subEvent.colorGreen == null ? 125 : subEvent.colorGreen!;
                double opacity =
                    subEvent.colorOpacity == null ? 1 : subEvent.colorOpacity!;
                var nameColor =
                    Color.fromRGBO(redColor, greenColor, blueColor, opacity);

                var hslColor = HSLColor.fromColor(nameColor);
                Color bgroundColor = hslColor
                    .withLightness(hslColor.lightness)
                    .toColor()
                    .withOpacity(0.7);
                showModalBottomSheet<void>(
                  context: context,
                  constraints: BoxConstraints(
                    maxWidth: 400,
                  ),
                  builder: (BuildContext context) {
                    var future = new Future.delayed(
                        const Duration(milliseconds: Constants.autoHideInMs));
                    var hideNewSheeTileFutrue =
                        future.asStream().listen((input) {
                      Navigator.pop(context);
                    });
                    return ElevatedButton(
                      onPressed: () {
                        hideNewSheeTileFutrue.cancel();
                        Navigator.pop(context);
                        Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => TileDetail(
                                        tileId: subEvent.calendarEvent?.id ??
                                            subEvent.id!)))
                            .whenComplete(() => Navigator.pop(context));
                      },
                      style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.all(0),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        height: 250,
                        width: 300,
                        decoration: BoxDecoration(
                          color: bgroundColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              NewTileSheet(subEvent: subEvent),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              }
            }
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

              reloadSchedule(state.currentDate,
                  forceRenderingPage: forceRenderingPage);
            }
          },
        ),
      ],
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoadedState) {
            if (!(state is DelayedScheduleLoadedState)) {
              handleNotificationsAndNextTile(state.subEvents);
            }
            return Stack(
              children: [
                renderSubCalendarTiles(
                    Tuple2(loadedTimeline, loadedSubCalendarEvent))
              ],
            );
          }

          if (state is ScheduleInitialState) {
            context.read<ScheduleBloc>().add(GetScheduleEvent(
                scheduleTimeline: timeLine,
                isAlreadyLoaded: false,
                previousSubEvents: List<SubCalendarEvent>.empty()));
            refreshScheduleSummary(lookupTimeline: timeLine);
            return renderPending();
          }
          // final dateMangerBloc = this.context.read<UiDateManagerBloc>().state;
          // if (dateMangerBloc is UiDateManagerUpdated) {
          //   print("Current day is " + dateMangerBloc.currentDate.toString());
          // }

          if (state is ScheduleLoadingState) {
            bool showPendingUI = !state.isAlreadyLoaded;

            final dateMangerBloc = this.context.read<UiDateManagerBloc>().state;
            if (dateMangerBloc is UiDateManagerUpdated) {
              showPendingUI = showPendingUI ||
                  !state.previousLookupTimeline
                      .isDateTimeWithin(dateMangerBloc.currentDate);
            }

            if (showPendingUI) {
              return renderPending();
            }
            return Stack(children: [
              renderSubCalendarTiles(Tuple2(state.timelines, state.subEvents))
            ]);
          }

          if (state is ScheduleEvaluationState) {
            return Stack(
              children: [
                renderSubCalendarTiles(
                    Tuple2(state.timelines, state.subEvents)),
                Container(
                    width: (MediaQuery.of(context).size.width),
                    height: (MediaQuery.of(context).size.height),
                    child: new Center(
                        child: new ClipRect(
                            child: new BackdropFilter(
                      filter: new ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                      child: new Container(
                        width: (MediaQuery.of(context).size.width),
                        height: (MediaQuery.of(context).size.height),
                        decoration: new BoxDecoration(
                            color: Colors.grey.shade200.withOpacity(0.5)),
                      ),
                    )))),
              ],
            );
          }

          return Text('Issue with retrieving data');
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
