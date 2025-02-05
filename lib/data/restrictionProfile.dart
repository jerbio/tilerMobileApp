import 'package:tiler_app/data/request/RestrictionWeekConfig.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/tileObject.dart';

class RestrictionProfile extends TilerObj {
  List<RestrictionDay?> daySelection = [];
  String timeZone = 'utc';
  bool isEnabled = true;
  RestrictionProfile({required List daySelection, this.isEnabled = true}) {
    assert(daySelection.length == 7);
    this.daySelection = daySelection as List<RestrictionDay?>;
  }

  bool get isAnyDayNotNull {
    return this.daySelection.any((restrictedDay) => restrictedDay != null);
  }

  RestrictionProfile.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json.containsKey('daySelection') && json['daySelection'] != null) {
      List<RestrictionDay?> daySelection = [];
      for (var eachRestrictionDay in json['daySelection']!) {
        if (eachRestrictionDay != null) {
          daySelection.add(RestrictionDay.fromJson(eachRestrictionDay));
        } else {
          daySelection.add(eachRestrictionDay);
        }
      }
      List<int?> notFoundDayIndexes = [0, 1, 2, 3, 4, 5, 6];

      var daySelectionCpy = daySelection.where((eachRestrictionDay) {
        if (eachRestrictionDay != null) {
          notFoundDayIndexes[eachRestrictionDay.weekday!] = null;
        }
        return eachRestrictionDay != null;
      }).toList();

      daySelectionCpy.sort((eachDaySelectionA, eachDaySelectionB) =>
          eachDaySelectionA!.weekday!.compareTo(eachDaySelectionB!.weekday!));
      daySelection = daySelectionCpy;
      for (int? notFoundDayIndex in notFoundDayIndexes) {
        if (notFoundDayIndex != null) {
          daySelection.insert(notFoundDayIndex, null);
        }
      }
      assert(daySelection.length == 7);
      this.daySelection = daySelection;
    }

    if (json.containsKey('timeZone') &&
        json['timeZone'] != null &&
        json['timeZone'].isNotEmpty) {
      timeZone = json['timeZone'];
    }

    if (json.containsKey('isEnabled') && json['isEnabled'] != null) {
      isEnabled = TilerObj.cast<bool>(json['isEnabled']) ?? true;
    }
  }

  RestrictionProfile.workDay(RestrictionTimeLine restrictionTimeLine) {
    for (int i = 0; i < 7; i++) {
      RestrictionDay? restrictionDay;
      if (i != 0 && i != 6) {
        restrictionDay = RestrictionDay(
            restrictionTimeLine: restrictionTimeLine, weekday: i);
      }
      daySelection.add(restrictionDay);
    }
  }

  RestrictionProfile.noRestriction() {
    isEnabled = false;
    daySelection = List.filled(7, null);
  }

  RestrictionProfile.everyDay(RestrictionTimeLine restrictionTimeLine) {
    for (int i = 0; i < 7; i++) {
      RestrictionDay restrictionDay =
          RestrictionDay(restrictionTimeLine: restrictionTimeLine, weekday: i);
      daySelection.add(restrictionDay);
    }
  }

  RestrictionProfile clone() {
    RestrictionProfile retValue = RestrictionProfile.fromJson({});
    retValue.daySelection = this.daySelection.toList();
    retValue.timeZone = this.timeZone;
    retValue.isEnabled = this.isEnabled;

    return retValue;
  }

  RestrictionWeekConfig? toRestrictionWeekConfig() {
    RestrictionWeekConfig retValue = RestrictionWeekConfig();
    bool isRestrictionEnabled = false;
    if (daySelection.isNotEmpty) {
      List<RestrictionWeekDayConfig> weekDayOptions =
          <RestrictionWeekDayConfig>[];
      for (RestrictionDay? restrictionDay
          in daySelection.where((restrictionDay) => restrictionDay != null)) {
        weekDayOptions.add(restrictionDay!.toRestrictionWeekDayConfig());
      }
      if (weekDayOptions.isNotEmpty) {
        isRestrictionEnabled = true;
        retValue.WeekDayOption = weekDayOptions;
      }
    }
    isRestrictionEnabled = this.isEnabled;
    if (this.timeZone.isNotEmpty) {
      retValue.timeZone = this.timeZone;
    }
    retValue.isEnabled = isRestrictionEnabled.toString();
    retValue.restrictionProfileId = this.id;
    return retValue;
  }

  bool isEquivalent(RestrictionProfile other) {
    bool retValue = true;
    if (this == other) {
      return true;
    }

    if (this.isEnabled != true && this.isEnabled == other.isEnabled) {
      return true;
    }

    if (this.isEnabled != other.isEnabled) {
      return false;
    }

    var daySelectionCpy =
        this.daySelection.where((element) => element != null).toList();
    var otherSelectionCpy =
        other.daySelection.where((element) => element != null).toList();

    if (daySelectionCpy.length != otherSelectionCpy.length) {
      return false;
    }

    daySelectionCpy.sort(daySelectorComparator);
    otherSelectionCpy.sort(daySelectorComparator);
    for (int i = 0; i < daySelectionCpy.length; i++) {
      if (daySelectionCpy[i]!.restrictionTimeLine ==
              otherSelectionCpy[i]!.restrictionTimeLine &&
          daySelectionCpy[i]!.weekday == otherSelectionCpy[i]!.weekday) {
        continue; //this is because there is an operator overload only for == in restriction timeline
      } else {
        return false;
      }
    }
    if (this.isAnyDayNotNull != other.isAnyDayNotNull) {
      return false;
    }

    if (this.timeZone != other.timeZone) {
      return false;
    }

    return retValue;
  }

  int daySelectorComparator(itemA, itemB) {
    if (itemA!.weekday == null || itemB!.weekday == null) {
      if (itemA.weekday == itemB!.weekday) {
        return 0;
      }
      if (itemA.weekday == null) {
        return -1;
      }
      return 1;
    }
    return itemA.weekday!.compareTo(itemB.weekday!);
  }
}
