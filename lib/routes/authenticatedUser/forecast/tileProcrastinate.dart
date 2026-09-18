import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/components/tileUI/playBackButtons.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';

/// "Defer this tile": push one tile back by a chosen duration.
///
/// The screen IS the redesigned duration picker ([AddTileDurationScreen],
/// titled "Defer"); it used to embed the raw package `DurationPicker` inside
/// the old Cancel/Proceed template. Committing a value sends the defer,
/// hands the request to [callBack] as [PlaybackOptions.Procrastinate], asks
/// the schedule to evaluate, and pops; Back defers nothing.
class TileProcrastinateRoute extends StatefulWidget {
  final Duration? duration;
  final String tileId;
  final Function? callBack;

  /// Optional API seam (tests). Production creates its own.
  final SubCalendarEventApi? subCalendarEventApi;

  const TileProcrastinateRoute({
    Key? key,
    this.duration,
    required this.tileId,
    this.callBack,
    this.subCalendarEventApi,
  }) : super(key: key);

  static final String routeName = '/TileProcrastinate';

  @override
  TileProcrastinateRouteState createState() => TileProcrastinateRouteState();
}

class TileProcrastinateRouteState extends State<TileProcrastinateRoute> {
  late SubCalendarEventApi _subCalendarEventApi;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _subCalendarEventApi = widget.subCalendarEventApi ??
        SubCalendarEventApi(getContextCallBack: () => context);
  }

  void showMessage(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: colorScheme.inverseSurface,
        textColor: colorScheme.onInverseSurface,
        fontSize: 16.0);
  }

  /// Sends the defer and wires the schedule's evaluating state to it.
  /// Returns the request so the caller's callback (and the pop) can wait
  /// on it. A schedule already evaluating within the last minute is left
  /// alone.
  Future _procrastinate(Duration duration) {
    String tileId = this.widget.tileId;
    showMessage(AppLocalizations.of(context)!.procrastinating);
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return Future(() => null);
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();

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
      lookupTimeline = scheduleState.previousLookupTimeline;
    }

    var requestFuture = _subCalendarEventApi.procrastinate(duration, tileId);
    if (this.widget.callBack != null) {
      this.widget.callBack!(PlaybackOptions.Procrastinate, requestFuture);
    }

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        isAlreadyLoaded: true,
        scheduleStatus: ScheduleStatus(),
        callBack: requestFuture));
    return requestFuture;
  }

  Future<void> _onSelected(Duration duration) async {
    if (_submitting || duration.inMilliseconds <= 0) return;
    // Busy from the first frame: the picker dims and shows a spinner so the
    // tap is visibly acknowledged while the request is in flight.
    setState(() => _submitting = true);
    try {
      await _procrastinate(duration);
    } catch (_) {
      // The schedule's evaluation state surfaces the failure; leaving the
      // picker up would only strand the user on it.
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AddTileDurationScreen(
      title: AppLocalizations.of(context)!.defer,
      initialDuration: widget.duration ?? Duration.zero,
      onSelected: _onSelected,
      busy: _submitting,
    );
  }
}
