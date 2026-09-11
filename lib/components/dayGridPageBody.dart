import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/util.dart';

/// Scope shared by every grid-mode day page (provided by
/// [GridDailyPageBody]; looked up, dependency-free, by `DayGridPage`):
///
///  * [controller] — the ONE `DayGridController` (zoom) for all day pages.
///    Owned + restored from prefs once by the body, so a page sliding into
///    view mounts already at the stored zoom (no per-page async restore
///    re-laying every tile out), and a pinch on one day is live on every
///    other day.
///  * [progress] / [report] — how much of the CURRENT day page's scrolling
///    header is revealed; the fixed top bar reads it to cross-fade the day
///    pill. Reports from non-current (off-screen carousel) pages are ignored.
///
/// Absent outside grid mode / in isolated tests — null-check [maybeOf].
class DayGridScope extends InheritedWidget {
  final DayGridController controller;

  /// 0 (header off-screen above the grid) → 1 (fully revealed).
  final ValueListenable<double> progress;

  /// Called by a day-page grid with its `dayIndex` and reveal progress.
  final void Function(int dayIndex, double progress) report;

  const DayGridScope({
    super.key,
    required this.controller,
    required this.progress,
    required this.report,
    required super.child,
  });

  static DayGridScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DayGridScope>();

  @override
  bool updateShouldNotify(DayGridScope oldWidget) =>
      progress != oldWidget.progress || controller != oldWidget.controller;
}

/// Grid-mode Daily page body (P6): a fixed-height top bar
/// ([DayGridTopChromeRow]) over the day grid ([DailyTileList]) filling the
/// remaining `Expanded` space. The day selector, big date, and alert rows
/// live INSIDE each day-page's grid scroll view as its negative-extent
/// header (`DayGridScrollHeader` via `DayGridWidget.header`), so pulling
/// down reveals them and nothing above the grid ever changes height.
///
/// Replaces the legacy `Stack` overlay when [DailyViewLayoutCubit] is grid.
/// Extracted from `AuthorizedRoute.renderAuthorizedUserPageView` so the
/// layout is testable in isolation.
class GridDailyPageBody extends StatefulWidget {
  /// The day the grid is currently showing. Drives the top-bar pill and the
  /// list/grid toggle's analytics day index.
  final DateTime currentDate;

  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// Builds the day-grid body for the bounded `Expanded` region. Defaults to
  /// the real [DailyTileList] (sized to the region via `carouselHeight`).
  /// Overridable in tests with a lightweight stand-in.
  final Widget Function(double maxHeight)? gridBodyBuilder;

  /// Seam for the day-pill date picker, passed through to
  /// [DayGridTopChromeRow].
  final DayGridDatePicker? pickDate;

  const GridDailyPageBody({
    super.key,
    required this.currentDate,
    required this.onSearch,
    required this.onSettings,
    required this.onGoToToday,
    this.gridBodyBuilder,
    this.pickDate,
  });

  @override
  State<GridDailyPageBody> createState() => _GridDailyPageBodyState();
}

class _GridDailyPageBodyState extends State<GridDailyPageBody> {
  final ValueNotifier<double> _headerReveal = ValueNotifier<double>(0.0);

  /// The shared zoom controller for every day page (see [DayGridScope]).
  final DayGridController _gridController = DayGridController();

  @override
  void initState() {
    super.initState();
    // Restore the last settled zoom ONCE for all pages.
    _gridController.restoreFromPrefs();
  }

  @override
  void dispose() {
    _headerReveal.dispose();
    _gridController.dispose();
    super.dispose();
  }

  int _currentDayIndex() {
    final state = context.read<UiDateManagerBloc>().state;
    if (state is UiDateManagerUpdated) {
      return state.currentDate.universalDayIndex;
    }
    return widget.currentDate.universalDayIndex;
  }

  void _report(int dayIndex, double progress) {
    if (dayIndex != _currentDayIndex()) return;
    _headerReveal.value = progress;
  }

  void _onDateSelected(DateTime pickedDate) {
    // C16: dispatch the picked day through UiDateManagerBloc, mirroring
    // DayRibbonCarousel.onDateButtonTapped — same DateChangeEvent /
    // DateChangeTrigger.buttonPress, guarded on the day actually changing.
    final uiDateManagerBloc = context.read<UiDateManagerBloc>();
    DateTime previousDate = widget.currentDate;
    final currentState = uiDateManagerBloc.state;
    if (currentState is UiDateManagerUpdated) {
      previousDate = currentState.currentDate;
    }
    if (pickedDate.millisecondsSinceEpoch !=
        previousDate.millisecondsSinceEpoch) {
      uiDateManagerBloc.add(DateChangeEvent(
        previousSelectedDate: previousDate,
        selectedDate: pickedDate,
        dateChangeTrigger: DateChangeTrigger.buttonPress,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UiDateManagerBloc, UiDateManagerState>(
      // A day swap lands the new page's grid at/below its grid top (the
      // header is never auto-revealed), so the pill must be back at full
      // opacity — reset here because the new grid only reports CHANGES.
      listenWhen: (previous, current) =>
          previous is UiDateManagerUpdated &&
          current is UiDateManagerUpdated &&
          previous.currentDate.universalDayIndex !=
              current.currentDate.universalDayIndex,
      listener: (context, state) => _headerReveal.value = 0.0,
      child: DayGridScope(
        controller: _gridController,
        progress: _headerReveal,
        report: _report,
        child: Column(children: [
          DayGridTopChromeRow(
            currentDate: widget.currentDate,
            onSearch: widget.onSearch,
            onSettings: widget.onSettings,
            onGoToToday: widget.onGoToToday,
            dayGridLayout: context.read<DailyViewLayoutCubit>().state,
            onDayGridLayoutToggle: () => context
                .read<DailyViewLayoutCubit>()
                .toggle(dayIndex: widget.currentDate.universalDayIndex),
            pickDate: widget.pickDate,
            onDateSelected: _onDateSelected,
            headerReveal: _headerReveal,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double maxHeight = constraints.maxHeight;
                if (kDebugMode && maxHeight <= 0) {
                  debugPrint(
                      'GridDailyPageBody: grid region resolved to a non-positive '
                      'height ($maxHeight) — the top bar is consuming the '
                      'whole viewport.');
                }
                return widget.gridBodyBuilder != null
                    ? widget.gridBodyBuilder!(maxHeight)
                    : DailyTileList(carouselHeight: maxHeight);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
