import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class SubCalendarEvent extends TilerEvent {
  double? travelTimeBefore;
  double? travelTimeAfter;
  double? rangeStart;
  double? rangeEnd;
  double? calendarEventStart;
  double? calendarEventEnd;
  String? emojis;
  bool? isPaused;
  bool? isPausedTimeLine = false;
  bool? isTardy;
  bool? isViable = true;
  bool? _isAllDay;
  bool isLocationInfoAvailable() {
    bool retValue = (this.address != null && this.address!.isNotEmpty) ||
        (this.addressDescription != null &&
            this.addressDescription!.isNotEmpty) ||
        (this.searchdDescription != null &&
            this.searchdDescription!.isNotEmpty);
    return retValue;
  }

  SubCalendarEvent(
      {int? start,
      int? end,
      String? name,
      String? address,
      String? addressDescription,
      String? id,
      String? userId})
      : super(
          start: start,
          end: end,
          name: name,
          address: address,
          addressDescription: addressDescription,
          id: id,
          userId: userId,
        );

  get isCurrent {
    int currentTimeInMs = Utility.msCurrentTime;
    if (this.start != null && this.end != null) {
      return this.start! <= currentTimeInMs && this.end! > currentTimeInMs;
    }

    return false;
  }

  bool get isToday {
    Timeline todayTimeline = Utility.todayTimeline();
    return todayTimeline.isInterfering(this);
  }

  bool get isAllDay {
    return _isAllDay ??
        this.duration.inMilliseconds > Utility.activeDayDuration.inMicroseconds;
  }

  bool get isBeforeNow {
    if (this.start != null) {
      return Utility.msCurrentTime < this.start!;
    }
    throw new ArgumentError.notNull('start');
  }

  get hasElapsed {
    if (this.end != null) {
      return Utility.msCurrentTime >= this.end!;
    }
    throw new ArgumentError.notNull('end');
  }

  DateTime? get rangeStartTime {
    if (this.rangeStart != null) {
      return DateTime.fromMillisecondsSinceEpoch(this.rangeStart!.toInt(),
          isUtc: true);
    }
  }

  DateTime? get rangeEndTime {
    if (this.rangeEnd != null) {
      return DateTime.fromMillisecondsSinceEpoch(this.rangeEnd!.toInt(),
          isUtc: true);
    }
  }

  DateTime? get calendarEventStartTime {
    if (this.calendarEventStart != null) {
      return DateTime.fromMillisecondsSinceEpoch(
          this.calendarEventStart!.toInt(),
          isUtc: true);
    }
  }

  DateTime? get calendarEventEndTime {
    if (this.calendarEventEnd != null) {
      return DateTime.fromMillisecondsSinceEpoch(this.calendarEventEnd!.toInt(),
          isUtc: true);
    }
  }

  static T? cast<T>(x) => x is T ? x : null;

  SubCalendarEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('travelTimeBefore') &&
        json['travelTimeBefore'] != null) {
      travelTimeBefore = double.parse(json['travelTimeBefore'].toString());
    }
    if (json.containsKey('travelTimeAfter') &&
        json['travelTimeAfter'] != null) {
      travelTimeAfter = double.parse(json['travelTimeAfter'].toString());
    }

    if (json.containsKey('calendarEventStart') &&
        json['calendarEventStart'] != null) {
      calendarEventStart = cast<int>(json['calendarEventStart'])!.toDouble();
    }

    if (json.containsKey('calendarEventEnd') &&
        json['calendarEventEnd'] != null) {
      calendarEventEnd = cast<int>(json['calendarEventEnd'])!.toDouble();
    }

    if (json.containsKey('rangeStart') && json['rangeStart'] != null) {
      rangeStart = cast<int>(json['rangeStart'])!.toDouble();
    }
    if (json.containsKey('rangeEnd') && json['rangeEnd'] != null) {
      rangeEnd = cast<int>(json['rangeEnd'])!.toDouble();
    }
    if (json.containsKey('emojis') && json['emojis'] != null) {
      emojis = cast<String>(json['emojis'])!.toString();
    }

    if (json.containsKey('isPaused') && json['isPaused'] != null) {
      isPaused = cast<bool>(json['isPaused'])!;
    }

    if (json.containsKey('isPausedTimeLine') &&
        json['isPausedTimeLine'] != null) {
      isPausedTimeLine = cast<bool>(json['isPausedTimeLine'])!;
    }

    if (json.containsKey('isTardy') && json['isTardy'] != null) {
      isTardy = cast<bool>(json['isTardy'])!;
    }

    if (json.containsKey('calendarEvent')) {
      calendarEvent = TilerEvent.fromJson(json['calendarEvent']);
      if (calendarEvent != null) {
        split = calendarEvent!.split;
      }
    }
    if (json.containsKey('isViable') && json['isViable'] != null) {
      isViable = cast<bool>(json['isViable'])!;
    }
  }
}
