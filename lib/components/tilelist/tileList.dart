import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/components/tilelist/tileBatchWithinNow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter/src/painting/gradient.dart' as paintGradient;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// This renders the list of tiles on a given day
class TileList extends StatefulWidget {
  SubCalendarEvent? notificationSubEvent;
  final ScheduleApi scheduleApi = new ScheduleApi();
  TileList({Key? key}) : super(key: key);

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  Timeline timeLine = Timeline.fromDateTimeAndDuration(
      DateTime.now().add(Duration(days: -3)), Duration(days: 7));
  Timeline? oldTimeline;
  Timeline _todayTimeLine = Utility.todayTimeline();
  ScrollController _scrollController = new ScrollController();
  late final LocalNotificationService localNotificationService;
  BoxDecoration previousTileBatchDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        spreadRadius: 5,
        blurRadius: 7,
        offset: const Offset(0, 3), // changes position of shadow
      ),
    ],
  );

  BoxDecoration upcomingTileBatchDecoration = BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.5),
        spreadRadius: 5,
        blurRadius: 7,
        offset: const Offset(0, -3), // changes position of shadow
      ),
    ],
  );

  @override
  void initState() {
    localNotificationService = LocalNotificationService();
    super.initState();
    _scrollController.addListener(() {
      double minScrollLimit = _scrollController.position.minScrollExtent + 1500;
      double maxScrollLimit = _scrollController.position.maxScrollExtent - 1500;
      Timeline updatedTimeline;
      if (_scrollController.position.pixels >= maxScrollLimit &&
          _scrollController.position.userScrollDirection.index == 2) {
        final currentState = this.context.read<ScheduleBloc>().state;
        if (currentState is ScheduleLoadedState) {
          final currentTimeline = this.timeLine;
          updatedTimeline = new Timeline(timeLine.startInMs!,
              (timeLine.endInMs! + Utility.sevenDays.inMilliseconds));
          setState(() {
            oldTimeline = timeLine;
            timeLine = updatedTimeline;
          });
          this.context.read<ScheduleBloc>().add(GetSchedule(
              previousSubEvents: currentState.subEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: updatedTimeline));
        }
      } else if (_scrollController.position.pixels <= minScrollLimit &&
          _scrollController.position.userScrollDirection.index == 1) {
        final currentState = this.context.read<ScheduleBloc>().state;
        if (currentState is ScheduleLoadedState) {
          final currentTimeline = this.timeLine;
          updatedTimeline = new Timeline(
              (timeLine.startInMs!.toInt() - Utility.sevenDays.inMilliseconds)
                  .toInt(),
              timeLine.endInMs!.toInt());
          setState(() {
            oldTimeline = timeLine;
            timeLine = updatedTimeline;
          });
          this.context.read<ScheduleBloc>().add(GetSchedule(
              previousSubEvents: currentState.subEvents,
              isAlreadyLoaded: true,
              previousTimeline: currentTimeline,
              scheduleTimeline: this.timeLine));
        }
      }
      localNotificationService.initialize(this.context);
    });
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
        if (todayTimeline.startInMs != null && tile.end != null) {
          if (todayTimeline.startInMs! > tile.end!) {
            referenceTime = tile.endTime;
          }
        }
      }

      if (referenceTime != null) {
        var dayIndex = Utility.getDayIndex(referenceTime);
        List<TilerEvent>? tilesForDay;
        if (dayIndexToTiles.containsKey(dayIndex)) {
          tilesForDay = dayIndexToTiles[dayIndex];
        } else {
          tilesForDay = [];
          dayIndexToTiles[dayIndex] = tilesForDay;
        }
        tilesForDay!.add(tile);
      }
    }

    Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> retValue =
        new Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>>(
            dayIndexToTiles, todaySubEvents);

    return retValue;
  }

  Widget renderSubCalendarTiles(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    WithinNowBatch elapsedTodayBatch;
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
      Timeline relevantTimeline = this.oldTimeline ?? this.timeLine;
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleLoadingState) {
        if (currentState.previousLookupTimeline != null) {
          relevantTimeline = currentState.previousLookupTimeline!;
        }
      }

      if (currentState is ScheduleLoadedState) {
        relevantTimeline = currentState.lookupTimeline;
      }

      int startIndex = Utility.getDayIndex(DateTime.fromMillisecondsSinceEpoch(
          relevantTimeline.startInMs!.toInt()));
      int endIndex = Utility.getDayIndex(DateTime.fromMillisecondsSinceEpoch(
          relevantTimeline.endInMs!.toInt()));
      int numberOfDays = (endIndex - startIndex) + 1;
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

      print('------------There are 111 ' +
          tileData.item2.length.toString() +
          ' tiles------------');
      print('------------There are relevant ' +
          relevantTimeline.toString() +
          ' tiles------------');

      print('------------There are ' +
          timeLine.toString() +
          ' tiles------------');

      List<TileBatch> preceedingDayTiles =
          preceedingDayTilesDict.values.toList();
      preceedingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
          eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));
      List<TileBatch> upcomingDayTiles = upcomingDayTilesDict.values.toList();
      upcomingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
          eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));

      List<TileBatch> childTileBatchs = <TileBatch>[];
      childTileBatchs.addAll(preceedingDayTiles);
      List<Widget> beforeNowBatch = preceedingDayTiles
          .map((tileBatch) => Container(
                decoration: previousTileBatchDecoration,
                child: tileBatch,
              ))
          .toList();
      List<Widget> todayAndUpcomingBatch = [];
      DateTime currentTime = Utility.currentTime();
      if (todayTiles.length > 0) {
        List<TilerEvent> elapsedTiles = [];
        List<TilerEvent> notElapsedTiles = [];
        for (TilerEvent eachSubEvent in todayTiles) {
          if (eachSubEvent.endTime!.millisecondsSinceEpoch >
              currentTime.millisecondsSinceEpoch) {
            notElapsedTiles.add(eachSubEvent);
          } else {
            elapsedTiles.add(eachSubEvent);
          }
        }

        if (elapsedTiles.isNotEmpty) {
          elapsedTodayBatch = WithinNowBatch(
            key: ValueKey(Utility.getUuid.toString()),
            tiles: elapsedTiles,
          );
          beforeNowBatch.add(Container(child: elapsedTodayBatch));
        }

        if (notElapsedTiles.isNotEmpty) {
          Widget notElapsedTodayBatch = WithinNowBatch(
            key: ValueKey(Utility.getUuid.toString()),
            tiles: notElapsedTiles,
          );
          todayAndUpcomingBatch.add(notElapsedTodayBatch);
        }
      }
      childTileBatchs.addAll(upcomingDayTiles);
      todayAndUpcomingBatch
          .addAll(upcomingDayTiles.map((tileBatch) => Container(
                decoration: upcomingTileBatchDecoration,
                child: tileBatch,
              )));
      Key centerKey = ValueKey(Utility.getUuid.toString());
      retValue = Container(
          decoration: TileStyles.defaultBackground,
          child: CustomScrollView(
            center: centerKey,
            controller: _scrollController,
            slivers: <Widget>[
              SliverList(
                key: ValueKey(Utility.getUuid.toString()),
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return beforeNowBatch[(beforeNowBatch.length - index) - 1];
                  },
                  childCount: beforeNowBatch.length,
                ),
              ),
              SliverList(
                key: centerKey,
                delegate: SliverChildBuilderDelegate(
                  (BuildContext context, int index) {
                    return todayAndUpcomingBatch[index];
                  },
                  childCount: todayAndUpcomingBatch.length,
                ),
              ),
            ],
          ));
    } else {
      retValue = ListView(children: []);
    }

    return retValue;
  }

  void createNextTileNotification(SubCalendarEvent nextTile) {
    if (this.widget.notificationSubEvent != null &&
        this.widget.notificationSubEvent!.isStartAndEndEqual(nextTile)) {
      return;
    }
    this.localNotificationService.cancelAllNotifications();
    this
        .localNotificationService
        .nextTileNotification(tile: nextTile, context: this.context);
    this.widget.notificationSubEvent = nextTile;
  }

  void handleNotifications(List<SubCalendarEvent> tiles) {
    List<TilerEvent> orderedTiles = Utility.orderTiles(tiles);
    double currentTime = Utility.msCurrentTime.toDouble();
    List<SubCalendarEvent> subSequentTiles = orderedTiles
        .map((eachTile) => eachTile as SubCalendarEvent)
        .where((eachTile) =>
            eachTile.start! > currentTime &&
            (eachTile.isViable == null || eachTile.isViable!))
        .toList();

    if (subSequentTiles.isNotEmpty) {
      SubCalendarEvent notificationTile = subSequentTiles.first;
      createNextTileNotification(notificationTile);
    } else {
      this.localNotificationService.cancelAllNotifications();
    }
  }

  void handleAutoRefresh(List<SubCalendarEvent> tiles) {
    List<TilerEvent> orderedTiles = Utility.orderTiles(tiles);
    double currentTime = Utility.msCurrentTime.toDouble();
    List<SubCalendarEvent> subSequentTiles = orderedTiles
        .where((eachTile) => eachTile.end! > currentTime)
        .map((eachTile) => eachTile as SubCalendarEvent)
        .toList();

    if (subSequentTiles.isNotEmpty) {
      SubCalendarEvent notificationTile = subSequentTiles.first;
      final scheduleState = this.context.read<ScheduleBloc>().state;
      if (scheduleState is ScheduleLoadedState) {
        this.context.read<ScheduleBloc>().add(DelayedGetSchedule(
            delayDuration: notificationTile.durationTillEnd,
            isAlreadyLoaded: true,
            previousSubEvents: scheduleState.subEvents,
            previousTimeline: scheduleState.lookupTimeline,
            scheduleTimeline: scheduleState.lookupTimeline,
            renderedTimelines: scheduleState.timelines));
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScheduleBloc, ScheduleState>(
      listener: (context, state) {
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
      },
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          if (state is ScheduleLoadedState) {
            if (!(state is DelayedScheduleLoadedState)) {
              handleNotificationsAndNextTile(state.subEvents);
            }
            return renderSubCalendarTiles(
                Tuple2(state.timelines, state.subEvents));
          }

          if (state is ScheduleInitialState) {
            context.read<ScheduleBloc>().add(GetSchedule(
                scheduleTimeline: timeLine,
                isAlreadyLoaded: false,
                previousSubEvents: List<SubCalendarEvent>.empty()));
          }

          if (state is ScheduleInitialState) {
            return renderPending();
          }

          if (state is ScheduleLoadingState) {
            if (!state.isAlreadyLoaded) {
              return renderPending();
            }
            return renderSubCalendarTiles(
                Tuple2(state.timelines, state.subEvents));
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
                renderPending(message: state.message),
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
