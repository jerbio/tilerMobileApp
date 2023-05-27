import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';

class TimelineSummary {
  Timeline? timeline;
  List<SubCalendarEvent>? tardy;
  List<SubCalendarEvent>? nonViable;
  List<SubCalendarEvent>? wake;
  List<SubCalendarEvent>? sleep;
  List<SubCalendarEvent>? complete;
  List<SubCalendarEvent>? deleted;

  TimelineSummary.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('timeline') && json['timeline'] != null) {
      timeline = Timeline.fromJson(json['timeline']);
    }

    if (json.containsKey('tardy') && json['tardy'] != null) {
      tardy = json['tardy']
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }

    const nonViableKey = 'nonViable';
    if (json.containsKey(nonViableKey) && json[nonViableKey] != null) {
      nonViable = json[nonViableKey]
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }

    const wakeKey = 'wake';
    if (json.containsKey(wakeKey) && json[wakeKey] != null) {
      wake = json[wakeKey]
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }

    const sleepCollectionKey = 'sleep';
    if (json.containsKey(sleepCollectionKey) &&
        json[sleepCollectionKey] != null) {
      sleep = json[sleepCollectionKey]
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }

    const completeCollectionKey = 'complete';
    if (json.containsKey(completeCollectionKey) &&
        json[completeCollectionKey] != null) {
      complete = json[completeCollectionKey]
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }

    const deleteCollectionKey = 'deleted';
    if (json.containsKey(deleteCollectionKey) &&
        json[deleteCollectionKey] != null) {
      deleted = json[deleteCollectionKey]
          .map<SubCalendarEvent>(
              (eachTileJson) => SubCalendarEvent.fromJson(eachTileJson))
          .toList();
    }
  }
}
