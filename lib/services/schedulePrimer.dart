import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/util.dart';

/// Kicks off the session's first schedule load as soon as credentials
/// verify — before the launch gate decides between the essentials
/// onboarding and the authorized app (product-tour-onboarding-redesign.md,
/// stage 3.5).
///
/// Both launch paths call this: the sign-in flow and the cold-start path in
/// `main.dart`. Firing it before the gate means the schedule is already
/// loading while the essentials pages are on screen, so Skip / Submit land
/// on a populated schedule instead of a spinner. The home surface still
/// issues its own fetch on mount; the schedule bloc reconciles the two.
///
/// Order matters: [LogInScheduleEvent] resets the bloc for the new
/// session, then [GetScheduleEvent] loads the initial window as a fresh
/// (not already-loaded) fetch; the day summary is primed alongside.
void primeScheduleAfterLogin(BuildContext context) {
  context
      .read<ScheduleBloc>()
      .add(LogInScheduleEvent(getContextCallBack: () => context));
  context.read<ScheduleBloc>().add(GetScheduleEvent(
      scheduleTimeline: Utility.initialScheduleTimeline,
      isAlreadyLoaded: false,
      previousSubEvents: []));
  context.read<ScheduleSummaryBloc>().add(
        GetScheduleDaySummaryEvent(timeline: Utility.initialScheduleTimeline),
      );
}
