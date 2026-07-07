// calendar_view_switcher_controller_test.dart
//
// Phase 3 (TDD) — the wiring that runs when a view is picked from the pop-out.
//
// Contract for selectCalendarView():
//   * Switching to a different view dispatches ChangeViewEvent so ScheduleBloc
//     reflects the new view.
//   * The OUTGOING view's date-manager is reset back to today (consistent
//     "reset outgoing" semantics), so it re-opens fresh next time.
//   * Selecting the already-active view is a no-op (no reset, no view change).

import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/calendarViewSwitcher/calendarViewSwitcherController.dart';
import 'package:tiler_app/util.dart';

class _Blocs {
  final ScheduleBloc schedule = ScheduleBloc(getContextCallBack: () => null);
  final UiDateManagerBloc daily = UiDateManagerBloc();
  final WeeklyUiDateManagerBloc weekly = WeeklyUiDateManagerBloc();
  final MonthlyUiDateManagerBloc monthly = MonthlyUiDateManagerBloc();

  void select(AuthorizedRouteTileListPage newView) => selectCalendarView(
        newView: newView,
        scheduleBloc: schedule,
        dailyDateBloc: daily,
        weeklyDateBloc: weekly,
        monthlyDateBloc: monthly,
      );

  Future<void> setView(AuthorizedRouteTileListPage view) async {
    if (schedule.state.currentView == view) return;
    schedule.add(ChangeViewEvent(view));
    await schedule.stream.firstWhere((s) => s.currentView == view);
  }

  Future<void> close() async {
    await schedule.close();
    await daily.close();
    await weekly.close();
    await monthly.close();
  }
}

void main() {
  test('Daily -> Monthly switches view and resets the daily date manager',
      () async {
    final b = _Blocs();

    final viewChanged = expectLater(
      b.schedule.stream,
      emitsThrough(isA<ScheduleState>().having(
          (s) => s.currentView, 'currentView', AuthorizedRouteTileListPage.Monthly)),
    );
    final dailyReset = expectLater(
      b.daily.stream,
      emitsThrough(isA<LoggedOutUiDateManagerUpdated>()),
    );

    b.select(AuthorizedRouteTileListPage.Monthly);

    await viewChanged;
    await dailyReset;
    await b.close();
  });

  test('Weekly -> Daily switches view and resets the weekly date manager',
      () async {
    final b = _Blocs();
    await b.setView(AuthorizedRouteTileListPage.Weekly);

    final today = Utility.currentTime().dayDate;
    final viewChanged = expectLater(
      b.schedule.stream,
      emitsThrough(isA<ScheduleState>().having(
          (s) => s.currentView, 'currentView', AuthorizedRouteTileListPage.Daily)),
    );
    final weeklyReset = expectLater(
      b.weekly.stream,
      emitsThrough(isA<WeeklyUiDateManagerState>()
          .having((s) => s.selectedDate, 'selectedDate', today)),
    );

    b.select(AuthorizedRouteTileListPage.Daily);

    await viewChanged;
    await weeklyReset;
    await b.close();
  });

  test('Monthly -> Weekly switches view and resets the monthly date manager',
      () async {
    final b = _Blocs();
    await b.setView(AuthorizedRouteTileListPage.Monthly);

    final today = Utility.currentTime().dayDate;
    final viewChanged = expectLater(
      b.schedule.stream,
      emitsThrough(isA<ScheduleState>().having(
          (s) => s.currentView, 'currentView', AuthorizedRouteTileListPage.Weekly)),
    );
    final monthlyReset = expectLater(
      b.monthly.stream,
      emitsThrough(isA<MonthlyUiDateManagerState>()
          .having((s) => s.selectedDate, 'selectedDate', today)),
    );

    b.select(AuthorizedRouteTileListPage.Weekly);

    await viewChanged;
    await monthlyReset;
    await b.close();
  });

  test('selecting the active view is a no-op (no reset, no view change)',
      () async {
    final b = _Blocs(); // starts Daily

    bool scheduleEmitted = false;
    bool dailyEmitted = false;
    final s1 = b.schedule.stream.listen((_) => scheduleEmitted = true);
    final s2 = b.daily.stream.listen((_) => dailyEmitted = true);

    b.select(AuthorizedRouteTileListPage.Daily);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(scheduleEmitted, isFalse,
        reason: 'Re-selecting the active view must not change the view.');
    expect(dailyEmitted, isFalse,
        reason: 'Re-selecting the active view must not reset any date manager.');

    await s1.cancel();
    await s2.cancel();
    await b.close();
  });
}
