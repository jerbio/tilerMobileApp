import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class DayStatus {
  DateTime? dayDate;
  double? sleepHours = 0.0;
  bool isOptimized = false;
  List<TilerEvent>? completedSubEvents = [];
  List<TilerEvent>? warningSubEvents = [];
  List<TilerEvent>? errorSubEvents = [];

  static T? cast<T>(x) => x is T ? x : null;

  DayStatus() {}

  DayStatus.fromJson(Map<String, dynamic> json) {
    completedSubEvents = json['completedSubEvents']
        .map((eachSubEventJson) => SubCalendarEvent.fromJson(eachSubEventJson));
    warningSubEvents = json['warningSubEvents']
        .map((eachSubEventJson) => SubCalendarEvent.fromJson(eachSubEventJson));
    errorSubEvents = json['errorSubEvents']
        .map((eachSubEventJson) => SubCalendarEvent.fromJson(eachSubEventJson));
    sleepHours = cast<double>(json['sleepHours']);
    int? dayDateInMs = cast<int>(json['dayDateInMs']);
    if (dayDateInMs != null) {
      dayDate = DateTime.fromMillisecondsSinceEpoch(dayDateInMs);
    }
  }
}
