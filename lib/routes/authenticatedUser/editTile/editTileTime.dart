import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class EditTileTime extends StatefulWidget {
  DateTime time;
  _EditTileTimeState? _state;
  Function? onInputChange;
  EditTileTime({required this.time, this.onInputChange});

  @override
  State<EditTileTime> createState() {
    _EditTileTimeState retValue = _EditTileTimeState();
    _state = retValue;
    return retValue;
  }

  TimeOfDay? get timeOfDay {
    return TimeOfDay.fromDateTime(time);
  }
}

class _EditTileTimeState extends State<EditTileTime> {
  late DateTime time;
  @override
  void initState() {
    super.initState();
    time = this.widget.time;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final formattedTimeOfDay =
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(time));
    return GestureDetector(
      onTap: () {
        Future<TimeOfDay?> selectedTime = showTimePicker(
          initialTime: TimeOfDay.fromDateTime(time),
          context: context,
        );
        selectedTime.then((timeOfDayUpdate) {
          if (timeOfDayUpdate != null) {
            DateTime updatedTime = DateTime(time.year, time.month, time.day,
                timeOfDayUpdate.hour, timeOfDayUpdate.minute);
            this.widget.time = updatedTime;
            setState(() {
              time = updatedTime;
            });
            if (this.widget.onInputChange != null) {
              this.widget.onInputChange!(TimeOfDay.fromDateTime(updatedTime));
            }
          }
        });
      },
      child: Row(
        children: [
          Container(
              margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
              child:
                  Icon(Icons.access_time_sharp, color: TileStyles.iconColor)),
          Container(child: Text(formattedTimeOfDay)),
        ],
      ),
    );
  }
}
