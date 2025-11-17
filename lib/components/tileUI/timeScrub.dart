import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


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
  late double evaluatedPosition;
  late int subEventDuratonInMs;
  late int durationInMs;
  final int _autoRefreshScrubberDelayInSecs = 20;
  late double widthOfUsedUpDuration = 0;
  late Timer refreshTimer;

  @override
  void initState() {
    int start = widget.timeline.start!;
    int end = widget.timeline.end!;
    var currentTimeInMs = Utility.msCurrentTime;
    subEventDuratonInMs = end - start;
    durationInMs = currentTimeInMs - start;
    evaluatedPosition = ((durationInMs / subEventDuratonInMs) *
        (maxWidthOfTimeline - diameterOfBall));
    widthOfUsedUpDuration =
        (durationInMs / subEventDuratonInMs) * maxWidthOfTimeline;
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (this.mounted) {
        setState(() {
          evaluatedPosition = (maxWidthOfTimeline - diameterOfBall);
          widthOfUsedUpDuration = maxWidthOfTimeline;
        });
      }
    });
    refreshTimer = Timer.periodic(
        Duration(seconds: _autoRefreshScrubberDelayInSecs), (timer) {
      setState(() {
        currentTimeInMs = Utility.msCurrentTime;
        subEventDuratonInMs = end - start;
        durationInMs = currentTimeInMs - start;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    final timelineTextStyle=TextStyle(
        fontFamily: TileTextStyles.rubikFontName,
        fontSize: 10,
        color: this.widget.loadTimeScrub
            ? TileColors.lightContent
            : colorScheme.onSurface);
    String locale = Localizations.localeOf(context).languageCode;
    bool isToday = widget.timeline.isInterfering(Utility.todayTimeline());
    var currentTimeInMs = Utility.msCurrentTime;

    Widget timeline;
    if (widget.timeline.start != null && widget.timeline.end != null) {
      int start = widget.timeline.start!;
      int end = widget.timeline.end!;
      bool isInterferring = widget.timeline.isInterfering(new Timeline(
          currentTimeInMs.toInt(), (currentTimeInMs + 10).toInt()));
      if (this.widget.loadTimeScrub || isInterferring) {
        int colorRed = 255;
        int colorGreen = 255;
        int colorBlue = 255;
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
                ? colorScheme.surfaceContainerLowest
                : tileThemeExtension!.surfaceContainerMaximum.withValues(alpha: 0.2),
          ),
        );
        var scrubberElements = <Widget>[backgroundShade];

        if (isInterferring) {
          int durationLeft = end - currentTimeInMs;
          var usedUpTimeWidget = AnimatedPositioned(
            duration: Duration(milliseconds: durationLeft.toInt()),
            width: widthOfUsedUpDuration,
            child: Container(
              height: 5,
              margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
                color: TileColors.success,
              ),
            ),
          ); //Used up time

          var movingBallWidget = AnimatedPositioned(
            duration: Duration(milliseconds: durationLeft.toInt()),
            left: evaluatedPosition,
            child: Container(
              width: diameterOfBall,
              height: diameterOfBall,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  color: Color.fromRGBO(colorRed, colorGreen, colorBlue, 1),
                  boxShadow: [
                    BoxShadow(
                        color: tileThemeExtension!.shadowTimeScrubMovingBall.withValues(alpha: 0.9),
                        blurRadius: 2,
                        spreadRadius: 2),
                  ]
              ),
            ),
          ); // moving ball
          scrubberElements.add(usedUpTimeWidget);
          scrubberElements.add(movingBallWidget);
        }
        timeline = Align(
            alignment: Alignment.center,
            child: Column(children: [
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: scrubberElements,
                ),
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
                        style: timelineTextStyle,
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
                            style: timelineTextStyle,
                          )
                      )
                  )
                ],
              )
            ]));
      } else {
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
                  AppLocalizations.of(context)!.elapsedDurationAgo(elapsedTime),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15
                  ),
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
                Icon(Icons.timelapse, color:colorScheme.onSurface),
                Text(
                  AppLocalizations.of(context)!.startsInDuration(elapsedTime),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontFamily:TileTextStyles.rubikFontName,
                  ),
                )
              ],
            ),
          );
        }
      }
    } else {
      throw ("Invalid subEvent sent, check the start and end time aren't null");
    }

    return Container(
      width: 300,
      height: 30,
      child: timeline,
    );
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    super.dispose();
  }
}
