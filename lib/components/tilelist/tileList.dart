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
import 'package:tiler_app/routes/authenticatedUser/tileDetails.dart/TileDetail.dart';
import 'package:tiler_app/services/notifications/localNotificationService.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/constants.dart' as Constants;


abstract class TileList extends StatefulWidget {
  TileList({Key? key}) : super(key: key);

  @override
  TileListState createState();
}

abstract class TileListState<T extends TileList> extends State<T> with TickerProviderStateMixin {

  late Timeline timeLine;
  String incrementalTilerScrollId = "";
  SubCalendarEvent? notificationSubEvent;
  SubCalendarEvent? concludingSubEvent;
  final Duration autoRefreshDuration = const Duration(minutes: 5);
  StreamSubscription? autoRefreshList;
  late final LocalNotificationService localNotificationService;
  bool isInitialLoad=true;
  AnimationController? swipingAnimationController;
  Animation<double>? swipingAnimation;
  int swipeDirection = 0;

  @override
  void initState() {
    super.initState();
    localNotificationService = LocalNotificationService();
    autoRefreshTileList(autoRefreshDuration);
  }

  @override
  void dispose() {
    swipingAnimationController?.dispose();
    super.dispose();
  }
  
  void initializingSwipingAnimation({Duration duration = const Duration(milliseconds: 300)}) {
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
    Future onTileExpiredCallBack = Future.delayed(duration,callScheduleRefresh);
    // ignore: cancel_subscriptions
    autoRefreshList = onTileExpiredCallBack.asStream().listen((_) {});
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
        refreshScheduleSummary(lookupTimeline: currentState.previousLookupTimeline);
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
        Duration(
            minutes: autoRefreshSubEventDurationInMinutes
        ));
  }

  void refreshScheduleSummary({Timeline? lookupTimeline}){
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
    final currentState = this.context
        .read<ScheduleBloc>()
        .state;
    if (currentState is ScheduleEvaluationState) {
      this.context.read<ScheduleBloc>().add(GetScheduleEvent(
        isAlreadyLoaded: true,
        previousSubEvents: currentState.subEvents,
        scheduleTimeline: currentState.lookupTimeline,
        previousTimeline: currentState.lookupTimeline,
        forceRefresh: true,));
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

  Widget renderPending({String? message}) {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
            child: CircularProgressIndicator(),
            height: 200.0,
            width: 200.0,
          )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    if (message != null && message.isNotEmpty) {
      centerElements.add(Center(
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 120, 0, 0),
          child: Text(message),
        ),
      ));
    }
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
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

    this.localNotificationService.concludingTileNotification(
        tile: concludingTile,
        context: this.context,
        title: notificationMessage);
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

    this.localNotificationService.cancelAllNotifications();

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

  void showSubEventModal( SubCalendarTileState state) {
    if (state is NewSubCalendarTilesLoadedState) {
      if (state.subEvent != null) {
        SubCalendarEvent subEvent = state.subEvent!;
        int redColor = subEvent.colorRed ?? 125;
        int blueColor = subEvent.colorBlue ?? 125;
        int greenColor = subEvent.colorGreen ?? 125;
        double opacity = subEvent.colorOpacity ?? 1.0;

        var nameColor = Color.fromRGBO(
            redColor, greenColor, blueColor, opacity);
        var hslColor = HSLColor.fromColor(nameColor);
        Color bgroundColor = hslColor.withLightness(hslColor.lightness)
            .toColor()
            .withOpacity(0.7);

        showModalBottomSheet(
          context: context,
          constraints: const BoxConstraints(maxWidth: 400),
          builder: (BuildContext context) {
            var future = Future.delayed(
                const Duration(milliseconds: Constants.autoHideInMs));
            var hideNewSheeTileFuture = future.asStream().listen((input) {
              Navigator.pop(context);
            });

            return ElevatedButton(
              onPressed: () {
                hideNewSheeTileFuture.cancel();
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TileDetail(
                        tileId: subEvent.calendarEvent?.id ?? subEvent.id!),
                  ),
                ).whenComplete(() => Navigator.pop(context));
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
      }
    }
  }
}