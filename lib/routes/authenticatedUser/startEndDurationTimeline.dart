import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/endTimeDurationDial.dart';
import 'package:tiler_app/routes/authenticatedUser/durationUIWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/timeAndDate.dart';
import 'package:tiler_app/util.dart';

class StartEndDurationTimeline extends StatefulWidget {
  late DateTime start;
  late Duration duration;
  late TimeRange _timeline;
  Function? onChange;
  StartEndDurationTimeline(
      {required this.start, required this.duration, this.onChange}) {
    _timeline = Timeline.fromDateTimeAndDuration(this.start, this.duration);
  }
  StartEndDurationTimeline.fromTimeline(
      {required TimeRange timeRange, Function? onChange}) {
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
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EndTimeDurationDial(
                startTime: this._start,
                duraton: this._duration))).then((value) {
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
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TimeAndDate(time: this._start, onInputChange: onTimeChange),
          Container(
            height: 120,
            margin: EdgeInsets.fromLTRB(10, 0, 10, 0),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black, width: 1.0),
                right: BorderSide(color: Colors.black, width: 1.0),
              ),
            ),
          ),
          GestureDetector(
            onTap: onDurationTap,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: DurationUIWidget(
                  duration: _duration, key: Key(Utility.getUuid)),
            ),
          )
        ],
      ),
    );
  }
}
