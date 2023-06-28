import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';

class DayData {
  int? dayIndex;
  List<TilerEvent>? deletedTiles;
  List<TilerEvent>? completeTiles;
  List<TilerEvent>? nonViableTiles;
  TilerEvent? sleepTile;
  TilerEvent? wakeTile;
  Duration? sleepDuration;

  DayData();

  static DayData generateRandomDayData(int dayIndex) {
    List<SubCalendarEvent> subEvents = Utility.generateAdhocSubEvents(
            new Timeline.fromDateTimeAndDuration(
                Utility.getTimeFromIndex(dayIndex), Utility.oneDay))
        .item2;
    List<SubCalendarEvent> completedSubEvents =
        subEvents.take((subEvents.length / 2).toInt()).toList();
    List<SubCalendarEvent> deletedSubEvents =
        subEvents.skip(completedSubEvents.length).toList();
    DayData retValue = DayData();
    retValue.dayIndex = dayIndex;
    retValue.completeTiles = completedSubEvents;
    retValue.deletedTiles = deletedSubEvents;

    retValue.sleepTile =
        Utility.randomizer.nextInt(2) % 2 == 0 ? subEvents.first : null;
    retValue.wakeTile =
        Utility.randomizer.nextInt(2) % 2 == 0 ? subEvents.last : null;
    retValue.sleepDuration = Duration(hours: Utility.randomizer.nextInt(10));

    return retValue;
  }

  DayData.fromJson(Map<String, dynamic> json) {}
}
