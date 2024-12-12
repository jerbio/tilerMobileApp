import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/weeklyDetailsTile.dart';
import 'package:tiler_app/components/tileUI/weeklyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class WeeklyTileBatch extends TileBatch {
  WeeklyTileBatch({
    List<TilerEvent>? tiles,
    int? dayIndex,
    Key? key,
  }) : super(
    tiles: tiles,
    dayIndex: dayIndex,
    key: key,
  );

  @override
  WeeklyTileBatchState createState() => WeeklyTileBatchState();
}

class WeeklyTileBatchState extends TileBatchState {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late ListModel<TilerEvent>? _list;
  bool _pendingRendering = false;

  @override
  void initState() {
    super.initState();
    _list = ListModel(listKey: _listKey, removedItemBuilder: _buildRemovedItem);
  }


  Widget _buildRemovedItem(
      TilerEvent item, BuildContext context, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(alignment: Alignment.topCenter, child: WeeklyTileWidget(subEvent: item)),
    );
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter, child: WeeklyTileWidget(subEvent: _list![index],onTap: () {
        if(_list![index].name == null || _list![index].name!.isEmpty) return;
        _showBottomSheet(context, _list![index]);
      },)),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = (screenWidth-10)/7;
    renderedTiles.clear();
    if (widget.tiles != null) {
      for (var tile in widget.tiles!) {
        if (tile.id != null && ((tile as SubCalendarEvent?)?.isViable ?? true)) {
          renderedTiles[tile.uniqueId] = tile;
        }
      }
    }

    evaluateTileDelta(renderedTiles.values);
    late Widget dayContent;
    if (renderedTiles.isNotEmpty) {
      if (animatedList == null || pendingRenderedTiles == null) {
        bool onlyNewEntriesPopulated = isAllNewEntries(orderedTiles!);
        var initialItems = orderedTiles!.values.where((element) {
          return onlyNewEntriesPopulated ? element.item3 != null : element.item2 != null;
        }).toList();

        initialItems.sort((tupleA, tupleB) {
          if (tupleA.item1.start == tupleB.item1.start) {
            if (tupleA.item1.end == tupleB.item1.end!) {
              return tupleA.item1.uniqueId.compareTo(tupleB.item1.uniqueId);
            }
            return tupleA.item1.end!.compareTo(tupleB.item1.end!);
          }
          return tupleA.item1.start!.compareTo(tupleB.item1.start!);
        });

        animatedList = AnimatedList(
          shrinkWrap: true,
          itemBuilder: _buildItem,
          key: _listKey,
          physics: const NeverScrollableScrollPhysics(),
          initialItemCount: initialItems.length,
        );

        _list = ListModel<TilerEvent>(
          listKey: _listKey,
          initialItems: Utility.orderTiles(initialItems.map<TilerEvent>((e) => e.item1).toList()),
          removedItemBuilder: _buildRemovedItem,
        );
      }
      dayContent = Container(
        width: calculatedWidth,
        child: Column(
          children: [
            animatedList!
          ],
        ),
      );
    } else {
      dayContent = SizedBox(width: calculatedWidth);
    }



    bool beforeProcessingPendingRenderingFlag = _pendingRendering;

    if (pendingRenderedTiles == null) {
      handleAddOrRemovalOfTimeSectionTiles(
          orderedTiles, _list, beforeProcessingPendingRenderingFlag);
      if (!beforeProcessingPendingRenderingFlag && _pendingRendering) {
        pendingRenderedTiles = Map.from(renderedTiles);
      }
    }

    if (!_pendingRendering && pendingRenderedTiles != null) {
      Timer(Duration(milliseconds: 1000), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              pendingRenderedTiles = null;
            });
          }
        });
      });
    }

    return dayContent;
  }

  @override
  void handleAddOrRemovalOfTimeSectionTiles(
      Map<String, Tuple3<TilerEvent, int?, int?>>? timeSectionTiles,
      ListModel<TilerEvent>? _timeSectionListModel,
      bool pendingRendering) {
    if (timeSectionTiles != null && !pendingRendering) {
      List<Tuple3<TilerEvent, int?, int?>> changeInTilerEventOrdering =
      timeSectionTiles.values
          .where((element) => element.item2 != element.item3)
          .toList();

      bool allNewEntries = isAllNewEntries(timeSectionTiles);
      if (allNewEntries) {
        List finalOrderedTileValues = timeSectionTiles.values.toList();
        for (var eachTileTupleData in finalOrderedTileValues) {
          timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
              eachTileTupleData.item1,
              eachTileTupleData.item3,
              eachTileTupleData.item3);
        }
        return;
      }

      List<Tuple3<TilerEvent, int?, int?>> removedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> reorderedTiles = [];
      List<Tuple3<TilerEvent, int?, int?>> insertedTiles = [];

      for (var eachTileTuple in changeInTilerEventOrdering) {
        if (eachTileTuple.item3 == null && eachTileTuple.item2 != null) {
          removedTiles.add(eachTileTuple);
          continue;
        }

        if (eachTileTuple.item2 != null) {
          reorderedTiles.add(eachTileTuple);
        } else {
          insertedTiles.add(eachTileTuple);
        }
      }

      List<String> listIds = _timeSectionListModel!
          .toList()
          .map<String>((e) => e.uniqueId)
          .toList();
      for (var removedTile in removedTiles) {
        listIds = _timeSectionListModel
            .toList()
            .map<String>((e) => e.uniqueId)
            .toList();
        int toBeRemovedIndex = listIds.indexOf(removedTile.item1.uniqueId);
        if (toBeRemovedIndex != removedTile.item3) {
          if (toBeRemovedIndex >= 0) {
            _timeSectionListModel.removeAt(toBeRemovedIndex);
          }
        }
      }

      for (var removedTile in removedTiles) {
        timeSectionTiles.remove(removedTile.item1.uniqueId);
      }

      if (insertedTiles.isNotEmpty || reorderedTiles.isNotEmpty) {
        _pendingRendering = true;
        Timer(Duration(milliseconds: 500), () {
          for (var insertedTile in insertedTiles) {
            _timeSectionListModel.insert(
              insertedTile.item3!,
              insertedTile.item1,
            );
          }

          for (var reorderedTile in reorderedTiles) {
            listIds = _timeSectionListModel
                .toList()
                .map<String>((e) => e.uniqueId)
                .toList();
            int toMovedIndex = listIds.indexOf(reorderedTile.item1.uniqueId);
            if (toMovedIndex != -1) {
              _timeSectionListModel.removeAndUpdate(
                  toMovedIndex, reorderedTile.item3!, reorderedTile.item1,
                  animate: toMovedIndex != reorderedTile.item3);
            }
          }
          if (mounted) {
            setState(() {
              _pendingRendering = false;
            });
          }
        });
      }
    }

    if (timeSectionTiles != null) {
      List finalOrderedTileValues = timeSectionTiles.values.toList();
      for (var eachTileTupleData in finalOrderedTileValues) {
        timeSectionTiles[eachTileTupleData.item1.uniqueId] = Tuple3(
            eachTileTupleData.item1,
            eachTileTupleData.item3,
            eachTileTupleData.item3);
      }
    }
  }

  void _showBottomSheet(BuildContext context, TilerEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TileStyles.borderRadius)),
      ),
      builder: (BuildContext context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: WeeklyDetailsTile(event as SubCalendarEvent),
            ),
          ),
        );
      },
    );
  }
}