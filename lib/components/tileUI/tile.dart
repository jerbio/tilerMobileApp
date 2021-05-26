import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';

import 'timeline.dart';

class TileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  TileWidget(subEvent) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }
  @override
  TileWidgetState createState() => TileWidgetState();
}

class TileWidgetState extends State<TileWidget> {
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
          child: TravelTimeBefore(
              this.widget.subEvent.travelTimeBefore?.toInt() ?? 0, subEvent)),
    ];

    var currentTime = Utility.currentTime();

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
