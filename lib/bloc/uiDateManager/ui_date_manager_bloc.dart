import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:tiler_app/data/timeline.dart';
import '../../services/analyticsSignal.dart';
import 'package:carousel_slider/carousel_slider.dart';



part 'ui_date_manager_event.dart';
part 'ui_date_manager_state.dart';

class UiDateManagerBloc extends Bloc<UiDateManagerEvent, UiDateManagerState> {
  final CarouselSliderController dayRibbonCarouselController = CarouselSliderController();
  final Map<int, Tuple2<int, Timeline>> universalIndexToBatch = {};

  UiDateManagerBloc()
      : super(UiDateManagerUpdated(
            currentDate: Utility.currentTime().dayDate,
            previousDate: Utility.currentTime().dayDate)) {
    on<DateChangeEvent>(_onDayDateChange);
    on<LogOutUiDateManagerEvent>(_onLogOutUiDateManagerChange);
  }

  _onDayDateChange(DateChangeEvent event, Emitter emit) {
    DateTime previousDate =
        event.previousSelectedDate ?? Utility.currentTime().dayDate;
    DateTime updatedDate = event.selectedDate;

    if (state is UiDateManagerUpdated) {
      previousDate = (state as UiDateManagerUpdated).currentDate;
    }
    emit(UiDateManagerUpdated(
        currentDate: updatedDate,
        previousDate: previousDate,
        dateChangeTrigger: event.dateChangeTrigger));
  }

  _onLogOutUiDateManagerChange(
      LogOutUiDateManagerEvent event, Emitter emit) async {
    emit(LoggedOutUiDateManagerUpdated());
  }

  void onDateButtonTapped(DateTime date) {
    AnalysticsSignal.send('DAY_RIBBON_TAPPED');
    print('DAY_RIBBON_TAPPED');
    DateTime previousDate = state is UiDateManagerUpdated
        ? (state as UiDateManagerUpdated).currentDate
        : Utility.currentTime().dayDate;
    DateTime currentDate = date;

    if (currentDate.millisecondsSinceEpoch !=
        previousDate.millisecondsSinceEpoch) {
      add(DateChangeEvent(
          previousSelectedDate: previousDate, selectedDate: date));
    }
  }

  void updateUniversalIndexToBatch(Map<int, Tuple2<int, Timeline>> newBatch) {
    universalIndexToBatch.clear();
    universalIndexToBatch.addAll(newBatch);
  }
}
