import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/sleepTile.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart';

class WithinNowBatch extends TileBatch {
  TileWidget? _currentWidget;
  WithinNowBatchState? _state;

  WithinNowBatch(
      {String? header = '',
      String? footer = 'Upcoming',
      List<TilerEvent>? tiles,
      Key? key})
      : super(header: header, footer: footer, key: key, tiles: tiles);

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

class WithinNowBatchState extends TileBatchState {
  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      if (widget.tiles != null) {
        widget.tiles!.forEach((eachTile) {
          if (eachTile.id != null) {
            renderedTiles[eachTile.id!] = eachTile;
          }
        });
      }
      isInitialized = true;
    }
    List<Widget> children = [];
    int currentTimeInMs = Utility.currentTime().millisecondsSinceEpoch;
    List<Widget> precedingTileWidgets = [];
    List<Widget> currentTileWidgets = [];
    List<Widget> upcomningTileWidgets = [];

    if (this.widget.sleepTimeline != null) {
      Timeline sleepTimeline = this.widget.sleepTimeline!;
      Widget sleepWidget = SleepTileWidget(sleepTimeline);
      children.add(sleepWidget);
    }

    if (renderedTiles.length > 0) {
      renderedTiles.values.forEach((eachTile) {
        Widget eachTileWidget = TileWidget(eachTile);
        if (eachTile.end != null && eachTile.start != null) {
          if (eachTile.end!.toInt() < currentTimeInMs) {
            precedingTileWidgets.add(eachTileWidget);
          }

          if (eachTile.end!.toInt() > currentTimeInMs &&
              eachTile.start!.toInt() <= currentTimeInMs) {
            currentTileWidgets.add(eachTileWidget);
          }

          if (eachTile.start!.toInt() > currentTimeInMs) {
            upcomningTileWidgets.add(eachTileWidget);
          }
        }
      });
    }

    if (widget.header != null && precedingTileWidgets.length > 0) {
      Container headerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 20, 0, 40),
        alignment: Alignment.centerLeft,
        child: Text(widget.header!, style: TileBatch.dayHeaderTextStyle),
      );
      precedingTileWidgets.add(headerContainer);
    }

    if (widget.footer != null && upcomningTileWidgets.length > 0) {
      Container footerContainer = Container(
        margin: EdgeInsets.fromLTRB(30, 40, 0, 20),
        alignment: Alignment.centerLeft,
        child: Text(widget.footer!, style: TileBatch.dayHeaderTextStyle),
      );
      upcomningTileWidgets.insert(0, footerContainer);
    }
    children.addAll(precedingTileWidgets);
    children.addAll(currentTileWidgets);
    children.addAll(upcomningTileWidgets);
    return Container(
      child: Column(
        children: children,
      ),
    );
  }
}
