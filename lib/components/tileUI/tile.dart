import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/styles.dart';

import '../../constants.dart';
import 'timeScrub.dart';

class TileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  TileWidgetState? _state;
  TileWidget(subEvent) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }
  @override
  TileWidgetState createState() {
    _state = TileWidgetState();
    return _state!;
  }

  Future<TileWidgetState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<TileWidgetState> retValue = new Future.delayed(
          const Duration(milliseconds: stateRetrievalRetry), () {
        return this.state;
      });

      return retValue;
    }
  }

  void updateSubEvent(SubCalendarEvent subEvent) async {
    this.subEvent = subEvent;
    var state = await this.state;
    state.updateSubEvent(subEvent);
  }
}

class TileWidgetState extends State<TileWidget> {
  void updateSubEvent(SubCalendarEvent subEvent) async {
    this.widget.subEvent = subEvent;
  }

  @override
  Widget build(BuildContext context) {
    var subEvent = widget.subEvent;
    int redColor =
        subEvent.colorRed == null ? Random().nextInt(255) : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null
        ? Random().nextInt(255)
        : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null
        ? Random().nextInt(255)
        : subEvent.colorGreen!;
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
        child: TimeScrubWidget(widget.subEvent)));

    allElements.add(Container(
        margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: PlayBack(widget.subEvent)));

    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Material(
          type: MaterialType.transparency,
          child: Container(
            width: TileStyles.tileWidth,
            height: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: Colors.white,
                width: 5,
              ),
              borderRadius: BorderRadius.circular(TileStyles.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 10,
                  blurRadius: 20,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Container(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                decoration: BoxDecoration(
                  color: tileBackGroundColor,
                  border: Border.all(
                    color: Colors.white,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(TileStyles.borderRadius),
                ),
                child: Column(
                  children: allElements,
                )),
          )),
    );
  }
}
