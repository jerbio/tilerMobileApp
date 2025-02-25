import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tilelist/monthlyView/monthlyTileBatch.dart';
import 'package:tiler_app/components/tilelist/monthlyView/precedingMonthlyTileBatch.dart';
import 'package:tiler_app/components/tilelist/tileList.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MonthlyTileList extends TileList {
  static final String routeName = '/MonthlyTileList';
  MonthlyTileList();

  @override
  _MonthlyTileListState createState() => _MonthlyTileListState();
}

class _MonthlyTileListState extends TileListState {
  @override
  void initState() {
    super.initState();
    initializingSwipingAnimation();
    List<DateTime> daysInMonth =
        Utility.getDaysInMonth(Utility.currentTime().dayDate);
    timeLine = Timeline.fromDateTime(
        daysInMonth.first, daysInMonth.last.add(Duration(days: 1)));
    incrementalTilerScrollId = "monthly-incremental-get-schedule";
  }

  reloadSchedule({required DateTime dateManageSelectedMonth}) {
    List<DateTime> selectedDaysInMonth =
        Utility.getDaysInMonth(dateManageSelectedMonth);
    DateTime startDateTime = selectedDaysInMonth.first;
    DateTime endDateTime = selectedDaysInMonth.last.add(Duration(days: 1));
    Timeline previousTimeLine = timeLine;
    List<SubCalendarEvent> subEvents = [];
    var scheduleSubEventState = this.context.read<ScheduleBloc>().state;
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
          scheduleTimeline: queryTimeline,
        ));
    refreshScheduleSummary(lookupTimeline: queryTimeline);
  }

  List<Widget> generateMonthRows(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    DateTime selectedMonth =
        context.read<MonthlyUiDateManagerBloc>().state.selectedDate.dayDate;
    List<DateTime> selectedDaysInMonth = Utility.getDaysInMonth(selectedMonth);
    int todayDayIndex = Utility.getDayIndex(Utility.currentTime());
    List<Widget> monthRows = [];
    for (int weekStart = 0;
        weekStart < selectedDaysInMonth.length;
        weekStart += 7) {
      List<Widget> weekBatches = [];
      for (int dayIndex = weekStart;
          dayIndex < weekStart + 7 && dayIndex < selectedDaysInMonth.length;
          dayIndex++) {
        DateTime selectedDate = selectedDaysInMonth[dayIndex];
        int selectedDateIndex = Utility.getDayIndex(selectedDate);
        List<TilerEvent> tilesForDay;
        if (todayDayIndex == selectedDateIndex) {
          tilesForDay = tileData!.item2
              .where((tile) => todayTimeLine.isInterfering(tile))
              .toList();
        } else {
          tilesForDay = tileData!.item2
              .where((tile) =>
                  Utility.getDayIndex(tile.startTime.dayDate) ==
                  selectedDateIndex)
              .toList();
        }
        weekBatches.add(
          selectedDateIndex < todayDayIndex
              ? PrecedingMonthlyTileBatch(
                  dayIndex: selectedDateIndex,
                  tiles: tilesForDay,
                  key: Key("monthly_$selectedDateIndex"),
                )
              : MonthlyTileBatch(
                  dayIndex: selectedDateIndex,
                  tiles: tilesForDay,
                  key: Key("monthly_$selectedDateIndex"),
                ),
        );
      }
      monthRows.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: weekBatches.map((batch) => batch).toList(),
      ));
    }
    return monthRows;
  }

  Widget buildMonthlyRenderSubCalendarTiles(
      Tuple2<List<Timeline>, List<SubCalendarEvent>>? tileData) {
    List<Widget> monthRows = generateMonthRows(tileData);
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        setState(() {
          swipeDirection = details.primaryVelocity! > 0 ? 1 : -1;
        });
        swipingAnimationController?.forward().then((_) {
          final monthlyUiBloc = context.read<MonthlyUiDateManagerBloc>();
          DateTime newDate = monthlyUiBloc.state.selectedDate;
          if (swipeDirection < 0) {
            newDate = newDate.month == 12
                ? DateTime(newDate.year + 1, 1)
                : DateTime(newDate.year, newDate.month + 1);
          } else if (swipeDirection > 0) {
            newDate = newDate.month == 1
                ? DateTime(newDate.year - 1, 12)
                : DateTime(newDate.year, newDate.month - 1);
          }
          monthlyUiBloc
              .add(UpdateSelectedMonthOnSwiping(selectedTime: newDate));
          swipingAnimationController?.reset();
        });
      },
      child: AnimatedBuilder(
        animation: swipingAnimationController!,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              swipeDirection *
                  swipingAnimation!.value *
                  MediaQuery.of(context).size.width,
              0,
            ),
            child: child,
          );
        },
        child: Container(
          margin: EdgeInsets.only(top: 150, right: 5, left: 5),
          child: RefreshIndicator(
            onRefresh: handleRefresh,
            child: CustomScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              slivers: [
                ...monthRows
                    .map((row) => SliverToBoxAdapter(child: row))
                    .toList(),
                SliverToBoxAdapter(
                  child: MediaQuery.of(context).orientation ==
                          Orientation.landscape
                      ? TileStyles.bottomLandScapePaddingForTileBatchListOfTiles
                      : TileStyles.bottomPortraitPaddingForTileBatchListOfTiles,
                ),
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
        BlocListener<MonthlyUiDateManagerBloc, MonthlyUiDateManagerState>(
            listenWhen: (previous, current) =>
                previous.selectedDate != current.selectedDate,
            listener: (context, state) {
              reloadSchedule(dateManageSelectedMonth: state.selectedDate);
              isInitialLoad = true;
            }),
        BlocListener<SubCalendarTileBloc, SubCalendarTileState>(
          listener: (context, state) {
            showSubEventModal(state);
          },
        ),
      ],
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        builder: (context, state) {
          final summaryState = context.watch<ScheduleSummaryBloc>().state;
          if (summaryState is ScheduleDaySummaryLoading && isInitialLoad) {
            return renderPending();
          }
          isInitialLoad = false;

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
                buildMonthlyRenderSubCalendarTiles(
                    Tuple2(state.timelines, state.subEvents))
              ],
            );
          }
          if (state is ScheduleLoadingState) {
            bool showPendingUI = !state.isAlreadyLoaded;
            if (state.currentView == AuthorizedRouteTileListPage.Monthly) {
              DateTime monthlyDateMangerSelectedWeek = this
                  .context
                  .read<MonthlyUiDateManagerBloc>()
                  .state
                  .selectedDate;
              List<DateTime> daysInMonth =
                  Utility.getDaysInMonth(monthlyDateMangerSelectedWeek);
              Timeline monthlySelectedTimeline = Timeline.fromDateTime(
                  daysInMonth.first, daysInMonth.last.add(Duration(days: 1)));
              showPendingUI = showPendingUI ||
                  !(state.previousLookupTimeline
                      .isStartAndEndEqual(monthlySelectedTimeline));
            }

            if (showPendingUI) {
              return renderPending();
            }
            return Stack(children: [
              buildMonthlyRenderSubCalendarTiles(
                  Tuple2(state.timelines, state.subEvents))
            ]);
          }
          if (state is ScheduleEvaluationState) {
            return Stack(
              children: [
                buildMonthlyRenderSubCalendarTiles(
                    Tuple2(state.timelines, state.subEvents)),
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
