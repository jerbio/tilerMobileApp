import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class EditTileTime extends StatefulWidget {
  TimeOfDay time;
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
    const textStyle = const TextStyle(
        fontSize: 20, color: const Color.fromRGBO(153, 153, 153, 1));
    final localizations = MaterialLocalizations.of(context);
    final formattedTimeOfDay = localizations.formatTimeOfDay(time);
    return GestureDetector(
      onTap: () {
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
                margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
                child:
                    Icon(Icons.access_time_sharp, color: TileStyles.iconColor)),
            Container(
                child: Text(
              formattedTimeOfDay,
              style: textStyle,
            )),
          ],
        ),
      ),
    );
  }
}
