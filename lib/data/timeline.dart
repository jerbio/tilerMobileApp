import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/util.dart';

class Timeline with TimeRange {
  String? id = Utility.getUuid;
  double? start;
  double? end;
  Timeline({this.start, this.end}) {
    if (this.start != null || this.end != null) {
      if (this.start != null && this.end != null) {
        if (this.start! > this.end!) {
          throw new Exception('start time cannot be later than end');
        }
      } else {
        if (this.start != null) {
          this.end = this.start;
        } else {
          this.start = this.end;
        }
      }
    } else {
      this.start = 0;
      this.end = 0;
    }
  }

  toString() {
    String retValue = "";
    if (this.start != null && this.end != null) {
      retValue += (new DateTime.fromMillisecondsSinceEpoch(this.start!.toInt())
              .toString()) +
          ' - ' +
          (new DateTime.fromMillisecondsSinceEpoch(this.end!.toInt())
              .toString());
    }

    return retValue;
  }

  Timeline.fromDateTime(DateTime startTime, DateTime endTime) {
    this.start = startTime.millisecondsSinceEpoch.toDouble();
    this.end = endTime.millisecondsSinceEpoch.toDouble();
  }

  Timeline.fromDateTimeAndDuration(DateTime startTime, Duration duration) {
    this.start = startTime.millisecondsSinceEpoch.toDouble();
    this.end = startTime.add(duration).millisecondsSinceEpoch.toDouble();
  }
}
