import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/tileDate.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
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
  bool isMoreDetailEnabled = false;
  void updateSubEvent(SubCalendarEvent subEvent) async {
    this.widget.subEvent = subEvent;
  }

  @override
  Widget build(BuildContext context) {
    var subEvent = widget.subEvent;
    int redColor = subEvent.colorRed == null ? 127 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 127 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 127 : subEvent.colorGreen!;
    var tileBackGroundColor =
        Color.fromRGBO(redColor, greenColor, blueColor, 0.2);

    List<Widget> allElements = [
      Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: TileName(widget.subEvent),
      )
    ];

    if (this.widget.subEvent.travelTimeBefore != null &&
        this.widget.subEvent.travelTimeBefore! > 0) {
      allElements.add(Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TravelTimeBefore(
              this.widget.subEvent.travelTimeBefore?.toInt() ?? 0, subEvent)));
    }

    if (widget.subEvent.address != null &&
        widget.subEvent.address!.isNotEmpty) {
      var adrressWidget = Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: TileAddress(widget.subEvent));
      allElements.insert(1, adrressWidget);
    }
    allElements.add(TileDate(
      date: widget.subEvent.startTime!,
    ));

    bool isTardy = this.widget.subEvent.isTardy ?? false;
    Widget tileTimeFrame = Container(
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              Icons.access_time_sharp,
              color: isTardy ? Colors.pink : TileStyles.defaultTextColor,
              size: 20.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: TimeFrameWidget(
              timeRange: widget.subEvent,
              textColor: isTardy ? Colors.pink : TileStyles.defaultTextColor,
            ),
          ),
        ],
      ),
    );
    allElements.add(tileTimeFrame);
    if (isMoreDetailEnabled || (this.widget.subEvent.isToday)) {
      allElements.add(FractionallySizedBox(
          widthFactor: TileStyles.tileWidthRatio,
          child: Container(
              margin: const EdgeInsets.fromLTRB(0, 40, 0, 0),
              child: TimeScrubWidget(
                timeline: widget.subEvent,
                isTardy: widget.subEvent.isTardy ?? false,
              ))));
      allElements.add(Container(
          margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
          child: PlayBack(widget.subEvent)));
    } else {
      allElements.add(GestureDetector(
        onTap: () {
          setState(() {
            isMoreDetailEnabled = true;
          });
        },
        child: Center(
            child: Container(
          width: 30,
          height: 30,
          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Transform.rotate(
            angle: pi / 2,
            child: Icon(
              Icons.chevron_right,
              size: 30,
            ),
          ),
          decoration: BoxDecoration(
              color: Color.fromRGBO(31, 31, 31, .1),
              borderRadius: BorderRadius.circular(25)),
        )),
      ));
    }

    return AnimatedSize(
        duration: Duration(milliseconds: 250),
        curve: Curves.fastOutSlowIn,
        child: Container(
          margin: this.widget.subEvent.isCurrentTimeWithin
              ? EdgeInsets.fromLTRB(0, 100, 0, 100)
              : EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Material(
              type: MaterialType.transparency,
              child: FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 5,
                      ),
                      borderRadius:
                          BorderRadius.circular(TileStyles.borderRadius),
                      boxShadow: [
                        BoxShadow(
                          color: tileBackGroundColor.withOpacity(0.1),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Container(
                        padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                        decoration: BoxDecoration(
                          color: tileBackGroundColor,
                          border: Border.all(
                            color: Colors.white,
                            width: 0.5,
                          ),
                          borderRadius:
                              BorderRadius.circular(TileStyles.borderRadius),
                        ),
                        child: Column(
                          mainAxisAlignment: allElements.length < 4
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                          children: allElements,
                        )),
                  ))),
        ));
  }
}
