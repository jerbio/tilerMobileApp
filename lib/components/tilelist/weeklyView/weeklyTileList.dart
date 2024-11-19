import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/components/tilelist/weeklyView/precedingWeeklyTileBatch.dart';
import 'package:tiler_app/components/tilelist/weeklyView/weeklyTileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WeeklyTileList extends TileList {

  static final String routeName = '/WeeklyTileList';
  WeeklyTileList();


  @override
  _WeeklyTileListState createState() => _WeeklyTileListState();
}

class _WeeklyTileListState extends TileListState {
  List<Widget> rowItems = [];

  @override
  void initState() {
    super.initState();
    initializingSwipingAnimation();
    final weeklyState = context.read<WeeklyUiDateManagerBloc>().state;
    timeLine = Timeline.fromDateTime(
        weeklyState.selectedWeek.first,
        weeklyState.selectedWeek.last.add(Duration(days: 1))
    );
    incrementalTilerScrollId= "weekly-incremental-get-schedule";
  }

  reloadSchedule({required List<DateTime> dateManageSelectedWeek}) {
    var scheduleSubEventState = this.context
        .read<ScheduleBloc>()
        .state;
    DateTime startDateTime = dateManageSelectedWeek.first;
    DateTime endDateTime = dateManageSelectedWeek.last.add(Duration(days: 1));
    Timeline previousTimeLine = timeLine;
    List<SubCalendarEvent> subEvents = [];
    if (scheduleSubEventState is ScheduleLoadedState) {
      subEvents = scheduleSubEventState.subEvents;
      previousTimeLine = scheduleSubEventState.lookupTimeline;
    }
    if (scheduleSubEventState is ScheduleEvaluationState) {
      subEvents = scheduleSubEventState.subEvents;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.lookupTimeline);
    }
    if (scheduleSubEventState is ScheduleLoadingState) {
      subEvents = scheduleSubEventState.subEvents;
      previousTimeLine =
          Timeline.fromTimeRange(scheduleSubEventState.previousLookupTimeline);
    }
    Timeline queryTimeline = Timeline.fromDateTime(startDateTime, endDateTime);
    this.context.read<ScheduleBloc>().add(GetScheduleEvent(
      previousSubEvents: subEvents,
      previousTimeline: previousTimeLine,
      scheduleTimeline: queryTimeline,));
    refreshScheduleSummary(lookupTimeline: queryTimeline);
  }

  List<Widget> buildRows(Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData){
    List<Widget> rowItems = [];
    List<DateTime> selectedWeek = context.read<WeeklyUiDateManagerBloc>().state.selectedWeek;
    int todayDayIndex = Utility.getDayIndex(DateTime.now());
    rowItems = selectedWeek.map<Widget>((selectedDate) {
      int selectedDateIndex = Utility.getDayIndex(selectedDate);
      if (selectedDateIndex < todayDayIndex) {
        return PrecedingWeeklyTileBatch(
          dayIndex: selectedDateIndex,
          key: Key("weekly_" + selectedDateIndex.toString()),
        );
      } else {
        List<TilerEvent> tilesForDay;
        if(todayDayIndex==selectedDateIndex) {
          tilesForDay = tileData!.item2
              .where((tile) => todayTimeLine.isInterfering(tile))
              .toList();
        }else {
          tilesForDay = tileData!.item2
              .where((tile) =>
          Utility.getDayIndex(tile.startTime.dayDate) ==
              selectedDateIndex)
              .toList();
        }
        return WeeklyTileBatch(
          dayIndex: selectedDateIndex,
          tiles: tilesForDay,
          key: Key("weekly_" + selectedDateIndex.toString()),
        );
      }
    }).toList();
    return rowItems;
  }

  Widget buildWeeklyRenderSubCalendarTiles(Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    List<Widget> rowItems = buildRows(tileData);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        setState(() {
          swipeDirection = details.primaryVelocity! > 0 ? 1 : -1;
        });
        swipingAnimationController?.forward().then((_) {
          final weeklyUiState = context.read<WeeklyUiDateManagerBloc>().state;
          DateTime newWeek=weeklyUiState.selectedDate.dayDate;
          if (swipeDirection < 0) {
            newWeek=DateTime(newWeek.year,newWeek.month,newWeek.day+7);
          } else if (swipeDirection > 0) {
            newWeek=DateTime(newWeek.year,newWeek.month,newWeek.day-7);
          }
          context.read<WeeklyUiDateManagerBloc>().add(
              UpdateSelectedWeek(
                  selectedDate: newWeek));
          swipingAnimationController?.reset();
        });
      },
      child:  AnimatedBuilder(
        animation: swipingAnimationController!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              swipeDirection * swipingAnimation!.value * MediaQuery.of(context).size.width,
              0,
            ),
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.only(top: 200, right: 10, left: 10),
          child: RefreshIndicator(
            onRefresh: handleRefresh,
            child: ListView(
              scrollDirection: Axis.vertical,
              physics: AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: rowItems,
                ),
                MediaQuery.of(context).orientation == Orientation.landscape
                    ? TileStyles.bottomLandScapePaddingForTileBatchListOfTiles
                    : TileStyles.bottomPortraitPaddingForTileBatchListOfTiles,
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<WeeklyUiDateManagerBloc, WeeklyUiDateManagerState>(
            listenWhen: (previous, current) => !listEquals(previous.selectedWeek, current.selectedWeek),
            listener: (context, state) {
              reloadSchedule(dateManageSelectedWeek: state.selectedWeek);
            }
        ),
        BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
          listener: (context, state) {
            showSubEventModal(state);
          },
        ),
      ],
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          final summaryState = context.watch<ScheduleSummaryBloc>().state;

          if(summaryState is ScheduleDaySummaryLoading &&
              !isAutoRefresh &&
              !isManualRefreshed) {
            isManualRefreshed = false;
            return renderPending();
          }

          if (state is ScheduleInitialState) {
            context.read<ScheduleBloc>().add(GetScheduleEvent(
                scheduleTimeline: timeLine,
                previousSubEvents: List<SubCalendarEvent>.empty()));
            refreshScheduleSummary(lookupTimeline: timeLine);
            return renderPending();
          }
          if (state is ScheduleLoadedState) {
            if (!(state is DelayedScheduleLoadedState)) {
              handleNotificationsAndNextTile(state.subEvents);
            }
            return Stack(
              children: [
                buildWeeklyRenderSubCalendarTiles(Tuple2(state.timelines, state.subEvents))
              ],
            );
          }
          if (state is ScheduleLoadingState) {
            bool showPendingUI = !state.isAlreadyLoaded;
            if(state.currentView==AuthorizedRouteTileListPage.Weekly){
              List<DateTime> weeklyDateMangerSelectedWeek = this.context.read<WeeklyUiDateManagerBloc>().state.selectedWeek;
              Timeline weeklySelectedTimeline=Timeline.fromDateTime(weeklyDateMangerSelectedWeek.first, weeklyDateMangerSelectedWeek.last.add(Duration(days:1)));
              showPendingUI=showPendingUI || !(state.previousLookupTimeline.isStartAndEndEqual(weeklySelectedTimeline));
            }
            if (showPendingUI ) {
              {
                isManualRefreshed=false;
                return renderPending();
              }
            }
            return Stack(children: [
              buildWeeklyRenderSubCalendarTiles(Tuple2(state.timelines, state.subEvents))
            ]);
          }

          if (state is ScheduleEvaluationState) {
            return Stack(
              children: [
                buildWeeklyRenderSubCalendarTiles(Tuple2(state.timelines, state.subEvents)),
                PendingWidget(
                  imageAsset: TileStyles.evaluatingScheduleAsset,
                ),
              ],
            );
          }
          return Text(AppLocalizations.of(context)!.retrievingDataIssue);

        },
      ),
    );
  }
}