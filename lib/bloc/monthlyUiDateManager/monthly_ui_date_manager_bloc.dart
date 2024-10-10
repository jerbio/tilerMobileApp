import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/util.dart';

part 'monthly_ui_date_manager_event.dart';
part 'monthly_ui_date_manager_state.dart';
class MonthlyUiDateManagerBloc extends Bloc<MonthlyUiDateManagerEvent, MonthlyUiDateManagerState> {
  MonthlyUiDateManagerBloc() : super((() {
    final currentDate = Utility.currentTime().dayDate;
    return MonthlyUiDateManagerState(
        selectedDate: currentDate,
        tempDate: currentDate,
        year: currentDate.year,
    );
  })()) {
    on<UpdateSelectedMonth>(_onUpdateSelectedMonth);
    on<ChangeYear>(_onChangeYear);
    on<ChangeMonth>(_onChangeMonth);
    on<ResetTempEvent>(_onResetTempState);
    on<LogOutMonthlyUiDateManagerEvent>(_onLogOutMonthlyUiDateManagerEvent);
  }

  void _onUpdateSelectedMonth(UpdateSelectedMonth event, Emitter<MonthlyUiDateManagerState> emit) {
    if(state.tempDate.month!=state.selectedDate.month)
    emit(state.copyWith(selectedDate: state.tempDate));
  }

  void _onChangeYear(ChangeYear event, Emitter<MonthlyUiDateManagerState> emit) {
    emit(state.copyWith(year: event.year));
  }

  void _onChangeMonth(ChangeMonth event, Emitter<MonthlyUiDateManagerState> emit) {
    final newDate = Utility.currentTime().copyWith(month: event.month,year:state.year).dayDate;
    emit(state.copyWith(tempDate:newDate));
  }
  void _onResetTempState(ResetTempEvent event, Emitter<MonthlyUiDateManagerState> emit) {
    emit(state.copyWith(
      year: state.selectedDate.year,
      tempDate: state.selectedDate
    ));
  }
  void _onLogOutMonthlyUiDateManagerEvent(LogOutMonthlyUiDateManagerEvent event, Emitter<MonthlyUiDateManagerState> emit) {
    final currentDate = Utility.currentTime().dayDate;
    emit(state.copyWith(selectedDate: currentDate,year: currentDate.year,tempDate: currentDate));
  }
}
