import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class TimeFrameWidget extends StatelessWidget {
  TimeRange timeRange;
  Color? textColor;
  double? fontSize;
  bool isWeeklyView;
  TimeFrameWidget({required this.timeRange, this.textColor,this.fontSize,this.isWeeklyView=false});

  String? getTimelineString(BuildContext context, TimeRange timeRange) {
    String timeFrameString= MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(DateTime.fromMillisecondsSinceEpoch(
                timeRange.start!.toInt())));
    if(!isWeeklyView)
      timeFrameString+=' - ' +
        MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(
                DateTime.fromMillisecondsSinceEpoch(timeRange.end!.toInt())));
    return timeFrameString;
  }

  @override
  Widget build(BuildContext context) {
    String? timeFrameString = this.getTimelineString(context, this.timeRange);
    return Container(
      child: Text(timeFrameString!,
          style: TextStyle(
              fontSize: this.fontSize??15,
              fontFamily: 'Rubik',
              fontWeight: FontWeight.normal,
              color: this.textColor ?? TileColors.defaultTextColor)),
    );
  }
}
