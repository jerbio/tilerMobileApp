import 'package:tiler_app/util.dart';

abstract class TimeRange {
  double? start = 0;
  double? end = 0;

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
}
