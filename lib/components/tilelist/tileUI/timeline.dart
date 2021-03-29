import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';

class Timeline extends StatefulWidget {
  SubCalendarEvent subEvent;
  Timeline(this.subEvent);
  @override
  TimelineState createState() => TimelineState();
}

class TimelineState extends State<Timeline> {
  final double maxWidthOfTimeline = 280;
  final double diameterOfBall = 10;
  final DateFormat formatter = DateFormat.jm();

  @override
  Widget build(BuildContext context) {
    var currentTimeInMs = Utility.currentTime().millisecondsSinceEpoch;
    double widthOfUsedUpDuration = 0;
    Widget timeline;
    if (widget.subEvent.isCurrent) {
      double subEventDuratonInMs = widget.subEvent.end - widget.subEvent.start;
      double durationInMs = currentTimeInMs - widget.subEvent.start;
      double evaluatedPosition = ((durationInMs / subEventDuratonInMs) *
          (maxWidthOfTimeline - diameterOfBall));
      widthOfUsedUpDuration =
          (durationInMs / subEventDuratonInMs) * maxWidthOfTimeline;

      String startString = formatter.format(
          DateTime.fromMillisecondsSinceEpoch(widget.subEvent.start.toInt()));
      String endString = formatter.format(
          DateTime.fromMillisecondsSinceEpoch(widget.subEvent.end.toInt()));
      timeline = Align(
          alignment: Alignment.center,
          child: Column(children: [
            Stack(
              children: [
                Container(
                  width: maxWidthOfTimeline,
                  height: 5,
                  margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    color: Color.fromRGBO(105, 105, 105, 0.2),
                  ),
                ), //background shade
                Container(
                  width: widthOfUsedUpDuration,
                  height: 5,
                  margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10.0)),
                    color: Colors.greenAccent,
                  ),
                ), //Used up time
                Container(
                  width: diameterOfBall,
                  height: diameterOfBall,
                  margin: new EdgeInsets.fromLTRB(evaluatedPosition, 0, 0, 0),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      color: Color.fromRGBO(
                          widget.subEvent.colorRed,
                          widget.subEvent.colorGreen,
                          widget.subEvent.colorBlue,
                          1),
                      boxShadow: [
                        BoxShadow(
                            color: Color.fromRGBO(150, 150, 150, 0.9),
                            blurRadius: 2,
                            spreadRadius: 2),
                      ]),
                ), // moving ball
              ],
            ),
            Stack(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(10, 5, 0, 0),
                    child: Text(
                      '$startString',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, fontFamily: 'Rubik'),
                    ),
                  ),
                ),
                Align(
                    alignment: Alignment.topRight,
                    child: Container(
                        margin: EdgeInsets.fromLTRB(0, 5, 10, 0),
                        child: Text(
                          '$endString',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 10, fontFamily: 'Rubik'),
                        )))
              ],
            )
          ]));
    } else if (widget.subEvent.hasElapsed) {
      int durationInMs = Utility.msCurrentTime - widget.subEvent.end.toInt();
      Duration durationToStart = Duration(milliseconds: durationInMs);
      String elapsedTime = Utility.toHuman(durationToStart);

      timeline = Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.check_circle_outline_outlined),
            Text(
              'Completed $elapsedTime ago',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
            )
          ],
        ),
      );
    } else {
      int durationInMs = widget.subEvent.start.toInt() - Utility.msCurrentTime;
      Duration durationToStart = Duration(milliseconds: durationInMs);
      String elapsedTime = Utility.toHuman(durationToStart);
      timeline = Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(Icons.timelapse),
            Text(
              'Starts in  $elapsedTime',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
            )
          ],
        ),
      );
    }

    return Container(
      width: 300,
      height: 30,
      margin: EdgeInsets.fromLTRB(0, 5, 0, 0),
      child: timeline,
    );
  }
}
