import 'package:flutter/material.dart';
import 'package:tiler_app/util.dart';

abstract class TimeRange {
  int? start = 0;
  int? end = 0;

  bool isInterfering(TimeRange timeRange) {
    bool retValue = false;
    if (this.start != null &&
        this.end != null &&
        timeRange.start != null &&
        timeRange.end != null) {
      retValue = this.end! > timeRange.start! && timeRange.end! > this.start!;
    }

    return retValue;
  }

  bool isDateTimeWithin(DateTime time) {
    int currentTime = time.millisecondsSinceEpoch;
    return this.start! <= currentTime && this.end! > currentTime;
  }

  bool get isCurrentTimeWithin {
    int currentTime = Utility.currentTime().millisecondsSinceEpoch;
    return this.start! <= currentTime && this.end! > currentTime;
  }

  bool get hasElapsed {
    return this.end! < DateTime.now().millisecondsSinceEpoch.toDouble();
  }

  Duration get duration {
    if (this.start != null && this.end != null) {
      return Duration(milliseconds: (this.end!.toInt() - this.start!.toInt()));
    }
    throw ErrorDescription("Invalid timerange provided");
  }

  bool isStartAndEndEqual(TimeRange timeRange) {
    return this.start == timeRange.start && this.end == timeRange.end;
  }

  Duration get durationTillStart {
    if (this.start != null) {
      return Duration(
          milliseconds: (this.start!.toInt() - Utility.msCurrentTime).toInt());
    }
    throw ErrorDescription("Invalid timerange provided");
  }

  Duration get durationTillEnd {
    if (this.start != null) {
      return Duration(
          milliseconds: (this.end!.toInt() - Utility.msCurrentTime).toInt());
    }
    throw ErrorDescription("Invalid timerange provided");
  }
}
