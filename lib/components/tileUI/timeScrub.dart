import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class TimeScrubWidget extends StatefulWidget {
  late TimeRange timeline;
  bool loadTimeScrub = false;
  bool isTardy = true;
  TimeScrubWidget(
      {required this.timeline,
      this.loadTimeScrub = false,
      this.isTardy = false}) {
    assert(this.timeline != null);
  }
  @override
  TimeScrubWidgetState createState() => TimeScrubWidgetState();
}

class TimeScrubWidgetState extends State<TimeScrubWidget> {
  final double maxWidthOfTimeline = 280;
  final double diameterOfBall = 10;
  final DateFormat formatter = DateFormat.jm();

  @override
  Widget build(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    bool isToday = widget.timeline.isInterfering(Utility.todayTimeline());
    var currentTimeInMs = Utility.currentTime().millisecondsSinceEpoch;
    double widthOfUsedUpDuration = 0;
    Widget timeline;
    if (widget.timeline.start != null && widget.timeline.end != null) {
      double start = widget.timeline.start!;
      double end = widget.timeline.end!;
      bool isInterferring = widget.timeline.isInterfering(new Timeline(
          currentTimeInMs.toDouble(), (currentTimeInMs + 10).toDouble()));
      if (this.widget.loadTimeScrub || isInterferring) {
        double subEventDuratonInMs = end - start;
        double durationInMs = currentTimeInMs - start;
        double evaluatedPosition = ((durationInMs / subEventDuratonInMs) *
            (maxWidthOfTimeline - diameterOfBall));
        widthOfUsedUpDuration =
            (durationInMs / subEventDuratonInMs) * maxWidthOfTimeline;

        int colorRed = 255;
        //widget.subEvent.colorRed ?? 0;
        int colorGreen = 255;
        //widget.subEvent.colorGreen ?? 0;
        int colorBlue = 255;
        //widget.subEvent.colorBlue ?? 0;
        String startString = formatter
            .format(DateTime.fromMillisecondsSinceEpoch(start.toInt()));
        String endString =
            formatter.format(DateTime.fromMillisecondsSinceEpoch(end.toInt()));

        var backgroundShade = Container(
          width: maxWidthOfTimeline,
          height: 5,
          margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
            color: this.widget.loadTimeScrub
                ? Colors.white
                : Color.fromRGBO(105, 105, 105, 0.2),
          ),
        ); //background shade
        var scrubberElements = [backgroundShade];

        if (isInterferring) {
          var usedUpTimeWidget = Container(
            width: widthOfUsedUpDuration,
            height: 5,
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: Colors.greenAccent,
            ),
          ); //Used up time

          var movingBallWidget = Container(
            width: diameterOfBall,
            height: diameterOfBall,
            margin: new EdgeInsets.fromLTRB(evaluatedPosition, 0, 0, 0),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                color: Color.fromRGBO(colorRed, colorGreen, colorBlue, 1),
                boxShadow: [
                  BoxShadow(
                      color: Color.fromRGBO(150, 150, 150, 0.9),
                      blurRadius: 2,
                      spreadRadius: 2),
                ]),
          ); // moving ball
          scrubberElements.add(usedUpTimeWidget);
          scrubberElements.add(movingBallWidget);
        }
        timeline = Align(
            alignment: Alignment.center,
            child: Column(children: [
              Stack(
                children: scrubberElements,
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
                        style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Rubik',
                            color: this.widget.loadTimeScrub
                                ? Colors.white
                                : Colors.black),
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
                            style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'Rubik',
                                color: this.widget.loadTimeScrub
                                    ? Colors.white
                                    : Colors.black),
                          )))
                ],
              )
            ]));
      } else {
        String? timeFrameString = MaterialLocalizations.of(context)
                .formatTimeOfDay(TimeOfDay.fromDateTime(
                    DateTime.fromMillisecondsSinceEpoch(
                        widget.timeline.start!.toInt()))) +
            ' - ' +
            MaterialLocalizations.of(context).formatTimeOfDay(
                TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(
                    widget.timeline.end!.toInt())));
        timeline = Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              this.widget.isTardy
                  ? Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: Color.fromRGBO(31, 31, 31, 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        Icons.access_time_sharp,
                        color: this.widget.isTardy
                            ? Colors.pink
                            : Color.fromRGBO(0, 0, 0, 1),
                        size: 20.0,
                      ),
                    )
                  : Container(),
              Text(
                timeFrameString,
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.normal,
                    color: this.widget.isTardy
                        ? Colors.pink
                        : Color.fromRGBO(31, 31, 31, 1)),
              )
            ],
          ),
        );
        if (isToday) {
          if (widget.timeline.hasElapsed) {
            int durationInMs = Utility.msCurrentTime - end.toInt();
            Duration durationToStart = Duration(milliseconds: durationInMs);
            String elapsedTime = Utility.toHuman(durationToStart);

            timeline = Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.check_circle_outline_outlined),
                  Text(
                    'Elpased $elapsedTime ago',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
                  )
                ],
              ),
            );
          } else {
            int durationInMs = start.toInt() - Utility.msCurrentTime as int;
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
        }
      }
    } else {
      throw ("Invalid subEvent sent, check the start and end time aren't null");
    }

    return Container(
      width: 300,
      height: 30,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: timeline,
    );
  }
}
