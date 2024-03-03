import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/peekdays.dart'; // Assuming this is the correct import for your CalendarEvent class

class Forecast {
  int? deadlineSuggestion;
  int? sleepDeadlineSuggestion;
  List<CalendarEvent>? riskCalendarEvents;
  List<CalendarEvent>? conflicts;
  int? conflictingCount;
  bool? isViable;
  List<PeekDay>? peekDays;

  Forecast.fromJson(Map<String, dynamic> json) {
    print("log10: Parsing JSON to Forecast model");
    if (json['deadlineSuggestion'] != null) {
      deadlineSuggestion = json['deadlineSuggestion'];
    }
    if (json['sleepDeadlineSuggestion'] != null) {
      sleepDeadlineSuggestion = json['sleepDeadlineSuggestion'];
    }
    if (json['riskCalendarEvents'] != null) {
      riskCalendarEvents = (json['riskCalendarEvents'] as List)
          .map((e) => CalendarEvent.fromJson(e))
          .toList();
    }
    if (json['conflicts'] != null) {
      conflicts = (json['conflicts'] as List)
          .map((e) => CalendarEvent.fromJson(e))
          .toList();
    }
    // if (json['riskCalendarEvents'] != null) {
    //   riskCalendarEvents = (json['riskCalendarEvents'] as List<dynamic>)
    //       .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
    //       .toList();
    // }
    // if (json['conflicts'] != null) {
    //   conflicts = (json['conflicts'] as List<dynamic>)
    //       .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
    //       .toList();
    // }
    if (json['conflictingCount'] != null) {
      conflictingCount = json['conflictingCount'];
    }
    if (json['isViable'] != null) {
      isViable = json['isViable'];
    }
    if (json['peekDays'] != null) {
      peekDays = (json['peekDays'] as List)
          .map((e) => PeekDay.fromJson(e))
          .toList();
    }
    print("log11: Parsed Forecast model: $this");
  }

}
