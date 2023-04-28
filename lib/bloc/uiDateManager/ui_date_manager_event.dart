part of 'ui_date_manager_bloc.dart';

abstract class UiDateManagerEvent extends Equatable {
  const UiDateManagerEvent();

  @override
  List<Object> get props => [];
}

class DateChange extends UiDateManagerEvent {
  DateTime? previousSelectedDate;
  DateTime selectedDate;
  DateChange({required this.selectedDate, this.previousSelectedDate});

  @override
  List<Object> get props => [];
}
