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
    on<UpdateSelectedMonthOnPicking>(_onUpdateSelectedMonth);
    on<UpdateSelectedMonthOnSwiping>(_onUpdateSelectedMonthOnSwiping);
    on<ChangeYear>(_onChangeYear);
    on<ChangeMonth>(_onChangeMonth);
    on<ResetTempEvent>(_onResetTempState);
    on<LogOutMonthlyUiDateManagerEvent>(_onLogOutMonthlyUiDateManagerEvent);
  }

  void _onUpdateSelectedMonth(UpdateSelectedMonthOnPicking event, Emitter<MonthlyUiDateManagerState> emit) {
    if(state.tempDate.month!=state.selectedDate.month || state.tempDate.year!=state.selectedDate.year)
    emit(state.copyWith(selectedDate: state.tempDate));
  }
  void _onUpdateSelectedMonthOnSwiping(UpdateSelectedMonthOnSwiping event, Emitter<MonthlyUiDateManagerState> emit) {
    if(event.selectedTime.month!=state.selectedDate.month || event.selectedTime.year!=state.selectedDate.year)
      emit(state.copyWith(selectedDate: event.selectedTime,tempDate: event.selectedTime,year: event.selectedTime.year));
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
