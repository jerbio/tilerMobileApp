part of 'ui_date_manager_bloc.dart';

abstract class UiDateManagerEvent extends Equatable {
  const UiDateManagerEvent();

  @override
  List<Object> get props => [];
}

class DateChangeEvent extends UiDateManagerEvent {
  DateTime? previousSelectedDate;
  DateTime selectedDate;
  DateChangeTrigger? dateChangeTrigger;
  DateChangeEvent(
      {required this.selectedDate,
      this.previousSelectedDate,
      this.dateChangeTrigger});

  @override
  List<Object> get props => [];
}

class LogOutUiDateManagerEvent extends UiDateManagerEvent {
  LogOutUiDateManagerEvent();

  @override
  List<Object> get props => [];
}
