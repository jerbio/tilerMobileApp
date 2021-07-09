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
  TileList({Key? key}) : super(key: key) {}

  @override
  _TileListState createState() => _TileListState();
}

class _TileListState extends State<TileList> {
  Timeline timeLine = Timeline.fromDateTimeAndDuration(
      DateTime.now().add(Duration(days: -3)), Duration(days: 8));
  Timeline _todayTimeLine = Utility.todayTimeline();
  ScrollController _scrollController = new ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      print('Scrollcontroller poke');
      double minScrollLimit = _scrollController.position.minScrollExtent + 0;
      double maxScrollLimit = _scrollController.position.maxScrollExtent - 0;
      Timeline updatedTimeline;
      if (_scrollController.position.pixels >= maxScrollLimit &&
          _scrollController.position.userScrollDirection.index == 2) {
        updatedTimeline = new Timeline(
            start: timeLine.start!,
            end: (timeLine.end!.toInt() + Utility.sevenDays.inMilliseconds)
                .toDouble());
        setState(() {
          timeLine = updatedTimeline;
        });
      } else if (_scrollController.position.pixels <= minScrollLimit &&
          _scrollController.position.userScrollDirection.index == 1) {
        updatedTimeline = new Timeline(
            start: (timeLine.start!.toInt() - Utility.sevenDays.inMilliseconds)
                .toDouble(),
            end: timeLine.end!.toInt().toDouble());
        setState(() {
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
        if (todayTimeline.start != null && tile.end != null) {
          if (todayTimeline.start! > tile.end!) {
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
    Map<int, TileBatch> allTileBatches = new Map<int, TileBatch>();
    WithinNowBatch withinNowBatch = WithinNowBatch(
      key: Key(Utility.getUuid),
    );
    Map<int, TileBatch> preceedingDayTilesDict = new Map<int, TileBatch>();
    Map<int, TileBatch> upcomingDayTilesDict = new Map<int, TileBatch>();
    return FutureBuilder(
        future: this.widget.scheduleApi.getSubEvents(timeLine),
        builder: (context, AsyncSnapshot<List<SubCalendarEvent>> snapshot) {
          Widget retValue;
          if (snapshot.hasData) {
            List<SubCalendarEvent>? tileData = snapshot.data;
            if (tileData != null) {
              tileData.sort((eachSubEventA, eachSubEventB) =>
                  eachSubEventA.start!.compareTo(eachSubEventB.start!));

              // tileData.forEach((eachTile) {
              //   print(eachTile);
              // });

              Tuple2<Map<int, List<TilerEvent>>, List<TilerEvent>> dayToTiles =
                  mapTilesToDays(tileData, _todayTimeLine);

              List<TilerEvent> todayTiles = dayToTiles.item2;
              Map<int, List<TilerEvent>> dayIndexToTileDict = dayToTiles.item1;

              int todayDayIndex = Utility.getDayIndex(DateTime.now());
              int startIndex = Utility.getDayIndex(
                  DateTime.fromMillisecondsSinceEpoch(
                      this.timeLine.start!.toInt()));
              int endIndex = Utility.getDayIndex(
                  DateTime.fromMillisecondsSinceEpoch(
                      this.timeLine.end!.toInt()));
              int numberOfDays = (endIndex - startIndex) + 1;
              List<int> dayIndexes =
                  List.generate(numberOfDays, (index) => index);
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
                    String headerString =
                        Utility.getTimeFromIndex(dayIndex).humanDate;
                    TileBatch upcomingTileBatch = TileBatch(
                      header: headerString,
                      dayIndex: dayIndex,
                      tiles: tiles,
                      key: Key(Utility.getUuid),
                    );
                    allTileBatches[dayIndex] = upcomingTileBatch;
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
                    TileBatch preceedingDayTileBatch = TileBatch(
                      footer: footerString,
                      dayIndex: dayIndex,
                      key: Key(Utility.getUuid),
                      tiles: tiles,
                    );
                    allTileBatches[dayIndex] = preceedingDayTileBatch;
                    preceedingDayTilesDict[dayIndex] = preceedingDayTileBatch;
                  }
                }
              }

              var timeStamps = dayIndexes.map(
                  (eachDayIndex) => Utility.getTimeFromIndex(eachDayIndex));

              print('There are ' + tileData.length.toString() + ' tiles');
              print('This is from ' +
                  Utility.getTimeFromIndex(dayIndexes[0]).toString() +
                  ' - ' +
                  Utility.getTimeFromIndex(dayIndexes[dayIndexes.length - 1])
                      .toString());

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
                childTileBatchs.add(withinNowBatch);
              }
              childTileBatchs.addAll(upcomingDayTiles);
              print("Width is " + MediaQuery.of(context).size.width.toString());
              retValue = Container(
                color: Color.fromRGBO(250, 254, 255, 1),
                alignment: Alignment.center,
                child: ListView.builder(
                    itemCount: childTileBatchs.length,
                    controller: _scrollController,
                    itemBuilder: (context, index) {
                      return childTileBatchs[index];
                    }),
              );

              new Future.delayed(const Duration(seconds: 1), () async {
                for (TileBatch tileBatch in childTileBatchs) {
                  if (tileBatch.dayIndex != null) {
                    if (dayIndexToTileDict.containsKey(tileBatch.dayIndex)) {
                      List<TilerEvent> tiles =
                          dayIndexToTileDict[tileBatch.dayIndex]!;
                      tileBatch.updateTiles(tiles);
                    }
                    continue;
                  }
                  tileBatch.updateTiles(todayTiles);
                }
              });
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
