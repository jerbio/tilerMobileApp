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
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/routes/authenticatedUser/startEndDurationTimeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
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
  EditDateAndTime? _editCalStartDateAndTime;
  EditDateAndTime? _editCalEndDateAndTime;
  StartEndDurationTimeline? _startEndDurationTimeline;

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

      if (_startEndDurationTimeline != null) {
        TimeRange timeRange = _startEndDurationTimeline!.timeRange;
        revisedEditTilerEvent.startTime = timeRange.startTime;
        revisedEditTilerEvent.endTime = timeRange.endTime;
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
                    subEvent!.startTime.toLocal().millisecondsSinceEpoch &&
                editTilerEvent!.endTime!.toLocal().millisecondsSinceEpoch ==
                    subEvent!.endTime.toLocal().millisecondsSinceEpoch;

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
                editTilerEvent!.endTime = subEvent!.endTime;
                editTilerEvent!.startTime = subEvent!.startTime;
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

            DateTime calStartTime = this.editTilerEvent?.calStartTime ??
                this.subEvent!.calendarEventStartTime!;
            _editCalStartDateAndTime = EditDateAndTime(
              time: calStartTime,
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

            _startEndDurationTimeline = StartEndDurationTimeline.fromTimeline(
              timeRange: this.subEvent!,
              onChange: (timeline) {
                dataChange();
              },
            );

            var inputChildWidgets = <Widget>[
              _editTileName!,
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                      child: _startEndDurationTimeline)),
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

            List<PlaybackOptions> playbackOptions = [
              PlaybackOptions.Procrastinate,
              PlaybackOptions.Now,
              PlaybackOptions.Delete,
              PlaybackOptions.Complete
            ];
            if (((this.subEvent!.isComplete ?? false)) ||
                (!(this.subEvent!.isEnabled ?? true))) {
              playbackOptions.remove(PlaybackOptions.Complete);
              playbackOptions.remove(PlaybackOptions.Delete);
              playbackOptions.remove(PlaybackOptions.Now);
              playbackOptions.remove(PlaybackOptions.Procrastinate);
            }
            if ((this.subEvent!.isProcrastinate ?? false)) {
              playbackOptions.remove(PlaybackOptions.Procrastinate);
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
              child: Column(
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
