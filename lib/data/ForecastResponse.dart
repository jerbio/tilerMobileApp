import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/travelTimeAndDistance.dart';
import 'package:tiler_app/util.dart';

class ForecastResponse {
  int? deadlineSuggestion;
  int? sleepDeadlineSuggestion;
  List<CalendarEvent>? riskCalendarEvents;
  List<CalendarEvent>? conflicts;
  int? conflictingCount;
  bool? isViable;
  List<PeekDay>? peekDays;
  List<TravelTimeAndDistance>? travelTimeAndDistances;

  ForecastResponse({
    this.deadlineSuggestion,
    this.sleepDeadlineSuggestion,
    this.riskCalendarEvents,
    this.conflicts,
    this.conflictingCount,
    this.isViable,
    this.peekDays,
  });

  ForecastResponse.fromJson(Map<String, dynamic> json) {
    deadlineSuggestion = json['deadlineSuggestion'] as int?;
    sleepDeadlineSuggestion = json['sleepDeadlineSuggestion'] as int?;
    riskCalendarEvents = (json['riskCalendarEvents'] as List<dynamic>?)
        ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    conflicts = (json['conflicts'] as List<dynamic>?)
        ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
        .toList();
    conflictingCount = json['conflictingCount'] as int?;
    isViable = json['isViable'] as bool?;
    peekDays = (json['peekDays'] as List<dynamic>?)
        ?.map((e) => PeekDay.fromJson(e as Map<String, dynamic>))
        .toList();
    if (json.containsKey('travel') && json['travel'] != null) {
      Map<String, dynamic>? travelTimeAndDistanceJson =
          json['travel'] as Map<String, dynamic>?;
      if (travelTimeAndDistanceJson != null) {
        Map<int, TravelTimeAndDistance> dayIndexToTravelTimeAndDistance = {};
        travelTimeAndDistanceJson.entries.forEach((element) {
          String? dayEndString = element.key;
          int? dayEndInMs = int.tryParse(dayEndString);

          if (dayEndInMs != null) {
            DateTime dayEndTime =
                DateTime.fromMillisecondsSinceEpoch(dayEndInMs);
            TravelTimeAndDistance travelTimeAndDistance =
                TravelTimeAndDistance.fromJson(travelTimeAndDistanceJson);
            travelTimeAndDistance.dayEndTime = dayEndTime;
            dayIndexToTravelTimeAndDistance[Utility.getDayIndex(dayEndTime)] =
                travelTimeAndDistance;
          }
        });
        travelTimeAndDistances =
            dayIndexToTravelTimeAndDistance.values.toList();
      }
    }
  }
}

class PeekDay {
  double? duration;
  double? durationRatio;
  int? dayIndex;
  double? sleepTime;

  PeekDay({
    this.duration,
    this.durationRatio,
    this.dayIndex,
    this.sleepTime,
  });

  // fromJson factory constructor
  factory PeekDay.fromJson(Map<String, dynamic> json) {
    return PeekDay(
      duration: (json['duration'] as num?)?.toDouble(),
      durationRatio: (json['durationRatio'] as num?)?.toDouble(),
      dayIndex: json['dayIndex'] as int?,
      sleepTime: (json['sleepTime'] as num?)?.toDouble(),
    );
  }
}
