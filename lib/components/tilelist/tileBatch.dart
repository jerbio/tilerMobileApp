import 'dart:async';
import 'dart:collection';
import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/daySummary.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/chillNow.dart';
import 'package:tiler_app/components/tileUI/emptyDayTile.dart';
import 'package:tiler_app/components/tileUI/loadingTile.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/dayData.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

class TileBatch extends StatefulWidget {
  static final TextStyle dayHeaderTextStyle = TextStyle(
      fontSize: 40,
      fontFamily: TileStyles.rubikFontName,
      color: TileStyles.primaryColorDarkHSL.toColor(),
      fontWeight: FontWeight.w700);
  List<TilerEvent>? tiles;
  Timeline? sleepTimeline;
  String? header;
  String? footer;
  int? dayIndex;
  DayData? dayData;
  ConnectionState? connectionState;

  TileBatch(
      {this.header,
      this.footer,
      this.dayIndex,
      this.tiles,
      this.sleepTimeline,
      this.connectionState,
      this.dayData,
      Key? key})
      : super(key: key);

  @override
  TileBatchState createState() => TileBatchState();
}

class TileBatchState extends State<TileBatch> {
  String uniqueKey = Utility.getUuid;
  bool isInitialized = false;
  Map<String, TilerEvent> renderedTiles = new Map<String, TilerEvent>();
  Map<String, Tuple3<TilerEvent, int?, int?>>? orderedTiles;
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();
  List<Widget> childrenColumnWidgets = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _list;
  bool isInitialLoad = true;
  Timeline? sleepTimeline;
  DayData? _dayData;
  AnimatedList? animatedList;

  @override
  void initState() {
    super.initState();
    if (this.widget.dayIndex != null) {
      _dayData = DayData.generateRandomDayData(this.widget.dayIndex!);
    }
    if (this.widget.dayData != null) {
      _dayData = this.widget.dayData!;
    }
    _list = ListModel(listKey: _listKey, removedItemBuilder: _buildRemovedItem);
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

  Widget _buildRemovedItem(
      TilerEvent item, BuildContext context, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: TileWidget(item)),
    );
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter, child: TileWidget(_list![index])),
    );
  }

  evaluateTileDelta(Iterable<TilerEvent>? tiles) {
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
      allFoundTiles[eachTile.item1.id!] = eachTile.item1;
    }
    Set.from(orderedTiles!.values.map<TilerEvent>((e) => e.item1));

    for (int i = 0; i < orderedByTimeTiles.length; i++) {
      TilerEvent eachTile = orderedByTimeTiles[i];
      int? currentIndexPosition;
      if (orderedTiles!.containsKey(eachTile.id)) {
        currentIndexPosition = orderedTiles![eachTile.id!]!.item2;
      }
      orderedTiles![eachTile.id!] = Tuple3(eachTile, currentIndexPosition, i);
      allFoundTiles.remove(eachTile.id);
    }

    for (TilerEvent eachTile in allFoundTiles.values) {
      orderedTiles![eachTile.id!] =
          Tuple3(eachTile, orderedTiles![eachTile.id!]!.item2, null);
    }
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
              widget.sleepTimeline!.start!, widget.sleepTimeline!.end!);

          List<TimeRange> contiguousSleep = allTiles.where((tile) {
            bool isInterfering = sleepTileEvent.isInterfering(tile);
            if (!isInterfering) {
              postSleepTiles.add(tile);
            }
            if (startOfSleep == null ||
                startOfSleep!.millisecondsSinceEpoch >
                    tile.startTime.millisecondsSinceEpoch) {
              startOfSleep = tile.startTime;
            }

            if (endOfSleep == null ||
                endOfSleep!.millisecondsSinceEpoch <
                    tile.endTime.millisecondsSinceEpoch) {
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
              eachTilerEvent.startTime.millisecondsSinceEpoch) {
            Timeline chillTimeline = new Timeline.fromDateTime(
                refTimeEndTime, eachTilerEvent.startTime);
            chillTimeLines.add(chillTimeline);
          }

          refTimeEndTime = eachTilerEvent.endTime;
        }

        widget.tiles!.forEach((eachTile) {
          if (eachTile.id != null) {
            renderedTiles[eachTile.id!] = eachTile;
          }
        });
      }
      isInitialized = true;
    }
    childrenColumnWidgets = [];
    if (_dayData != null) {
      this._dayData!.nonViableTiles = renderedTiles.values
          .where(
              (eachTile) => !((eachTile as SubCalendarEvent).isViable ?? true))
          .toList();
      childrenColumnWidgets.add(DaySummary(dayData: this._dayData!));
    }

    Widget? sleepWidget;
    if (sleepTimeline != null) {
      Timeline sleepTimeline = this.sleepTimeline!;
      sleepWidget = SleepTileWidget(sleepTimeline);
      childrenColumnWidgets.add(sleepWidget);
    }

    evaluateTileDelta(this.widget.tiles);
    if (renderedTiles.length > 0) {
      if (animatedList == null) {
        var initialItems = this
            .orderedTiles!
            .values
            .where((element) => element.item3 != null)
            .toList();
        animatedList = AnimatedList(
          shrinkWrap: true,
          itemBuilder: _buildItem,
          key: _listKey,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: initialItems.length,
        );
        _list = ListModel<TilerEvent>(
          listKey: _listKey,
          initialItems: initialItems.map<TilerEvent>((e) => e.item1),
          removedItemBuilder: _buildRemovedItem,
        );
      }

      childrenColumnWidgets.add(Container(
        padding: EdgeInsets.all(20),
        child: animatedList!,
      ));
    }

    if (renderedTiles.length == 0) {
      animatedList = null;
      _list = null;
      this.orderedTiles = null;
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
    handleAddOrRemovalOfTiles();
    return Flex(direction: Axis.vertical, children: [
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: childrenColumnWidgets,
      ),
      // )
    ]);
  }

  handleAddOrRemovalOfTiles() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (this.mounted) {
        if (this.orderedTiles != null) {
          List<Tuple3<TilerEvent, int?, int?>> changeDetectedTilerEvent = this
              .orderedTiles!
              .values
              .where((element) => element.item2 != element.item3)
              .toList();
          List<Tuple3<TilerEvent, int?, int?>> removedTiles = [];
          List<Tuple3<TilerEvent, int?, int?>> reorderedTiles = [];
          List<Tuple3<TilerEvent, int?, int?>> insertedTiles = [];
          for (var eachTileTuple in changeDetectedTilerEvent) {
            if (eachTileTuple.item3 == null && eachTileTuple.item2 != null) {
              removedTiles.add(eachTileTuple);
              continue;
            }
            if (!isInitialLoad) {
              if (eachTileTuple.item2 != null) {
                reorderedTiles.add(eachTileTuple);
              } else {
                insertedTiles.add(eachTileTuple);
              }
            }
          }

          if (changeDetectedTilerEvent.length == 0) {
            List<TilerEvent> orderedTilerEvent = Utility.orderTiles(this
                .orderedTiles!
                .values
                .map<TilerEvent>((e) => e.item1)
                .toList());
            for (int i = 0; i < orderedTilerEvent.length; i++) {
              if (!_list![i].isStartAndEndEqual(orderedTilerEvent[i])) {
                _list!.removeAndUpdate(i, i, orderedTilerEvent[i]);
              }
            }
          }

          List<String> listIds =
              _list!.toList().map<String>((e) => e.id!).toList();
          for (var removedTile in removedTiles) {
            int toBeRemovedIndex = listIds.indexOf(removedTile.item1.id!);
            if (toBeRemovedIndex != removedTile.item3) {
              if (toBeRemovedIndex >= 0) {
                _list!.removeAt(toBeRemovedIndex);
              }
            }
          }

          for (var removedTile in removedTiles) {
            orderedTiles!.remove(removedTile.item1.id);
          }

          Timer(Duration(milliseconds: 500), () {
            for (var insertedTile in insertedTiles) {
              _list!.insert(
                insertedTile.item3!,
                insertedTile.item1,
              );
            }

            for (var reorderedTile in reorderedTiles) {
              listIds = _list!.toList().map<String>((e) => e.id!).toList();
              int toMovedIndex = listIds.indexOf(reorderedTile.item1.id!);
              if (toMovedIndex != -1) {
                _list!.removeAndUpdate(
                    toMovedIndex, reorderedTile.item3!, reorderedTile.item1);
              }
            }
          });

          for (var eachTileTupleData in this.orderedTiles!.values) {
            this.orderedTiles![eachTileTupleData.item1.id!] = Tuple3(
                eachTileTupleData.item1,
                eachTileTupleData.item3,
                eachTileTupleData.item3);
          }
          if (this.orderedTiles!.isEmpty) {
            this.widget.tiles = [];
            setState(() {
              this.renderedTiles = {};
            });
          }
        }

        isInitialLoad = false;
      }
    });
  }
}
