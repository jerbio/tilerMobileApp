import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class TimelineSummary {
  int? dayIndex;
  Duration? sleepDuration;
  Timeline? timeline;
  List<TilerEvent>? tardy;
  List<TilerEvent>? nonViable;
  List<TilerEvent>? wake;
  List<TilerEvent>? sleep;
  List<TilerEvent>? complete;
  List<TilerEvent>? deleted;

  TimelineSummary();

  static TimelineSummary generateRandomDayData(int dayIndex) {
    List<SubCalendarEvent> subEvents = Utility.generateAdhocSubEvents(
            new Timeline.fromDateTimeAndDuration(
                Utility.getTimeFromIndex(dayIndex), Utility.oneDay))
        .item2;
    List<SubCalendarEvent> completedSubEvents =
        subEvents.take((subEvents.length / 2).toInt()).toList();
    List<SubCalendarEvent> deletedSubEvents =
        subEvents.skip(completedSubEvents.length).toList();
    TimelineSummary retValue = TimelineSummary();
    retValue.dayIndex = dayIndex;
    retValue.complete = completedSubEvents;
    retValue.deleted = deletedSubEvents;

    // retValue.sleepTile =
    //     Utility.randomizer.nextInt(2) % 2 == 0 ? subEvents.first : null;
    // retValue.wakeTile =
    //     Utility.randomizer.nextInt(2) % 2 == 0 ? subEvents.last : null;
    retValue.sleepDuration = Duration(hours: Utility.randomizer.nextInt(10));

    return retValue;
  }

  DateTime? get date {
    if (this.dayIndex != null) {
      return Utility.getTimeFromIndex(dayIndex!);
    }
    return null;
  }

  TimelineSummary.subCalendarEventFromJson(Map<String, dynamic> json) {
    if (json.containsKey('timeline') && json['timeline'] != null) {
      timeline = Timeline.fromJson(json['timeline']);
    }

    if (json.containsKey('dayIndex') && json['dayIndex'] != null) {
      dayIndex = int.tryParse(json['dayIndex']);
      timeline = Timeline.fromJson(json['dayIndex']);
    }

    if (json.containsKey('sleepDuration') && json['sleepDuration'] != null) {
      int? durationMs = int.tryParse(json['sleepDuration']);
      if (durationMs != null) {
        sleepDuration = Duration(milliseconds: durationMs);
      }
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

  TimelineSummary.tilerEventFromJson(Map<String, dynamic> json) {
    if (json.containsKey('dayIndex') && json['dayIndex'] != null) {
      dayIndex = int.tryParse(json['dayIndex']);
      timeline = Timeline.fromJson(json['dayIndex']);
    }

    if (json.containsKey('timeline') && json['timeline'] != null) {
      timeline = Timeline.fromJson(json['timeline']);
    }

    if (json.containsKey('sleepDuration') && json['sleepDuration'] != null) {
      int? durationMs = int.tryParse(json['sleepDuration']);
      if (durationMs != null) {
        sleepDuration = Duration(milliseconds: durationMs);
      }
    }

    if (json.containsKey('tardy') && json['tardy'] != null) {
      tardy = json['tardy']
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }

    const nonViableKey = 'nonViable';
    if (json.containsKey(nonViableKey) && json[nonViableKey] != null) {
      nonViable = json[nonViableKey]
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }

    const wakeKey = 'wake';
    if (json.containsKey(wakeKey) && json[wakeKey] != null) {
      wake = json[wakeKey]
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }

    const sleepCollectionKey = 'sleep';
    if (json.containsKey(sleepCollectionKey) &&
        json[sleepCollectionKey] != null) {
      sleep = json[sleepCollectionKey]
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }

    const completeCollectionKey = 'complete';
    if (json.containsKey(completeCollectionKey) &&
        json[completeCollectionKey] != null) {
      complete = json[completeCollectionKey]
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }

    const deleteCollectionKey = 'deleted';
    if (json.containsKey(deleteCollectionKey) &&
        json[deleteCollectionKey] != null) {
      deleted = json[deleteCollectionKey]
          .map<TilerEvent>((eachTileJson) => TilerEvent.fromJson(eachTileJson))
          .toList();
    }
  }
}
