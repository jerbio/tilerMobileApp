import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
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
      if (_editTileName != null) {
        revisedEditTilerEvent.name = _editTileName!.name;
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

  void updateProceed() {
    if (editTilerEvent != null) {
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
          if (state is SubCalendarTileLoadedState)
            setState(() {
              if (subEvent == null) {
                subEvent = state.subEvent;
                editTilerEvent = new EditTilerEvent();
                editTilerEvent!.endTime = subEvent!.endTime!;
                editTilerEvent!.startTime = subEvent!.startTime!;
                editTilerEvent!.splitCount = subEvent!.split;
                editTilerEvent!.name = subEvent!.name!;
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
        },
        child: BlocBuilder<SubCalendarTileBloc, SubCalendarTileState>(
          builder: (context, state) {
            if (state is SubCalendarTilesInitialState ||
                state is SubCalendarTilesLoadingState ||
                this.subEvent == null) {
              return PendingWidget();
            }
            _editTileName = EditTileName(
              subEvent: this.subEvent!,
              onInputChange: dataChange,
            );
            _editStartDateAndTime = EditDateAndTime(
              time: this.subEvent!.startTime!.toLocal(),
              onInputChange: dataChange,
            );
            _editEndDateAndTime = EditDateAndTime(
              time: this.subEvent!.endTime!.toLocal(),
              onInputChange: dataChange,
            );
            _editCalStartDateAndTime = EditDateAndTime(
              time: this.subEvent!.calendarEventStartTime!.toLocal(),
              onInputChange: dataChange,
            );
            _editCalEndDateAndTime = EditDateAndTime(
              time: this.subEvent!.calendarEventEndTime!.toLocal(),
              onInputChange: dataChange,
            );
            return Container(
              child: Column(
                children: [
                  _editTileName!,
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.start),
                      _editStartDateAndTime!
                    ],
                  ),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.end),
                      _editEndDateAndTime!
                    ],
                  ),
                  Row(
                    children: [
                      Text(AppLocalizations.of(context)!.deadline),
                      _editCalEndDateAndTime!
                    ],
                  ),
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: splitCountController,
                  )
                ],
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
