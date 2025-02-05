import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/util.dart';

part 'weekly_ui_date_manager_event.dart';
part 'weekly_ui_date_manager_state.dart';

class WeeklyUiDateManagerBloc extends Bloc<WeeklyUiDateManagerEvent, WeeklyUiDateManagerState> {
  WeeklyUiDateManagerBloc() : super((() {
    final currentDate = Utility.currentTime().dayDate;
    final List<DateTime> currentWeek=Utility.getDaysInWeek(currentDate);
    return WeeklyUiDateManagerState(
      selectedDate: currentDate,
      selectedWeek: currentWeek,
      tempDate: currentDate,
      tempSelectedWeek: currentWeek,
    );
  })()) {
    on<UpdateSelectedWeek>(_onUpdateSelectedWeek);
    on<UpdateTempDate>(_onUpdateTempDate);
    on<LogOutWeeklyUiDateManagerEvent>(_onLogOutWeeklyUiDateManagerEvent);
    on<SetTempSelectedWeek>(_onSetTempSelectedWeek);
    on<ResetTempEvent>(_onResetTempState);
  }

  void _onUpdateSelectedWeek(UpdateSelectedWeek event, Emitter<WeeklyUiDateManagerState> emit) {
    final selectedWeek = Utility.getDaysInWeek(event.selectedDate.dayDate);
    if(Utility.isDateWithinPickerRange(event.selectedDate.dayDate) &&!listEquals(selectedWeek, state.selectedWeek)) {
      emit(state.copyWith(
        selectedDate: event.selectedDate,
        selectedWeek: selectedWeek,
        tempSelectedWeek: selectedWeek,
        tempDate: event.selectedDate
      ));
    }
  }


  void _onUpdateTempDate(UpdateTempDate event, Emitter<WeeklyUiDateManagerState> emit) {
    if(Utility.isDateWithinPickerRange(event.tempDate))
      emit(state.copyWith(tempDate: event.tempDate));
  }

  void _onSetTempSelectedWeek(SetTempSelectedWeek event, Emitter<WeeklyUiDateManagerState> emit) {
    if(Utility.isDateWithinPickerRange(event.selectedDate.dayDate)) {
      final tempWeek = Utility.getDaysInWeek(event.selectedDate.dayDate);
      emit(state.copyWith(tempSelectedWeek: tempWeek));
    }
  }

  void _onResetTempState(ResetTempEvent event, Emitter<WeeklyUiDateManagerState> emit) {
    emit(state.copyWith(
      tempDate: state.selectedDate,
      tempSelectedWeek: state.selectedWeek,
    ));
  }

  void _onLogOutWeeklyUiDateManagerEvent(LogOutWeeklyUiDateManagerEvent event, Emitter<WeeklyUiDateManagerState> emit) {
    DateTime now = Utility.currentTime().dayDate;
    List<DateTime> nowWeek=Utility.getDaysInWeek(now);
    emit(WeeklyUiDateManagerState(
      selectedDate: now,
      selectedWeek: nowWeek,
      tempDate: now,
      tempSelectedWeek: nowWeek,
    ));
  }
}