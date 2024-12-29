import 'package:flutter/material.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeCellWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';

class TileDayGrid extends DayGridWidget {
  final List<TilerEvent>? tilerEvents;
  TileDayGrid({this.tilerEvents});
}

class TileDayGridState extends State<DayGridWidget> {
  @override
  @override
  Widget build(BuildContext context) {
    List<TimeCellWidget> allDayTimeTiles = [];
    List<TimeCellWidget> tileTimeCell = [];
    int timeCellCount = 24;
    double heightPerCell = TimeCellWidget.defaultTimeCelHeight;
    TimeOfDay currentTOD = TimeOfDay(hour: 0, minute: 00);
    for (int i = 0; i < timeCellCount; i++) {
      allDayTimeTiles.add(TimeOfDayTimeCellWidget(start: currentTOD));
      tileTimeCell.add(TileTimeCellWidget(
        start: currentTOD,
        left: 70,
      ));
      currentTOD = TimeOfDay(hour: currentTOD.hour + 1, minute: 0);
    }
    if (allDayTimeTiles.isNotEmpty && allDayTimeTiles.first.height != null) {
      heightPerCell = allDayTimeTiles.first.height!;
    }
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          Container(
            height: timeCellCount * heightPerCell,
          ),
          ...tileTimeCell,
          ...allDayTimeTiles,
        ],
      ),
    );
  }
}
