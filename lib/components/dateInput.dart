import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tileThemeExtension.dart';
import 'package:tiler_app/theme/tile_box_shadows.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../theme/tile_text_styles.dart';

class DateInputWidget extends StatefulWidget {
  final Function? onDateChange;
  final DateTime? time;
  final String? placeHolder;
  DateInputWidget({this.onDateChange, this.time, this.placeHolder});
  @override
  State<StatefulWidget> createState() => _DateInputWidgetState();
}

class _DateInputWidgetState extends State<DateInputWidget> {
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
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    return InkWell(
      onTap: onDateTap,
      child: Container(
          padding: EdgeInsets.fromLTRB(30, 10, 10, 10),
          height: TileDimensions.inputHeight,
          decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: TileStyles.inputFieldBorderRadius,
              boxShadow: [TileBoxShadows.inputFieldBoxShadow(tileThemeExtension!.shadowHigh)],
              border: Border.all(
                color: colorScheme.onInverseSurface,
                width: 1.5,
              )),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month, color: colorScheme.onSurface),
              Container(
                  padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontSize: TileDimensions.inputFontSize,
                      ),
                    ),
                    onPressed: onDateTap,
                    child: Text(
                      textButtonString,
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        color: colorScheme.onSurface,
                        fontWeight: (this._time != null)
                            ? TileStyles.inputFieldFontWeight
                            : TileStyles.inputFieldHintFontWeight,
                      ),
                    ),
                  ))
            ],
          )),
    );
  }
}
