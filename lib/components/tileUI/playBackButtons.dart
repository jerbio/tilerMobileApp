import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/tilerEvent.dart';
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

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void showErrorMessage(String message) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
      SnackBar(
          content: Text(message),
          action: SnackBarAction(
              label: AppLocalizations.of(context)!.close,
              onPressed: scaffold.hideCurrentSnackBar)),
    );
  }

  pauseTile() async {
    showMessage(AppLocalizations.of(context)!.pausing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi
        .pauseTile((_subEvent ?? this.widget.subEvent).id!)
        .then((value) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyPaused,
          triggerTile: subTile));
    }).onError((error, stackTrace) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyPaused,
          triggerTile: subTile));
    });
  }

  resumeTile() async {
    showMessage(AppLocalizations.of(context)!.resuming);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi
        .resumeTile((_subEvent ?? this.widget.subEvent))
        .then((value) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyResumed,
          triggerTile: subTile));
    }).onError((error, stackTrace) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyResumed,
          triggerTile: subTile));
    });
  }

  setAsNowTile() async {
    showMessage(AppLocalizations.of(context)!.movingUp);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi.setAsNow((subTile)).then((value) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.movedUpToNow,
          triggerTile: subTile));
    }).onError((error, stackTrace) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.movedUpToNow,
          triggerTile: subTile));
    });
  }

  completeTile() async {
    showMessage(AppLocalizations.of(context)!.completing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi.complete((subTile)).then((value) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyCompleted,
          triggerTile: subTile));
    }).onError((error, stackTrace) {
      this.context.read<SubCalendarTilesBloc>().add(UpdateSchedule(
          message: AppLocalizations.of(context)!.successfullyCompleted,
          triggerTile: subTile));
    });
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
              Text(AppLocalizations.of(context)!.complete,
                  style: TextStyle(fontSize: 12))
            ],
          )),
      Column(
        children: [
          GestureDetector(
              onTap: setAsNowTile,
              child: Container(
                width: 50,
                height: 50,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Transform.rotate(
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
          Text(AppLocalizations.of(context)!.now,
              style: TextStyle(fontSize: 12))
        ],
      )
    ];
    if (widget.subEvent.isCurrent ||
        (widget.subEvent.isPaused != null && widget.subEvent.isPaused!)) {
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
          Text(AppLocalizations.of(context)!.pause,
              style: TextStyle(fontSize: 12))
        ],
      );

      if (widget.subEvent.isPaused != null && widget.subEvent.isPaused!) {
        playPauseButton = Column(
          children: [
            GestureDetector(
              onTap: resumeTile,
              child: Container(
                width: 50,
                height: 50,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                child: Icon(Icons.play_arrow_rounded),
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, .1),
                    borderRadius: BorderRadius.circular(25)),
              ),
            ),
            Text(AppLocalizations.of(context)!.resume,
                style: TextStyle(fontSize: 12))
          ],
        );
      }
      playBackElements.insert(1, playPauseButton as Column);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: playBackElements,
      ),
    );
  }
}
