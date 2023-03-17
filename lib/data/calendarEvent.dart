import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class CalendarEvent extends TilerEvent {
  List<SubCalendarEvent>? subEvents;

  CalendarEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('subEvents') && json['subEvents'] != null) {
      if (json['subEvents'] is List) {
        subEvents = json['subEvents']
            .map<SubCalendarEvent>((eachJsonSubEvent) =>
                SubCalendarEvent.fromJson(eachJsonSubEvent))
            .toList() as List<SubCalendarEvent>;
      }
    }
  }
}
