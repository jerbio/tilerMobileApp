import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/routes/authenticatedUser/endTimeDurationDial.dart';

class DurationUIWidget extends StatefulWidget {
  Duration duration;
  List<Duration>? presetDurations;
  DurationUIWidget({required this.duration, presetDurations, Key? key})
      : super(key: key);
  @override
  State createState() => _DurationUIWidgetState();
}

class _DurationUIWidgetState extends State<DurationUIWidget> {
  late Duration _duration;
  @override
  void initState() {
    _duration = this.widget.duration;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int days = this._duration.inDays.floor();
    int totalHoursFloor = this._duration.inHours.floor();
    int hour = totalHoursFloor - (days * 24);
    int minute = this._duration.inMinutes.floor() - (totalHoursFloor * 60);
    const unitTimeStyle = TextStyle(
        color: Color.fromRGBO(180, 180, 180, 1),
        fontSize: 35,
        fontFamily: 'Rubik',
        fontWeight: FontWeight.w500);
    const topSpacing = EdgeInsets.fromLTRB(0, 0, 0, 10);

    Widget dayBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              days.toString(),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.day)
        ],
      ),
    );

    Widget hourBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.hour)
        ],
      ),
    );
    Widget minuteBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              minute.toString().padLeft(2, '0'),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.min)
        ],
      ),
    );

    Widget columnBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              ':',
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.whiteSpace)
        ],
      ),
    );

    List<Widget> childWidgets = <Widget>[hourBox, columnBox, minuteBox];
    if (days > 0) {
      childWidgets.insert(0, columnBox);
      childWidgets.insert(0, dayBox);
    }

    return Column(
      children: [
        Container(
          child: Row(
            children: childWidgets,
          ),
        ),
      ],
    );
  }
}
