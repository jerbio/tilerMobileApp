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
  late bool isInitialLoad;
  Map<String, TilerEvent> renderedTiles = new Map<String, TilerEvent>();
  Map<String, Tuple3<TilerEvent, int?, int?>>? orderedTiles;
  Map<String, Tuple2<TilerEvent, RemovalType>> removedTiles =
      new Map<String, Tuple2<TilerEvent, RemovalType>>();
  List<Widget> childrenColumnWidgets = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _list;
  bool _pendingRendering = false;

  Timeline? sleepTimeline;
  DayData? _dayData;
  AnimatedList? animatedList;

  @override
  void initState() {
    super.initState();
    isInitialLoad = true;
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
    renderedTiles = {};
    if (widget.tiles != null) {
      widget.tiles!.forEach((eachTile) {
        if (eachTile.id != null) {
          renderedTiles[eachTile.id!] = eachTile;
        }
      });
    }

    print('' +
        this.widget.dayIndex.toString() +
        " " +
        Utility.getTimeFromIndex(this.widget.dayIndex!).humanDate +
        " " +
        widget.tiles!.length.toString() +
        " " +
        uniqueKey);
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
        dayIndex: this.widget.dayIndex,
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
        if (this.orderedTiles != null && !_pendingRendering) {
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
          List<TilerEvent> orderedTilerEvent = Utility.orderTiles(this
              .orderedTiles!
              .values
              .map<TilerEvent>((e) => e.item1)
              .toList());
          if (changeDetectedTilerEvent.length == 0) {
            for (int i = 0; i < orderedTilerEvent.length; i++) {
              if (!_list![i].isStartAndEndEqual(orderedTilerEvent[i])) {
                _list!.removeAndUpdate(i, i, orderedTilerEvent[i],
                    animate: false);
              }
            }
          }

          List<String> listIds =
              _list!.toList().map<String>((e) => e.id!).toList();
          for (var removedTile in removedTiles) {
            listIds = _list!.toList().map<String>((e) => e.id!).toList();
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

          if (insertedTiles.isNotEmpty || reorderedTiles.isNotEmpty) {
            _pendingRendering = true;
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
                      toMovedIndex, reorderedTile.item3!, reorderedTile.item1,
                      animate: toMovedIndex != reorderedTile.item3);
                }
              }
              _pendingRendering = false;
            });
          }

          if (this.orderedTiles!.isEmpty) {
            this.widget.tiles = [];
            setState(() {
              this.renderedTiles = {};
            });
          }
        }

        if (isInitialLoad && !_pendingRendering) {
          this.isInitialLoad = false;
        }
        if (this.orderedTiles != null) {
          List finalOrderedTileValues = this.orderedTiles!.values.toList();
          for (var eachTileTupleData in finalOrderedTileValues) {
            this.orderedTiles![eachTileTupleData.item1.id!] = Tuple3(
                eachTileTupleData.item1,
                eachTileTupleData.item3,
                eachTileTupleData.item3);
          }
        }
      }
    });
  }
}
