import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/tileObject.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

class Repetition extends TilerObj {
  bool? isEnabled;
  bool? isForever;
  RepetitionFrequency? frequency;
  List<String>? weekday;
  Timeline? repetitionTimeline;
  Timeline? tileTimeline;

  Repetition.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('id') && json['id'] != null) {
      id = json['id'];
    }

    if (json.containsKey('isEnabled') && json['isEnabled'] != null) {
      isEnabled = json['isEnabled'];
    }

    if (json.containsKey('isEnabled') && json['isEnabled'] != null) {
      isEnabled = json['isEnabled'];
    }

    String isForeverKey = 'isForever';
    if (json.containsKey(isForeverKey) && json[isForeverKey] != null) {
      isForever = json[isForeverKey];
    }

    String frequencyKey = 'frequency';
    frequency = RepetitionFrequency.none;
    if (json.containsKey(frequencyKey) && json[frequencyKey] != null) {
      try {
        frequency = RepetitionFrequency.values
            .byName(json[frequencyKey].toString().toLowerCase());
      } catch (e) {
        frequency = null;
      }
    }

    String weekDayKey = 'weekday';
    if (json.containsKey(weekDayKey) && json[weekDayKey] != null) {
      if (json[weekDayKey] is List) {
        weekday = (json[weekDayKey] as List)
            .where((e) => (e as String?) != null)
            .map((e) => (e as String))
            .toList();
      }
    }

    String repetitionTimelineyKey = 'repetitionTimeline';
    if (json.containsKey(repetitionTimelineyKey) &&
        json[repetitionTimelineyKey] != null) {
      this.repetitionTimeline = Timeline.fromJson(json[repetitionTimelineyKey]);
    }

    String tileTimelineKey = 'tileTimeline';
    if (json.containsKey(tileTimelineKey) && json[tileTimelineKey] != null) {
      this.tileTimeline = Timeline.fromJson(json[tileTimelineKey]);
    }
  }

  Repetition.fromRepetitionData(RepetitionData repetitionData) {
    this.isForever = repetitionData.isForever;
    this.frequency = repetitionData.frequency;
    this.isEnabled = repetitionData.isEnabled;

    if (repetitionData.repetitionEnd != null &&
        repetitionData.repetitionStart != null) {
      this.repetitionTimeline = Timeline.fromDateTime(
          repetitionData.repetitionStart!, repetitionData.repetitionEnd!);
    } else if (repetitionData.repetitionEnd != null) {
      this.repetitionTimeline = Timeline.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(0),
          repetitionData.repetitionEnd!);
    }

    this.weekday = repetitionData.weeklyRepetition
        ?.map((e) => Utility.weekdays[e])
        .toList();
  }

  RepetitionData? toRepetitionData() {
    RepetitionData? retValue = null;
    if (this.isForever == true || this.repetitionTimeline != null) {
      retValue = RepetitionData(
          frequency: this.frequency ?? RepetitionFrequency.none,
          repetitionStart: this.repetitionTimeline?.startTime,
          repetitionEnd: this.repetitionTimeline?.endTime,
          weeklyRepetition: Set.from(
              (this.weekday ?? []).map((e) => Utility.weekdays.indexOf(e))),
          isEnabled: this.isEnabled ?? false);
      retValue.isForever = this.isForever ?? false;
    }
    return retValue;
  }

  Map<String, dynamic>? toRequestJson() {
    Map<String, dynamic> retValue = {
      'IsEnabled': this.isEnabled,
      'IsForever': this.isForever,
      'RepetitionStart': this.repetitionTimeline?.start,
      'RepetitionEnd': this.repetitionTimeline?.end,
      'Frequency': this.frequency?.name.toLowerCase(),
      'TileStart': this.tileTimeline?.start,
      'TileEnd': this.tileTimeline?.end,
      'DayOfWeekRepetitions': this.weekday?.toList()
    };
    return retValue;
  }

  bool isEquivalent(Repetition other) {
    if (this == other) {
      return true;
    }
    if (this.isEnabled != other.isEnabled) {
      return false;
    }
    if (this.isForever != other.isForever) {
      return false;
    }

    if (this.frequency != other.frequency) {
      return false;
    }

    if (this.repetitionTimeline != null && other.repetitionTimeline != null) {
      return this.repetitionTimeline!.isEquivalent(other.repetitionTimeline!);
    } else if (this.repetitionTimeline != other.repetitionTimeline) {
      return false;
    }

    if (this.weekday != null && other.weekday != null) {
      var weekDayCpy = this.weekday!.toList();
      var otherWeekDayCpy = other.weekday!.toList();

      if (weekDayCpy.length != otherWeekDayCpy.length) {
        return false;
      }

      weekDayCpy.sort((a, b) => a.compareTo(b));
      otherWeekDayCpy.sort((a, b) => a.compareTo(b));
      for (int i = 0; i < weekDayCpy.length; i++) {
        if (weekDayCpy[i].toLowerCase() != otherWeekDayCpy[i].toLowerCase()) {
          return false;
        }
      }
    } else if (this.weekday != other.weekday) {
      return false;
    }

    return true;
  }
}
