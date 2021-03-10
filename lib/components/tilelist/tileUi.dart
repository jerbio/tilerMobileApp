import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCakendarEvent.dart';

class Tile extends StatefulWidget {
  SubCalendarEvent subEvent;
  Tile(this.subEvent);
  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [Text(widget.subEvent.name), Text(widget.subEvent.address)],
      ),
    );
  }
}
