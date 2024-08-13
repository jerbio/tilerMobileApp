part of 'ui_date_manager_bloc.dart';

abstract class UiDateManagerState extends Equatable {
  const UiDateManagerState();

  @override
  List<Object> get props => [];
}

enum DateChangeTrigger { buttonPress, dateTimePassed }

class UiDateManagerUpdated extends UiDateManagerState {
  DateTime previousDate;
  DateTime currentDate;
  DateChangeTrigger? dateChangeTrigger;

  UiDateManagerUpdated(
      {required this.currentDate,
      required this.previousDate,
      this.dateChangeTrigger});
  @override
  List<Object> get props => [currentDate, previousDate];
}

class LoggedOutUiDateManagerUpdated extends UiDateManagerState {
  LoggedOutUiDateManagerUpdated();
  @override
  List<Object> get props => [];
}
