import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

class PlayBack extends StatefulWidget {
  SubCalendarEvent subEvent;
  PlayBack(this.subEvent);
  @override
  PlayBackState createState() => PlayBackState();
}

class PlayBackState extends State<PlayBack> {
  @override
  Widget build(BuildContext context) {
    var playBackElements = [
      Column(
        children: [
          Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Icon(Icons.clear_rounded),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          ),
          Text('Cancel', style: TextStyle(fontSize: 12))
        ],
      ),
      Column(
        children: [
          Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Icon(Icons.chevron_right),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          ),
          Text('Procrastinate', style: TextStyle(fontSize: 12))
        ],
      )
    ];
    if (widget.subEvent.isCurrent) {
      Widget pauseButton = Column(
        children: [
          Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Icon(Icons.pause_rounded),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          ),
          Text('Pause', style: TextStyle(fontSize: 12))
        ],
      );
      playBackElements.insert(1, pauseButton as Column);
    }

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: playBackElements,
      ),
    );
  }
}
