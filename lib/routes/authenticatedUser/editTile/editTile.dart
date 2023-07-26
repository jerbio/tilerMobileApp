import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lottie/lottie.dart';

import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/components/tileUI/tileProgress.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/preview.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/nextTileSuggestionCarousel.dart';
import 'package:tiler_app/routes/authenticatedUser/startEndDurationTimeline.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editDateAndTime.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileName.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class EditTile extends StatefulWidget {
  String tileId;
  EditTile({required this.tileId});

  @override
  _EditTileState createState() => _EditTileState();
}

class _EditTileState extends State<EditTile> {
  WhatIfApi whatIfApi = new WhatIfApi();
  SubCalendarEvent? subEvent;
  TextEditingController? splitCountController;
  EditTilerEvent? editTilerEvent;
  Function? onProceed;
  int? splitCount;
  SubCalendarEventApi subCalendarEventApi = new SubCalendarEventApi();
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  bool isPendingSubEventProcessing = false;
  EditTileName? _editTileName;
  Widget? bottomWidget;

  EditTileNote? _editTileNote;
  EditDateAndTime? _editStartDateAndTime;
  EditDateAndTime? _editEndDateAndTime;
  EditDateAndTime? _editCalStartDateAndTime;
  EditDateAndTime? _editCalEndDateAndTime;
  StartEndDurationTimeline? _startEndDurationTimeline;
  bool hideButtons = false;
  List<NextTileSuggestion>? nextTileSuggestions;
  Preview? beforePreview;
  Preview? afterPreview;

  TextStyle labelStyle = const TextStyle(
      color: Color.fromRGBO(31, 31, 31, 1),
      fontSize: 25,
      fontFamily: TileStyles.rubikFontName,
      fontWeight: FontWeight.w500);

  @override
  void initState() {
    super.initState();
    print("Edit sub event with id ${this.widget.tileId}");
    this
        .context
        .read<SubCalendarTileBloc>()
        .add(GetSubCalendarTileBlocEvent(subEventId: this.widget.tileId));

    calendarEventApi.getNextTileSuggestion(this.widget.tileId).then((value) {
      setState(() {
        nextTileSuggestions = value;
      });
    });
  }

  bool isScheduleTimelineReady(EditTilerEvent? editTilerEvent) {
    return editTilerEvent != null &&
        editTilerEvent.startTime != null &&
        editTilerEvent.endTime != null &&
        editTilerEvent.calStartTime != null &&
        editTilerEvent.calEndTime != null;
  }

  Widget renderTardyTiles(List<SubCalendarEvent> tiles) {
    Widget tardyHeader = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context)!.late,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            fontFamily: TileStyles.rubikFontName,
          )),
    );

    if (tiles.isEmpty) {
      return Align(
        alignment: Alignment.center,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
          child: Column(
            children: [
              tardyHeader,
              Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
                child: Container(
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset(
                            'assets/lottie/abstract-waves-circles.json',
                            height: 100),
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color.fromRGBO(255, 255, 255, 0.25),
                                    Color.fromRGBO(255, 255, 255, 0.9),
                                  ])),
                          width: MediaQuery.of(context).size.width *
                              TileStyles.widthRatio,
                          height: 100,
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Text(AppLocalizations.of(context)!.onTime,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 50,
                                fontFamily: TileStyles.rubikFontName,
                              )),
                        ),
                      ],
                    )),
              )
            ],
          ),
        ),
      );
    }

    Widget tardyBodyHeader = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.warning, color: Colors.amberAccent),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tiles.length.toString()),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
        child: Column(
          children: [
            tardyHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                tardyBodyHeader,
                Column(
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  Widget renderListOfTiles(List<SubCalendarEvent> tiles) {
    return Column(
      children: tiles.map<Widget>((e) => renderTile(e)).toList(),
    );
  }

  Widget renderTile(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = OutlinedButton(
      style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Colors.transparent,
          ),
          padding: EdgeInsets.all(0)),
      onPressed: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    EditTile(tileId: subCalendarEventTile.id!)));
      },
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                    height: 20,
                    width: 20,
                    margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                    decoration: BoxDecoration(
                        color: subCalendarEventTile.color ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(5))),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width *
                          TileStyles.widthRatio -
                      190,
                  child: Text(
                    subCalendarEventTile.name!,
                    style: TextStyle(
                      fontFamily: TileStyles.rubikFontName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [renderDate(subCalendarEventTile)],
            ),
          ],
        ),
      ),
    );

    return retValue;
  }

  Widget renderDate(SubCalendarEvent subCalendarEventTile) {
    Widget retValue = Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      width: 110,
      height: 30,
      decoration: BoxDecoration(
          color: Color.fromRGBO(31, 31, 31, 0.05),
          borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(0, 0, 5, 0),
            child: Icon(
              Icons.calendar_month,
              size: 15,
              color: Color.fromRGBO(31, 31, 31, 0.8),
            ),
          ),
          Container(
            child: Text(
              (subCalendarEventTile.calendarEventEndTime ??
                      subCalendarEventTile.startTime)
                  .humanDate,
              style: TextStyle(
                fontSize: 12,
                color: Color.fromRGBO(31, 31, 31, 0.8),
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          ),
        ],
      ),
    );

    return retValue;
  }

  Widget renderUnscheduledTiles(List<SubCalendarEvent> tiles) {
    Widget unscheduledHeader = Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 10),
      alignment: Alignment.centerLeft,
      child: Text(AppLocalizations.of(context)!.unScheduled,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 20,
            fontFamily: TileStyles.rubikFontName,
          )),
    );

    if (tiles.isEmpty) {
      return SizedBox.shrink();
    }

    Widget unscheduledBodyHeader = Container(
      margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.05),
                borderRadius: BorderRadius.circular(20)),
            child: Icon(Icons.error, color: Colors.redAccent),
          ),
          Container(
            margin: EdgeInsets.fromLTRB(20, 0, 0, 0),
            child: Text(
              AppLocalizations.of(context)!.countTile(tiles.length.toString()),
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
          )
        ],
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
        width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
        child: Column(
          children: [
            unscheduledHeader,
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Column(children: [
                unscheduledBodyHeader,
                Column(
                  children: [renderListOfTiles(tiles)],
                )
              ]),
            )
          ],
        ),
      ),
    );
  }

  updatePreviewWidget() {
    setState(() {
      bottomWidget = ElevatedButton(
          onPressed: () {
            if (afterPreview == null) {
              clearPreviewButton();
              return;
            }
            List<SubCalendarEvent> tardySubEvents = [];
            if (afterPreview != null && afterPreview!.tardies != null) {
              tardySubEvents = afterPreview!.tardies!.subEvents
                  .map<SubCalendarEvent>((e) => e as SubCalendarEvent)
                  .toList();
            }

            List<SubCalendarEvent> unScheduledSubEvents = [];
            if (afterPreview != null && afterPreview!.nonViable != null) {
              unScheduledSubEvents =
                  afterPreview!.nonViable!.map<SubCalendarEvent>((e) {
                return e as SubCalendarEvent;
              }).toList();
            }
            if (tardySubEvents.isEmpty && unScheduledSubEvents.isEmpty) {
              clearPreviewButton();
              return;
            }

            showModalBottomSheet<void>(
              context: context,
              builder: (BuildContext context) {
                return Container(
                  height: 300,
                  color: Colors.amber,
                  child: Center(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
                      children: <Widget>[
                        renderTardyTiles(tardySubEvents),
                        renderUnscheduledTiles(unScheduledSubEvents)
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Text(AppLocalizations.of(context)!.prediction));
    });
  }

  clearPreviewButton() {
    setState(() {
      bottomWidget = null;
    });
  }

  void onScheduleTimelineChange() {
    if (editTilerEvent != null && isScheduleTimelineReady(editTilerEvent)) {
      int beforeSplitCount = editTilerEvent!.splitCount ?? 1;
      Timeline beforeStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.startTime!, editTilerEvent!.endTime!);
      Timeline beforeCalStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.calStartTime!, editTilerEvent!.calEndTime!);
      dataChange();
      int afterSplitCount = editTilerEvent!.splitCount ?? 1;
      Timeline afterStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.startTime!, editTilerEvent!.endTime!);
      Timeline afterCalStartToEnd = Timeline.fromDateTime(
          editTilerEvent!.calStartTime!, editTilerEvent!.calEndTime!);
      if ((this.onProceed != null) &&
          isScheduleTimelineReady(editTilerEvent) &&
          editTilerEvent!.splitCount != null &&
          (beforeSplitCount != afterSplitCount ||
              !beforeStartToEnd.isStartAndEndEqual(afterStartToEnd) ||
              !beforeCalStartToEnd.isStartAndEndEqual(afterCalStartToEnd))) {
        whatIfApi.updateSubEvent(editTilerEvent!).then((value) {
          if (value == null) {
            clearPreviewButton();
            return;
          }
          setState(() {
            beforePreview = value.item1;
            afterPreview = value.item2;
          });
          updatePreviewWidget();
        }).catchError((onError) {
          clearPreviewButton();
          print(onError);
        });
      }
    } else {
      dataChange();
      if (this.onProceed == null) {
        clearPreviewButton();
      }
    }
  }

  void onInputCountChange() {
    onScheduleTimelineChange();
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
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
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
    return (this.subEvent!.calendarEvent?.isRigid ??
        this.subEvent!.isRigid ??
        false);
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

  Widget renderNextTileSuggestionContainer() {
    Widget retValue = SizedBox.shrink();
    if (this.nextTileSuggestions != null &&
        this.nextTileSuggestions!.length > 0) {
      return Column(
        children: [
          Container(
            margin: EdgeInsets.fromLTRB(25, 0, 0, 0),
            alignment: Alignment.topLeft,
            child: Text(
              AppLocalizations.of(context)!.suggestions,
              style: this.labelStyle,
            ),
          ),
          NextTileSuggestionCarouselWidget(
              nextTileSuggestions: this.nextTileSuggestions!),
        ],
      );
    }

    return retValue;
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      lookupTimeline =
          lookupTimeline == null ? Utility.todayTimeline() : lookupTimeline;
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
        hideButtons: hideButtons,
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

              final Color textBorderColor =
                  TileStyles.primaryColorLightHSL.toColor();

              Widget? tileProgressWidget;

              final Color textBackgroundColor = TileStyles.textBackgroundColor;
              String tileName =
                  this.editTilerEvent?.name ?? this.subEvent!.name ?? '';
              _editTileName = EditTileName(
                tileName: tileName,
                isProcrastinate: isProcrastinateTile,
                isReadOnly: !this.subEvent!.isActive,
                onInputChange: dataChange,
              );

              BoxDecoration containerClusterStyle = BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(TileStyles.borderRadius),
              );
              var inputChildWidgets = <Widget>[];
              String tileNote = this.editTilerEvent?.note ??
                  this.subEvent!.noteData?.note ??
                  '';
              _editTileNote = EditTileNote(
                tileNote: tileNote,
                onInputChange: dataChange,
                isReadOnly: !this.subEvent!.isActive,
              );
              DateTime startTime =
                  this.editTilerEvent?.startTime ?? this.subEvent!.startTime;
              _editStartDateAndTime = EditDateAndTime(
                time: startTime,
                onInputChange: onScheduleTimelineChange,
              );
              DateTime endTime =
                  this.editTilerEvent?.endTime ?? this.subEvent!.endTime;
              _editEndDateAndTime = EditDateAndTime(
                time: endTime,
                onInputChange: onScheduleTimelineChange,
              );
              if (this.subEvent!.calendarEventStartTime != null) {
                DateTime calStartTime = this.editTilerEvent?.calStartTime ??
                    this.subEvent!.calendarEventStartTime!;
                _editCalStartDateAndTime = EditDateAndTime(
                  time: calStartTime,
                  onInputChange: onScheduleTimelineChange,
                );
              }

              if (this.subEvent!.calendarEventEndTime != null) {
                DateTime calEndTime = this.editTilerEvent?.calEndTime ??
                    this.subEvent!.calendarEventEndTime!;
                _editCalEndDateAndTime = EditDateAndTime(
                  time: calEndTime,
                  onInputChange: onScheduleTimelineChange,
                  isReadOnly: !this.subEvent!.isActive,
                );
              }

              _startEndDurationTimeline = StartEndDurationTimeline.fromTimeline(
                timeRange: this.subEvent!,
                isReadOnly: !this.subEvent!.isActive,
                onChange: (timeline) {
                  onScheduleTimelineChange();
                },
              );
              _startEndDurationTimeline!.headerTextStyle = labelStyle;

              List<Widget> nameAndSplitCluster = <Widget>[
                FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: _editTileName!)
              ];
              List<Widget> durationAndDeadlineCluster = <Widget>[
                FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: _startEndDurationTimeline))
              ];

              if (!isRigidTile && !isProcrastinateTile) {
                Widget splitWidget = FractionallySizedBox(
                    widthFactor: TileStyles.tileWidthRatio,
                    child: Container(
                      height: 80,
                      margin: EdgeInsets.fromLTRB(30, 30, 0, 20),
                      child: Stack(
                        children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(0, 8, 0, 0),
                            height: 50,
                            child: Text(AppLocalizations.of(context)!.split,
                                style: labelStyle),
                          ),
                          Positioned(
                              top: 45,
                              child: Container(
                                child: Text(
                                    AppLocalizations.of(context)!.timeBlocks,
                                    style: const TextStyle(
                                        color: Color.fromRGBO(150, 150, 150, 1),
                                        fontSize: 20,
                                        fontFamily: TileStyles.rubikFontName,
                                        fontWeight: FontWeight.w300)),
                              )),
                          Positioned(
                            top: 0,
                            right: 5,
                            child: Container(
                              width: 100,
                              height: 100,
                              child: TextField(
                                decoration: InputDecoration(
                                  filled: true,
                                  isDense: true,
                                  enabled: this.subEvent!.isActive,
                                  fillColor: Colors.transparent,
                                  border: UnderlineInputBorder(
                                    borderSide:
                                        BorderSide(color: Colors.transparent),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                      borderSide:
                                          BorderSide(color: textBorderColor)),
                                  enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                          color: textBorderColor
                                              .withLightness(0.8))),
                                  contentPadding:
                                      EdgeInsets.fromLTRB(20, 5, 20, 0),
                                ),
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 30),
                                keyboardType: TextInputType.numberWithOptions(
                                    signed: true, decimal: true),
                                controller: splitCountController,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ));

                inputChildWidgets.add(Container(
                    decoration: containerClusterStyle,
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                    child: Stack(
                      children: [
                        Positioned(
                            bottom: -20,
                            right: -20,
                            child: SvgPicture.asset(
                              'assets/iconScout/block.svg',
                              height: 150,
                              colorFilter: ColorFilter.mode(
                                  Color.fromRGBO(0, 0, 0, 0.05),
                                  BlendMode.srcIn),
                            )),
                        splitWidget
                      ],
                    )));
                if (_editCalEndDateAndTime != null) {
                  Widget deadlineWidget = FractionallySizedBox(
                      widthFactor: TileStyles.tileWidthRatio,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              child: Text(
                                  AppLocalizations.of(context)!.deadline,
                                  style: labelStyle),
                            ),
                            _editCalEndDateAndTime!
                          ],
                        ),
                      ));
                  durationAndDeadlineCluster.add(deadlineWidget);
                }
                tileProgressWidget = Container(
                    decoration: containerClusterStyle,
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                    child: Stack(
                      children: [
                        Positioned(
                            bottom: -20,
                            right: -20,
                            child: SvgPicture.asset(
                              'assets/iconScout/chart.svg',
                              height: 150,
                              colorFilter: ColorFilter.mode(
                                  Color.fromRGBO(0, 0, 0, 0.05),
                                  BlendMode.srcIn),
                            )),
                        Column(children: [
                          Container(
                            margin: EdgeInsets.fromLTRB(25, 0, 0, 0),
                            alignment: Alignment.topLeft,
                            child: Text(
                              AppLocalizations.of(context)!.progress,
                              style: this.labelStyle,
                            ),
                          ),
                          TileProgress(
                              calendarEvent: this.subEvent!.calendarEvent!
                                  as CalendarEvent),
                        ])
                      ],
                    ));
              }
              Widget nameAndSplitClusterWrapper = Container(
                decoration: containerClusterStyle,
                margin: EdgeInsets.fromLTRB(0, 10, 0, 20),
                padding: EdgeInsets.fromLTRB(0, 10, 0, 5),
                child: Column(children: nameAndSplitCluster),
              );

              inputChildWidgets.insert(0, nameAndSplitClusterWrapper);

              Widget durationClusterWrapper = Container(
                  decoration: containerClusterStyle,
                  padding: EdgeInsets.fromLTRB(0, 5, 0, 0),
                  child: Stack(children: [
                    Positioned(
                        bottom: -20,
                        right: -20,
                        child: SvgPicture.asset(
                          'assets/iconScout/deadline.svg',
                          height: 150,
                          colorFilter: ColorFilter.mode(
                              Color.fromRGBO(0, 0, 0, 0.05), BlendMode.srcIn),
                        )),
                    Container(
                      alignment: Alignment.center,
                      child: Column(
                        children: durationAndDeadlineCluster,
                      ),
                      margin: EdgeInsets.fromLTRB(0, 0, 0, 30),
                    )
                  ]));

              inputChildWidgets.add(durationClusterWrapper);

              if (_editTileNote != null) {
                inputChildWidgets.add(Container(
                    decoration: containerClusterStyle,
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned(
                          bottom: -20,
                          right: -20,
                          child: SvgPicture.asset(
                            'assets/iconScout/notes.svg',
                            height: 150,
                            colorFilter: ColorFilter.mode(
                                Color.fromRGBO(0, 0, 0, 0.05), BlendMode.srcIn),
                          )),
                      Container(
                        child: _editTileNote!,
                        margin: EdgeInsets.fromLTRB(0, 30, 0, 10),
                      )
                    ])));
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
              Widget playBackButtonWrapper = Container(
                margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
                decoration: containerClusterStyle,
                child: PlayBack(
                  this.subEvent!,
                  forcedOption: playbackOptions,
                  callBack: (status, Future responseFuture) {
                    setState(() {
                      isPendingSubEventProcessing = true;
                      hideButtons = true;
                    });
                    responseFuture.then((value) {
                      if (!this.mounted) {
                        return value;
                      }
                      setState(() {
                        isPendingSubEventProcessing = false;
                        hideButtons = false;
                      });
                      final currentState =
                          this.context.read<ScheduleBloc>().state;
                      if (currentState is ScheduleEvaluationState) {
                        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                        refreshScheduleSummary(currentState.lookupTimeline);
                      }
                      if (currentState is ScheduleLoadedState) {
                        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                              isAlreadyLoaded: true,
                              previousSubEvents: currentState.subEvents,
                              scheduleTimeline: currentState.lookupTimeline,
                              previousTimeline: currentState.lookupTimeline,
                            ));
                        refreshScheduleSummary(currentState.lookupTimeline);
                      }
                      Navigator.pop(context);
                      return value;
                    });
                  },
                ),
              );

              if (this.nextTileSuggestions != null &&
                  this.nextTileSuggestions!.length > 0) {
                Widget nextTileSuggestionWrapper = Container(
                    padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                    decoration: containerClusterStyle,
                    child: renderNextTileSuggestionContainer());
                inputChildWidgets.add(nextTileSuggestionWrapper);
              }
              if (subEvent!.isActive) {
                inputChildWidgets.add(playBackButtonWrapper);
              }
              if (tileProgressWidget != null) {
                inputChildWidgets.add(tileProgressWidget);
              }

              List<Widget> stackElements = <Widget>[
                Container(
                  color: TileStyles.primaryColorLightHSL
                      .toColor()
                      .withLightness(0.95),
                  padding: EdgeInsets.fromLTRB(30, 0, 30, 100),
                  alignment: Alignment.topCenter,
                  child: ListView(
                    children: inputChildWidgets,
                  ),
                )
              ];

              if (isPendingSubEventProcessing) {
                stackElements.add(PendingWidget());
              }
              return Stack(
                children: stackElements,
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
        bottomWidget: this.bottomWidget,
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
        ));
  }

  @override
  void dispose() {
    if (splitCountController != null) {
      splitCountController!.dispose();
    }
    super.dispose();
  }
}
