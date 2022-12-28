import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/components/tilelist/tileBatchWithinNow.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

/**
 * This renders the list of tiles on a given day
 */

class TileList extends StatefulWidget {
  final ScheduleApi scheduleApi = new ScheduleApi();
  TileList({Key? key}) : super(key: key);

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  Timeline timeLine = Timeline.fromDateTimeAndDuration(
      DateTime.now().add(Duration(days: -3)), Duration(days: 3));
  Timeline? oldTimeline;
  Timeline _todayTimeLine = Utility.todayTimeline();
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      double minScrollLimit = _scrollController.position.minScrollExtent + 0;
      double maxScrollLimit = _scrollController.position.maxScrollExtent - 0;
      Timeline updatedTimeline;
      if (_scrollController.position.pixels >= maxScrollLimit &&
          _scrollController.position.userScrollDirection.index == 2) {
        updatedTimeline = new Timeline(
            timeLine.startInMs!,
            (timeLine.endInMs!.toInt() + Utility.sevenDays.inMilliseconds)
                .toDouble());
        setState(() {
          oldTimeline = timeLine;
          timeLine = updatedTimeline;
        });
      } else if (_scrollController.position.pixels <= minScrollLimit &&
          _scrollController.position.userScrollDirection.index == 1) {
        updatedTimeline = new Timeline(
            (timeLine.startInMs!.toInt() - Utility.sevenDays.inMilliseconds)
                .toDouble(),
            timeLine.endInMs!.toInt().toDouble());
        setState(() {
          oldTimeline = timeLine;
          timeLine = updatedTimeline;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    WithinNowBatch withinNowBatch;
    Map<int, TileBatch> preceedingDayTilesDict = new Map<int, TileBatch>();
    Map<int, TileBatch> upcomingDayTilesDict = new Map<int, TileBatch>();
    return FutureBuilder(
        future: this.widget.scheduleApi.getSubEvents(timeLine),
        builder: (context,
            AsyncSnapshot<Tuple2<List<Timeline>, List<SubCalendarEvent>>>
                snapshot) {
          Widget retValue;
          if (snapshot.hasData) {
            Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData =
                snapshot.data;

            if (snapshot.connectionState == ConnectionState.done &&
                this.oldTimeline != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                setState(() {
                  oldTimeline = null;
                });
              });
            }
            if (tileData != null) {
              List<Timeline> sleepTimelines = tileData.item1;
              tileData.item2.sort((eachSubEventA, eachSubEventB) =>
                  eachSubEventA.start!.compareTo(eachSubEventB.start!));

              Map<int, Timeline> dayToSleepTimeLines = {};
              sleepTimelines.forEach((sleepTimeLine) {
                int dayIndex = Utility.getDayIndex(sleepTimeLine.startTime!);
                dayToSleepTimeLines[dayIndex] = sleepTimeLine;
              });

              Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> dayToTiles =
                  mapTilesToDays(tileData.item2, _todayTimeLine);

              List<TilerEvent> todayTiles = dayToTiles.item2;
              Map<int, List<TilerEvent>> dayIndexToTileDict = dayToTiles.item1;

              int todayDayIndex = Utility.getDayIndex(DateTime.now());
              Timeline relevantTimeline = this.oldTimeline ?? this.timeLine;
              int startIndex = Utility.getDayIndex(
                  DateTime.fromMillisecondsSinceEpoch(
                      relevantTimeline.startInMs!.toInt()));
              int endIndex = Utility.getDayIndex(
                  DateTime.fromMillisecondsSinceEpoch(
                      relevantTimeline.endInMs!.toInt()));
              int numberOfDays = (endIndex - startIndex) + 1;
              List<int> dayIndexes =
                  List.generate(numberOfDays, (index) => index);
              dayIndexToTileDict.keys.toList();
              dayIndexes.sort();

              for (int i = 0; i < dayIndexes.length; i++) {
                int dayIndex = dayIndexes[i];
                dayIndex += startIndex;
                dayIndexes[i] = dayIndex;
                bool alreadyDayIndex = dayIndexToTileDict.containsKey(dayIndex);
                if (dayIndex > todayDayIndex) {
                  if (!upcomingDayTilesDict.containsKey(dayIndex)) {
                    var tiles = <TilerEvent>[];
                    if (dayIndexToTileDict.containsKey(dayIndex)) {
                      tiles = dayIndexToTileDict[dayIndex]!;
                    }
                    String headerString =
                        Utility.getTimeFromIndex(dayIndex).humanDate;
                    Key key = Key(dayIndex.toString());
                    TileBatch upcomingTileBatch = TileBatch(
                      header: headerString,
                      dayIndex: dayIndex,
                      tiles: tiles,
                      key: key,
                      connectionState: alreadyDayIndex
                          ? ConnectionState.done
                          : (snapshot.connectionState == ConnectionState.done
                              ? ConnectionState.done
                              : ConnectionState.waiting),
                    );
                    upcomingDayTilesDict[dayIndex] = upcomingTileBatch;
                  }
                } else {
                  String footerString =
                      Utility.getTimeFromIndex(dayIndex).humanDate;
                  if (!preceedingDayTilesDict.containsKey(dayIndex)) {
                    var tiles = <TilerEvent>[];
                    if (dayIndexToTileDict.containsKey(dayIndex)) {
                      tiles = dayIndexToTileDict[dayIndex]!;
                    }
                    Key key = Key(dayIndex.toString());
                    TileBatch preceedingDayTileBatch = TileBatch(
                      header: footerString,
                      dayIndex: dayIndex,
                      key: key,
                      tiles: tiles,
                      connectionState: alreadyDayIndex
                          ? ConnectionState.done
                          : (snapshot.connectionState == ConnectionState.done
                              ? ConnectionState.done
                              : ConnectionState.waiting),
                    );
                    preceedingDayTilesDict[dayIndex] = preceedingDayTileBatch;
                  }
                }
              }

              var timeStamps = dayIndexes.map(
                  (eachDayIndex) => Utility.getTimeFromIndex(eachDayIndex));

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
              List<TileBatch> upcomingDayTiles =
                  upcomingDayTilesDict.values.toList();
              upcomingDayTiles.sort((eachTileBatchA, eachTileBatchB) =>
                  eachTileBatchA.dayIndex!.compareTo(eachTileBatchB.dayIndex!));

              List<TileBatch> childTileBatchs = <TileBatch>[];
              childTileBatchs.addAll(preceedingDayTiles);
              if (todayTiles.length > 0) {
                withinNowBatch = WithinNowBatch(
                  key: Key(Utility.getUuid),
                  tiles: todayTiles,
                );
                childTileBatchs.add(withinNowBatch);
              }
              childTileBatchs.addAll(upcomingDayTiles);
              retValue = Column(children: [
                Expanded(
                  // color: Colors.white,
                  // alignment: Alignment.center,
                  child: ListView.builder(
                      itemCount: childTileBatchs.length,
                      controller: _scrollController,
                      itemBuilder: (context, index) {
                        return childTileBatchs[index];
                      }),
                )
              ]);
            } else {
              retValue = ListView(children: []);
            }
          } else {
            retValue = CircularProgressIndicator();
          }
          return retValue;
        });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
