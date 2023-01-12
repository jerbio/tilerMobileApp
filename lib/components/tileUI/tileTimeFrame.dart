import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:maps_launcher/maps_launcher.dart';

class TileTimeFrame extends StatefulWidget {
  SubCalendarEvent subEvent;
  TileTimeFrame(this.subEvent) {
    assert(this.subEvent != null);
  }
  @override
  _TileTimeFrameState createState() => _TileTimeFrameState();
}

class _TileTimeFrameState extends State<TileTimeFrame> {
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
            DateFormat.yMMMd(locale).format(DateTime.fromMillisecondsSinceEpoch(
                this.widget.subEvent.end!.toInt())),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
          )
        ],
      ),
    );
  }
}
