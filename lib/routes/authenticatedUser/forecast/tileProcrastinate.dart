import 'dart:ffi';

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TileProcrastinateRoute extends StatefulWidget {
  Map? _params;
  Duration? duration;
  String tileId;
  Function? callBack;
  TileProcrastinateRoute({this.duration, required this.tileId, this.callBack});
  static final String routeName = '/TileProcrastinate';
  @override
  TileProcrastinateRouteState createState() => TileProcrastinateRouteState();
}

class TileProcrastinateRouteState extends State<TileProcrastinateRoute> {
  Key switchUpID = ValueKey(Utility.getUuid);
  Duration _duration = Duration();
  bool _isInitialize = false;
  Duration? _selectedPresetValue = null;
  Map<String, Duration> durationStringToDuration = {};
  SubCalendarEventApi _subCalendarEventApi = new SubCalendarEventApi();

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['duration'] = _duration;
    }
    Duration populatedDuration = _duration;
    String tileId = this.widget.tileId;
    showMessage(AppLocalizations.of(context)!.procrastinating);
    final scheduleState = this.context.read<ScheduleBloc>().state;
    if (scheduleState is ScheduleEvaluationState) {
      DateTime timeOutTime = Utility.currentTime().subtract(Utility.oneMin);
      if (scheduleState.evaluationTime.isAfter(timeOutTime)) {
        return;
      }
    }

    List<SubCalendarEvent> renderedSubEvents = [];
    List<Timeline> timeLines = [];
    Timeline lookupTimeline = Utility.todayTimeline();
    ScheduleStatus scheduleStatus = ScheduleStatus();

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
      lookupTimeline = scheduleState.previousLookupTimeline;
      scheduleStatus = scheduleState.scheduleStatus;
    }

    var requestFuture =
        _subCalendarEventApi.procrastinate(populatedDuration, tileId);
    if (this.widget.callBack != null) {
      this.widget.callBack!(requestFuture);
    }

    context.read<ScheduleBloc>().add(EvaluateSchedule(
        renderedSubEvents: renderedSubEvents,
        renderedTimelines: timeLines,
        renderedScheduleTimeline: lookupTimeline,
        isAlreadyLoaded: true,
        scheduleStatus: ScheduleStatus(),
        callBack: requestFuture));
  }

  onTabTypeChange(value) {
    if (value == AppLocalizations.of(context)!.custom) {
      setState(() {
        _selectedPresetValue = null;
      });
    } else {
      setState(() {
        _selectedPresetValue = durationStringToDuration[value];
        _duration = _selectedPresetValue!;
      });
    }
  }

  onDurationButtonTap(Duration duration) {
    setState(() {
      _duration = duration;
      _selectedPresetValue = duration;
    });
  }

  resetSselectedPresetValue() {
    if (_selectedPresetValue != null) {
      switchUpID = ValueKey(Utility.getUuid);
    }
    _selectedPresetValue = null;
  }

  @override
  Widget build(BuildContext context) {
    Map durationParams =
        ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    if (!_isInitialize) {
      _isInitialize = true;
      this.widget._params = durationParams;
      if (durationParams.containsKey('initialDuration') &&
          durationParams['initialDuration'] != null) {
        this.widget.duration = durationParams['initialDuration'];
        _duration = this.widget.duration!;
      }
    }

    List<Widget> widgetColumn = <Widget>[
      Expanded(
          child: DurationPicker(
        duration: _duration,
        onChange: (val) {
          setState(() {
            _duration = val;
            resetSselectedPresetValue();
          });
        },
        snapToMins: 5.0,
      ))
    ];

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.duration,
            style: TextStyle(
                color: TileStyles.appBarTextColor,
                fontWeight: FontWeight.w800,
                fontSize: 22),
          ),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.topCenter,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: widgetColumn),
        ),
        onProceed: () {
          return this.onProceedTap();
        });

    return retValue;
  }
}
