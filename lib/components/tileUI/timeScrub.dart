import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/tileUI/timeScrubGeometry.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import 'package:tiler_app/util.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

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

class TimeScrubWidgetState extends State<TimeScrubWidget>
    with SingleTickerProviderStateMixin {
  /// Fallback track width used when the parent gives us an unbounded width.
  final double fallbackTrackWidth = 280;
  final double diameterOfBall = 10;
  final DateFormat formatter = DateFormat.jm();
  final int _autoRefreshScrubberDelayInSecs = 20;

  /// Flips true after the first frame so the ball/fill glide toward the end of
  /// the occurrence over the remaining time (smooth, proportional motion).
  bool _animateToEnd = false;

  late Timer refreshTimer;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (this.mounted) {
        setState(() {
          _animateToEnd = true;
        });
      }
    });
    refreshTimer = Timer.periodic(
        Duration(seconds: _autoRefreshScrubberDelayInSecs), (timer) {
      if (this.mounted) {
        setState(() {});
      }
    });
  }

  /// Derives the usable track width from the parent constraints, keeping a
  /// little slack for the start/end labels and falling back to a fixed width
  /// when the parent is unbounded (e.g. inside an unconstrained Row).
  double _trackWidthFor(BoxConstraints constraints) {
    if (constraints.maxWidth.isFinite) {
      return (constraints.maxWidth - 20).clamp(120.0, 600.0);
    }
    return fallbackTrackWidth;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>();
    final timelineTextStyle = TextStyle(
        fontFamily: TileTextStyles.rubikFontName,
        fontSize: 10,
        color: this.widget.loadTimeScrub
            ? TileColors.lightContent
            : colorScheme.onSurface);

    if (widget.timeline.start == null || widget.timeline.end == null) {
      throw ("Invalid subEvent sent, check the start and end time aren't null");
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double outerWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final double trackWidth = _trackWidthFor(constraints);

        final int start = widget.timeline.start!;
        final int end = widget.timeline.end!;
        final int currentTimeInMs = Utility.msCurrentTime;
        final bool isInterferring = widget.timeline.isInterfering(new Timeline(
            currentTimeInMs.toInt(), (currentTimeInMs + 10).toInt()));

        Widget timeline;
        if (this.widget.loadTimeScrub || isInterferring) {
          const int colorRed = 255;
          const int colorGreen = 255;
          const int colorBlue = 255;
          final String startString = formatter
              .format(DateTime.fromMillisecondsSinceEpoch(start.toInt()));
          final String endString = formatter
              .format(DateTime.fromMillisecondsSinceEpoch(end.toInt()));

          final backgroundShade = Container(
            width: trackWidth,
            height: 5,
            margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10.0)),
              color: this.widget.loadTimeScrub
                  ? colorScheme.surfaceContainerLowest
                  : tileThemeExtension!.surfaceContainerMaximum
                      .withValues(alpha: 0.2),
            ),
          );
          final scrubberElements = <Widget>[backgroundShade];

          if (isInterferring) {
            // Both endpoints are derived from the SAME geometry/track so the
            // fill edge and the ball stay aligned. The current geometry is the
            // starting point; we glide to the end geometry over the remaining
            // time, keeping motion smooth and proportional at every instant.
            final nowGeo = TimeScrubGeometry(
                startMs: start, endMs: end, nowMs: currentTimeInMs);
            final endGeo =
                TimeScrubGeometry(startMs: start, endMs: end, nowMs: end);
            final TimeScrubGeometry activeGeo = _animateToEnd ? endGeo : nowGeo;

            final double fillW =
                activeGeo.fillWidth(trackWidth, diameterOfBall);
            final double ballL = activeGeo.ballLeft(trackWidth, diameterOfBall);

            final int durationLeft =
                (end - currentTimeInMs).clamp(0, 1 << 31).toInt();
            final Duration animDuration = _animateToEnd
                ? Duration(milliseconds: durationLeft)
                : Duration.zero;

            final usedUpTimeWidget = AnimatedPositioned(
              duration: animDuration,
              left: 0,
              width: fillW,
              child: Container(
                height: 5,
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  color: TileColors.success,
                ),
              ),
            ); // Used up time

            final ball = Container(
              width: diameterOfBall,
              height: diameterOfBall,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                  color: Color.fromRGBO(colorRed, colorGreen, colorBlue, 1),
                  boxShadow: [
                    BoxShadow(
                        color: tileThemeExtension!.shadowTimeScrubMovingBall
                            .withValues(alpha: 0.9),
                        blurRadius: 2,
                        spreadRadius: 2),
                  ]),
            );

            final movingBallWidget = AnimatedPositioned(
              duration: animDuration,
              left: ballL,
              child: ScaleTransition(
                key: const ValueKey('timeScrubPulse'),
                scale: _pulseScale,
                child: ball,
              ),
            ); // moving ball (pulses only while current)
            scrubberElements.add(usedUpTimeWidget);
            scrubberElements.add(movingBallWidget);
          }
          timeline = Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: trackWidth,
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
                              )))
                    ],
                  )
                ]),
              ));
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
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!
                          .elapsedDurationAgo(elapsedTime),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15),
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
                  Icon(Icons.timelapse, color: colorScheme.onSurface),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!
                          .startsInDuration(elapsedTime),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontFamily: TileTextStyles.rubikFontName,
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        }

        return SizedBox(
          width: outerWidth,
          height: 30,
          child: timeline,
        );
      },
    );
  }

  @override
  void dispose() {
    refreshTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }
}
