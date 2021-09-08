import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/util.dart';

class Timeline with TimeRange {
  String? id = Utility.getUuid;
  DateTime? startTime;
  DateTime? endTime;
  double? _startInMs;
  double? _endInMs;

  set startInMs(double? value) {
    _startInMs = value;
    this.start = _startInMs;
    _updateStartEndTime();
  }

  set endInMs(double? value) {
    _endInMs = value;
    this.end = _endInMs;
    _updateStartEndTime();
  }

  double? get startInMs {
    return _startInMs;
  }

  double? get endInMs {
    return _endInMs;
  }

  Timeline(double? startInMs, double? endInMs) {
    this.startInMs = startInMs;
    this.endInMs = endInMs;
    if (this.startInMs != null || this.endInMs != null) {
      if (this.startInMs != null && this.endInMs != null) {
        if (this.startInMs! > this.endInMs!) {
          throw new Exception('start time cannot be later than end');
        }
      } else {
        if (this.startInMs != null) {
          this.endInMs = this.startInMs;
        } else {
          this.startInMs = this.endInMs;
        }
      }
    } else {
      this.startInMs = 0;
      this.endInMs = 0;
    }
    _updateStartEndTime();
  }

  toString() {
    String retValue = "";
    if (this.startInMs != null && this.endInMs != null) {
      retValue +=
          (new DateTime.fromMillisecondsSinceEpoch(this.startInMs!.toInt())
                  .toString()) +
              ' - ' +
              (new DateTime.fromMillisecondsSinceEpoch(this.endInMs!.toInt())
                  .toString());
    }

    return retValue;
  }

  void _updateStartEndTime() {
    if (this.startInMs != null && this.endInMs != null) {
      startTime = DateTime.fromMillisecondsSinceEpoch(this.startInMs!.toInt());
      endTime = DateTime.fromMillisecondsSinceEpoch(this.endInMs!.toInt());
    }
  }

  Timeline.fromDateTime(DateTime startTime, DateTime endTime) {
    this.startInMs = startTime.millisecondsSinceEpoch.toDouble();
    this.endInMs = endTime.millisecondsSinceEpoch.toDouble();
    assert(this.startInMs! <= this.endInMs!);
    _updateStartEndTime();
  }

  Timeline.fromJson(Map<String, dynamic> json) {
    String? startString;
    String? endString;
    if (json.containsKey('start') && json['start'] != null) {
      startString = json['start'].toString();
    }

    if (json.containsKey('end') && json['end'] != null) {
      endString = json['end'].toString();
    }

    if (startString != null && endString != null) {
      this.startInMs = double.parse(startString);
      this.endInMs = double.parse(endString);
      assert(this.startInMs! <= this.endInMs!);
    } else {
      this.startInMs = 0;
      this.endInMs = 0;
    }
    _updateStartEndTime();
  }

  Timeline.fromDateTimeAndDuration(DateTime startTime, Duration duration) {
    this.startInMs = startTime.millisecondsSinceEpoch.toDouble();
    this.endInMs = startTime.add(duration).millisecondsSinceEpoch.toDouble();
    assert(this.startInMs! <= this.endInMs!);
    _updateStartEndTime();
  }
}
