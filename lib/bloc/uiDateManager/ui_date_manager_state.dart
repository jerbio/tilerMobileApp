part of 'ui_date_manager_bloc.dart';

abstract class UiDateManagerState extends Equatable {
  const UiDateManagerState();

  @override
  List<Object> get props => [];
}

class UiDateManagerInitial extends UiDateManagerState {
  DateTime currentDate = Utility.currentTime().dayDate;
  UiDateManagerInitial();
}

class UiDateManagerUpdated extends UiDateManagerState {
  DateTime previousDate;
  DateTime currentDate;
  UiDateManagerUpdated({required this.currentDate, required this.previousDate});
  @override
  List<Object> get props => [currentDate, previousDate];
}
