import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class CalendarEvent extends TilerEvent {
  List<SubCalendarEvent>? subEvents;
  int? completeCount;
  int? deleteCount;

  CalendarEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('subEvents') && json['subEvents'] != null) {
      if (json['subEvents'] is List) {
        subEvents = json['subEvents']
            .map<SubCalendarEvent>((eachJsonSubEvent) =>
                SubCalendarEvent.fromJson(eachJsonSubEvent))
            .toList() as List<SubCalendarEvent>;
      }
    }

    if (json.containsKey('completeCount') && json['completeCount'] != null) {
      completeCount = TilerEvent.cast<int>(json['completeCount'])!.toInt();
    }

    if (json.containsKey('deletionCount') && json['deletionCount'] != null) {
      deleteCount = TilerEvent.cast<int>(json['deletionCount'])!.toInt();
    }
  }
}
