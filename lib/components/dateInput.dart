import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DateInputWidget extends StatefulWidget {
  final Function? onDateChange;
  final DateTime? time;
  final String? placeHolder;
  DateInputWidget({this.onDateChange, this.time, this.placeHolder});
  @override
  State<StatefulWidget> createState() => _DateInputWidgetState();
}

class _DateInputWidgetState extends State<DateInputWidget> {
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();
  String textButtonString = "";
  DateTime? _time;
  @override
  void initState() {
    super.initState();
    _time = this.widget.time;
    if (this.widget.placeHolder != null) {
      textButtonString = this.widget.placeHolder!;
    }
    if (this._time != null) {
      textButtonString = DateFormat.yMMMd().format(this._time!);
    }
  }

  Future onDateTap() async {
    DateTime _endDate =
        this._time ?? Utility.todayTimeline().endTime.add(Utility.oneDay);
    if (this._time == null) {
      _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);
    }
    DateTime firstDate = _endDate.add(Duration(days: -180));
    DateTime lastDate = _endDate.add(Duration(days: 180));
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
      setState(() => _time = updatedEndTime);
      textButtonString = DateFormat.yMMMd().format(this._time!);
    }

    if (this.widget.onDateChange != null) {
      this.widget.onDateChange!(_time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onDateTap,
      child: Container(
          padding: TileStyles.inputFieldPadding,
          height: TileStyles.inputHeight,
          decoration: BoxDecoration(
              color: textBackgroundColor,
              borderRadius: TileStyles.inputFieldBorderRadius,
              boxShadow: [TileStyles.inputFieldBoxShadow],
              border: Border.all(
                color: textBorderColor,
                width: 1.5,
              )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month, color: inputFieldIconColor),
              Container(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: TileStyles.inputFontSize,
                      ),
                    ),
                    onPressed: onDateTap,
                    child: Text(
                      textButtonString,
                      style: TextStyle(
                        fontFamily: TileStyles.rubikFontName,
                      ),
                    ),
                  ))
            ],
          )),
    );
    ;
  }
}
