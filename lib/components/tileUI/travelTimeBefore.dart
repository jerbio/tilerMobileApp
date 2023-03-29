import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/util.dart';

class TravelTimeBefore extends StatefulWidget {
  SubCalendarEvent? subEvent;
  late Duration travelTimeDuration;
  TravelTimeBefore(travelTimeBeforeMs, this.subEvent) {
    assert(travelTimeBeforeMs != null);
    this.travelTimeDuration = travelTimeBeforeMs;
  }
  @override
  TravelTimeBeforeState createState() => TravelTimeBeforeState();
}

class TravelTimeBeforeState extends State<TravelTimeBefore> {
  @override
  Widget build(BuildContext context) {
    String durationString = Utility.toHuman(this.widget.travelTimeDuration);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: Colors.orange, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              Icons.directions_walk,
              color: Colors.white,
              size: 20.0,
            ),
          ),
          Row(
            children: [
              Text(
                'You need to leave in ',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontFamily: 'Rubik'),
              ),
              Text(
                '$durationString',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w600,
                    color: Colors.orange),
              )
            ],
          )
        ],
      ),
    );
  }
}
