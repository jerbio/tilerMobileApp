import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/styles.dart';

import '../../../util.dart';

class EditTileDate extends StatefulWidget {
  DateTime time;
  _EditTileDateState? _state;
  Function? onInputChange;
  EditTileDate({required this.time, this.onInputChange});

  @override
  State<EditTileDate> createState() {
    _EditTileDateState retValue = _EditTileDateState();
    _state = retValue;
    return retValue;
  }

  DateTime? get dateTime {
    return time;
  }
}

class _EditTileDateState extends State<EditTileDate> {
  late DateTime time;
  @override
  void initState() {
    super.initState();
    time = this.widget.time;
  }

  void onEndDateTap() async {
    DateTime _endDate = time;
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
      this.widget.time = updatedEndTime;
      setState(() => time = updatedEndTime);
      if (this.widget.onInputChange != null) {
        this.widget.onInputChange!(updatedEndTime);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    return GestureDetector(
        onTap: onEndDateTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
          child: Row(
            children: [
              Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.fromLTRB(0, 0, 5, 0),
                  child: Icon(
                    Icons.calendar_month,
                    color: TileStyles.iconColor,
                  )),
              Text(
                DateFormat.yMMMd(locale).format(time),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
              )
            ],
          ),
        ));
  }
}
