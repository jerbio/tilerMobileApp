import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:intl/intl.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TimeAndDate extends StatefulWidget {
  DateTime time = Utility.currentTime();
  Function? onInputChange;
  bool isReadOnly = false;
  TimeAndDate({
    required this.time,
    Key? key,
    this.onInputChange,
    this.isReadOnly = false,
  }) : super(key: key);
  @override
  State<StatefulWidget> createState() => _TimeAndDateState();
}

class _TimeAndDateState extends State<TimeAndDate> {
  late DateTime dateTime;
  @override
  void initState() {
    dateTime = this.widget.time;
    super.initState();
  }

  Widget RenderTimePicker() {
    final localizations = MaterialLocalizations.of(context);
    final formattedTimeOfDay =
        localizations.formatTimeOfDay(TimeOfDay.fromDateTime(dateTime));
    return GestureDetector(
      onTap: () {
        if (this.widget.isReadOnly) {
          return;
        }
        Future<TimeOfDay?> selectedTime = showTimePicker(
          initialTime: TimeOfDay.fromDateTime(dateTime),
          context: context,
        );
        selectedTime.then((timeOfDayUpdate) {
          if (timeOfDayUpdate != null) {
            DateTime updatedTime = DateTime(dateTime.year, dateTime.month,
                dateTime.day, timeOfDayUpdate.hour, timeOfDayUpdate.minute);
            setState(() {
              dateTime = updatedTime;
            });
            if (this.widget.onInputChange != null) {
              this.widget.onInputChange!(updatedTime);
            }
          }
        });
      },
      child: Container(
        child: Container(
            child: Text(formattedTimeOfDay,
                style: TextStyle(
                    color: Color.fromRGBO(31, 31, 31, 1),
                    fontSize: 35,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w500))),
      ),
    );
  }

  void onDateTap() async {
    if (this.widget.isReadOnly) {
      return;
    }
    DateTime _endDate = dateTime;
    DateTime firstDate = _endDate.add(Duration(days: -14));
    DateTime lastDate = _endDate.add(Duration(days: 90));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectADeadline,
    );
    if (revisedEndDate != null) {
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endDate.hour,
          _endDate.minute);
      dateTime = updatedEndTime;
      setState(() {
        dateTime = updatedEndTime;
      });
      if (this.widget.onInputChange != null) {
        this.widget.onInputChange!(updatedEndTime);
      }
    }
  }

  Widget RenderDatePicker() {
    String locale = Localizations.localeOf(context).languageCode;
    return GestureDetector(
        onTap: onDateTap,
        child: Container(
            padding: EdgeInsets.all(10),
            margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Text(
              DateFormat.yMMMd(locale).format(dateTime),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'Rubik'),
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [RenderTimePicker(), RenderDatePicker()],
      ),
    );
  }
}
