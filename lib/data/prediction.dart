import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class DayPrediction {
  int? dayIndex;
  List<TilerEvent>? subEvents;

  DayPrediction.fromTime(int epochJsTime, List<TilerEvent> tilerEvents) {
    dayIndex =
        DateTime.fromMillisecondsSinceEpoch(epochJsTime).universalDayIndex;
    subEvents = tilerEvents;
  }
}

class Conflict {
  List<DayPrediction>? dayPreviews;
  Iterable<TilerEvent> get subEvents {
    return dayPreviews!.expand((eachDayPreview) => eachDayPreview.subEvents!);
  }

  double? conflictScore;

  Conflict.fromJson(Map<String, dynamic> json) {
    String dayKey = 'days';
    if (json.containsKey(dayKey)) {
      List<int> epochJSTimes = json[dayKey]
          .keys
          .map<int>((timeAsJsString) => int.parse(timeAsJsString))
          .toList() as List<int>;
      dayPreviews = epochJSTimes
          .map<DayPrediction>((eachEpochJSTime) => DayPrediction.fromTime(
              eachEpochJSTime,
              json[dayKey][eachEpochJSTime.toString()]
                  .map<TilerEvent>(
                      (eachSubEvent) => SubCalendarEvent.fromJson(eachSubEvent))
                  .toList() as List<TilerEvent>))
          .toList();
    }

    String scoreKey = 'score';
    if (json.containsKey(scoreKey)) {
      conflictScore = Utility.cast<double>(json[scoreKey])!.toDouble();
    }
  }
}

class SleepTimeline {
  int? dayIndex;
  Duration? lostSleepDuration;
  Timeline? timeline;
  SleepTimeline.fromTime(int epochJsTime, Timeline timeline) {
    dayIndex =
        DateTime.fromMillisecondsSinceEpoch(epochJsTime).universalDayIndex;
    this.timeline = timeline;
  }
}

class DayDetails {
  Timeline? sleepTimeline;
  Timeline? maximumSleepTimeline;

  DayDetails({
    this.sleepTimeline,
    this.maximumSleepTimeline,
  });

  factory DayDetails.fromJson(Map<String, dynamic> json) {
    return DayDetails(
      sleepTimeline: json['sleepTimeline'] != null
          ? Timeline.fromJson(json['sleepTimeline'])
          : null,
      maximumSleepTimeline: json['maximumSleepTimeLine'] != null
          ? Timeline.fromJson(json['maximumSleepTimeLine'])
          : null,
    );
  }
}

class Sleep {
  List<SleepTimeline>? sleepTimeline;
  List<SleepTimeline>? maximumSleepTimeline;
  List<TilerEvent>? subEvents;
  Map<String, DayDetails>? days;
  double? sleepScore;

  Sleep.fromJson(Map<String, dynamic> json) {
    String dayKey = 'days';
    if (json.containsKey(dayKey)) {
      List<int> epochJSTimes = json[dayKey]
          .keys
          .map<int>((timeAsJsString) => int.parse(timeAsJsString))
          .toList() as List<int>;
      epochJSTimes.sort();
      String maxSleepTimelineKey = 'maximumSleepTimeLine';
      maximumSleepTimeline = epochJSTimes
          .where((jsTime) =>
              json[dayKey][jsTime.toString()].containsKey(maxSleepTimelineKey))
          .map<SleepTimeline>((jsTime) {
        var timelineJson = json[dayKey][jsTime.toString()][maxSleepTimelineKey];
        SleepTimeline retValue =
            SleepTimeline.fromTime(jsTime, Timeline.fromJson(timelineJson));

        return retValue;
      }).toList();
      String sleepTimelineKey = 'sleepTimeline';
      sleepTimeline = epochJSTimes
          .where((jsTime) =>
              json[dayKey][jsTime.toString()].containsKey(sleepTimelineKey))
          .map<SleepTimeline>((jsTime) {
        SleepTimeline retValue = SleepTimeline.fromTime(
            jsTime,
            Timeline.fromJson(
                json[dayKey][jsTime.toString()][sleepTimelineKey]));
        String lostSleepKey = 'lostSleep';
        if (json[dayKey][jsTime.toString()].containsKey(lostSleepKey)) {
          retValue.lostSleepDuration = Duration(
              milliseconds: Utility.cast<double>(
                      json[dayKey][jsTime.toString()][lostSleepKey])!
                  .toInt());
        }

        return retValue;
      }).toList();
    }

    String scoreKey = 'score';
    if (json.containsKey(scoreKey)) {
      sleepScore = Utility.cast<double>(json[scoreKey])!.toDouble();
    }
  }
}

class Tardy {
  List<DayPrediction>? dayPreviews;
  Iterable<TilerEvent> get subEvents {
    return dayPreviews!.expand((eachDayPreview) => eachDayPreview.subEvents!);
  }

  Tardy.fromJson(Map<String, dynamic> json) {
    String dayKey = 'days';
    if (json.containsKey(dayKey)) {
      List<int> epochJSTimes = json[dayKey]
          .keys
          .map<int>((timeAsJsString) => int.parse(timeAsJsString))
          .toList() as List<int>;
      epochJSTimes.sort();
      dayPreviews = epochJSTimes
          .map<DayPrediction>((eachEpochJSTime) => DayPrediction.fromTime(
              eachEpochJSTime,
              json[dayKey][eachEpochJSTime.toString()]
                  .map<TilerEvent>(
                      (eachSubEvent) => SubCalendarEvent.fromJson(eachSubEvent))
                  .toList() as List<TilerEvent>))
          .toList();
    }
  }
}

class TravelData {
  Map<String, TravelDetails>? travel;

  TravelData({this.travel});

  factory TravelData.fromJson(Map<String, dynamic>? json) {
    return TravelData(
      travel: (json)?.map(
        (key, value) => MapEntry(key, TravelDetails.fromJson(value)),
      ),
    );
  }
}

class TravelDetails {
  double? travelTime;
  double? totalDistance;

  TravelDetails({
    this.travelTime,
    this.totalDistance,
  });

  factory TravelDetails.fromJson(Map<String, dynamic> json) {
    return TravelDetails(
      travelTime: json['travelTime'] as double?,
      totalDistance: (json['totalDistance'] as num?)?.toDouble(),
    );
  }
}

class Preview {
  Conflict? conflict;
  Sleep? sleep;
  Tardy? tardies;
  List<TilerEvent>? nonViable;
  TravelData? travelData;
  double? scheduleScore;

  Preview.fromJson(Map<String, dynamic> json) {
    String conflictKey = 'conflict';
    if (json.containsKey(conflictKey)) {
      conflict = Conflict.fromJson(json[conflictKey]);
    }

    String sleepKey = 'sleep';
    if (json.containsKey(sleepKey)) {
      sleep = Sleep.fromJson(json[sleepKey]);
    }

    String tardiesKey = 'tardy';
    if (json.containsKey(tardiesKey)) {
      tardies = Tardy.fromJson(json[tardiesKey]);
    }

    String nonViableKey = 'nonViable';
    if (json.containsKey(nonViableKey)) {
      nonViable = json[nonViableKey]
          .map<TilerEvent>((eachJsonTilerEvent) =>
              SubCalendarEvent.fromJson(eachJsonTilerEvent))
          .toList() as List<TilerEvent>;
    }

    String scoreKey = 'score';
    if (json.containsKey(scoreKey)) {
      scheduleScore = Utility.cast<double>(json[scoreKey])!.toDouble();
    }

    String travelKey = 'travel';
    if (json.containsKey(travelKey) && json[travelKey] != null) {
      travelData = TravelData.fromJson(json[travelKey]);
    }
  }
}
