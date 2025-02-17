import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/util.dart';

class Timeline with TimeRange {
  String? id = Utility.getUuid;
  List<Timeline>? occupiedSlots;

  DateTime get startTime {
    return Utility.localDateTimeFromMs(this.start!.toInt());
  }

  DateTime get endTime {
    return Utility.localDateTimeFromMs(this.end!.toInt());
  }

  Timeline(int? startInMs, int? endInMs) {
    this.start = startInMs;
    this.end = endInMs;
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
      retValue += (new DateTime.fromMillisecondsSinceEpoch(this.start!.toInt(),
                  isUtc: true)
              .toString()) +
          ' - ' +
          (new DateTime.fromMillisecondsSinceEpoch(this.end!.toInt(),
                  isUtc: true)
              .toString()) +
          ' ## ' +
          (this.duration.inDays > 1
              ? this.duration.inDays.toString() + ' days'
              : this.duration.toString());
    }

    return retValue;
  }

  Timeline.fromDateTime(DateTime startTime, DateTime endTime) {
    this.start = startTime.millisecondsSinceEpoch.toInt();
    this.end = endTime.millisecondsSinceEpoch.toInt();
    assert(this.start! <= this.end!);
  }

  Timeline.fromTimeRange(TimeRange timeRange) {
    this.start = timeRange.start;
    this.end = timeRange.end;
    assert(this.start! <= this.end!);
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

    if (json.containsKey('id') && json['id'] != null) {
      id = json['id'] as String?;
    }

    String occupiedSlotsKey = "occupiedSlots";
    if (json.containsKey(occupiedSlotsKey) && json[occupiedSlotsKey] != null) {
      if (json[occupiedSlotsKey] is List) {
        occupiedSlots = (json[occupiedSlotsKey] as List)
            .where((element) => element != null)
            .map<Timeline>((e) => Timeline.fromJson(e))
            .toList();
      }
    }

    if (startString != null && endString != null) {
      this.start = int.parse(startString);
      this.end = int.parse(endString);
      assert(this.start! <= this.end!);
    } else {
      this.start = 0;
      this.end = 0;
    }
  }

  Timeline.fromDateTimeAndDuration(DateTime startTime, Duration duration) {
    this.start = startTime.millisecondsSinceEpoch.toInt();
    this.end = startTime.add(duration).millisecondsSinceEpoch.toInt();
    assert(this.start! <= this.end!);
  }

  bool isEquivalent(Timeline other) {
    if (this == other) {
      return true;
    }
    return this.start == other.start && this.end == other.end;
  }
}
