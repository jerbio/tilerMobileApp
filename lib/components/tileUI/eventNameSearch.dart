import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/src/painting/gradient.dart' as paintGradient;
import 'package:tuple/tuple.dart';

import '../../bloc/calendarTiles/calendar_tile_bloc.dart';
import '../../styles.dart';
import '../../constants.dart' as Constants;

class EventNameSearchWidget extends SearchWidget {
  EventNameSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      context,
      renderBelowTextfield = true,
      Key? key})
      : super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            key: key);
  @override
  EventNameSearchState createState() => EventNameSearchState();
}

enum LookupStatus { NotStarted, Pending, Finished, Failed }

class EventNameSearchState extends SearchWidgetState {
  TileNameApi tileNameApi = new TileNameApi();
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  TextEditingController textController = TextEditingController();
  List<Widget> nameSearchResult = [];
  LookupStatus _lookupStatus = LookupStatus.NotStarted;

  Tuple3<List<SubCalendarEvent>, List<Timeline>, Timeline>
      getPriorStateVariables() {
    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
    }

    return Tuple3(renderedSubEvents, timeLines, lookupTimeline);
  }

  Function? createSetAsNowCallBack(String tileId) {
    Function retValue = () async {
      final scheduleState = this.context.read<ScheduleBloc>().state;
      if (scheduleState is ScheduleEvaluationState) {
        DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
        if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
          return;
        }
      }

      String message = AppLocalizations.of(context)!.movingUp;
      Function generateCallBack = () {
        return this.calendarEventApi.setAsNow(tileId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };

      Tuple3<List<SubCalendarEvent>, List<Timeline>, Timeline> priorState =
          getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;

      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          message: message,
          callBack: generateCallBack()));
      Navigator.pop(context);
    };
    return retValue;
  }

  Function? createDeletionCallBack(String tileId, String thirdPartyId) {
    Function retValue = () async {
      final scheduleState = this.context.read<ScheduleBloc>().state;
      if (scheduleState is ScheduleEvaluationState) {
        DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
        if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
          return;
        }
      }

      String message = AppLocalizations.of(context)!.deleting;
      Function generateCallBack = () {
        return this.calendarEventApi.delete(tileId, thirdPartyId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };
      Tuple3<List<SubCalendarEvent>, List<Timeline>, Timeline> priorState =
          getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;

      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          message: message,
          callBack: generateCallBack()));
      Navigator.pop(context);
    };
    return retValue;
  }

  Function? createCompletionCallBack(String tileId) {
    Function retValue = () async {
      final scheduleState = this.context.read<ScheduleBloc>().state;
      if (scheduleState is ScheduleEvaluationState) {
        DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
        if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
          return;
        }
      }

      String message = AppLocalizations.of(context)!.completing;
      Function generateCallBack = () {
        return this.calendarEventApi.complete(tileId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };
      Tuple3<List<SubCalendarEvent>, List<Timeline>, Timeline> priorState =
          getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          message: message,
          callBack: generateCallBack()));
      refreshScheduleSummary();
      Navigator.pop(context);
    };
    return retValue;
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  Widget createDeletionButton(TilerEvent tile) {
    Function deletionCallBack =
        createDeletionCallBack(tile.id!, tile.thirdpartyId ?? "")!;
    return GestureDetector(
      onTap: () => {deletionCallBack()},
      child: Container(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          height: 70,
          decoration: BoxDecoration(
            color: Color.fromRGBO(53, 53, 53, 0.1),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Colors.white70.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.clear_rounded,
                size: 20,
                color: Colors.red,
              ),
              SizedBox.square(
                dimension: 5,
              ),
              Text(
                AppLocalizations.of(context)!.delete,
                style: TextStyle(fontSize: 15),
              )
            ],
          )),
    );
  }

  Widget createCompletionButton(TilerEvent tile) {
    Function completionCallBack = createCompletionCallBack(tile.id!)!;
    return GestureDetector(
      onTap: () => {completionCallBack()},
      child: Container(
          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
          height: 70,
          decoration: BoxDecoration(
            color: Color.fromRGBO(53, 53, 53, 0.1),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
                bottomRight: Radius.circular(5)),
            boxShadow: [
              BoxShadow(
                color: Colors.white70.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check,
                size: 20,
                color: Colors.green,
              ),
              SizedBox.square(
                dimension: 5,
              ),
              Text(AppLocalizations.of(context)!.done,
                  style: TextStyle(fontSize: 15))
            ],
          )),
    );
  }

  Widget createSetAsNowButton(TilerEvent tile) {
    Function setAsNowCallBack = createSetAsNowCallBack(tile.id!)!;
    return GestureDetector(
      onTap: () => {setAsNowCallBack()},
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
        height: 70,
        decoration: BoxDecoration(
          color: Color.fromRGBO(53, 53, 53, 0.1),
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(5),
              topRight: Radius.circular(5),
              bottomLeft: Radius.circular(5),
              bottomRight: Radius.circular(5)),
          boxShadow: [
            BoxShadow(
              color: Colors.white70.withOpacity(0.2),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Stack(
            children: [
              Positioned(
                  top: 1,
                  bottom: 0,
                  left: 0,
                  child: IconButton(
                      icon: Transform.rotate(
                        angle: -pi / 2,
                        child: Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                          size: 35,
                        ),
                      ),
                      onPressed: () => {setAsNowCallBack()})),
              Positioned(
                  top: 4,
                  bottom: 0,
                  left: 50,
                  child: Text(AppLocalizations.of(context)!.now,
                      style: TextStyle(fontSize: 15)))
            ],
          ),
        ),
      ),
    );
  }

  Widget tileToEventNameWidget(TilerEvent tile) {
    List<Widget> childWidgets = [];
    Widget textContainer;
    if (tile.name != null) {
      if (tile.start != null && tile.end != null) {
        DateTime start =
            DateTime.fromMillisecondsSinceEpoch(tile.start!.toInt());
        DateTime end = DateTime.fromMillisecondsSinceEpoch(tile.end!.toInt());
        String monthString = Utility.returnMonth(end);
        monthString = monthString.substring(0, 3);
        Widget deadlineContainer = Container(
          margin: EdgeInsets.fromLTRB(20, 45, 20, 30),
          alignment: Alignment.topRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.deadline,
                  style: TextStyle(
                      fontSize: 12, fontFamily: TileStyles.rubikFontName)),
              Text(': ',
                  style: TextStyle(
                      fontSize: 12, fontFamily: TileStyles.rubikFontName)),
              Text(monthString,
                  style: TextStyle(
                      fontSize: 12, fontFamily: TileStyles.rubikFontName)),
              Text(' ',
                  style: TextStyle(
                      fontSize: 25, fontFamily: TileStyles.rubikFontName)),
              Text(end.day.toString(),
                  style: TextStyle(
                      fontSize: 12, fontFamily: TileStyles.rubikFontName)),
            ],
          ),
        );
        childWidgets.add(deadlineContainer);
      }

      List<Widget> detailWidgets = [];
      textContainer = Container(
        margin: EdgeInsets.fromLTRB(20, 0, 20, 0),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: Text(tile.name!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: TileStyles.rubikFontName)))
        ]),
      );
      detailWidgets.add(textContainer);

      DateTime now = Utility.currentTime();
      Widget completionButton = Expanded(
        child: Padding(
            padding: const EdgeInsets.all(2.0),
            child: createCompletionButton(tile)),
      );
      Widget setAsNowButton = Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: createSetAsNowButton(tile)));
      Widget deletionButton = Expanded(
          child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: createDeletionButton(tile)));

      List<Widget> searchActionButtons = <Widget>[];
      if (!(tile.isRecurring ?? false)) {
        searchActionButtons.add(completionButton);
      }

      if ((!(tile.isRecurring ?? false)) ||
          tile.end! > Utility.utcEpochMillisecondsFromDateTime(now)) {
        searchActionButtons.add(setAsNowButton);
      }

      searchActionButtons.add(deletionButton);

      Widget iconContainer = Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
              widthFactor: 0.95,
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: searchActionButtons,
                ),
              )));

      detailWidgets.add(iconContainer);

      Widget detailContainer = Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        child: Stack(
          children: detailWidgets,
        ),
      );
      childWidgets.add(detailContainer);
    }

    Widget editTileButton = GestureDetector(
      onTap: () {
        if (tile.id != null) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TileDetail(tileId: tile.id!)));
        }
      },
      child: Align(
        alignment: Alignment.topRight,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 10, 10, 0),
          child: Icon(
            Icons.edit_outlined,
            color: TileStyles.defaultTextColor,
            size: 20.0,
          ),
        ),
      ),
    );
    childWidgets.add(editTileButton);

    Widget retValue = GestureDetector(
      onTap: () {},
      child: Container(
        height: 125,
        padding: EdgeInsets.fromLTRB(7, 7, 7, 14),
        margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
        ),
        child: Stack(
          children: childWidgets,
        ),
      ),
    );

    return retValue;
  }

  Future<List<Widget>> _onInputFieldChange(
      String name, Function callBackOnCloseInput) async {
    List<Widget> retValue = [
      Container(
        padding: EdgeInsets.all(10),
        child: Text(
            AppLocalizations.of(this.context)!.atLeastThreeLettersForLookup),
        alignment: Alignment.center,
      )
    ];

    if (name.length > Constants.autoCompleteMinCharLength) {
      List<TilerEvent> tileEvents = await tileNameApi.getTilesByName(name);

      retValue = tileEvents.map((tile) => tileToEventNameWidget(tile)).toList();
      if (retValue.length == 0) {
        retValue = [
          Container(
            child: Text(AppLocalizations.of(context)!.noMatchWasFound),
          )
        ];
      }
    }

    setState(() {
      nameSearchResult = retValue;
    });

    return retValue;
  }

  @override
  Widget build(BuildContext eventNameSearchContext) {
    return BlocBuilder<CalendarTileBloc, CalendarTileState>(
      builder: (context, calendarTileState) {
        return BlocListener<ScheduleBloc, ScheduleState>(
          listener: (context, state) {
            if (state is ScheduleEvaluationState) {
              if (state.message != null) {
                Fluttertoast.showToast(
                    msg: state.message!,
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.SNACKBAR,
                    timeInSecForIosWeb: 1,
                    backgroundColor: Colors.black45,
                    textColor: Colors.white,
                    fontSize: 16.0);
              }
            }
          },
          child: BlocBuilder<ScheduleBloc, ScheduleState>(
              builder: (context, scheduleState) {
            String hintText = AppLocalizations.of(context)!.tileName;
            this.widget.onChanged = this._onInputFieldChange;
            this.widget.resultMargin = EdgeInsets.fromLTRB(0, 70, 0, 0);
            this.widget.textField = TextField(
                autofocus: true,
                controller: textController,
                style: TileStyles.fullScreenTextFieldStyle,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  isDense: true,
                  hintStyle: TextStyle(
                      color: Color.fromRGBO(180, 180, 180, 1),
                      fontSize: TileStyles.textFontSize,
                      fontFamily: TileStyles.rubikFontName,
                      fontWeight: FontWeight.w500),
                  contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                  fillColor: TileStyles.primaryContrastColor,
                  border: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(15.0),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(15.0),
                    ),
                    borderSide:
                        BorderSide(color: TileStyles.textBorderColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(15.0),
                    ),
                    borderSide: BorderSide(
                      color: TileStyles.textBorderColor,
                      width: 1.5,
                    ),
                  ),
                ));
            var hslLightColor =
                HSLColor.fromColor(Color.fromRGBO(0, 194, 237, 1));
            hslLightColor =
                hslLightColor.withLightness(hslLightColor.lightness + 0.4);
            var hslDarkColor =
                HSLColor.fromColor(Color.fromRGBO(0, 119, 170, 1));
            hslDarkColor =
                hslDarkColor.withLightness(hslDarkColor.lightness + 0.4);

            this.widget.resultBoxDecoration = BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.transparent, Colors.transparent]));

            return Scaffold(
              resizeToAvoidBottomInset: false,
              body: Container(
                  margin: TileStyles.topMargin,
                  alignment: Alignment.topCenter,
                  child:
                      Stack(alignment: Alignment.topCenter, children: <Widget>[
                    FractionallySizedBox(
                      widthFactor: 0.825,
                      child: super.build(context),
                    ),
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(0, 30, 0, 0),
                        child: BackButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    )
                  ]),
                  decoration: TileStyles.defaultBackground),
            );
          }),
        );
      },
    );
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
