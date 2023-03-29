import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class EditTile extends StatefulWidget {
  String tileId;
  EditTile({required this.tileId});

  @override
  _EditTileState createState() => _EditTileState();
}

class _EditTileState extends State<EditTile> {
  SubCalendarEvent? subEvent;
  TextEditingController? splitCountController;
  EditTilerEvent? editTilerEvent;
  Function? onProceed;
  int? splitCount;
  SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  EditTileName? _editTileName;
  EditTileNnote? _editTileNote;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;
  EditDateAndTime? _editCalStartDateAndTime;
  EditDateAndTime? _editCalEndDateAndTime;

  @override
  void initState() {
    super.initState();
    this
        .context
        .read<SubCalendarTileBloc>()
        .add(GetSubCalendarTileBlocEvent(subEventId: this.widget.tileId));
  }

  void onInputCountChange() {
    dataChange();
  }

  void onOtherCountChange() {
    dataChange();
  }

  Future<SubCalendarEvent> subEventUpdate() {
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    return this
        .subCalendarEventApi
        .updateSubEvent(this.editTilerEvent!)
        .then((value) {
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetSchedule(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
      }
      return value;
    });
  }

  void dataChange() {
    if (editTilerEvent != null) {
      EditTilerEvent revisedEditTilerEvent = editTilerEvent!;
      if (_editTileName != null && !isProcrastinateTile) {
        revisedEditTilerEvent.name = _editTileName!.name;
      }
      if (_editTileNote != null) {
        revisedEditTilerEvent.note = _editTileNote!.tileNote;
      }
      if (_editStartDateAndTime != null &&
          _editStartDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.startTime =
            _editStartDateAndTime!.dateAndTime!.toUtc();
      }

      if (_editEndDateAndTime != null &&
          _editEndDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.endTime =
            _editEndDateAndTime!.dateAndTime!.toUtc();
      }

      if (_editCalStartDateAndTime != null &&
          _editCalStartDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.calStartTime =
            _editCalStartDateAndTime!.dateAndTime!.toUtc();
      }

      if (_editCalEndDateAndTime != null &&
          _editCalEndDateAndTime!.dateAndTime != null) {
        revisedEditTilerEvent.calEndTime =
            _editCalEndDateAndTime!.dateAndTime!.toUtc();
      }

      if (splitCountController != null && splitCountController != null) {
        revisedEditTilerEvent.splitCount =
            int.tryParse(splitCountController!.text);
      }
      updateProceed();
      setState(() {
        editTilerEvent = revisedEditTilerEvent;
      });
    }
  }

  bool get isProcrastinateTile {
    return (this.subEvent!.isProcrastinate ?? false);
  }

  bool get isRigidTile {
    return (this.subEvent!.isProcrastinate ?? false);
  }

  void updateProceed() {
    if (editTilerEvent != null) {
      if (isProcrastinateTile) {
        bool timeIsTheSame =
            editTilerEvent!.startTime!.toLocal().millisecondsSinceEpoch ==
                    subEvent!.startTime!.toLocal().millisecondsSinceEpoch &&
                editTilerEvent!.endTime!.toLocal().millisecondsSinceEpoch ==
                    subEvent!.endTime!.toLocal().millisecondsSinceEpoch;

        bool isValidTimeFrame = Utility.utcEpochMillisecondsFromDateTime(
                editTilerEvent!.startTime!) <
            Utility.utcEpochMillisecondsFromDateTime(editTilerEvent!.endTime!);
        if (!timeIsTheSame && isValidTimeFrame) {
          setState(() {
            onProceed = subEventUpdate;
          });
          return;
        }
      }
      if (editTilerEvent!.isValid) {
        if (!Utility.isEditTileEventEquivalentToSubCalendarEvent(
            editTilerEvent!, this.subEvent!)) {
          setState(() {
            onProceed = subEventUpdate;
          });
          return;
        }
      }
    }
    setState(() {
      onProceed = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      child: BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
        listener: (context, state) {
          if (state is SubCalendarTileLoadedState) {
            setState(() {
              if (subEvent == null) {
                subEvent = state.subEvent;
                editTilerEvent = new EditTilerEvent();
                editTilerEvent!.endTime = subEvent!.endTime!;
                editTilerEvent!.startTime = subEvent!.startTime!;
                editTilerEvent!.splitCount = subEvent!.split;
                editTilerEvent!.name = subEvent!.name ?? '';
                editTilerEvent!.thirdPartyId = subEvent!.thirdpartyId;
                editTilerEvent!.thirdPartyType = subEvent!.thirdpartyType;
                editTilerEvent!.thirdPartyUserId = subEvent!.thirdPartyUserId;
                editTilerEvent!.id = subEvent!.id;
                if (subEvent!.noteData != null) {
                  editTilerEvent!.note = subEvent!.noteData!.note;
                }
                if (subEvent!.calendarEvent != null) {
                  splitCount = subEvent!.calendarEvent!.split;
                  splitCountController =
                      TextEditingController(text: splitCount!.toString());
                  splitCountController!.addListener(onInputCountChange);
                  editTilerEvent!.splitCount = splitCount;
                }
              }
            });
          }
        },
        child: BlocBuilder<SubCalendarTileBloc, SubCalendarTileState>(
          builder: (context, state) {
            if (state is SubCalendarTilesInitialState ||
                state is SubCalendarTilesLoadingState ||
                this.subEvent == null) {
              return PendingWidget();
            }
            String tileName =
                this.editTilerEvent?.name ?? this.subEvent!.name ?? '';
            _editTileName = EditTileName(
              tileName: tileName,
              isProcrastinate: isProcrastinateTile,
              onInputChange: dataChange,
            );
            String tileNote = this.editTilerEvent?.note ??
                this.subEvent!.noteData?.note ??
                '';
            _editTileNote = EditTileNnote(
              tileNote: tileNote,
              onInputChange: dataChange,
            );
            DateTime startTime =
                this.editTilerEvent?.startTime ?? this.subEvent!.startTime!;
            _editStartDateAndTime = EditDateAndTime(
              time: startTime,
              onInputChange: dataChange,
            );
            DateTime endTime =
                this.editTilerEvent?.endTime ?? this.subEvent!.endTime!;
            _editEndDateAndTime = EditDateAndTime(
              time: endTime,
              onInputChange: dataChange,
            );
            if (this.subEvent!.calendarEventStartTime != null) {
              DateTime calStartTime = this.editTilerEvent?.calStartTime ??
                  this.subEvent!.calendarEventStartTime!;
              _editCalStartDateAndTime = EditDateAndTime(
                time: calStartTime,
                onInputChange: dataChange,
              );
            }

            if (this.subEvent!.calendarEventEndTime != null) {
              DateTime calEndTime = this.editTilerEvent?.calEndTime ??
                  this.subEvent!.calendarEventEndTime!;
              _editCalEndDateAndTime = EditDateAndTime(
                time: calEndTime,
                onInputChange: dataChange,
              );
            }

            var inputChildWidgets = <Widget>[
              _editTileName!,
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.start,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        _editStartDateAndTime!
                      ],
                    ),
                  )),
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.end,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        _editEndDateAndTime!
                      ],
                    ),
                  )),
            ];

            if (!isRigidTile && !isProcrastinateTile) {
              Widget splitWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          child: Text(AppLocalizations.of(context)!.split,
                              style: TextStyle(
                                  color: Color.fromRGBO(31, 31, 31, 1),
                                  fontSize: 15,
                                  fontFamily: TileStyles.rubikFontName,
                                  fontWeight: FontWeight.w500)),
                        ),
                        Container(
                          margin: const EdgeInsets.fromLTRB(45, 0, 0, 0),
                          width: 50,
                          child: TextField(
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            controller: splitCountController,
                          ),
                        )
                      ],
                    ),
                  ));

              if (_editCalEndDateAndTime != null) {
                Widget deadlineWidget = FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            child: Text(AppLocalizations.of(context)!.deadline,
                                style: TextStyle(
                                    color: Color.fromRGBO(31, 31, 31, 1),
                                    fontSize: 15,
                                    fontFamily: TileStyles.rubikFontName,
                                    fontWeight: FontWeight.w500)),
                          ),
                          _editCalEndDateAndTime!
                        ],
                      ),
                    ));
                inputChildWidgets.add(deadlineWidget);
              }
              inputChildWidgets.insert(1, splitWidget);
            }

            if (_editTileNote != null) {
              inputChildWidgets.add(Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: _editTileNote!));
            }

            List<PlaybackOptions> playbackOptions = [
              PlaybackOptions.Procrastinate,
              PlaybackOptions.Now,
              PlaybackOptions.Delete,
              PlaybackOptions.Complete
            ];
            if (((this.subEvent!.isComplete)) ||
                (!(this.subEvent!.isEnabled))) {
              playbackOptions.remove(PlaybackOptions.Complete);
              playbackOptions.remove(PlaybackOptions.Delete);
              playbackOptions.remove(PlaybackOptions.Now);
              playbackOptions.remove(PlaybackOptions.Procrastinate);
            }
            if ((this.subEvent!.isProcrastinate ?? false)) {
              playbackOptions.remove(PlaybackOptions.Procrastinate);
              playbackOptions.remove(PlaybackOptions.PlayPause);
              playbackOptions.remove(PlaybackOptions.Now);
            }
            PlayBack playBackButton = PlayBack(
              this.subEvent!,
              forcedOption: playbackOptions,
              callBack: (status, response) {
                final currentState = this.context.read<ScheduleBloc>().state;
                if (currentState is ScheduleEvaluationState) {
                  this.context.read<ScheduleBloc>().add(GetSchedule(
                        isAlreadyLoaded: true,
                        previousSubEvents: currentState.subEvents,
                        scheduleTimeline: currentState.lookupTimeline,
                        previousTimeline: currentState.lookupTimeline,
                      ));
                }
                if (currentState is ScheduleLoadedState) {
                  this.context.read<ScheduleBloc>().add(GetSchedule(
                        isAlreadyLoaded: true,
                        previousSubEvents: currentState.subEvents,
                        scheduleTimeline: currentState.lookupTimeline,
                        previousTimeline: currentState.lookupTimeline,
                      ));
                }
                Navigator.pop(context);
              },
            );

            inputChildWidgets.add(playBackButton);

            return Container(
              margin: TileStyles.topMargin,
              alignment: Alignment.topCenter,
              child: ListView(
                children: inputChildWidgets,
              ),
            );
          },
        ),
      ),
      onCancel: () {
        this
            .context
            .read<SubCalendarTileBloc>()
            .add(ResetSubCalendarTileBlocEvent());
      },
      onProceed: this.onProceed,
    );
  }
}
