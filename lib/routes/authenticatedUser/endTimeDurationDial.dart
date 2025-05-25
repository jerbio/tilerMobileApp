import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/routes/authenticatedUser/timeAndDate.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EndTimeDurationResult {
  DateTime time;
  Duration? duration;
  EndTimeDurationResult({required this.time});
}

class EndTimeDurationDial extends StatefulWidget {
  late DateTime startTime;
  late Duration duraton;

  EndTimeDurationDial({required this.startTime, required this.duraton});
  EndTimeDurationDial.fromTimeRange(TimeRange timeRange) {
    this.startTime = Utility.localDateTimeFromMs(timeRange.start!);
    this.duraton = timeRange.duration;
  }
  @override
  _EndTimeDurationDialState createState() => _EndTimeDurationDialState();
}

class _EndTimeDurationDialState extends State<EndTimeDurationDial> {
  late Duration _duration;
  late DateTime _end;
  final String endTimeDurationRouteName = "endTimeDuration";

  @override
  void initState() {
    _duration = this.widget.duraton;
    _end = this.widget.startTime.add(_duration);

    super.initState();
  }

  bool isProceedReady() {
    return _duration.inMinutes != this.widget.duraton.inMinutes &&
        Utility.utcEpochMillisecondsFromDateTime(this._end) >
            Utility.utcEpochMillisecondsFromDateTime(this.widget.startTime);
  }

  onProceedTap() {
    EndTimeDurationResult retValue = EndTimeDurationResult(time: this._end);
    retValue.duration = this._duration;
    return retValue;
  }

  onDurationChange(Duration duration) {
    setState(() {
      _duration = duration;
      _end = this.widget.startTime.add(duration);
    });
  }

  onEndTimeChange(DateTime time) {
    if (time.isBefore(this.widget.startTime)) {
      return;
    }
    setState(() {
      _end = time;
      _duration = _end.difference(this.widget.startTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    TimeAndDate timeAndDate = TimeAndDate(
      time: this._end,
      key: Key(Utility.getUuid),
      onInputChange: onEndTimeChange,
    );
    return CancelAndProceedTemplateWidget(
        routeName: endTimeDurationRouteName,
        appBar: AppBar(
          backgroundColor: TileColors.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.duration,
            style: TextStyle(
                color: TileColors.appBarTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.topCenter,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    child: DurationPicker(
                  duration: _duration,
                  onChange: (val) {
                    onDurationChange(val);
                  },
                  snapToMins: 5.0,
                )),
                timeAndDate
              ]),
        ),
        onProceed: isProceedReady() ? this.onProceedTap : null);

    // return retValue;
  }
}
