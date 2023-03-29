import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/chillNow.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/loadingTile.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class TileBatch extends StatefulWidget {
  static final TextStyle dayHeaderTextStyle = TextStyle(
      fontSize: 40,
      fontFamily: TileStyles.rubikFontName,
      color: TileStyles.primaryColorDarkHSL.toColor(),
      fontWeight: FontWeight.w700);
  List<TilerEvent>? tiles;
  List<TilerEvent>? previousRenderedTiles;
  Timeline? sleepTimeline;
  String? header;
  String? footer;
  int? dayIndex;
  ConnectionState? connectionState;

  TileBatch(
      {this.header,
      this.footer,
      this.dayIndex,
      this.tiles,
      this.sleepTimeline,
      this.connectionState,
      this.previousRenderedTiles,
      Key? key})
      : super(key: key);

  @override
  TileBatchState createState() => TileBatchState();
}

class TileBatchState extends State<TileBatch> {
  bool isTransitionToNewTile = false;
  String uniqueKey = Utility.getUuid;
  bool isInitialized = false;
  Map<String, TilerEvent> tiles = new Map<String, TilerEvent>();
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();
  List<Widget> childrenColumnWidgets = [];

  Timeline? sleepTimeline;

  void updateSubEvents(List<TilerEvent> updatedTiles) {
    Map<String, TilerEvent> currentTiles = new Map.from(tiles);
    Map<String, Tuple2<TilerEvent, RemovalType>> currentRemovedTiles =
        new Map.from(removedTiles);
    Map<String, TilerEvent> allTilesRefreshed = new Map<String, TilerEvent>();
    Map<String, TilerEvent> newlyAddedTiles = new Map<String, TilerEvent>();
    Map<String, Tuple2<TilerEvent, RemovalType>> newlyRemovedTiles =
        new Map<String, Tuple2<TilerEvent, RemovalType>>();
    updatedTiles.forEach((eachTile) {
      if (!currentTiles.containsKey(eachTile.id)) {
        newlyAddedTiles[eachTile.id!] = eachTile;
      } else {
        newlyRemovedTiles[eachTile.id!] =
            new Tuple2<TilerEvent, RemovalType>(eachTile, RemovalType.none);
      }
      allTilesRefreshed[eachTile.id!] = eachTile;
    });

    Map<String, Tuple2<TilerEvent, RemovalType>> refreshRemovedTiles =
        new Map.from(currentRemovedTiles);

    newlyRemovedTiles.forEach((tileId, tileRemovalTuple) {
      if (!refreshRemovedTiles.containsKey(tileId)) {
        refreshRemovedTiles[tileId] = tileRemovalTuple;
      }
    });

    this.setState(() {
      tiles = allTilesRefreshed;
      removedTiles = refreshRemovedTiles;
      uniqueKey = uniqueKey + " || " + this.widget.dayIndex.toString();
    });
  }

  void updateSleepTimelines(Timeline timeline) {
    this.setState(() {
      sleepTimeline = timeline;
      uniqueKey = uniqueKey + " || " + this.widget.dayIndex.toString();
    });
    print('---sleep TL 0 -- ' +
        sleepTimeline!.startTime.toString() +
        ' - ' +
        uniqueKey);
  }

  @override
  Widget build(BuildContext context) {
    List<Timeline> chillTimeLines = [];

    print('' +
        this.widget.dayIndex.toString() +
        " " +
        Utility.getTimeFromIndex(this.widget.dayIndex!).humanDate +
        " " +
        widget.tiles!.length.toString() +
        " " +
        uniqueKey);
    if (!isInitialized) {
      if (widget.tiles != null) {
        var conflicts = Utility.getConflictingEvents(widget.tiles!);
        List<TilerEvent> allTiles = [];
        HashSet<TilerEvent> postSleepTiles = new HashSet();
        allTiles.addAll(conflicts.item1);
        allTiles.addAll(conflicts.item2);
        allTiles.sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));
        Timeline sleepTileEvent;
        DateTime? startOfSleep;
        DateTime? endOfSleep;
        if (sleepTimeline != null) {
          print('---sleep TL 1 -- ' + sleepTimeline!.startTime.toString() + '');
          postSleepTiles = new HashSet();
          sleepTileEvent = new Timeline(
              widget.sleepTimeline!.startInMs!, widget.sleepTimeline!.endInMs!);

          List<TimeRange> contiguousSleep = allTiles.where((tile) {
            bool isInterfering = sleepTileEvent.isInterfering(tile);
            if (!isInterfering) {
              postSleepTiles.add(tile);
            }
            if (startOfSleep == null ||
                startOfSleep!.millisecondsSinceEpoch >
                    tile.startTime!.millisecondsSinceEpoch) {
              startOfSleep = tile.startTime;
            }

            if (endOfSleep == null ||
                endOfSleep!.millisecondsSinceEpoch <
                    tile.endTime!.millisecondsSinceEpoch) {
              endOfSleep = tile.endTime;
            }

            startOfSleep = startOfSleep!.millisecondsSinceEpoch >
                    sleepTileEvent.startTime.millisecondsSinceEpoch
                ? sleepTileEvent.startTime
                : startOfSleep!;
            endOfSleep = endOfSleep!.millisecondsSinceEpoch <
                    sleepTileEvent.endTime.millisecondsSinceEpoch
                ? sleepTileEvent.endTime
                : endOfSleep!;

            return isInterfering;
          }).toList();
        } else {
          postSleepTiles = HashSet.from(allTiles);
        }
        var sortedPostSleepTiles = postSleepTiles.toList();
        sortedPostSleepTiles
            .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

        DateTime? refTimeEndTime;
        int beginIndex = 0;
        if (endOfSleep != null) {
          refTimeEndTime = endOfSleep;
        } else {
          if (sortedPostSleepTiles.length > 0) {
            refTimeEndTime = sortedPostSleepTiles[0].endTime;
            beginIndex = 1;
          }
        }

        for (int subEventIndex = beginIndex;
            subEventIndex < sortedPostSleepTiles.length;
            subEventIndex++) {
          TilerEvent eachTilerEvent = sortedPostSleepTiles[subEventIndex];
          if (refTimeEndTime!.millisecondsSinceEpoch <
              eachTilerEvent.startTime!.millisecondsSinceEpoch) {
            Timeline chillTimeline = new Timeline.fromDateTime(
                refTimeEndTime, eachTilerEvent.startTime!);
            chillTimeLines.add(chillTimeline);
          }

          refTimeEndTime = eachTilerEvent.endTime;
        }

        widget.tiles!.forEach((eachTile) {
          if (eachTile.id != null) {
            tiles[eachTile.id!] = eachTile;
          }
        });
      }
      isInitialized = true;
    }
    childrenColumnWidgets = [];
    if (widget.header != null) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!, style: TileBatch.dayHeaderTextStyle),
      );
      SizedBox topHeaderMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(topHeaderMargin);
      childrenColumnWidgets.add(headerContainer);
      SizedBox bottomHeaderMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(bottomHeaderMargin);
    }

    Widget? sleepWidget;
    if (sleepTimeline != null) {
      Timeline sleepTimeline = this.sleepTimeline!;
      sleepWidget = SleepTileWidget(sleepTimeline);
      childrenColumnWidgets.add(sleepWidget);
    }

    List<Tuple3<bool, TimeRange, Widget>> allWidgets = [];
    if (tiles.length > 0) {
      List<TilerEvent> tileList = tiles.values.toList();
      for (int eachTileIndex = 0;
          eachTileIndex < tileList.length;
          eachTileIndex++) {
        TilerEvent eachTile = tileList[eachTileIndex];
        Widget eachTileWidget = AnimatedSwitcher(
            key: ValueKey(eachTile.id),
            duration: const Duration(milliseconds: Constants.animationDuration),
            // transitionBuilder: (Widget child, Animation<double> animation) {
            //   return ScaleTransition(scale: animation, child: child);
            // },
            child: TileWidget(eachTile));
        if ((isTransitionToNewTile ||
                (this.widget.previousRenderedTiles != null &&
                    this.widget.previousRenderedTiles!.length > 0)) &&
            eachTileIndex < this.widget.previousRenderedTiles!.length) {
          TilerEvent previousTile =
              this.widget.previousRenderedTiles![eachTileIndex];
          if (!previousTile.isEquivalent(eachTile)) {
            SubCalendarEvent previousTile = this
                .widget
                .previousRenderedTiles![eachTileIndex] as SubCalendarEvent;
            Widget previousTileWidget = TileWidget(previousTile);
            eachTileWidget = AnimatedSwitcher(
                key: ValueKey(eachTile.id! + previousTile.id!),
                duration: const Duration(milliseconds: 500),
                // transitionBuilder: (Widget child, Animation<double> animation) {
                //   return ScaleTransition(scale: animation, child: child);
                // },
                child: isTransitionToNewTile
                    ? TileWidget(eachTile)
                    : previousTileWidget);
          }
        }
        var tuple = new Tuple3(true, eachTile, eachTileWidget);
        allWidgets.add(tuple);
      }
      tiles.values.forEach((eachTile) {});

      allWidgets.sort(
          (tileA, tileB) => tileA.item2.start!.compareTo(tileB.item2.start!));

      childrenColumnWidgets
          .addAll(allWidgets.map((widgetTuple) => widgetTuple.item3));
    }

    if (tiles.length == 0) {
      DateTime? endOfDayTime;
      if (this.widget.dayIndex != null) {
        DateTime evaluatedEndOfTIme =
            Utility.getTimeFromIndex(this.widget.dayIndex!).endOfDay;
        if (Utility.utcEpochMillisecondsFromDateTime(evaluatedEndOfTIme) >
            Utility.msCurrentTime) {
          endOfDayTime = evaluatedEndOfTIme;
        }
      }

      childrenColumnWidgets.add(EmptyDayTile(
        deadline: endOfDayTime,
      ));
    }

    if (widget.footer != null) {
      Container footerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 40, 0, 20),
        alignment: Alignment.centerLeft,
        child: Text(widget.footer!, style: TileBatch.dayHeaderTextStyle),
      );
      SizedBox topFooterMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(topFooterMargin);
      childrenColumnWidgets.add(footerContainer);
      SizedBox bottomFooterMargin = SizedBox(
        height: 10,
      );
      childrenColumnWidgets.add(bottomFooterMargin);
    }

    if (sleepWidget != null && sleepTimeline != null) {
      if (childrenColumnWidgets.contains(sleepWidget)) {
        print('---sleep TL 4 -- ' +
            sleepTimeline!.startTime.toString() +
            '\t\t' +
            childrenColumnWidgets.length.toString() +
            "Child widgets " +
            uniqueKey);
      }
    }

    if (this.widget.previousRenderedTiles != null &&
        this.widget.previousRenderedTiles!.length > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Timer(Duration(milliseconds: 1000), () {
          if (this.mounted && !this.isTransitionToNewTile) {
            print("There should be a dance");
            setState(() {
              isTransitionToNewTile = true;
            });
          }
        });
      });
    }
    return Container(
      width: (MediaQuery.of(context).size.width * 0.90),
      margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
      padding: EdgeInsets.fromLTRB(0, 50, 0, 100),
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        children: childrenColumnWidgets,
      ),
    );
  }
}
