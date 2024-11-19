part of 'weekly_ui_date_manager_bloc.dart';

class WeeklyUiDateManagerState extends Equatable {
  final DateTime selectedDate;
  final List<DateTime> selectedWeek;
  final DateTime tempDate;
  final List<DateTime> tempSelectedWeek;


  const WeeklyUiDateManagerState({
    required this.selectedDate,
    required this.selectedWeek,
    required this.tempDate,
    required this.tempSelectedWeek,
  });

  @override
  List<Object?> get props => [selectedDate, selectedWeek, tempDate,  tempSelectedWeek];


  WeeklyUiDateManagerState copyWith({
    DateTime? selectedDate,
    List<DateTime>? selectedWeek,
    DateTime? tempDate,
    List<DateTime>? tempSelectedWeek,

  }) {
    return WeeklyUiDateManagerState(
      selectedDate: selectedDate ?? this.selectedDate,
      selectedWeek: selectedWeek ?? this.selectedWeek,
      tempDate: tempDate ?? this.tempDate,
      tempSelectedWeek: tempSelectedWeek ??this.tempSelectedWeek,
    );
  }
}