import 'package:flutter/material.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeCellWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DayGridWidget extends StatefulWidget {
  final PeekDay peekDay;
  Function? onTileTap;
  DayGridWidget({required this.peekDay, this.onTileTap});
  @override
  DayGridWidgetState createState() => DayGridWidgetState();
}

class DayGridWidgetState extends State<DayGridWidget> {
  ScrollController _scrollController = ScrollController();
  bool isInitialLoad = true;
  List<TimeCellWidget> allDayTimeTiles = [];
  List<TimeCellWidget> tileTimeCell = [];
  List<TileGridWidget> tileGridWidgetCell = [];
  int timeCellCount = 24;
  double heightPerCell = GridPositionableWidget.defaultHeigtPerDuration;
  double? animatedHeight = null;
  double activeHour = 8;
  Map<String, SubCalendarEvent> selectedSubEvent = {};
  bool isInitialRun = true;

  @override
  void initState() {
    super.initState();
    TimeOfDay currentTOD = TimeOfDay(hour: 0, minute: 00);
    for (int i = 0; i < timeCellCount; i++) {
      allDayTimeTiles.add(TimeOfDayTimeCellWidget(
        start: currentTOD,
      ));
      tileTimeCell.add(TileTimeCellWidget(
        start: currentTOD,
        left: TileStyles.timeOfDayCellWidth,
        height: heightPerCell,
      ));
      currentTOD = TimeOfDay(hour: currentTOD.hour + 1, minute: 0);
    }
    if (allDayTimeTiles.isNotEmpty) {
      heightPerCell = allDayTimeTiles.first.height;
    }
    animatedHeight = heightPerCell * activeHour;
  }

  void onTileGridTap({TilerEvent? tilerEvent}) {
    if (tilerEvent != null && tilerEvent.id.isNot_NullEmptyOrWhiteSpace()) {
      if (tilerEvent is SubCalendarEvent &&
          tilerEvent.id.isNot_NullEmptyOrWhiteSpace()) {
        setState(() {
          selectedSubEvent = {};
          selectedSubEvent[tilerEvent.id!] = tilerEvent;
        });
      }
    }
    if (this.widget.onTileTap != null) {
      this.widget.onTileTap!(tilerEvent: tilerEvent);
    }
  }

  void _initialRun() {
    if (isInitialRun) {
      if (this.widget.peekDay.subEvents != null &&
          this.widget.peekDay.subEvents!.isNotEmpty) {
        var subEvents = this.widget.peekDay.subEvents!;
        subEvents.sort((a, b) => (a.start ?? 0).compareTo((b.start ?? 0)));
        setState(() {
          isInitialRun = false;
          animatedHeight = heightPerCell * subEvents.first.startTime.hour;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (this.widget.peekDay.subEvents != null &&
        this.widget.peekDay.subEvents!.isNotEmpty) {
      var subEvents = this.widget.peekDay.subEvents!;
      subEvents.sort((a, b) => (a.start ?? 0).compareTo((b.start ?? 0)));
      subEvents.forEach((element) {
        if (element.id.isNot_NullEmptyOrWhiteSpace() &&
            !selectedSubEvent.containsKey(element.id)) {
          tileGridWidgetCell.add(TileGridWidget(
            tilerEvent: element,
            onTap: onTileGridTap,
          ));
        }
      });
      tileGridWidgetCell.addAll(selectedSubEvent.values.map((eachTile) {
        return TileGridWidget(
          tilerEvent: eachTile,
          onTap: onTileGridTap,
        );
      }));
    }
    _initialRun();

    Widget retValue = SingleChildScrollView(
      controller: _scrollController,
      child: Stack(
        children: <Widget>[
          Container(
            height: timeCellCount * heightPerCell,
          ),
          ...tileTimeCell,
          ...allDayTimeTiles,
          ...tileGridWidgetCell,
        ],
      ),
    );
    if (animatedHeight != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.jumpTo(animatedHeight!);
        if (mounted) {
          setState(() {
            animatedHeight = null;
          });
        }
        animatedHeight = null;
      });
    }

    return retValue;
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }
}
