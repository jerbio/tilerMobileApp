import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/forecastTemplate/DatePickerWidget.dart';
import 'package:tiler_app/components/forecastTemplate/durationWidget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/util.dart';

import '../../../styles.dart';

class ForecastPreview extends StatefulWidget {
  ForecastPreview({Key? key}) : super(key: key);

  @override
  _ForecastPreviewState createState() => _ForecastPreviewState();
}

class _ForecastPreviewState extends State<ForecastPreview> {
  TextEditingController date = TextEditingController();
  Duration _duration = Duration(hours: 0, minutes: 0);
  DateTime? _endTime;

  Widget generateDeadline() {
    void onEndDateTap() async {
      DateTime _endDate = this._endTime == null
          ? Utility.todayTimeline().endTime!.add(Utility.oneDay)
          : this._endTime!;
      DateTime firstDate = _endDate.add(Duration(days: -14));
      DateTime lastDate = _endDate.add(Duration(days: 90));
      final DateTime? revisedEndDate = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: AppLocalizations.of(context)!.whenQ,
      );
      if (revisedEndDate != null) {
        DateTime updatedEndTime = new DateTime(
            revisedEndDate.year,
            revisedEndDate.month,
            revisedEndDate.day,
            _endDate.hour,
            _endDate.minute);
        setState(() => _endTime = updatedEndTime);
      }
    }

    String textButtonString = this._endTime == null
        ? AppLocalizations.of(context)!.deadline_auto
        : DateFormat.yMMMd().format(this._endTime!);
    Widget deadlineContainer = new GestureDetector(
        onTap: onEndDateTap,
        child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: TileStyles.textBackgroundColor,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: TileStyles.textBorderColor,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_month, color: TileStyles.iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: onEndDateTap,
                          child: Text(textButtonString),
                        ))
                  ],
                ))));
    return deadlineContainer;
  }

  Widget generateDurationPicker() {
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': _duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _duration = populatedDuration;
          }
        });
      });
    };
    String textButtonString = 'Duration';
    if (_duration.inMinutes > 1) {
      textButtonString = "";
      int hour = _duration.inHours.floor();
      int minute = _duration.inMinutes.remainder(60);
      if (hour > 0) {
        textButtonString = '${hour}h';
        if (minute > 0) {
          textButtonString = '${textButtonString} : ${minute}m';
        }
      } else {
        if (minute > 0) {
          textButtonString = '${minute}m';
        }
      }
    }
    Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: TileStyles.textBackgroundColor,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: TileStyles.textBorderColor,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.timelapse_outlined, color: TileStyles.iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: setDuration,
                          child: Text(textButtonString),
                        ))
                  ],
                ))));
    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.forecast,
          style: TextStyle(
              color: TileStyles.enabledTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Container(
        margin: TileStyles.topMargin,
        alignment: Alignment.topCenter,
        child: Column(
          children: [
            generateDurationPicker(),
            generateDeadline(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    date.dispose();
    super.dispose();
  }
}
