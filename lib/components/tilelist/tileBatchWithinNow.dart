import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/components/tilelist/tileBatch.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class WithinNowBatch extends TileBatch {
  TileWidget? _currentWidget;
  @override
  WithinNowBatchState createState() => WithinNowBatchState();
}

class WithinNowBatchState extends TileBatchState {
  List<TilerEvent> tiles = [];
  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    if (widget.header != null) {
      Container headerContainer = Container(
        child: Text(widget.header!),
      );
      children.add(headerContainer);
    }

    if (tiles.length > 0) {
      tiles.forEach((eachTile) {
        Widget eachTileWidget = TileWidget(eachTile);
        children.add(eachTileWidget);
      });
    }

    if (widget.footer != null) {
      Container footerContainer = Container(
        child: Text(widget.footer!),
      );
      children.add(footerContainer);
    }
    return Container(
      child: Row(
        children: children,
      ),
    );
  }
}
