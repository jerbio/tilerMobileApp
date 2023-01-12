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
import 'package:tiler_app/util.dart';

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
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true));
    }
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi
        .pauseTile((_subEvent ?? this.widget.subEvent).id!)
        .then((value) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(context)!.successfullyPaused));
    }).onError((error, stackTrace) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(context)!.successfullyPaused));
    });
  }

  resumeTile() async {
    showMessage(AppLocalizations.of(context)!.resuming);
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }
    if (scheduleState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true));
    }
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi
        .resumeTile((_subEvent ?? this.widget.subEvent))
        .then((value) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(context)!.successfullyResumed));
    }).onError((error, stackTrace) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(context)!.successfullyResumed));
    });
  }

  setAsNowTile(thisContext) async {
    showMessage(AppLocalizations.of(context)!.movingUp);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      return;
    }
    // var thisContext = this.context;
    if (scheduleState is ScheduleLoadedState) {
      thisContext.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: scheduleState.subEvents,
          renderedTimelines: scheduleState.timelines,
          renderedScheduleTimeline: scheduleState.lookupTimeline,
          isAlreadyLoaded: true));
    }
    await _subCalendarEventApi.setAsNow((subTile)).then((value) {
      thisContext.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(this.context)!.movedUpToNow));
    }).onError((error, stackTrace) {
      thisContext.read<ScheduleBloc>().add(
          GetSchedule(message: AppLocalizations.of(thisContext)!.movedUpToNow));
    });
  }

  completeTile() async {
    showMessage(AppLocalizations.of(context)!.completing);
    SubCalendarEvent subTile = _subEvent ?? this.widget.subEvent;
    await _subCalendarEventApi.complete((subTile)).then((value) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
          message: AppLocalizations.of(context)!.successfullyCompleted));
    }).onError((error, stackTrace) {
      this.context.read<ScheduleBloc>().add(GetSchedule(
            message: AppLocalizations.of(context)!.successfullyCompleted,
          ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        // if (state is ScheduleLoadedState) {
        //   context.read<ScheduleBloc>().add(GetSchedule(
        //       scheduleTimeline: Utility.initialScheduleTimeline,
        //       isAlreadyLoaded: false,
        //       previousSubEvents: List<SubCalendarEvent>.empty()));
        // }
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
                  onTap: () async {
                    showMessage(AppLocalizations.of(context)!.movingUp);
                    SubCalendarEvent subTile =
                        _subEvent ?? this.widget.subEvent;
                    final scheduleState =
                        this.context.read<ScheduleBloc>().state;
                    if (scheduleState is ScheduleEvaluationState) {
                      return;
                    }

                    if (scheduleState is ScheduleLoadedState) {
                      context.read<ScheduleBloc>().add(EvaluateSchedule(
                          renderedSubEvents: scheduleState.subEvents,
                          renderedTimelines: scheduleState.timelines,
                          renderedScheduleTimeline:
                              scheduleState.lookupTimeline,
                          isAlreadyLoaded: true,
                          callBack: _subCalendarEventApi.setAsNow((subTile))));
                    }
                    // await _subCalendarEventApi
                    //     .setAsNow((subTile))
                    //     .then((value) {
                    //   showMessage(AppLocalizations.of(context)!.addTile);
                    //   context.read<ScheduleBloc>().add(GetSchedule(
                    //       message:
                    //           AppLocalizations.of(this.context)!.movedUpToNow));
                    // }).onError((error, stackTrace) {
                    //   context.read<ScheduleBloc>().add(GetSchedule(
                    //       message: AppLocalizations.of(context)!.movedUpToNow));
                    // });
                  },
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
      },
    );
  }
}
