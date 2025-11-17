import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/endTimeDurationDial.dart';
import 'package:tiler_app/routes/authenticatedUser/durationUIWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/timeAndDate.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StartEndDurationTimeline extends StatefulWidget {
  late DateTime start;
  late Duration duration;
  late TimeRange _timeline;
  bool isReadOnly = false;
  TextStyle? headerTextStyle;
  Function? onChange;
  StartEndDurationTimeline(
      {required this.start,
      required this.duration,
      this.isReadOnly = false,
      this.onChange,
      this.headerTextStyle}) {
    _timeline = Timeline.fromDateTimeAndDuration(this.start, this.duration);
  }
  StartEndDurationTimeline.fromTimeline({
    required TimeRange timeRange,
    Function? onChange,
    this.isReadOnly = false,
  }) {
    this.start = Utility.localDateTimeFromMs(timeRange.start!);
    this.duration = timeRange.duration;
    this.onChange = onChange;
    _timeline = Timeline.fromDateTimeAndDuration(this.start, this.duration);
  }

  TimeRange get timeRange {
    return new Timeline(this._timeline.start, this._timeline.end);
  }

  @override
  State<StatefulWidget> createState() => _StartEndDurationTimelineState();
}

class _StartEndDurationTimelineState extends State<StartEndDurationTimeline> {
  late DateTime _start;
  late Duration _duration;

  @override
  void initState() {
    _start = this.widget.start;
    _duration = this.widget.duration;
    super.initState();
  }

  onTimeChange(DateTime time) {
    setState(() {
      this._start = time;
      onTimeLineChange();
    });
  }

  onTimeLineChange() {
    Timeline timeline =
        Timeline.fromDateTimeAndDuration(this._start, this._duration);
    if (this.widget.onChange != null) {
      this.widget._timeline = timeline;
      this.widget.onChange!(timeline);
    }
  }

  onDurationTap() {
    if (this.widget.isReadOnly) {
      return;
    }
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EndTimeDurationDial(
                startTime: this._start,
                duration: this._duration))).then((value) {
      if (value != null && value is EndTimeDurationResult) {
        Duration duration = value.duration ??
            Duration(
                milliseconds:
                    Utility.utcEpochMillisecondsFromDateTime(value.time) -
                        Utility.utcEpochMillisecondsFromDateTime(this._start));

        setState(() {
          _duration = duration;
          onTimeLineChange();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;

    TextStyle textTitleStyle = this.widget.headerTextStyle ??
        const TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 20,
            fontWeight: FontWeight.w500);

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Container(
                  alignment: Alignment.topLeft,
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  child: Text(
                    AppLocalizations.of(context)!.start,
                    style: textTitleStyle,
                  )),
              Container(
                  alignment: Alignment.topLeft,
                  color: !this.widget.isReadOnly
                      ? Colors.transparent
                      : tileThemeExtension.surfaceContainerDisabled,
                  child: TimeAndDate(
                    time: this._start,
                    onInputChange: onTimeChange,
                    isReadOnly: this.widget.isReadOnly,
                  )),
            ],
          ),
          GestureDetector(
            onTap: onDurationTap,
            child: Container(
              alignment: Alignment.topLeft,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Column(
                children: [
                  Container(
                      alignment: Alignment.topLeft,
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: Text(
                        AppLocalizations.of(context)!.duration,
                        style: textTitleStyle,
                      )
                  ),
                  Container(
                    alignment: Alignment.center,
                    color: !this.widget.isReadOnly
                        ? Colors.transparent
                        : tileThemeExtension.surfaceContainerDisabled,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DurationUIWidget(
                            duration: _duration, key: Key(Utility.getUuid)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
