import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';

/// Switches the active calendar view to [newView].
///
/// Behaviour:
///   * If [newView] is already the active view, does nothing.
///   * Otherwise resets the OUTGOING view's date-manager back to today so it
///     re-opens fresh next time, then dispatches [ChangeViewEvent] so the
///     schedule reflects the new view.
void selectCalendarView({
  required AuthorizedRouteTileListPage newView,
  required ScheduleBloc scheduleBloc,
  required UiDateManagerBloc dailyDateBloc,
  required WeeklyUiDateManagerBloc weeklyDateBloc,
  required MonthlyUiDateManagerBloc monthlyDateBloc,
}) {
  final AuthorizedRouteTileListPage currentView = scheduleBloc.state.currentView;
  if (newView == currentView) {
    return;
  }

  // Reset the outgoing view's date manager back to today.
  switch (currentView) {
    case AuthorizedRouteTileListPage.Daily:
      dailyDateBloc.add(LogOutUiDateManagerEvent());
      break;
    case AuthorizedRouteTileListPage.Weekly:
      weeklyDateBloc.add(LogOutWeeklyUiDateManagerEvent());
      break;
    case AuthorizedRouteTileListPage.Monthly:
      monthlyDateBloc.add(LogOutMonthlyUiDateManagerEvent());
      break;
  }

  scheduleBloc.add(ChangeViewEvent(newView));
}
