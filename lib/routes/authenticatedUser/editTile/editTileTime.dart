import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class EditTileTime extends StatefulWidget {
  TimeOfDay time;
  _EditTileTimeState? _state;
  Function? onInputChange;
  bool isReadOnly = false;
  bool isPref=false;
  EditTileTime(
      {required this.time, this.onInputChange, this.isReadOnly = false,this.isPref = false});

  @override
  State<EditTileTime> createState() {
    _EditTileTimeState retValue = _EditTileTimeState();
    _state = retValue;
    return retValue;
  }

  TimeOfDay? get timeOfDay {
    return time;
  }
}

class _EditTileTimeState extends State<EditTileTime> {
  late TimeOfDay time;
  @override
  void initState() {
    super.initState();
    time = this.widget.time;
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TileStyles.editTimeOrDateTimeStyle;
    final localizations = MaterialLocalizations.of(context);
    final formattedTimeOfDay = localizations.formatTimeOfDay(time);
    return ElevatedButton(
      style: TileStyles.strippedButtonStyle,
      onPressed: () {
        if (this.widget.isReadOnly) {
          return;
        }
        Future<TimeOfDay?> selectedTime = showTimePicker(
          initialTime: time,
          context: context,
        );
        selectedTime.then((timeOfDayUpdate) {
          if (timeOfDayUpdate != null) {
            this.widget.time = timeOfDayUpdate;
            setState(() {
              time = timeOfDayUpdate;
            });
            if (this.widget.onInputChange != null) {
              this.widget.onInputChange!(timeOfDayUpdate);
            }
          }
        });
      },
      child: Container(
        child: Row(
          children: [
            Container(
                margin: EdgeInsets.fromLTRB(0, 0, widget.isPref?10:5, 0),
                child: Icon(
                  Icons.access_time_sharp,
                  color: TileStyles.iconColor,
                  size: widget.isPref?18:25,
                )),
            Container(
                child: Text(
              formattedTimeOfDay,
              style: widget.isPref?textStyle.copyWith(
                  color: Color.fromRGBO(154, 158, 159, 1),
                  decoration: TextDecoration.underline,
                  decorationColor: Color.fromRGBO(154, 158, 159, 1),) :textStyle
                ),
            ),
          ],
        ),
      ),
    );
  }
}
