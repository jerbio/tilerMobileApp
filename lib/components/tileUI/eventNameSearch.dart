import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/src/painting/gradient.dart' as paintGradient;

import '../../bloc/calendarTiles/calendar_tile_bloc.dart';
import '../../styles.dart';

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

class EventNameSearchState extends SearchWidgetState {
  TileNameApi tileNameApi = new TileNameApi();
  CalendarEventApi calendarEventApi = new CalendarEventApi();
  TextEditingController textController = TextEditingController();
  List<Widget> nameSearchResult = [];

  Function? createSetAsNowCallBack(String tileId) {
    Function retValue = () async {
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
      this.calendarEventApi.setAsNow(tileId).then((value) {
        this.context.read<ScheduleBloc>().add(GetSchedule());
      }).onError((error, stackTrace) {
        if (scheduleState is ScheduleEvaluationState) {
          this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
              subEvents: scheduleState.subEvents,
              timelines: scheduleState.timelines,
              lookupTimeline: scheduleState.lookupTimeline));
        }
      });
    };
    return retValue;
  }

  Function? createDeletionCallBack(String tileId, String thirdPartyId) {
    Function retValue = () async {
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

      this.calendarEventApi.delete(tileId, thirdPartyId).then((value) {
        this.context.read<ScheduleBloc>().add(GetSchedule());
      }).onError((error, stackTrace) {
        if (scheduleState is ScheduleEvaluationState) {
          this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
              subEvents: scheduleState.subEvents,
              timelines: scheduleState.timelines,
              lookupTimeline: scheduleState.lookupTimeline));
        }
      });
    };
    return retValue;
  }

  Function? createCompletionCallBack(String tileId) {
    Function retValue = () async {
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

      this.calendarEventApi.complete(tileId).then((value) {
        this.context.read<ScheduleBloc>().add(GetSchedule());
      }).onError((error, stackTrace) {
        if (scheduleState is ScheduleEvaluationState) {
          this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
              subEvents: scheduleState.subEvents,
              timelines: scheduleState.timelines,
              lookupTimeline: scheduleState.lookupTimeline));
        }
      });
    };
    return retValue;
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
                      fontWeight: FontWeight.w600,
                      fontFamily: TileStyles.rubikFontName)))
        ]),
      );
      detailWidgets.add(textContainer);
      Function setAsNowCallBack = createSetAsNowCallBack(tile.id!)!;
      Function completionCallBack = createCompletionCallBack(tile.id!)!;
      Function deletionCallBack =
          createDeletionCallBack(tile.id!, tile.thirdpartyId)!;
      Widget iconContainer = FractionallySizedBox(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 60, 0, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => {deletionCallBack()},
                      child: Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          height: 30,
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
                              IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                iconSize: 15,
                                onPressed: () => {deletionCallBack()},
                              ),
                              Text(
                                AppLocalizations.of(context)!.delete,
                                style: TextStyle(fontSize: 10),
                              )
                            ],
                          )),
                    ),
                    GestureDetector(
                      onTap: () => {completionCallBack()},
                      child: Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          height: 30,
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
                              IconButton(
                                icon: const Icon(Icons.check),
                                iconSize: 15,
                                color: Colors.green,
                                onPressed: () => {completionCallBack()},
                              ),
                              Text(AppLocalizations.of(context)!.complete,
                                  style: TextStyle(fontSize: 10))
                            ],
                          )),
                    ),
                    GestureDetector(
                      onTap: () => {setAsNowCallBack()},
                      child: Container(
                          padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                          height: 30,
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
                              IconButton(
                                  icon: Transform.rotate(
                                    angle: -pi / 2,
                                    child: Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                      size: 35,
                                    ),
                                  ),
                                  onPressed: () => {setAsNowCallBack()}),
                              Text(AppLocalizations.of(context)!.now,
                                  style: TextStyle(fontSize: 10))
                            ],
                          )),
                    )
                  ],
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

    Key dismissibleKey = Key(tile.id!);
    Widget retValue = Dismissible(
        key: dismissibleKey,
        child: Container(
          height: 125,
          padding: EdgeInsets.fromLTRB(7, 7, 7, 14),
          margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 5,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            children: childWidgets,
          ),
        ));

    return retValue;
  }

  Future<List<Widget>> _onInputFieldChange(
      String name, Function callBackOnCloseInput) async {
    List<Widget> retValue = this.nameSearchResult;

    if (name.length > 3) {
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
            if (scheduleState is ScheduleLoadingState) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            }

            // this.context.read<ScheduleBloc>().add(GetSchedule());

            // if (calendarTileState is CalendarTileLoaded &&
            //     isPendingScheduleEvaluation &&
            //     scheduleState is ScheduleEvaluationState) {
            //   WidgetsBinding.instance.addPostFrameCallback((_) {
            //     this.context.read<ScheduleBloc>().add(GetSchedule());
            //     Navigator.pop(context);
            //     setState(() {
            //       isPendingScheduleEvaluation = false;
            //     });
            //   });
            // }
            String hintText = AppLocalizations.of(context)!.tileName;
            this.widget.onChanged = this._onInputFieldChange;
            this.widget.resultMargin = EdgeInsets.fromLTRB(0, 70, 0, 0);
            this.widget.textField = TextField(
              controller: textController,
              style: TileStyles.fullScreenTextFieldStyle,
              decoration: TileStyles.generateTextInputDecoration(hintText),
            );
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
                  child: FractionallySizedBox(
                      alignment: FractionalOffset.center,
                      widthFactor: TileStyles.inputWidthFactor,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: super.build(context),
                            )
                          ])),
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
