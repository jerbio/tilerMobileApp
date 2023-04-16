import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/components/daySummary.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';

part 'schedule_summary_event.dart';
part 'schedule_summary_state.dart';

class ScheduleSummaryBloc
    extends Bloc<ScheduleSummaryEvent, ScheduleSummaryState> {
  ScheduleSummaryBloc() : super(ScheduleSummaryInitial()) {
    on<ScheduleSummaryEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}
