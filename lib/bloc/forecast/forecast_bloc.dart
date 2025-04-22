import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/whatIfApi.dart';
import 'package:tiler_app/util.dart';
import 'forecast_event.dart';
import 'forecast_state.dart';

class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  late WhatIfApi whatIfApi;
  ForecastBloc({required Function getContextCallBack})
      : super(ForecastInitial()) {
    this.whatIfApi = WhatIfApi(getContextCallBack: getContextCallBack);
    on<UpdateDuration>(_onUpdateDuration);
    on<UpdateDateTime>(_onUpdateDateTime);
    on<NewTileEvent>(_onNewTile);
    on<FetchData>(_onFetchData);
    on<ResetEvent>(_onResetEvent);
  }

  void _onResetEvent(ResetEvent event, Emitter<ForecastState> emit) {
    emit(ForecastInitial(duration: null, endTime: null));
  }

  void _onNewTile(NewTileEvent event, Emitter<ForecastState> emit) {
    Duration? duration = event.newTile.getDuration();
    DateTime? endTime = event.newTile.getEndDateTime() ??
        Utility.currentTime().add(Duration(days: 7));
    Location? location = event.newTile.getLocation();
    print(
        "NewTileEvent: duration: $duration, endTime: $endTime, location: $location");

    if (duration != null &&
        duration.inMinutes > 0 &&
        endTime.isAfter(Utility.currentTime())) {
      print(
          "Emitting ForecastLoading state with duration: $duration, endTime: $endTime, location: $location");
      bool isDifferentState = false;
      if (state is ForecastLoading) {
        final currentState = state as ForecastLoading;
        final newState = ForecastLoading(
            duration: duration, endTime: endTime, location: location);
        isDifferentState = currentState == newState ? false : true;
      } else {
        isDifferentState = true;
      }
      print("isDifferentState: $isDifferentState");
      if (isDifferentState) {
        emit(ForecastLoading(
            duration: duration, endTime: endTime, location: location));
        _checkAndTriggerEvent(duration, endTime, location, event.requestId);
      }
    } else {
      emit(ForecastInitial(duration: duration, endTime: endTime));
    }
  }

  void _onUpdateDuration(UpdateDuration event, Emitter<ForecastState> emit) {
    final newState = state;
    if (event.duration.inMinutes > 0 &&
        newState.endTime != null &&
        newState.endTime!.isAfter(Utility.currentTime())) {
      emit(
          ForecastLoading(duration: event.duration, endTime: newState.endTime));
      _checkAndTriggerEvent(
          event.duration, newState.endTime, newState.location, event.requestId);
    } else {
      emit(
          ForecastInitial(duration: event.duration, endTime: newState.endTime));
    }
  }

  void _onUpdateDateTime(UpdateDateTime event, Emitter<ForecastState> emit) {
    Utility.debugPrint("Updating end time: ${event.dateTime}");
    final currentState = state;
    if (currentState.duration != null &&
        currentState.duration!.inMinutes > 0 &&
        event.dateTime.isAfter(Utility.currentTime())) {
      emit(ForecastLoading(
          duration: currentState.duration!, endTime: event.dateTime));
      _checkAndTriggerEvent(currentState.duration!, event.dateTime,
          state.location, event.requestId);
    } else {
      emit(ForecastInitial(
          duration: currentState.duration, endTime: event.dateTime));
    }
  }

  void _checkAndTriggerEvent(Duration duration, DateTime? endTime,
      Location? location, String? requestId) {
    if (duration >= Duration(minutes: 1) && endTime != null) {
      Utility.debugPrint("Emitting FetchData event");
      add(FetchData(requestId: requestId));
    }
  }

  Future<void> _onFetchData(
      FetchData event, Emitter<ForecastState> emit) async {
    if (state.duration == null || state.endTime == null) {
      return;
    }
    Duration duration = state.duration!;
    DateTime endTime = state.endTime!;
    try {
      emit(ForecastLoading(duration: duration, endTime: endTime));
      Utility.debugPrint('Fetching data...');

      DateTime now = Utility.currentTime();
      int currentMinute = now.minute;
      int currentHour = now.hour;
      int currentDay = now.day;
      int currentMonth = now.month;
      int currentYear = now.year;
      int endDay = state.endTime!.day;
      int endMonth = state.endTime!.month;
      int endYear = state.endTime!.year;
      var durInHours = duration.inHours;
      var durrInMilliseconds = duration.inMilliseconds;
      var durInUtc = durationToUtcString(duration);

      Map<String, Object> queryParams = {
        "StartMinute": currentMinute.toString(),
        "StartHour": currentHour.toString(),
        "StartDay": currentDay.toString(),
        "StartMonth": currentMonth.toString(),
        "StartYear": currentYear.toString(),
        "EndDay": endDay.toString(),
        "EndMonth": endMonth.toString(),
        "EndYear": endYear.toString(),
        "DurationHours": durInHours.toString(),
        "DurationInMs": durrInMilliseconds.toString(),
        "Duration": durInUtc.toString(),
        "Address": state.location?.address ?? "",
        "LocationId": state.location?.id ?? "",
      };

      final forecastResponse = await whatIfApi.forecastNewTile(queryParams);
      Utility.debugPrint('Data fetched: $forecastResponse');

      emit(ForecastLoaded(
        isViable: forecastResponse.isViable ?? false,
        foreCastResponse: forecastResponse,
        duration: duration,
        endTime: state.endTime,
        requestId: event.requestId,
      ));
    } catch (e) {
      emit(ForecastError(
        'An error occurred while fetching data. Please try again later.',
        duration: duration,
        endTime: state.endTime,
      ));
    }
  }

  String durationToUtcString(Duration duration) {
    DateTime utcTime = DateTime.utc(0, 0, 0, duration.inHours,
        duration.inMinutes.remainder(60), duration.inSeconds.remainder(60));
    return utcTime
        .toIso8601String()
        .split('T')[1]
        .split('.')[0]; // Extract the time part in HH:mm:ss format
  }

  // Future<void> _onFetchData(FetchData event, Emitter<ForecastState> emit) async {
  //   final currentState = state;
  //   try {
  //     emit(ForecastLoading(duration: currentState.duration, endTime: currentState.endTime));
  //     print('Fetching data...');
  //     DateTime now = DateTime.now();
  //     int currentMinute = now.minute;
  //     int currentHour = now.hour;
  //     int currentDay = now.day;
  //     int currentMonth = now.month;
  //     int currentYear = now.year;
  //     int endDay = currentState.endTime!.day;
  //     int endMonth = currentState.endTime!.month;
  //     int endYear = currentState.endTime!.year;
  //     var durInHours = currentState.duration.inHours;
  //     var durrInMilliseconds = currentState.duration.inMilliseconds;
  //     var durInUtc = durationToUtcString(currentState.duration);

  //     Map<String, Object> queryParams = {
  //       "StartMinute": currentMinute.toString(),
  //       "StartHour": currentHour.toString(),
  //       "StartDay": currentDay.toString(),
  //       "StartMonth": currentMonth.toString(),
  //       "StartYear": currentYear.toString(),
  //       "EndDay": endDay.toString(),
  //       "EndMonth": endMonth.toString(),
  //       "EndYear": endYear.toString(),
  //       "DurationHours": durInHours.toString(),
  //       "DurationInMs": durrInMilliseconds.toString(),
  //       "Duration": durInUtc.toString(),
  //     };

  //     final val = await WhatIfApi().forecastNewTile(queryParams);
  //     print('Data fetched: $val');
  //     emit(ForecastLoaded(
  //       isViable: val[0],
  //       subCalEvents: val[1],
  //       resp: val.toString(),
  //       duration: currentState.duration,
  //       endTime: currentState.endTime,
  //     ));
  //   } catch (e) {
  //     print('Error: $e');
  //     emit(ForecastError(e.toString(), duration: currentState.duration, endTime: currentState.endTime));
  //   }
  // }

  // String durationToUtcString(Duration duration) {
  //   DateTime utcTime = DateTime.utc(0, 0, 0, duration.inHours,
  //       duration.inMinutes.remainder(60), duration.inSeconds.remainder(60));
  //   return utcTime
  //       .toIso8601String()
  //       .split('T')[1]
  //       .split('.')[0]; // Extract the time part in HH:mm:ss format
  // }
}
