import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';
import 'package:tiler_app/services/api/tileNameApi.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_spacing.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';

import '../../bloc/calendarTiles/calendar_tile_bloc.dart';
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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late  TileThemeExtension tileThemeExtension;
  late TileNameApi tileNameApi;
  late CalendarEventApi calendarEventApi;
  TextEditingController textController = TextEditingController();
  List<Widget> nameSearchResult = [];
  LookupStatus _lookupStatus = LookupStatus.NotStarted;

  @override
  void initState() {
    super.initState();
    calendarEventApi = new CalendarEventApi(getContextCallBack: () => context);
    tileNameApi = new TileNameApi(getContextCallBack: () => context);
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;

  }
  Tuple4<List<SubCalendarEvent>, List<Timeline>, Timeline, ScheduleStatus>
      getPriorStateVariables() {
    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = new ScheduleStatus();
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleLoadedState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleEvaluationState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      lookupTimeline = scheduleState.lookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    if (scheduleState is ScheduleLoadingState) {
      renderedSubEvents = scheduleState.subEvents;
      timeLines = scheduleState.timelines;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    return Tuple4(renderedSubEvents, timeLines, lookupTimeline, scheduleStatus);
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
        AnalysticsSignal.send('NAME_SEARCH_SETASNOW_REQUEST');
        return this.calendarEventApi.setAsNow(tileId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          print("Error in eventname search on setAsNow callback");
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                scheduleStatus: scheduleState.scheduleStatus,
                previousLookupTimeline: scheduleState.previousLookupTimeline,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };

      var priorState = getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;
      ScheduleStatus scheduleStatus = priorState.item4;

      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          message: message,
          scheduleStatus: scheduleStatus,
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
        AnalysticsSignal.send('NAME_SEARCH_DELETION_REQUEST');
        return this.calendarEventApi.delete(tileId, thirdPartyId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          print("Error in eventname search on delete callback");
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                scheduleStatus: scheduleState.scheduleStatus,
                previousLookupTimeline: scheduleState.previousLookupTimeline,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };
      var priorState = getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;
      var scheduleStatus = priorState.item4;

      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          message: message,
          scheduleStatus: scheduleStatus,
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
        AnalysticsSignal.send('NAME_SEARCH_COMPLETE_REQUEST');
        return this.calendarEventApi.complete(tileId).then((value) {
          this.context.read<ScheduleBloc>().add(GetScheduleEvent());
          refreshScheduleSummary();
        }).onError((error, stackTrace) {
          print("Error in eventname search on complete callback");
          if (scheduleState is ScheduleEvaluationState) {
            this.context.read<ScheduleBloc>().add(ReloadLocalScheduleEvent(
                subEvents: scheduleState.subEvents,
                timelines: scheduleState.timelines,
                scheduleStatus: scheduleState.scheduleStatus,
                previousLookupTimeline: scheduleState.previousLookupTimeline,
                lookupTimeline: scheduleState.lookupTimeline));
          }
        });
      };
      var priorState = getPriorStateVariables();
      List<SubCalendarEvent> renderedSubEvents = priorState.item1;
      List<Timeline> timeLines = priorState.item2;
      Timeline lookupTimeline = priorState.item3;
      var scheduleStatus = priorState.item4;
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          renderedSubEvents: renderedSubEvents,
          renderedTimelines: timeLines,
          renderedScheduleTimeline: lookupTimeline,
          isAlreadyLoaded: true,
          scheduleStatus: scheduleStatus,
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

  Widget _createActionButton({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
        height: 70,
        decoration: BoxDecoration(
          color: tileThemeExtension.surfaceContainerUltimate.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: tileThemeExtension.shadowSearch.withValues(alpha: 0.2),
              spreadRadius: 5,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: iconColor),
            SizedBox.square(dimension: 5),
            Text(
                text,
                style: TextStyle(
                  fontSize: 15
                )
            ),
          ],
        ),
      ),
    );
  }

  Widget createDeletionButton(TilerEvent tile) {
    return _createActionButton(
      icon: Icons.clear_rounded,
      iconColor: colorScheme.onError,
      text: AppLocalizations.of(context)!.delete,
      onTap: () => createDeletionCallBack(tile.id!, tile.thirdpartyId ?? "")!,
    );
  }

  Widget createCompletionButton(TilerEvent tile) {
    return _createActionButton(
      icon: Icons.check,
      iconColor: TileColors.completedGreen,
      text: AppLocalizations.of(context)!.done,
      onTap: () => createCompletionCallBack(tile.id!)!,
    );
  }

  Widget createSetAsNowButton(TilerEvent tile) {
    return _createActionButton(
      icon:   FontAwesomeIcons.chevronUp,
      iconColor: colorScheme.onSurface,
      text: AppLocalizations.of(context)!.now,
      onTap: () =>createSetAsNowCallBack(tile.id!)!,
    );
  }

  Widget tileToEventNameWidget(TilerEvent tile) {
      final textStyle= TextStyle(
          fontSize: 12,
          fontFamily: TileTextStyles.rubikFontName
      );
    List<Widget> childWidgets = [];
    Widget textContainer;
    if (tile.name != null) {
      if (tile.start != null && tile.end != null) {
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
                  style: textStyle),
              Text(': ',
                  style: textStyle
              ),
              Text(monthString,
                  style: textStyle
                ),
              Text(' ',
                  style: TextStyle(
                      fontSize: 25,
                      fontFamily: TileTextStyles.rubikFontName),
              ),
              Text(end.day.toString(),
                  style: textStyle
              ),
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
                      fontFamily: TileTextStyles.rubikFontName
                  )

              ),
          ),
        ]
        ),
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
            color: colorScheme.onSurface,
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
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20)),
          border: Border.all(
            color: tileThemeExtension.surfaceContainerUltimate.withValues(alpha: 0.1),
            width: 2,
          ),
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
      AnalysticsSignal.send('NAME_SEARCH_REQUEST_RECEIVED');
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
                    backgroundColor: colorScheme.inverseSurface,
                    textColor: colorScheme.onInverseSurface,
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
                style: TileTextStyles.fullScreenTextFieldStyle,
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: true,
                  isDense: true,
                  hintStyle: TextStyle(
                      color: tileThemeExtension.onSurfaceHint,
                      fontSize: TileDimensions.textFontSize,
                      fontFamily: TileTextStyles.rubikFontName,
                      fontWeight: FontWeight.w500
                     ),
                  contentPadding: TileSpacing.inputFieldPadding,
                  fillColor: colorScheme.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: TileDimensions.inputFieldBorderRadius,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: TileDimensions.inputFieldBorderRadius,
                    borderSide: BorderSide(color: colorScheme.onInverseSurface, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: TileDimensions.inputFieldBorderRadius,
                    borderSide: BorderSide(
                      color: colorScheme.onInverseSurface,
                      width: 1.5,
                    ),
                  ),
                ));
            //ey: none of those hsl colors used
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
              backgroundColor: TileStyles.defaultBackgroundColor,
              body: Container(
                  margin: TileSpacing.topMargin,
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
                  decoration: TileDecorations.defaultBackground,),
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
