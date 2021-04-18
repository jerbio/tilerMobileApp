import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tilelist/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tilelist/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tilelist/tileUI/tileName.dart';
import 'package:tiler_app/components/tilelist/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';

import 'timeline.dart';

class Tile extends StatefulWidget {
  SubCalendarEvent subEvent;
  Tile(this.subEvent) {
    assert(this.subEvent != null);
  }
  @override
  TileState createState() => TileState();
}

class TileState extends State<Tile> {
  @override
  Widget build(BuildContext context) {
    var subEvent = widget.subEvent;
    int redColor = subEvent.colorRed == null ? 125 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 125 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 125 : subEvent.colorGreen!;
    var tileBackGroundColor =
        Color.fromRGBO(redColor, greenColor, blueColor, 0.2);

    var allElements = [
      Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: TileName(widget.subEvent),
      ),
      Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TileAddress(widget.subEvent)),
      Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TravelTimeBefore(widget.subEvent)),
    ];

    var currentTime = Utility.currentTime();
    // if (widget.subEvent.isCurrent) {

    // }

    allElements.add(Container(
        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
        child: Timeline(widget.subEvent)));

    allElements.add(Container(
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: PlayBack(widget.subEvent)));

    return Align(
      alignment: Alignment.topLeft,
      child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: 350,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                decoration: BoxDecoration(
                  color: tileBackGroundColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: allElements,
                )),
          )),
    );
  }
}
