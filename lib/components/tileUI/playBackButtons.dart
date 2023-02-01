import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
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
  SubCalendarEventApi _subCalendarEventApi = new SubCalendarEventApi();
  SubCalendarEvent? _subEvent;

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  pauseTile() async {
    showMessage(AppLocalizations.of(context)!.pausing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }

    if (scheduleState is ScheduleLoadedState) {
      context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true,
          callBack: _subCalendarEventApi
              .pauseTile((_subEvent ?? this.widget.subEvent).id!)));
    }
  }

  resumeTile() async {
    showMessage(AppLocalizations.of(context)!.resuming);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }

    if (scheduleState is ScheduleLoadedState) {
      context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true,
          callBack: _subCalendarEventApi
              .resumeTile((_subEvent ?? this.widget.subEvent))));
    }
  }

  setAsNowTile() async {
    showMessage(AppLocalizations.of(context)!.movingUp);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }

    if (scheduleState is ScheduleLoadedState) {
      context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true,
          callBack: _subCalendarEventApi.setAsNow((subTile))));
    }
  }

  completeTile() async {
    showMessage(AppLocalizations.of(context)!.completing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }

    if (scheduleState is ScheduleLoadedState) {
      context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true,
          callBack: _subCalendarEventApi.complete((subTile))));
    }
  }

  procrastinate() async {
    Map<String, dynamic> durationParams = {'duration': Duration(hours: 0)};
    Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
        .whenComplete(() {
      print('done with pop');
      print(durationParams['duration']);
      Duration? populatedDuration = durationParams['duration'] as Duration?;

      if (populatedDuration != null && populatedDuration.inMinutes > 0) {
        SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
        if (subTile.id != null) {
          showMessage(AppLocalizations.of(context)!.procrastinating);
          final scheduleState = this.context.read<ScheduleBloc>().state;
          if (scheduleState is ScheduleEvaluationState) {
            return;
          }

          if (scheduleState is ScheduleLoadedState) {
            context.read<ScheduleBloc>().add(EvaluateSchedule(
                renderedSubEvents: scheduleState.subEvents,
                renderedTimelines: scheduleState.timelines,
                renderedScheduleTimeline: scheduleState.lookupTimeline,
                isAlreadyLoaded: true,
                callBack: _subCalendarEventApi.procrastinate(
                    populatedDuration, subTile.id!)));
          }
        }
      }
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

    Widget procrastinateButton = Column(
      children: [
        GestureDetector(
            onTap: procrastinate,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Transform.rotate(
                angle: 0,
                child: Icon(
                  Icons.chevron_right,
                  size: 35,
                ),
              ),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            )),
        Text(AppLocalizations.of(context)!.procrastinate,
            style: TextStyle(fontSize: 12))
      ],
    );

    if (widget.subEvent.isRigid == null ||
        (widget.subEvent.isRigid != null && !widget.subEvent.isRigid!)) {
      playBackElements.add(procrastinateButton);
    }

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
