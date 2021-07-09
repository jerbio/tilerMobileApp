import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileRemovalType.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart';
import '../../util.dart';

class TileBatch extends StatefulWidget {
  List<TilerEvent>? tiles;
  String? header;
  String? footer;
  int? dayIndex;
  TileBatchState? _state;

  TileBatch({this.header, this.footer, this.dayIndex, this.tiles, Key? key})
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
    if (!isInitialized) {
      if (widget.tiles != null) {
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

    if (tiles.length > 0) {
      tiles.values.forEach((eachTile) {
        Widget eachTileWidget = TileWidget(eachTile);
        children.add(eachTileWidget);
      });
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
