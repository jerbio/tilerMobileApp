import 'package:tiler_app/util.dart';

class Timeline {
  String? id = Utility.getUuid;
  int? start;
  int? end;
  Timeline({this.start, this.end}) {
    if(this.start != null || this.end != null ) {
      if(this.start!=null && this.end!=null) {
        if(this.start! > this.end!) {
          throw new Exception('start time cannot be later than end');
        }
      } else {
        if(this.start !=null) {
          this.end = this.start;
        } else {
          this.start = this.end;
        }
      }
    } else{
      this.start = 0;
      this.end = 0;
    }
  }

  Timeline.fromDateTime(DateTime startTime, DateTime endTime) {
    this.start = startTime.millisecondsSinceEpoch;
    this.end = endTime.millisecondsSinceEpoch;
  }

  Timeline.fromDateTimeAndDuration(DateTime startTime, Duration duration) {
    this.start = startTime.millisecondsSinceEpoch;
    this.end = startTime.add(duration).millisecondsSinceEpoch;
  }
}