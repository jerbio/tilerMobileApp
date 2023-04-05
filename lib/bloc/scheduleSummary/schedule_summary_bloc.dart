import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  ScheduleSummaryBloc() : super(ScheduleSummaryInitial()) {
    on<ScheduleSummaryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
