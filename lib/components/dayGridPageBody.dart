import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonTab.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';
import 'package:tiler_app/util.dart';

/// Grid-mode Daily page body: the in-flow
/// `Column` composition that replaces the legacy `Stack` overlay when
/// [DailyViewLayoutCubit] is grid. Top to bottom:
///
///  1. [DayGridTopChromeRow] — tappable human day label + top-right actions.
///  2. the day ribbon (or its collapsed today tab), laid out in-flow — NOT an
///     `Align` overlay — so the 50px overlay top margin is dropped.
///  3. the day grid ([DailyTileList]) filling the remaining `Expanded` space.
///
/// The grid's own scroll viewport genuinely starts BELOW the chrome:
/// it is the `Expanded` region, so it never runs behind/under the day
/// selector. Extracted from
/// `AuthorizedRoute.renderAuthorizedUserPageView` (which only takes this path
/// for Daily + grid) so the layout is testable in isolation — the full route
/// carries auth/network/platform-channel dependencies that are out of scope
/// for a layout test.
class GridDailyPageBody extends StatelessWidget {
  /// The day the grid is currently showing. Drives the chrome label and the
  /// list/grid toggle's analytics day index.
  final DateTime currentDate;

  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// Builds the day-grid body for the bounded `Expanded` region. Defaults to
  /// the real [DailyTileList] (sized to the region via `carouselHeight`).
  /// Overridable in tests with a lightweight stand-in so the layout contract
  /// can be verified without the schedule-loading side effects of the real
  /// list.
  final Widget Function(double maxHeight)? gridBodyBuilder;

  /// Seam for the day-label date picker, passed through to
  /// [DayGridTopChromeRow]. When non-null it is called instead of Flutter's
  /// built-in `showDatePicker`, so tests drive a mocked picker and never need
  /// the real platform dialog.
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
  Widget build(BuildContext context) {
    return Column(children: [
      DayGridTopChromeRow(
        currentDate: currentDate,
        onSearch: onSearch,
        onSettings: onSettings,
        onGoToToday: onGoToToday,
        dayGridLayout: context.read<DailyViewLayoutCubit>().state,
        onDayGridLayoutToggle: () => context
            .read<DailyViewLayoutCubit>()
            .toggle(dayIndex: currentDate.universalDayIndex),
        pickDate: pickDate,
        onDateSelected: (pickedDate) {
          // C16: dispatch the picked day through UiDateManagerBloc, mirroring
          // DayRibbonCarousel.onDateButtonTapped — same DateChangeEvent /
          // DateChangeTrigger.buttonPress, guarded on the day actually
          // changing. previousSelectedDate is the bloc's current date (the
          // canonical shown day), falling back to the grid's currentDate.
          final uiDateManagerBloc = context.read<UiDateManagerBloc>();
          DateTime previousDate = currentDate;
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
        },
      ),
      _DailyRibbonInFlow(),
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double maxHeight = constraints.maxHeight;
            // Defensive (debug-only): should never happen once the grid is a
            // real `Expanded` region and `DailyTileList.carouselHeight` is
            // bounded — but a non-positive height would mean the chrome row +
            // ribbon are consuming the whole viewport, so surface it loudly.
            if (kDebugMode && maxHeight <= 0) {
              debugPrint(
                  'GridDailyPageBody: grid region resolved to a non-positive '
                  'height ($maxHeight) — the chrome row/ribbon are consuming '
                  'the whole viewport.');
            }
            return gridBodyBuilder != null
                ? gridBodyBuilder!(maxHeight)
                : DailyTileList(carouselHeight: maxHeight);
          },
        ),
      ),
    ]);
  }
}

/// The Daily ribbon laid out in-flow (below the chrome row). Mirrors
/// `AuthorizedRoute._ribbonCarousel`'s Daily case, but with `topMargin: 0` —
/// the 50px the overlay context reserved to clear the top-right actions is
/// unnecessary once the ribbon sits in the `Column` below the chrome row.
class _DailyRibbonInFlow extends StatelessWidget {
  const _DailyRibbonInFlow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UiDateManagerBloc, UiDateManagerState>(
      builder: (context, uiDateState) {
        DateTime ribbonDate = Utility.currentTime().dayDate;
        if (uiDateState is UiDateManagerUpdated) {
          ribbonDate = uiDateState.currentDate;
        }
        // Viewing today shows the collapsed tap-to-expand tab; any other
        // day shows the full ribbon, laid out in-flow.
        if (ribbonDate.isToday) {
          return DayRibbonTab(dayRibbonDate: ribbonDate);
        }
        return DayRibbonCarousel(ribbonDate,
            autoUpdateAnchorDate: false, topMargin: 0);
      },
    );
  }
}