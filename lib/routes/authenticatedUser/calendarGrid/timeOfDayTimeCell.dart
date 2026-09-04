import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeCellWidget.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

class TimeOfDayTimeCellWidget extends TimeCellWidget {
  final TimeOfDay? start;
  TimeOfDayTimeCellWidget({this.start, double? height})
      : super(timeCellHeight: height);

  @override
  _TimeOfDayTimeCellState createState() => _TimeOfDayTimeCellState();
}

class _TimeOfDayTimeCellState extends TimeCellWidgetState {
  double widgetWidth = TileDimensions.timeOfDayCellWidth;
  double topPosition = 0;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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
      // IgnorePointer: the time label is display-only but its Container has a
      // (BorderRadius) decoration, making it hit-test-opaque, and the inner
      // Stack with only Positioned children expands to the available width.
      // Without this it would swallow taps across the grid and block the
      // DayGrid background tap-to-add detector (C12). No visual change.
      child: IgnorePointer(
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
                    color: colorScheme.primary,
                    height: TileDimensions.thickness,
                    width: 20,
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
