import 'dart:collection';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/tileUI/chillNow.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

class TileBatch extends StatefulWidget {
  List<TilerEvent>? tiles;
  Timeline? sleepTimeline;
  String? header;
  String? footer;
  int? dayIndex;
  TileBatchState? _state;

  TileBatch(
      {this.header,
      this.footer,
      this.dayIndex,
      this.tiles,
      this.sleepTimeline,
      Key? key})
      : super(key: key);

  @override
  TileBatchState createState() {
    _state = TileBatchState();
    return _state!;
  }

  Future<TileBatchState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<TileBatchState> retValue = new Future.delayed(
          const Duration(milliseconds: stateRetrievalRetry), () {
        return this.state;
      });

      return retValue;
    }
  }

  Future updateTiles(List<TilerEvent> updatedTiles) async {
    var state = await this.state;
    state.updateSubEvents(updatedTiles);
  }

  Future updateSleep(Timeline timeline) async {
    sleepTimeline = timeline;
  }
}

class TileBatchState extends State<TileBatch> {
  bool isInitialized = false;
  Map<String, TilerEvent> tiles = new Map<String, TilerEvent>();
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();

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
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Timeline> chillTimeLines = [];
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
        if (widget.sleepTimeline != null) {
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
                    sleepTileEvent.startTime!.millisecondsSinceEpoch
                ? sleepTileEvent.startTime!
                : startOfSleep!;
            endOfSleep = endOfSleep!.millisecondsSinceEpoch <
                    sleepTileEvent.endTime!.millisecondsSinceEpoch
                ? sleepTileEvent.endTime!
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
          Timeline chillTimeline = new Timeline.fromDateTime(
              refTimeEndTime!, eachTilerEvent.startTime!);
          chillTimeLines.add(chillTimeline);
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
    List<Widget> children = [];
    if (widget.header != null) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
      SizedBox topHeaderMargin = SizedBox(
        height: 10,
      );
      children.add(topHeaderMargin);
      children.add(headerContainer);
      SizedBox bottomHeaderMargin = SizedBox(
        height: 10,
      );
      children.add(bottomHeaderMargin);
    }

    if (this.widget.sleepTimeline != null) {
      Timeline sleepTimeline = this.widget.sleepTimeline!;
      Widget sleepWidget = SleepTileWidget(sleepTimeline);
      children.add(sleepWidget);
    }

    List<Tuple3<bool, TimeRange, Widget>> allWidgets = [];
    if (tiles.length > 0) {
      tiles.values.forEach((eachTile) {
        Widget eachTileWidget = TileWidget(eachTile);
        var tuple = new Tuple3(true, eachTile, eachTileWidget);
        allWidgets.add(tuple);
      });

      chillTimeLines.forEach((chillTimeline) {
        Widget eachTileWidget = ChillTimeWidget(chillTimeline);
        var tuple = new Tuple3(false, chillTimeline, eachTileWidget);
        allWidgets.add(tuple);
      });

      allWidgets.sort(
          (tileA, tileB) => tileA.item2.start!.compareTo(tileB.item2.start!));

      children.addAll(allWidgets.map((widgetTuple) => widgetTuple.item3));
    }

    if (widget.footer != null) {
      Container footerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 40, 0, 20),
        alignment: Alignment.centerLeft,
        child: Text(widget.footer!,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      );
      SizedBox topFooterMargin = SizedBox(
        height: 10,
      );
      children.add(topFooterMargin);
      children.add(footerContainer);
      SizedBox bottomFooterMargin = SizedBox(
        height: 10,
      );
      children.add(bottomFooterMargin);
    }
    return Container(
      child: Column(
        children: children,
      ),
    );
  }
}
