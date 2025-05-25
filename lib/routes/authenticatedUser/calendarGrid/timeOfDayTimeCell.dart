import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeCellWidget.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimeOfDayTimeCellWidget extends TimeCellWidget {
  final TimeOfDay? start;
  TimeOfDayTimeCellWidget({this.start});

  @override
  _TimeOfDayTimeCellState createState() => _TimeOfDayTimeCellState();
}

class _TimeOfDayTimeCellState extends TimeCellWidgetState {
  double widgetWidth = TileStyles.timeOfDayCellWidth;
  double topPosition = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String formattedTimeOfDay = "";
    if (this.widget.start != null) {
      int hour = this.widget.start!.hour;

      if (hour > 11) {
        hour = hour % 12;
        if (hour == 0) {
          hour = 12;
        }
        formattedTimeOfDay =
            AppLocalizations.of(context)!.numberPm((hour).toString());
      } else {
        if (hour == 0) {
          hour = 12;
        }
        formattedTimeOfDay =
            AppLocalizations.of(context)!.numberAm(hour.toString());
      }
    }
    return Positioned(
      top: topPosition,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        height: this.widgetHeight,
        width: widgetWidth,
        child: Stack(
          children: [
            Positioned(right: 0, child: Text("$formattedTimeOfDay")),
            Positioned(
                right: 0,
                child: Container(
                  color: TileColors.gridLineColor,
                  height: TileStyles.thickness,
                  width: 20,
                ))
          ],
        ),
      ),
    );
  }
}
