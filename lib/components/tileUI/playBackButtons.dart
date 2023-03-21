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

enum PlaybackOptions { PlayPause, Now, Procrastinate, Delete, Complete }

class PlayBack extends StatefulWidget {
  SubCalendarEvent subEvent;
  List<PlaybackOptions>? forcedOption;
  Function? callBack;
  PlayBack(this.subEvent, {this.forcedOption, this.callBack});
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
              .pauseTile((_subEvent ?? this.widget.subEvent).id!)
              .then((value) {
            if (this.widget.callBack != null) {
              this.widget.callBack!(PlaybackOptions.PlayPause, value);
            }
            return value;
          })));
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
              .resumeTile((_subEvent ?? this.widget.subEvent))
              .then((value) {
            if (this.widget.callBack != null) {
              this.widget.callBack!(PlaybackOptions.PlayPause, value);
            }
            return value;
          })));
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
          callBack: _subCalendarEventApi.setAsNow((subTile)).then((value) {
            if (this.widget.callBack != null) {
              this.widget.callBack!(PlaybackOptions.Now, value);
            }
            return value;
          })));
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
          callBack: _subCalendarEventApi.complete((subTile)).then((value) {
            if (this.widget.callBack != null) {
              this.widget.callBack!(PlaybackOptions.Complete, value);
            }
            return value;
          })));
    }
  }

  deleteTile() async {
    showMessage(AppLocalizations.of(context)!.deleting);
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
              .delete(subTile.id!, subTile.thirdpartyType!)
              .then((value) {
            if (this.widget.callBack != null) {
              this.widget.callBack!(PlaybackOptions.Delete, value);
            }
            return value;
          })));
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
                callBack: _subCalendarEventApi
                    .procrastinate(populatedDuration, subTile.id!)
                    .then((value) {
                  if (this.widget.callBack != null) {
                    this.widget.callBack!(PlaybackOptions.Procrastinate, value);
                  }
                  return value;
                })));
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Set<PlaybackOptions> alreadyAddedButton = Set<PlaybackOptions>();
    Widget? playPauseButton;
    Widget? deleteButton;
    Widget? setAsNowButton;
    Widget? procrastinateButton;
    Widget? completeButton = GestureDetector(
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
        ));
    var playBackElements = <Widget>[
      completeButton,
    ];
    alreadyAddedButton.add(PlaybackOptions.Complete);

    deleteButton = Column(
      children: [
        GestureDetector(
            onTap: deleteTile,
            child: Container(
              width: 50,
              height: 50,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
              child: Icon(
                Icons.close,
                size: 35,
              ),
              decoration: BoxDecoration(
                  color: Color.fromRGBO(31, 31, 31, .1),
                  borderRadius: BorderRadius.circular(25)),
            )),
        Text(AppLocalizations.of(context)!.delete,
            style: TextStyle(fontSize: 12))
      ],
    );

    setAsNowButton = Column(
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
        Text(AppLocalizations.of(context)!.now, style: TextStyle(fontSize: 12))
      ],
    );

    if (!(widget.subEvent.isCurrent ||
        (widget.subEvent.isPaused != null && widget.subEvent.isPaused!))) {
      playBackElements.add(setAsNowButton);
      alreadyAddedButton.add(PlaybackOptions.Now);
    }
    procrastinateButton = Column(
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
      alreadyAddedButton.add(PlaybackOptions.Procrastinate);
    }

    if (widget.subEvent.isCurrent ||
        (widget.subEvent.isPaused != null && widget.subEvent.isPaused!)) {
      playPauseButton = Column(
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
      alreadyAddedButton.add(PlaybackOptions.PlayPause);
    }

    if (this.widget.forcedOption != null) {
      for (PlaybackOptions playbackOptions in this.widget.forcedOption!) {
        if (!alreadyAddedButton.contains(playbackOptions)) {
          switch (playbackOptions) {
            case PlaybackOptions.PlayPause:
              if (playPauseButton != null) {
                playBackElements.add(playPauseButton);
              }
              break;
            case PlaybackOptions.Now:
              if (setAsNowButton != null) {
                playBackElements.add(setAsNowButton);
              }
              break;
            case PlaybackOptions.Procrastinate:
              if (procrastinateButton != null) {
                playBackElements.add(procrastinateButton);
              }
              break;
            case PlaybackOptions.Delete:
              if (deleteButton != null) {
                playBackElements.add(deleteButton);
              }
              break;
            case PlaybackOptions.Complete:
              if (completeButton != null) {
                playBackElements.add(completeButton);
              }
              break;

            default:
          }
        }
      }
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: playBackElements
            .map((e) => Expanded(child: e))
            .toList(), // Wrapping in expanded to ensure they are equally spaced
      ),
    );
  }
}
