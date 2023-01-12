import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:maps_launcher/maps_launcher.dart';

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
              width: 32,
              height: 32,
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, 0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(
                Icons.calendar_month,
                color: Color.fromRGBO(0, 0, 0, 0.4),
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
