import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  EditDateAndTime? _editDateAndTime;
   
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

  Future<SubCalendarEvent> subEventUpdate() {final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    return this.subCalendarEventApi.getSubEvent(this.subEvent!.id!).then((value) {
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
    if (editTilerEvent!=null) {
      EditTilerEvent revisedEditTilerEvent = editTilerEvent!;
      if (_editTileName!=null) {
        revisedEditTilerEvent.name = _editTileName!.name;
      }
      if (_editDateAndTime!=null && _editDateAndTime!.time!=null) {
        revisedEditTilerEvent.endTime = _editDateAndTime!.time!.toUtc();
      }
      if (splitCountController!=null && splitCountController != null) {
        revisedEditTilerEvent.splitCount = int.tryParse(splitCountController!.text);
      }
      updateProceed ();
      setState(() {
        editTilerEvent = revisedEditTilerEvent;
      });
    }
    
  }

  void updateProceed () {
    if(editTilerEvent!=null) {
      if(editTilerEvent!.isValid) {
        if(!Utility.isEditTileEventEquivalentToTileEvent(editTilerEvent!, this.subEvent!)) {
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
        if(state is SubCalendarTileLoadedState)
        setState(() {
          if(subEvent==null){
          subEvent = state.subEvent;
          editTilerEvent = new EditTilerEvent();
          editTilerEvent!.endTime = subEvent!.endTime!;
          editTilerEvent!.startTime = subEvent!.startTime!;
          editTilerEvent!.splitCount = subEvent!.split;
          editTilerEvent!.name = subEvent!.name!;
          if(subEvent!.calendarEvent != null) {
            splitCount = subEvent!.calendarEvent!.split;
            splitCountController = TextEditingController(text: splitCount!.toString());
            splitCountController!.addListener(onInputCountChange);
            editTilerEvent!.splitCount = splitCount;  
          }}
        });
      },
      child: BlocBuilder<SubCalendarTileBloc, SubCalendarTileState>(
        builder: (context, state) {
          if (state is SubCalendarTilesInitialState ||
              state is SubCalendarTilesLoadingState) {
            return PendingWidget();
          }
          _editTileName = EditTileName(subEvent: this.subEvent!, onInputChange: dataChange,);
          _editDateAndTime = EditDateAndTime(subEvent: this.subEvent!, onInputChange: dataChange,);
          return Container(
            child: Column(
              children: [
                _editTileName!,
                _editDateAndTime!,
                TextField(
                  keyboardType: TextInputType.number,
                  controller: splitCountController,)],
                
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
