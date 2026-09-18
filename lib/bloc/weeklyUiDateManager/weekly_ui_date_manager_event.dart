part of 'weekly_ui_date_manager_bloc.dart';

abstract class WeeklyUiDateManagerEvent extends Equatable {
  const WeeklyUiDateManagerEvent();

  @override
  List<Object> get props => [];
}

class UpdateSelectedWeek extends WeeklyUiDateManagerEvent {
  final DateTime selectedDate;
  const UpdateSelectedWeek({required this.selectedDate});

  @override
  List<Object> get props => [selectedDate];
}

class UpdateTempDate extends WeeklyUiDateManagerEvent {
  final DateTime tempDate;

  const UpdateTempDate({required this.tempDate});

  @override
  List<Object> get props => [tempDate];
}

class SetTempSelectedWeek extends WeeklyUiDateManagerEvent {
  final DateTime selectedDate;
  const SetTempSelectedWeek({required this.selectedDate});
  @override
  List<Object> get props => [selectedDate];
}

class ResetTempEvent extends WeeklyUiDateManagerEvent {}

class LogOutWeeklyUiDateManagerEvent extends WeeklyUiDateManagerEvent {
  LogOutWeeklyUiDateManagerEvent();
  @override
  List<Object> get props => [];
}
