import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/styles.dart';

class TimeFrameWidget extends StatelessWidget {
  TimeRange timeRange;
  Color? textColor;
  TimeFrameWidget({required this.timeRange, this.textColor});

  String? getTimelineString(BuildContext context, TimeRange timeRange) {
    return MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(
                timeRange.start!.toInt()))) +
        ' - ' +
        MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(
                DateTime.fromMillisecondsSinceEpoch(timeRange.end!.toInt())));
  }

  @override
  Widget build(BuildContext context) {
    String? timeFrameString = this.getTimelineString(context, this.timeRange);
    return Container(
      child: Text(timeFrameString!,
          style: TextStyle(
              fontSize: 15,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.normal,
              color: this.textColor ?? TileStyles.defaultTextColor)),
    );
  }
}
