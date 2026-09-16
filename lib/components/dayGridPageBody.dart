import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayContentFilterStrip.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/dayQuickActionsRow.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/util.dart';

/// Scope shared by every grid-mode day page (provided by
/// [GridDailyPageBody]; looked up, dependency-free, by `DayGridPage`): the
/// ONE `DayGridController` (zoom) for all day pages. Owned + restored from
/// prefs once by the body, so a page sliding into view mounts already at
/// the stored zoom (no per-page async restore re-laying every tile out),
/// and a pinch on one day is live on every other day.
///
/// Absent outside grid mode / in isolated tests — null-check [maybeOf].
class DayGridScope extends InheritedWidget {
  final DayGridController controller;

  const DayGridScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static DayGridScope? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<DayGridScope>();

  @override
  bool updateShouldNotify(DayGridScope oldWidget) =>
      controller != oldWidget.controller;
}

/// The Daily page body — ONE composition for both layouts (list and grid):
///
///  1. the fixed top bar ([DayGridTopChromeRow] —
///     `toggle · day pill ▾ · summary · … · search · settings`),
///  2. the compact, swipeable day strip ([DayRibbonCarousel] in `compact`
///     mode), always visible, in-flow, a single instance for all days,
///  3. the quick actions ([DayQuickActionsRow]: show route · re-optimize +
///     the schedule loading bar), always present,
///  4. the day carousel ([DailyTileList]) filling the remaining `Expanded`
///     space — list pages or grid pages per [DailyViewLayoutCubit].
///
/// Nothing above the content ever changes height, and the day selector is
/// never an overlay, so neither layout can be covered or pushed around.
/// Extracted from `AuthorizedRoute.renderAuthorizedUserPageView` so the
/// layout is testable in isolation.
class GridDailyPageBody extends StatefulWidget {
  /// The day currently shown. Drives the top-bar pill, the strip anchor and
  /// the list/grid toggle's analytics day index.
  final DateTime currentDate;

  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// Builds the day content for the bounded `Expanded` region. Defaults to
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

  /// The in-flow day strip's height (strip + 8px top inset).
  static const double dayStripHeight = DayRibbonCarousel.compactHeight + 8;

  @override
  State<GridDailyPageBody> createState() => _GridDailyPageBodyState();
}

class _GridDailyPageBodyState extends State<GridDailyPageBody> {
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
    _gridController.dispose();
    super.dispose();
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
    final colorScheme = Theme.of(context).colorScheme;
    return DayGridScope(
      controller: _gridController,
      // P7: an added tile the filter would hide clears the filter (+toast).
      child: DayContentFilterAutoClear(
        currentDate: widget.currentDate,
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
        ),
        // The day strip: one compact, swipeable instance for both layouts.
        // It anchors on the bloc's current date and dispatches
        // DateChangeEvent like the ribbon always has.
        Container(
          key: const Key('dailyDayStrip'),
          height: GridDailyPageBody.dayStripHeight,
          width: double.infinity,
          padding: const EdgeInsets.only(top: 8),
          color: colorScheme.surface,
          child: DayRibbonCarousel(
            widget.currentDate,
            autoUpdateAnchorDate: false,
            topMargin: 0,
            compact: true,
          ),
        ),
        // Show route · Re-optimize · content filter (+ loading bar): the
        // same actions the list's sticky header used to carry, now shared
        // by both layouts.
        DayQuickActionsRow(currentDate: widget.currentDate),
        // P7: "Showing blocks only · 4 of 11 · Show all" while filtered.
        DayContentFilterStrip(currentDate: widget.currentDate),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double maxHeight = constraints.maxHeight;
              if (kDebugMode && maxHeight <= 0) {
                debugPrint(
                    'GridDailyPageBody: day region resolved to a non-positive '
                    'height ($maxHeight) — the bar + strip are consuming the '
                    'whole viewport.');
              }
              return widget.gridBodyBuilder != null
                  ? widget.gridBodyBuilder!(maxHeight)
                  : DailyTileList(
                      carouselHeight: maxHeight,
                      // The bar carries the day + summary entry; list pages
                      // skip their own day-summary block.
                      showDaySummaryHeader: false,
                    );
            },
          ),
        ),
        ]),
      ),
    );
  }
}
