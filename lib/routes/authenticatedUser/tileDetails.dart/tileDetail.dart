import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/routes/authenticatedUser/tileCarousel.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

class TileDetail extends StatefulWidget {
  String tileId;
  TileDetail({required this.tileId});

  @override
  State<StatefulWidget> createState() => _TileDetailState();
}

class _TileDetailState extends State<TileDetail> {
  CalendarEvent? calEvent;
  EditTilerEvent? editTilerEvent;
  int? splitCount;
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  TextEditingController? splitCountController;
  EditTileName? _editTileName;
  EditTileNote? _editTileNote;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;
  Function? onProceed;

  @override
  void initState() {
    super.initState();
    this
        .context
        .read<CalendarTileBloc>()
        .add(GetCalendarTileEvent(calEventId: this.widget.tileId));
  }

  void onInputCountChange() {
    dataChange();
  }

  void updateProceed() {
    if (editTilerEvent != null) {
      if (isProcrastinateTile) {
        bool timeIsTheSame =
            editTilerEvent!.startTime!.toLocal().millisecondsSinceEpoch ==
                    calEvent!.startTime!.toLocal().millisecondsSinceEpoch &&
                editTilerEvent!.endTime!.toLocal().millisecondsSinceEpoch ==
                    calEvent!.endTime!.toLocal().millisecondsSinceEpoch;

        bool isValidTimeFrame = Utility.utcEpochMillisecondsFromDateTime(
                editTilerEvent!.startTime!) <
            Utility.utcEpochMillisecondsFromDateTime(editTilerEvent!.endTime!);
        if (!timeIsTheSame && isValidTimeFrame) {
          setState(() {
            onProceed = calEventUpdate;
          });
          return;
        }
      }
      if (editTilerEvent!.isValid) {
        if (!Utility.isEditTileEventEquivalentToCalendarEvent(
            editTilerEvent!, this.calEvent!)) {
          setState(() {
            onProceed = calEventUpdate;
          });
          return;
        }
      }
    }
    setState(() {
      onProceed = null;
    });
  }

  Future<CalendarEvent> calEventUpdate() {
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    return this
        .calendarEventApi
        .updateCalEvent(this.editTilerEvent!)
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
    return (this.calEvent!.isProcrastinate ?? false);
  }

  bool get isRigidTile {
    return (this.calEvent!.isProcrastinate ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      onProceed: this.onProceed,
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.edit,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: BlocListener<CalendarTileBloc, CalendarTileState>(
        listener: (context, state) {
          if (state is CalendarTileLoaded) {
            setState(() {
              if (calEvent == null) {
                calEvent = state.calEvent;
                editTilerEvent = new EditTilerEvent();
                editTilerEvent!.endTime = calEvent!.endTime!;
                editTilerEvent!.startTime = calEvent!.startTime!;
                editTilerEvent!.splitCount = calEvent!.split;
                editTilerEvent!.name = calEvent!.name ?? '';
                editTilerEvent!.thirdPartyId = calEvent!.thirdpartyId;
                editTilerEvent!.thirdPartyType = calEvent!.thirdpartyType;
                editTilerEvent!.thirdPartyUserId = calEvent!.thirdPartyUserId;
                editTilerEvent!.id = calEvent!.id;
                editTilerEvent!.calStartTime = Utility.currentTime();
                editTilerEvent!.calEndTime = Utility.currentTime();
                editTilerEvent!.note = '';
                if (calEvent!.noteData != null) {
                  editTilerEvent!.note = calEvent!.noteData!.note;
                }
                if (calEvent!.split != null) {
                  splitCount = calEvent!.split;
                  splitCountController =
                      TextEditingController(text: splitCount!.toString());
                  splitCountController!.addListener(onInputCountChange);
                  editTilerEvent!.splitCount = splitCount;
                }
              }
            });
          }
        },
        child: BlocBuilder<CalendarTileBloc, CalendarTileState>(
          builder: (context, state) {
            if (state is CalendarTileInitial ||
                state is CalendarTileLoading ||
                this.calEvent == null) {
              return PendingWidget();
            }
            String tileName =
                this.editTilerEvent?.name ?? this.calEvent!.name ?? '';
            _editTileName = EditTileName(
              tileName: tileName,
              isProcrastinate: isProcrastinateTile,
              onInputChange: dataChange,
            );

            DateTime startTime =
                this.editTilerEvent?.startTime ?? this.calEvent!.startTime!;
            _editStartDateAndTime = EditDateAndTime(
              time: startTime,
              onInputChange: dataChange,
            );
            DateTime endTime =
                this.editTilerEvent?.endTime ?? this.calEvent!.endTime!;
            _editEndDateAndTime = EditDateAndTime(
              time: endTime,
              onInputChange: dataChange,
            );

            Widget? tileStartWidget;
            Widget? tileEndWidget;
            Widget? splitWidget;

            var inputChildWidgets = <Widget>[
              FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: _editTileName!),
            ];

            String tileNote = this.editTilerEvent?.note ??
                this.calEvent!.noteData?.note ??
                '';

            _editTileNote = EditTileNote(
              tileNote: tileNote,
              onInputChange: dataChange,
            );
            if (!isRigidTile &&
                !isProcrastinateTile &&
                !this.calEvent!.isRecurring!) {
              splitWidget = FractionallySizedBox(
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

              tileStartWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  ));
              tileEndWidget = FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                  ));
            }

            if (_editTileNote != null) {
              inputChildWidgets.add(Container(
                  margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: _editTileNote!));
            }

            if (splitWidget != null) {
              inputChildWidgets.add(splitWidget);
            }
            if (tileStartWidget != null) {
              inputChildWidgets.add(tileStartWidget);
            }
            if (tileEndWidget != null) {
              inputChildWidgets.add(tileEndWidget);
            }

            if (calEvent!.subEvents != null &&
                calEvent!.subEvents!.length > 0) {
              inputChildWidgets.add(FractionallySizedBox(
                  widthFactor: TileStyles.tileWidthRatio,
                  child: Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: TileCarousel(
                        subEventIds:
                            calEvent!.subEvents!.map((e) => e.id!).toList()),
                  )));
            }

            return Container(
              padding: EdgeInsets.fromLTRB(0, 0, 0, 100),
              margin: TileStyles.topMargin,
              alignment: Alignment.topCenter,
              child: ListView(
                children: inputChildWidgets,
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (splitCountController != null) {
      splitCountController!.dispose();
    }
    super.dispose();
  }
}
