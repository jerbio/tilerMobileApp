import 'package:tiler_app/data/calendarEvent.dart';

class ForecastResponse {
  int? deadlineSuggestion;
  int? sleepDeadlineSuggestion;
  List<CalendarEvent>? riskCalendarEvents;
  List<CalendarEvent>? conflicts;
  int? conflictingCount;
  bool? isViable;
  List<PeekDay>? peekDays;

  ForecastResponse({
    this.deadlineSuggestion,
    this.sleepDeadlineSuggestion,
    this.riskCalendarEvents,
    this.conflicts,
    this.conflictingCount,
    this.isViable,
    this.peekDays,
  });

// fromJson factory constructor
  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    return ForecastResponse(
      deadlineSuggestion: json['deadlineSuggestion'] as int?,
      sleepDeadlineSuggestion: json['sleepDeadlineSuggestion'] as int?,
      riskCalendarEvents: (json['riskCalendarEvents'] as List<dynamic>?)
          ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      conflicts: (json['conflicts'] as List<dynamic>?)
          ?.map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      conflictingCount: json['conflictingCount'] as int?,
      isViable: json['isViable'] as bool?,
      peekDays: (json['peekDays'] as List<dynamic>?)
          ?.map((e) => PeekDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
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
