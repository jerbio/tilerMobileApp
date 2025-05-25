import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';

class TileDate extends StatefulWidget {
  DateTime date;
  TileDate({required this.date});
  @override
  _TileDateState createState() => _TileDateState();
}

class _TileDateState extends State<TileDate> {
  @override
  Widget build(BuildContext context) {
    String locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
              width: 25,
              height: 25,
              decoration: TileStyles.tileIconContainerBoxDecoration,
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: Icon(
                Icons.calendar_month,
                color: TileColors.defaultTextColor,
                size: TileStyles.tileIconSize,
              )),
          Text(
            DateFormat.yMMMd(locale).format(this.widget.date),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
          )
        ],
      ),
    );
  }
}
