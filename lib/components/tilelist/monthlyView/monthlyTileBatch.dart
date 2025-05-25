import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/listModel.dart';
import 'package:tiler_app/components/tileUI/monthlyDailyTile.dart';
import 'package:tiler_app/components/tileUI/monthlyTile.dart';
import 'package:tiler_app/components/tilelist/DailyView/tileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class MonthlyTileBatch extends TileBatch {
  MonthlyTileBatch({
    List<TilerEvent>? tiles,
    int? dayIndex,
    Key? key,
  }) : super(
          tiles: tiles,
          dayIndex: dayIndex,
          key: key,
        );

  @override
  TileBatchState createState() => MonthlyTileBatchState();
}

class MonthlyTileBatchState extends TileBatchState {
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
      child: Align(
          alignment: Alignment.topCenter,
          child: MonthlyTileWidget(subEvent: item)),
    );
  }

  Widget _buildItem(
      BuildContext context, int index, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: Align(
          alignment: Alignment.topCenter,
          child: MonthlyTileWidget(
            subEvent: _list![index],
          )),
    );
  }

  double calculateListHeight(List<dynamic> initialItems) {
    double totalHeight = 0.0;
    for (var item in initialItems) {
      if (item is Tuple3<TilerEvent, int?, int?>) {
        TilerEvent tile = item.item1;
        int nameLength = tile.name?.length ?? 0;
        if (nameLength <= 6) {
          totalHeight += 32;
        } else {
          int rows = (nameLength / 6).ceil();
          totalHeight += rows * 32;
        }
      }
    }
    return totalHeight;
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = (screenWidth - 10) / 7 - 4;
    renderedTiles.clear();
    var initialItems = [];
    if (widget.tiles != null) {
      for (var tile in widget.tiles!) {
        if (tile.id != null &&
            ((tile as SubCalendarEvent?)?.isViable ?? true)) {
          renderedTiles[tile.uniqueId] = tile;
        }
      }
    }

    evaluateTileDelta(renderedTiles.values);

    late Widget dayContent;
    if (animatedList == null || pendingRenderedTiles == null) {
      bool onlyNewEntriesPopulated = isAllNewEntries(orderedTiles!);
      initialItems = orderedTiles!.values.where((element) {
        return onlyNewEntriesPopulated
            ? element.item3 != null
            : element.item2 != null;
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
        itemBuilder: (context, index, animation) {
          if (index < 7) return _buildItem(context, index, animation);
          if (index == 7 && initialItems.length > 7) {
            return SizeTransition(
              sizeFactor: animation,
              child: Padding(
                padding: const EdgeInsets.only(left: 2.0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Text('•••', style: TextStyle(fontSize: 12)),
                ),
              ),
            );
          }
          return SizedBox.shrink();
        },
        key: _listKey,
        physics: const NeverScrollableScrollPhysics(),
        initialItemCount: initialItems.length > 7 ? 8 : initialItems.length,
      );

      _list = ListModel<TilerEvent>(
        listKey: _listKey,
        initialItems: Utility.orderTiles(
            initialItems.map<TilerEvent>((e) => e.item1).take(7).toList()),
        removedItemBuilder: _buildRemovedItem,
      );
    }
    int todayDayIndex = Utility.getDayIndex(Utility.currentTime());
    dayContent = GestureDetector(
      onTap: () {
        if (_list!.toList().length > 0) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(TileStyles.borderRadius)),
            ),
            builder: (BuildContext context) {
              return Container(
                margin: EdgeInsets.symmetric(vertical: 20),
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Column(children: [
                      FractionallySizedBox(
                        widthFactor: TileStyles.tileWidthRatio,
                        child: Text(
                          DateFormat('d MMM yyyy').format(
                              Utility.getTimeFromIndex(widget.dayIndex!)),
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      ..._list!.toList().map((event) {
                        return MonthlyDailyTile(event);
                      }).toList(),
                    ]),
                  ),
                ),
              );
            },
          );
        }
      },
      child: Container(
        constraints: BoxConstraints(
          maxHeight: double.infinity,
        ),
        width: calculatedWidth,
        height: 195,
        padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        margin: EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: todayDayIndex == widget.dayIndex
              ? TileColors.primaryColor
              : Color.fromRGBO(240, 240, 240, 1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                margin: EdgeInsets.only(left: 2, top: 2),
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Color.fromRGBO(220, 220, 220, 1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(Utility.getDayOfMonthFromIndex(widget.dayIndex!)
                    .toString()),
              ),
            ),
            if (animatedList != null) Flexible(child: animatedList!),
          ],
        ),
      ),
    );

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
}
