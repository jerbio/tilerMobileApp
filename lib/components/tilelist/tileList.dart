import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tileUI/newTileUIPreview.dart';
import 'package:tiler_app/constants.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/constants.dart' as Constants;

/// This renders the list of tiles on a given day
abstract class TileList extends StatefulWidget {
  static final String routeName = '/TileList';
  TileList({Key? key}) : super(key: key);

  @override
  TileListState createState();
}

abstract class TileListState<T extends TileList> extends State<T>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late Timeline timeLine;
  String incrementalTilerScrollId = "";
  SubCalendarEvent? notificationSubEvent;
  SubCalendarEvent? concludingSubEvent;
  final Duration autoRefreshDuration = const Duration(minutes: 5);

  /// The pending auto-refresh tick. A real [Timer] (rather than the previous
  /// `Future.delayed(...).asStream().listen(...)`, whose subscription could
  /// never actually cancel the underlying timer — `Future.delayed` starts its
  /// timer immediately on construction, bound directly to
  /// [callScheduleRefresh], so "cancelling" that subscription was a no-op).
  /// Holding the real [Timer] lets a resume refresh below supersede it
  /// instead of racing it.
  Timer? autoRefreshList;
  // late final LocalNotificationService localNotificationService;
  bool isInitialLoad = true;
  AnimationController? swipingAnimationController;
  Animation<double>? swipingAnimation;
  int swipeDirection = 0;
  bool isSubEventModalShown = false;
  StreamSubscription? hideNewSheeTileFuture;
  late ThemeData theme;
  late ColorScheme colorScheme;

  @override
  void initState() {
    super.initState();
    // localNotificationService = LocalNotificationService();
    autoRefreshTileList(autoRefreshDuration);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    autoRefreshList?.cancel();
    swipingAnimationController?.dispose();
    super.dispose();
  }

  /// The auto-refresh timer pauses whenever the OS suspends this isolate in
  /// the background, so a lock/unlock (or a long app-switch) can leave the
  /// schedule and its summary counts stale with no visible indication.
  /// Foregrounding re-fetches to close that gap.
  ///
  /// Cancels the pending auto-refresh tick FIRST. `GetScheduleEvent` and
  /// `GetScheduleDaySummaryEvent` both use bloc_concurrency's `restartable()`,
  /// so if the old timer's deadline had already elapsed while backgrounded it
  /// fires on the very next event-loop tick after resume — i.e. right
  /// alongside this refresh. Two concurrent dispatches race restartable():
  /// whichever lands second cancels the first mid-flight, which is exactly
  /// what a live device log showed — a forced resume refresh getting
  /// superseded by the stale timer's un-forced one, doubling the network
  /// calls (two `getDaySummary` round trips for one wake-up) while the
  /// screen never visibly updated. Cancelling first and re-arming fresh
  /// after means exactly one refresh happens per resume.
  ///
  /// Deliberately calls [handleRefresh] — the same pull-to-refresh path —
  /// rather than [callScheduleRefresh], which also re-arms the timer itself;
  /// re-arming is done explicitly below once the refresh settles instead.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      autoRefreshList?.cancel();
      handleRefresh().whenComplete(() {
        if (mounted) {
          autoRefreshTileList(
              Duration(minutes: autoRefreshSubEventDurationInMinutes));
        }
      });
    }
  }

  void initializingSwipingAnimation(
      {Duration duration = const Duration(milliseconds: 300)}) {
    swipingAnimationController = AnimationController(
      duration: duration,
      vsync: this,
    );
    swipingAnimation = CurvedAnimation(
      parent: swipingAnimationController!,
      curve: Curves.easeInOut,
    );
  }

  Timeline get todayTimeLine {
    return Utility.todayTimeline();
  }

  void autoRefreshTileList(Duration duration) {
    print("Schedule auto refresh called " +
        Utility.currentTime(minuteLimitAccuracy: false).toString());
    autoRefreshList?.cancel();
    autoRefreshList = Timer(duration, callScheduleRefresh);
  }

  void callScheduleRefresh() {
    if (this.mounted) {
      final currentState = this.context.read<ScheduleBloc>().state;
      Timeline? lookupTimeline;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        lookupTimeline = currentState.lookupTimeline;
        refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
      }

      if (currentState is ScheduleLoadedState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        lookupTimeline = currentState.lookupTimeline;
        refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
      }

      if (currentState is ScheduleLoadingState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.previousLookupTimeline,
              previousTimeline: currentState.previousLookupTimeline,
            ));
        lookupTimeline = currentState.previousLookupTimeline;
        refreshScheduleSummary(
            lookupTimeline: currentState.previousLookupTimeline);
      }
      final currentScheduleSummaryState =
          this.context.read<ScheduleSummaryBloc>().state;
      if (currentScheduleSummaryState is ScheduleSummaryInitial ||
          currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
          currentScheduleSummaryState is ScheduleDaySummaryLoading) {
        this.context.read<ScheduleSummaryBloc>().add(
              GetScheduleDaySummaryEvent(
                timeline: lookupTimeline,
              ),
            );
      }
    }

    autoRefreshTileList(
        Duration(minutes: autoRefreshSubEventDurationInMinutes));
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(
                timeline: lookupTimeline, requestId: incrementalTilerScrollId),
          );
    }
  }

  Future<void> handleRefresh() async {
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleEvaluationState) {
      this.context.read<ScheduleBloc>().add(GetScheduleEvent(
            isAlreadyLoaded: true,
            previousSubEvents: currentState.subEvents,
            scheduleTimeline: currentState.lookupTimeline,
            previousTimeline: currentState.lookupTimeline,
            forceRefresh: true,
          ));
      refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
    }

    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(GetScheduleEvent(
          isAlreadyLoaded: true,
          previousSubEvents: currentState.subEvents,
          scheduleTimeline: currentState.lookupTimeline,
          previousTimeline: currentState.lookupTimeline,
          forceRefresh: true));
      refreshScheduleSummary(lookupTimeline: currentState.lookupTimeline);
    }

    if (currentState is ScheduleLoadingState) {
      this.context.read<ScheduleBloc>().add(GetScheduleEvent(
          isAlreadyLoaded: true,
          previousSubEvents: currentState.subEvents,
          scheduleTimeline: currentState.previousLookupTimeline,
          previousTimeline: currentState.previousLookupTimeline,
          forceRefresh: true));
      refreshScheduleSummary(
          lookupTimeline: currentState.previousLookupTimeline);
    }
  }

  void handleAutoRefresh(List<SubCalendarEvent> tiles) {
    List<TilerEvent> orderedTiles = Utility.orderTiles(tiles);
    double currentTime = Utility.msCurrentTime.toDouble();
    List<SubCalendarEvent> subSequentTiles = orderedTiles
        .where((eachTile) => eachTile.end! > currentTime)
        .map((eachTile) => eachTile as SubCalendarEvent)
        .toList();
  }

  void createNextTileNotification(SubCalendarEvent nextTile) {
    if (this.notificationSubEvent != null &&
        this.notificationSubEvent!.id == nextTile.id &&
        this.notificationSubEvent!.isStartAndEndEqual(nextTile)) {
      return;
    }

    this.notificationSubEvent = nextTile;
  }

  void createConclusionTileNotification(SubCalendarEvent concludingTile) {
    if (this.concludingSubEvent != null &&
        this.concludingSubEvent!.id == concludingTile.id &&
        this.concludingSubEvent!.isStartAndEndEqual(concludingTile)) {
      return;
    }

    String notificationMessage = AppLocalizations.of(context)!.concludesAtTime(
        (concludingTile.isProcrastinate ?? false
            ? AppLocalizations.of(context)!.procrastinateBlockOut
            : concludingTile.name!));

    // this.localNotificationService.concludingTileNotification(
    //     tile: concludingTile,
    //     context: this.context,
    //     title: notificationMessage);
    this.concludingSubEvent = concludingTile;
  }

  void handleNotifications(List<SubCalendarEvent> tiles) {
    double currentTimeMs = Utility.msCurrentTime.toDouble();
    List<TilerEvent> orderedByStartTiles = tiles
        .where((eachTile) =>
            (eachTile.isViable ?? true) && eachTile.start! > currentTimeMs)
        .toList();
    orderedByStartTiles = Utility.orderTiles(orderedByStartTiles);
    List<TilerEvent> orderedByEndTiles = tiles
        .where((eachTile) =>
            (eachTile.isViable ?? true) && eachTile.end! > currentTimeMs)
        .toList();
    orderedByEndTiles.sort((tileA, tileB) {
      int retValue = tileA.end! - tileB.end!;
      return retValue.toInt();
    });

    TilerEvent? earliestByStartSubTile;
    if (orderedByStartTiles.isNotEmpty) {
      earliestByStartSubTile = orderedByStartTiles.first;
    }

    TilerEvent? earliestByEndSubTile;
    if (orderedByEndTiles.isNotEmpty) {
      earliestByEndSubTile = orderedByEndTiles.first;
    }

    // this.localNotificationService.cancelAllNotifications();

    if (earliestByStartSubTile != null && earliestByEndSubTile != null) {
      if (earliestByStartSubTile.start! < earliestByEndSubTile.end!) {
        createNextTileNotification(earliestByStartSubTile as SubCalendarEvent);
        return;
      }
      createConclusionTileNotification(
          earliestByEndSubTile as SubCalendarEvent);
      return;
    }

    if (earliestByStartSubTile != null) {
      createNextTileNotification(earliestByStartSubTile as SubCalendarEvent);
      return;
    }
    if (earliestByEndSubTile != null) {
      createConclusionTileNotification(
          earliestByEndSubTile as SubCalendarEvent);
    }
  }

  handleNotificationsAndNextTile(List<SubCalendarEvent> tiles) {
    handleNotifications(tiles);
    handleAutoRefresh(tiles);
  }

  void showSubEventModal(SubCalendarTileState state) {
    if (state is NewSubCalendarTilesLoadedState) {
      if (state.subEvent != null && state.subEvent!.id != null) {
        SubCalendarEvent subEvent = state.subEvent!;
        int redColor = subEvent.colorRed ?? 125;
        int blueColor = subEvent.colorBlue ?? 125;
        int greenColor = subEvent.colorGreen ?? 125;
        double opacity = subEvent.colorOpacity ?? 1.0;

        var nameColor =
            Color.fromRGBO(redColor, greenColor, blueColor, opacity);
        var hslColor = HSLColor.fromColor(nameColor);
        Color bgroundColor = hslColor
            .withLightness(hslColor.lightness)
            .toColor()
            .withAlpha((0.7 * 255).toInt());
        if (isSubEventModalShown) {
          print("SubEvent modal already shown, not showing again");
          return;
        }
        showModalBottomSheet(
          context: context,
          constraints: const BoxConstraints(maxWidth: 400),
          builder: (BuildContext modalContext) {
            print("modal bottom sheet called for new tile");
            if (isSubEventModalShown) {
              isSubEventModalShown = false;
              var future = Future.delayed(
                  const Duration(milliseconds: Constants.autoHideInMs));
              if (hideNewSheeTileFuture != null) {
                hideNewSheeTileFuture?.cancel();
              }
              hideNewSheeTileFuture = future.asStream().listen((input) {
                setState(() {
                  print(
                      "modal bottom sheet auto hide called and setState called");
                  // isSubEventModalShown = false;
                });
                print("modal bottom sheet auto hide called");
                if (modalContext.mounted) {
                  print(
                      "modal bottom sheet auto hide called and context is mounted");
                  if (Navigator.canPop(modalContext)) {
                    print(
                        "modal bottom sheet auto hide called and Navigator can pop");
                    Navigator.pop(modalContext);
                  }
                }
              });
            }

            return ElevatedButton(
              onPressed: () {
                if (hideNewSheeTileFuture != null) {
                  hideNewSheeTileFuture?.cancel();
                }

                if (Navigator.canPop(modalContext)) {
                  print(
                      "modal bottom sheet auto hide called and Navigator can pop");
                  Navigator.pop(modalContext);
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TileDetailRoute(
                        tileId: subEvent.calendarEvent?.id ?? subEvent.id!),
                  ),
                ).whenComplete(() {
                  // if (Navigator.canPop(context)) {
                  //   Navigator.pop(context);
                  // }
                });
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(0),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                height: 250,
                width: 300,
                decoration: BoxDecoration(color: bgroundColor),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CreatedTileSheet(subEvent: subEvent),
                    ],
                  ),
                ),
              ),
            );
          },
        );
        setState(() {
          isSubEventModalShown = true;
        });
      }
    }
  }
}
