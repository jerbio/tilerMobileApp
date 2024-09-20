import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class CreatedTileSheet extends StatefulWidget {
  final SubCalendarEvent subEvent;
  CreatedTileSheet({required this.subEvent});
  _CreatedTileSheetState createState() => _CreatedTileSheetState();
}

class _CreatedTileSheetState extends State<CreatedTileSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 10),
            width: 300,
            child: TileName(widget.subEvent),
          ),
          Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 10, 10),
              width: 300,
              child: TileAddress(widget.subEvent)),
          Container(
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
                      size: 20.0,
                    ),
                  ),
                  Text(
                    this.widget.subEvent.startTime.humanDate,
                    style: TextStyle(
                        fontSize: 15,
                        fontFamily: 'Rubik',
                        fontWeight: FontWeight.normal,
                        color: Color.fromRGBO(31, 31, 31, 1)),
                  )
                ],
              )),
          FractionallySizedBox(
              alignment: FractionalOffset.center,
              widthFactor: TileStyles.inputWidthFactor,
              child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: TimeScrubWidget(
                    timeline: Timeline(
                        this.widget.subEvent.start, this.widget.subEvent.end),
                    loadTimeScrub: true,
                  ))),
        ],
      ),
    );
  }
}
