import 'package:flutter/cupertino.dart';
import 'package:tiler_app/components/tileUI/tile.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class TileBatch extends StatefulWidget {
  String? header;
  String? footer;
  @override
  TileBatchState createState() => TileBatchState();
}

class TileBatchState extends State<TileBatch> {
  List<TilerEvent> tiles = [];

  void updateSubEvents(List<TilerEvent> updatedTiles) {
    this.setState(() {
      this.tiles = updatedTiles;
    });
  }

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
