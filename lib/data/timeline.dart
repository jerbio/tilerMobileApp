import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/util.dart';

class Timeline with TimeRange {
  String? id = Utility.getUuid;

  double? _startInMs;
  double? _endInMs;

  set startInMs(double? value) {
    _startInMs = value;
    this.start = _startInMs;
  }

  set endInMs(double? value) {
    _endInMs = value;
    this.end = _endInMs;
  }

  double? get startInMs {
    return _startInMs;
  }

  double? get endInMs {
    return _endInMs;
  }

  DateTime get startTime {
    return Utility.localDateTimeFromMs(this._startInMs!.toInt());
  }

  DateTime get endTime {
    return Utility.localDateTimeFromMs(this._endInMs!.toInt());
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
  }

  toString() {
    String retValue = "";
    if (this.startInMs != null && this.endInMs != null) {
      retValue += (new DateTime.fromMillisecondsSinceEpoch(
                  this.startInMs!.toInt(),
                  isUtc: true)
              .toString()) +
          ' - ' +
          (new DateTime.fromMillisecondsSinceEpoch(this.endInMs!.toInt(),
                  isUtc: true)
              .toString());
    }

    return retValue;
  }

  Timeline.fromDateTime(DateTime startTime, DateTime endTime) {
    this.startInMs = startTime.millisecondsSinceEpoch.toDouble();
    this.endInMs = endTime.millisecondsSinceEpoch.toDouble();
    assert(this.startInMs! <= this.endInMs!);
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
  }

  Timeline.fromDateTimeAndDuration(DateTime startTime, Duration duration) {
    this.startInMs = startTime.millisecondsSinceEpoch.toDouble();
    this.endInMs = startTime.add(duration).millisecondsSinceEpoch.toDouble();
    assert(this.startInMs! <= this.endInMs!);
  }
}
