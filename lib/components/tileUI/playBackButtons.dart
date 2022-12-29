import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';

class PlayBack extends StatefulWidget {
  SubCalendarEvent subEvent;
  PlayBack(this.subEvent);
  @override
  PlayBackState createState() => PlayBackState();
}

class PlayBackState extends State<PlayBack> {
  ScheduleApi _scheduleApi = new ScheduleApi();
  SubCalendarEventApi _subCalendarEventApi = new SubCalendarEventApi();
  SubCalendarEvent? _subEvent;

  pauseTile() async {
    await _subCalendarEventApi.pauseTile((_subEvent ?? this.widget.subEvent).id!);
  }

  resumeTile() async {
    await _subCalendarEventApi.resumeTile((_subEvent ?? this.widget.subEvent).id!);
  }

  setAsNowTile() async {
    await _subCalendarEventApi.setAsNow((_subEvent ?? this.widget.subEvent).id!);
  }

  completeTile() async {
    await _subCalendarEventApi.complete((_subEvent ?? this.widget.subEvent).id!);
  }

  @override
  Widget build(BuildContext context) {
    var playBackElements = [
      GestureDetector(
        onTap: completeTile,
        child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Icon(Icons.check),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          ),
          Text(AppLocalizations.of(context)!.delete, style: TextStyle(fontSize: 12))
        ],
      )
      )
      ,
      Column(
        children: [
          GestureDetector(
            onTap: setAsNowTile,
            child: Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child:Transform.rotate(
                                  angle: -pi / 2,
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 35,
                                  ),
                                ),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          )),
          Text(AppLocalizations.of(context)!.now, style: TextStyle(fontSize: 12))
        ],
      )
    ];
    if (widget.subEvent.isCurrent || 
      (widget.subEvent.isPaused!= null && widget.subEvent.isPaused!) ) {
      Widget playPauseButton = Column(
        children: [
          GestureDetector(
            onTap: pauseTile,
            child: Container(
            width: 50,
            height: 50,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
            child: Icon(Icons.pause_rounded),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, .1),
                borderRadius: BorderRadius.circular(25)),
          ),
          ),
          Text(AppLocalizations.of(context)!.pause, style: TextStyle(fontSize: 12))
        ],
      );

      if(widget.subEvent.isPaused!= null && widget.subEvent.isPaused!) {
        playPauseButton = Column(
          children: [
            GestureDetector(
              onTap: resumeTile,
              child:Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Icon(Icons.play_arrow_rounded),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            ) ,
            ),
            Text(AppLocalizations.of(context)!.pause, style: TextStyle(fontSize: 12))
          ],
        );
      }
      playBackElements.insert(1, playPauseButton as Column);
    }

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: playBackElements,
      ),
    );
  }
}
