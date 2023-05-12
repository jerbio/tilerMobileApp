import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/daySummary.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/data/dayData.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';

class WithinNowBatch extends TileBatch {
  TileWidget? _currentWidget;
  WithinNowBatchState? _state;
  DayData? dayData;

  WithinNowBatch(
      {String? header = '',
      String? footer = 'Upcoming',
      List<TilerEvent>? tiles,
      DayData? dayData,
      Key? key})
      : super(
            header: header,
            footer: footer,
            key: key,
            tiles: tiles,
            dayData: dayData,
            dayIndex: Utility.currentTime().universalDayIndex);

  @override
  WithinNowBatchState createState() {
    _state = WithinNowBatchState();
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
}

enum _AnimatedListType { preceeding, current, upcoming }

class WithinNowBatchState extends TileBatchState {
  final GlobalKey<AnimatedListState> _preceedingListKey =
      GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _preceedingList;
  AnimatedList? preceedingAnimatedList;
  Map<String, Tuple3<TilerEvent, int?, int?>>? preceedingOrderedTiles;
  final GlobalKey<AnimatedListState> _currentListKey =
      GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _currentList;
  AnimatedList? currentAnimatedList;
  Map<String, Tuple3<TilerEvent, int?, int?>>? currentOrderedTiles;
  final GlobalKey<AnimatedListState> _upcomingListKey =
      GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _upcomingList;
  AnimatedList? upcomingAnimatedList;
  Map<String, Tuple3<TilerEvent, int?, int?>>? upcomingOrderedTiles;
  bool _pendingRendering = false;
  @override
  void initState() {
    super.initState();
    _preceedingList = ListModel(
        listKey: _preceedingListKey, removedItemBuilder: _buildRemovedItem);
    _currentList = ListModel(
        listKey: _currentListKey, removedItemBuilder: _buildRemovedItem);
    _upcomingList = ListModel(
        listKey: _upcomingListKey, removedItemBuilder: _buildRemovedItem);
  }

  Widget _buildRemovedItem(
      TilerEvent item, BuildContext context, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: TileWidget(item)),
    );
  }

  Widget _currentBuildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter,
          child: TileWidget(_currentList![index])),
    );
  }

  Widget _upcomingBuildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter,
          child: TileWidget(_upcomingList![index])),
    );
  }

  Widget _preceedingBuildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter,
          child: TileWidget(_preceedingList![index])),
    );
  }

  processEmptyAnimatedList(
      _AnimatedListType _animatedListType, List<TilerEvent> collection) {
    switch (_animatedListType) {
      case _AnimatedListType.current:
        this.currentAnimatedList = null;
        this._currentList = null;
        this.currentOrderedTiles = null;
        break;
      case _AnimatedListType.preceeding:
        this.preceedingAnimatedList = null;
        this._preceedingList = null;
        this.preceedingOrderedTiles = null;
        break;
      case _AnimatedListType.upcoming:
        this.upcomingAnimatedList = null;
        this._upcomingList = null;
        this.upcomingOrderedTiles = null;
        break;
      default:
    }
  }

  evaluatePopulatedTileDelta(
      _AnimatedListType _animatedListType, Iterable<TilerEvent>? tiles) {
    Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles;
    switch (_animatedListType) {
      case _AnimatedListType.current:
        if (this.currentOrderedTiles == null) {
          this.currentOrderedTiles = {};
        }
        timeSectionTiles = this.currentOrderedTiles;
        break;
      case _AnimatedListType.preceeding:
        if (this.preceedingOrderedTiles == null) {
          this.preceedingOrderedTiles = {};
        }
        timeSectionTiles = this.preceedingOrderedTiles;
        break;
      case _AnimatedListType.upcoming:
        if (this.upcomingOrderedTiles == null) {
          this.upcomingOrderedTiles = {};
        }
        timeSectionTiles = this.upcomingOrderedTiles;
        break;
      default:
    }

    if (tiles == null) {
      tiles = <TilerEvent>[];
    }
    List<TilerEvent> orderedByTimeTiles = tiles.toList();
    orderedByTimeTiles
        .sort((tileA, tileB) => tileA.start!.compareTo(tileB.start!));

    Map<String, TilerEvent> allFoundTiles = {};

    for (var eachTile in timeSectionTiles!.values) {
      allFoundTiles[eachTile.item1.id!] = eachTile.item1;
    }
    Set.from(timeSectionTiles.values.map<TilerEvent>((e) => e.item1));

    for (int i = 0; i < orderedByTimeTiles.length; i++) {
      TilerEvent eachTile = orderedByTimeTiles[i];
      int? currentIndexPosition;
      if (timeSectionTiles.containsKey(eachTile.id)) {
        currentIndexPosition = timeSectionTiles[eachTile.id!]!.item2;
      }
      timeSectionTiles[eachTile.id!] =
          Tuple3(eachTile, currentIndexPosition, i);
      allFoundTiles.remove(eachTile.id);
    }

    for (TilerEvent eachTile in allFoundTiles.values) {
      timeSectionTiles[eachTile.id!] =
          Tuple3(eachTile, timeSectionTiles[eachTile.id!]!.item2, null);
    }
  }

  processPopulatedAnimatedList(
      _AnimatedListType _animatedListType, List<TilerEvent> collection) {
    switch (_animatedListType) {
      case _AnimatedListType.current:
        evaluatePopulatedTileDelta(_AnimatedListType.current, collection);
        if (this.currentAnimatedList == null) {
          var initialItems = this
              .currentOrderedTiles!
              .values
              .where((element) => element.item3 != null)
              .toList();
          if (!this.isInitialLoad) {
            initialItems = [];
          }
          this._currentList = ListModel<TilerEvent>(
            listKey: this._currentListKey,
            initialItems: initialItems.map<TilerEvent>((e) => e.item1),
            removedItemBuilder: _buildRemovedItem,
          );
          this.currentAnimatedList = AnimatedList(
            shrinkWrap: true,
            itemBuilder: _currentBuildItem,
            key: this._currentListKey,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: initialItems.length,
          );
        }
        break;
      case _AnimatedListType.preceeding:
        evaluatePopulatedTileDelta(_AnimatedListType.preceeding, collection);
        if (this.preceedingAnimatedList == null) {
          var initialItems = this
              .preceedingOrderedTiles!
              .values
              .where((element) => element.item3 != null)
              .toList();
          if (!this.isInitialLoad) {
            initialItems = [];
          }
          this._preceedingList = ListModel<TilerEvent>(
            listKey: this._preceedingListKey,
            initialItems: initialItems.map<TilerEvent>((e) => e.item1),
            removedItemBuilder: _buildRemovedItem,
          );
          this.preceedingAnimatedList = AnimatedList(
            shrinkWrap: true,
            itemBuilder: _preceedingBuildItem,
            key: this._preceedingListKey,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: initialItems.length,
          );
        }
        break;
      case _AnimatedListType.upcoming:
        evaluatePopulatedTileDelta(_AnimatedListType.upcoming, collection);
        if (this.upcomingAnimatedList == null) {
          var initialItems = this
              .upcomingOrderedTiles!
              .values
              .where((element) => element.item3 != null)
              .toList();
          if (!this.isInitialLoad) {
            initialItems = [];
          }
          this._upcomingList = ListModel<TilerEvent>(
            listKey: this._upcomingListKey,
            initialItems: initialItems.map<TilerEvent>((e) => e.item1),
            removedItemBuilder: _buildRemovedItem,
          );
          this.upcomingAnimatedList = AnimatedList(
            shrinkWrap: true,
            itemBuilder: _upcomingBuildItem,
            key: this._upcomingListKey,
            physics: const NeverScrollableScrollPhysics(),
            initialItemCount: initialItems.length,
          );
        }
        break;
      default:
    }
  }

  processAnimatedList(
      _AnimatedListType _animatedListType, List<TilerEvent> collection) {
    Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles;
    if (collection.isEmpty) {
      processEmptyAnimatedList(_animatedListType, collection);
    } else {
      processPopulatedAnimatedList(_animatedListType, collection);
    }
  }

  @override
  Widget build(BuildContext context) {
    latestBuildTiles = {};
    renderedTiles = this.pendingRenderedTiles ?? {};
    if (widget.tiles != null) {
      widget.tiles!.forEach((eachTile) {
        if (eachTile.id != null) {
          latestBuildTiles[eachTile.id!] = eachTile;
        }
      });
    }

    if (pendingRenderedTiles == null) {
      renderedTiles = latestBuildTiles;
    }

    List<Widget> children = [];
    if (dayData != null) {
      this.dayData!.nonViableTiles = renderedTiles.values
          .where(
              (eachTile) => !((eachTile as SubCalendarEvent).isViable ?? true))
          .toList();
      childrenColumnWidgets.add(Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
          child: DaySummary(dayData: this.dayData!)));
    }

    children.add(Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 61),
        child: DaySummary(dayData: this.dayData ?? DayData())));
    int currentTimeInMs = Utility.currentTime().millisecondsSinceEpoch;
    List<TilerEvent> precedingTiles = [];
    List<Widget> precedingTileWidgets = [];
    List<TilerEvent> currentTiles = [];
    List<Widget> currentTileWidgets = [];
    List<TilerEvent> upcomningTiles = [];
    List<Widget> upcomningTileWidgets = [];

    if (this.widget.sleepTimeline != null) {
      Timeline sleepTimeline = this.widget.sleepTimeline!;
      Widget sleepWidget = SleepTileWidget(sleepTimeline);
      children.add(sleepWidget);
    }

    if (renderedTiles.length > 0) {
      renderedTiles.values.forEach((eachTile) {
        if (eachTile.end != null && eachTile.start != null) {
          if (eachTile.end!.toInt() < currentTimeInMs) {
            precedingTiles.add(eachTile);
          }

          if (eachTile.end!.toInt() > currentTimeInMs &&
              eachTile.start!.toInt() <= currentTimeInMs) {
            currentTiles.add(eachTile);
          }

          if (eachTile.start!.toInt() > currentTimeInMs) {
            upcomningTiles.add(eachTile);
          }
        }
      });
    }
    processAnimatedList(_AnimatedListType.preceeding, precedingTiles);
    processAnimatedList(_AnimatedListType.current, currentTiles);
    processAnimatedList(_AnimatedListType.upcoming, upcomningTiles);

    if (currentTiles.length > 0) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!, style: TileBatch.dayHeaderTextStyle),
      );
      if (this.currentAnimatedList != null) {
        currentTileWidgets.add(this.currentAnimatedList!);
      }
      currentTileWidgets.add(headerContainer);
    }

    if (widget.header != null && precedingTiles.length > 0) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!, style: TileBatch.dayHeaderTextStyle),
      );
      if (this.preceedingAnimatedList != null) {
        precedingTileWidgets.add(this.preceedingAnimatedList!);
      }
      precedingTileWidgets.add(headerContainer);
    }

    if (widget.footer != null && upcomningTiles.length > 0) {
      Container footerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 40, 0, 20),
        alignment: Alignment.centerLeft,
        child: Text(widget.footer!, style: TileBatch.dayHeaderTextStyle),
      );
      if (this.upcomingAnimatedList != null) {
        upcomningTileWidgets.add(this.upcomingAnimatedList!);
      }
      upcomningTileWidgets.insert(0, footerContainer);
    }
    Widget scrollableItems = Container(
      height: MediaQuery.of(context).size.height - 200,
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 200),
      child: ListView(
        children: [
          ...precedingTileWidgets,
          ...currentTileWidgets,
          ...upcomningTileWidgets
        ],
      ),
    );

    children.add(scrollableItems);
    bool initialLoad = this.isInitialLoad;
    bool beforeProcessingPendingRenderingFlag = this._pendingRendering;
    handleAddOrRemovalOfTimeSectionTiles(
        this.preceedingOrderedTiles,
        this._preceedingList,
        initialLoad,
        beforeProcessingPendingRenderingFlag);
    handleAddOrRemovalOfTimeSectionTiles(this.currentOrderedTiles,
        this._currentList, initialLoad, beforeProcessingPendingRenderingFlag);
    handleAddOrRemovalOfTimeSectionTiles(this.upcomingOrderedTiles,
        this._upcomingList, initialLoad, beforeProcessingPendingRenderingFlag);
    if (!beforeProcessingPendingRenderingFlag && this._pendingRendering) {
      this.pendingRenderedTiles = Map.from(this.renderedTiles);
    }

    if (!this._pendingRendering && this.pendingRenderedTiles != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            this.pendingRenderedTiles = null;
          });
        }
      });
    }
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 300),
      child: Column(
        children: children,
      ),
    );
  }

  handleAddOrRemovalOfTimeSectionTiles(
      Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles,
      ListModel<TilerEvent>? _timeSectionListModel,
      bool isInitialLoadFlag,
      bool pendingRendering) {
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    // if (this.mounted)
    {
      if (timeSectionTiles != null && !pendingRendering) {
        List<Tuple3<TilerEvent, int?, int?>> changeDetectedTilerEvent =
            timeSectionTiles.values
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
          if (!isInitialLoadFlag) {
            if (eachTileTuple.item2 != null) {
              reorderedTiles.add(eachTileTuple);
            } else {
              insertedTiles.add(eachTileTuple);
            }
          }
        }

        if (changeDetectedTilerEvent.length == 0) {
          List<TilerEvent> orderedTilerEvent = Utility.orderTiles(
              timeSectionTiles.values.map<TilerEvent>((e) => e.item1).toList());
          for (int i = 0; i < orderedTilerEvent.length; i++) {
            if (!_timeSectionListModel![i]
                .isStartAndEndEqual(orderedTilerEvent[i])) {
              print('withinNow 0 removeAndUpdate');
              _timeSectionListModel.removeAndUpdate(i, i, orderedTilerEvent[i],
                  animate: false);
            }
          }
        }

        List<String> listIds =
            _timeSectionListModel!.toList().map<String>((e) => e.id!).toList();
        for (var removedTile in removedTiles) {
          listIds =
              _timeSectionListModel.toList().map<String>((e) => e.id!).toList();
          int toBeRemovedIndex = listIds.indexOf(removedTile.item1.id!);
          if (toBeRemovedIndex != removedTile.item3) {
            if (toBeRemovedIndex >= 0) {
              _timeSectionListModel.removeAt(toBeRemovedIndex);
            }
          }
        }

        for (var removedTile in removedTiles) {
          timeSectionTiles.remove(removedTile.item1.id);
        }

        Utility.isWithinNowSet = false;
        if (insertedTiles.isNotEmpty || reorderedTiles.isNotEmpty) {
          this._pendingRendering = true;
          Timer(Duration(milliseconds: 500), () {
            Utility.isWithinNowSet = true;
            for (var insertedTile in insertedTiles) {
              print('withinNow insert');
              _timeSectionListModel.insert(
                insertedTile.item3!,
                insertedTile.item1,
              );
            }

            for (var reorderedTile in reorderedTiles) {
              listIds = _timeSectionListModel
                  .toList()
                  .map<String>((e) => e.id!)
                  .toList();
              int toMovedIndex = listIds.indexOf(reorderedTile.item1.id!);
              if (toMovedIndex != -1) {
                print('withinNow 1 removeAndUpdate');
                _timeSectionListModel.removeAndUpdate(
                    toMovedIndex, reorderedTile.item3!, reorderedTile.item1,
                    animate: toMovedIndex != reorderedTile.item3);
              }
            }
            this._pendingRendering = false;
          });
        }

        // if (timeSectionTiles.isEmpty) {
        //   this.widget.tiles = [];
        //   setState(() {
        //     this.renderedTiles = {};
        //   });
        // }
      }

      if (isInitialLoadFlag && !pendingRendering) {
        this.isInitialLoad = false;
      }
      if (timeSectionTiles != null) {
        List finalOrederedTileValues = timeSectionTiles.values.toList();
        for (var eachTileTupleData in finalOrederedTileValues) {
          timeSectionTiles[eachTileTupleData.item1.id!] = Tuple3(
              eachTileTupleData.item1,
              eachTileTupleData.item3,
              eachTileTupleData.item3);
        }
      }
    }
    // });
  }
}
