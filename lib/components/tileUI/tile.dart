import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/animatedLine.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/tileDate.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/components/tileUI/travelTimeBefore.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../constants.dart';
import 'timeScrub.dart';

///
/// Class creates tile widget that handles rendering the tile UI for a given
/// user tile.
///
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
  StreamSubscription? pendingScheduleRefresh;

  @override
  void initState() {
    if (this.widget.subEvent.isCurrentTimeWithin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (this.mounted) {
          int timeLeft = this.widget.subEvent.end! - Utility.msCurrentTime;

          Future onTileExpiredCallBack = Future.delayed(
              Duration(milliseconds: timeLeft.toInt()), callScheduleRefresh);
          // ignore: cancel_subscriptions
          StreamSubscription pendingSchedule =
              onTileExpiredCallBack.asStream().listen((_) {});
          setState(() {
            pendingScheduleRefresh = pendingSchedule;
          });
        }
      });
    }
    super.initState();
  }

  void updateSubEvent(SubCalendarEvent subEvent) async {
    this.widget.subEvent = subEvent;
  }

  void callScheduleRefresh() {
    this.context.read<ScheduleBloc>().add(GetSchedule());
  }

  bool get isEditable {
    return !(this.widget.subEvent.isReadOnly ?? true);
  }

  bool get isTardy {
    return this.widget.subEvent.isTardy ?? false;
  }

  Widget renderTravelTime(Timeline travelTimeLine) {
    String lottieAsset =
        isTardy ? 'assets/lottie/redCars.json' : 'assets/lottie/blackCars.json';
    String startString = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(
            travelTimeLine.start!.toInt())));
    String endString = MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay.fromDateTime(
            DateTime.fromMillisecondsSinceEpoch(travelTimeLine.end!.toInt())));
    Color? textColor =
        isTardy ? TileStyles.lateTextColor : TileStyles.defaultTextColor;
    Widget retValue =
        Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
          padding: EdgeInsets.fromLTRB(2, 0, 0, 0),
          height: 50,
          width: 5,
          child: AnimatedLine(
            Duration(milliseconds: 0),
            textColor,
            reverse: true,
          )),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: Text(startString,
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.normal,
                      color: textColor))),
          Lottie.asset(lottieAsset, height: 85),
          Container(
              margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
              child: Text(endString,
                  style: TextStyle(
                      fontSize: 20,
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.normal,
                      color: textColor)))
        ],
      ),
      Container(
          padding: EdgeInsets.fromLTRB(2, 0, 0, 0),
          height: 50,
          width: 5,
          child: AnimatedLine(
            Duration(milliseconds: 0),
            textColor,
            reverse: true,
          )),
    ]);

    return retValue;
  }

  Widget renderTileElement() {
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
              color: isTardy
                  ? TileStyles.lateTextColor
                  : TileStyles.defaultTextColor,
              size: 20.0,
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: TimeFrameWidget(
              timeRange: widget.subEvent,
              textColor: isTardy
                  ? TileStyles.lateTextColor
                  : TileStyles.defaultTextColor,
            ),
          ),
        ],
      ),
    );
    allElements.add(tileTimeFrame);
    if (isEditable) {
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
            margin: EdgeInsets.fromLTRB(0, 20, 0, 10),
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
    }

    Widget editTileButton = GestureDetector(
      onTap: () {
        if (isEditable) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      EditTile(tileId: this.widget.subEvent.id!)));
        }
      },
      child: Center(
        child: Container(
          child: Text('...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        ),
      ),
    );

    allElements.add(editTileButton);

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
                        color: this.widget.subEvent.isViable!
                            ? Colors.white
                            : Colors.black,
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

  @override
  Widget build(BuildContext context) {
    List<Widget> columnChildren = [renderTileElement()];

    if (this.widget.subEvent.travelTimeBefore != null &&
        this.widget.subEvent.travelTimeBefore! > 0.0) {
      Duration travelDuration = Duration(
          milliseconds: this.widget.subEvent.travelTimeBefore!.toInt());
      Timeline travelTimeLine = Timeline.fromDateTimeAndDuration(
          this.widget.subEvent.startTime!.add(-travelDuration), travelDuration);
      Widget travelTimeWidget = renderTravelTime(travelTimeLine);
      columnChildren.insert(0, travelTimeWidget);
    }
    return Column(
      children: columnChildren,
    );
  }

  @override
  void dispose() {
    if (this.pendingScheduleRefresh != null) {
      this.pendingScheduleRefresh!.cancel();
    }
    super.dispose();
  }
}
