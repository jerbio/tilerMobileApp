import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDate.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileTime.dart';
import 'package:tiler_app/styles.dart';

class EditDateAndTime extends StatelessWidget {
  DateTime time;
  EditTileTime? _tileTime;
  EditTileDate? _tileDate;
  Function? onInputChange;
  EditDateAndTime({required this.time, this.onInputChange}) {
    _tileTime = EditTileTime(
      time: time.toLocal(),
      onInputChange: onTimeChange,
    );
    _tileDate = EditTileDate(
      time: time.toLocal(),
      onInputChange: onDateChange,
    );
  }

  DateTime? get dateAndTime {
    if (_tileTime != null && _tileDate != null) {
      TimeOfDay? timeOfDayTime = _tileTime!.timeOfDay;
      DateTime? dateOfTile = _tileDate!.dateTime;
      if (dateOfTile != null && timeOfDayTime != null) {
        DateTime retValue = DateTime(dateOfTile.year, dateOfTile.month,
            dateOfTile.day, timeOfDayTime.hour, timeOfDayTime.minute);
        return retValue;
      }
    }
  }

  onTimeChange(TimeOfDay timeOfDayUpdate) {
    if (onInputChange != null) {
      onInputChange!();
    }
  }

  onDateChange(DateTime dateUpdate) {
    if (onInputChange != null) {
      onInputChange!();
    }
  }

  @override
  Widget build(BuildContext context) {
    _tileTime = EditTileTime(
      time: time.toLocal(),
      onInputChange: onTimeChange,
    );
    _tileDate = EditTileDate(
      time: time.toLocal(),
      onInputChange: onDateChange,
    );
    return Row(
      children: [_tileTime!, _tileDate!],
    );
  }
}
