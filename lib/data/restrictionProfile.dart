import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/tileObject.dart';

class RestrictionProfile extends TilerObj {
  List<RestrictionDay?> daySelection = [];
  RestrictionProfile({required List daySelection}) {
    assert(daySelection.length == 7);
    this.daySelection = daySelection as List<RestrictionDay?>;
  }
  RestrictionProfile.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json.containsKey('daySelection')) {
      List<RestrictionDay?> daySelection = [];
      for (var eachRestrictionDay in json['daySelection']!) {
        daySelection.add(RestrictionDay.fromJson(eachRestrictionDay));
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
      assert(daySelection.length == 7);
    }
  }
}
