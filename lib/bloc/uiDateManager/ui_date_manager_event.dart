part of 'ui_date_manager_bloc.dart';

abstract class UiDateManagerEvent extends Equatable {
  const UiDateManagerEvent();

  @override
  List<Object> get props => [];
}

class SelectedDate extends UiDateManagerEvent {
  DateTime? previousSelectedDate;
  DateTime selectedDate;
  SelectedDate({required this.selectedDate, this.previousSelectedDate});

  @override
  List<Object> get props => [];
}
