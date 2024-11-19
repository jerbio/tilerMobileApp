part of 'monthly_ui_date_manager_bloc.dart';

class MonthlyUiDateManagerState extends Equatable {
  final DateTime selectedDate;
  final DateTime tempDate;
  final int year;

  const MonthlyUiDateManagerState({
    required this.selectedDate,
    required this.tempDate,
    required this.year,
  });

  @override
  List<Object> get props => [selectedDate,tempDate,year];

  MonthlyUiDateManagerState copyWith({
    DateTime? selectedDate,
    DateTime? tempDate,
    int? year,

  }) {
    return MonthlyUiDateManagerState(
      tempDate: tempDate??this.tempDate,
      selectedDate: selectedDate ?? this.selectedDate,
      year: year ?? this.year,
    );
  }
}
