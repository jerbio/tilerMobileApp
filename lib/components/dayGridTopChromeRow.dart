import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todayStatusScreen.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/util.dart';

/// Signature of the injectable date-picker seam used by
/// [DayGridTopChromeRow]. Mirrors the relevant parameters of
/// Flutter's built-in `showDatePicker`: it receives the context plus the
/// initial / first / last dates and returns the picked date, or null when the
/// user cancels.
typedef DayGridDatePicker = Future<DateTime?> Function(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
});

/// Grid-mode fixed top bar (P6, C19/C20):
///
/// `[list/grid toggle]   [ day pill ▾ ] [summary]   [go-to-today?] [search] [settings]`
///
/// - The bar has a **constant height** ([height]); nothing in it changes
///   layout when the scrolling header (`DayGridScrollHeader`) is revealed —
///   the day pill only cross-fades (opacity) by [headerReveal] so the big
///   date in the header is never duplicated on screen (no-snap rule 1).
/// - The day pill is tappable (C16): it opens a date picker; a confirmed
///   selection is reported via [onDateSelected]. Cancelling invokes nothing.
/// - The summary button (C20) opens [TodayStatusScreen] for the **shown**
///   day — today or any other day — with that day's start→end [Timeline].
///
/// This widget knows nothing about `UiDateManagerBloc` — the date-picker
/// wiring is injected via [onDateSelected], so the row stays testable.
class DayGridTopChromeRow extends StatelessWidget {
  /// Spotlight / test key for the tappable day pill.
  static const Key dayLabelKey = ValueKey('dayGridTopChromeDayLabel');

  /// Test key for the day-summary button.
  static const Key summaryButtonKey = ValueKey('dayGridTopChromeSummary');

  /// Test key for the list/grid toggle (left slot).
  static const Key layoutToggleKey = ValueKey('dayGridTopChromeLayoutToggle');

  /// The bar's fixed height (a standard 48px icon-button row).
  static const double height = 48;

  /// The day the grid is currently showing. Rendered as the pill label,
  /// used as the date picker's initial date and as the summary's day.
  final DateTime currentDate;

  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// When non-null (and [onDayGridLayoutToggle] is set) the list/grid
  /// toggle button is shown in the left slot.
  final DailyViewLayout? dayGridLayout;
  final VoidCallback? onDayGridLayoutToggle;

  /// Invoked with the picked date when the user confirms a date in the picker.
  final ValueChanged<DateTime>? onDateSelected;

  /// Seam for the date-picker dialog (tests inject a fake).
  final DayGridDatePicker? pickDate;

  /// How much of the scrolling header is revealed (0 → 1). The day pill's
  /// opacity is `1 - reveal`. Null = always fully visible.
  final ValueListenable<double>? headerReveal;

  const DayGridTopChromeRow({
    super.key,
    required this.currentDate,
    required this.onSearch,
    required this.onSettings,
    required this.onGoToToday,
    this.dayGridLayout,
    this.onDayGridLayoutToggle,
    this.onDateSelected,
    this.pickDate,
    this.headerReveal,
  });

  /// Production-inert observable for the summary-open tag (see
  /// [summaryOpenTag]); a widget test increments it through a REAL tap to
  /// prove the tag fires. Never read by production logic.
  static int summaryOpenTagFireCount = 0;

  /// Fires `daygrid_summary_opened` (grid-mode only) and returns the debug
  /// line so it can be asserted headlessly. [isToday] lets the open rate be
  /// split for today vs. any other day (C20 feedback signal).
  static String summaryOpenTag(int dayIndex, {required bool isToday}) {
    summaryOpenTagFireCount++;
    final String line =
        'DayGrid:: daygrid_summary_opened (dayIndex: $dayIndex, isToday: $isToday)';
    Utility.debugPrint(line);
    AnalysticsSignal.send(
      'daygrid_summary_opened',
      additionalInfo: {'dayIndex': dayIndex, 'isToday': isToday},
    );
    return line;
  }

  Future<void> _onDayLabelTapped(BuildContext context) async {
    AnalysticsSignal.send(
      'daygrid_date_picker_opened',
      additionalInfo: {'dayIndex': currentDate.universalDayIndex},
    );

    // The codebase has no single shared min/max for showDatePicker
    // (existing call sites range from ±180 days to ±999999 days). Default to a
    // generous multi-year window centred on the shown day so the initial date
    // is always in range and the user can jump to (nearly) any date.
    final DateTime firstDate = currentDate.subtract(const Duration(days: 3650));
    final DateTime lastDate = currentDate.add(const Duration(days: 3650));

    final DateTime? picked = pickDate != null
        ? await pickDate!(context,
            initialDate: currentDate,
            firstDate: firstDate,
            lastDate: lastDate)
        : await showDatePicker(
            context: context,
            initialDate: currentDate,
            firstDate: firstDate,
            lastDate: lastDate,
          );

    if (picked != null) {
      AnalysticsSignal.send(
        'daygrid_date_picker_selected',
        additionalInfo: {'dayIndex': picked.universalDayIndex},
      );
      onDateSelected?.call(picked);
    }
  }

  /// C20: open the day summary for the shown day (today or any other).
  void _onSummaryTapped(BuildContext context) {
    final int dayIndex = currentDate.universalDayIndex;
    summaryOpenTag(dayIndex, isToday: currentDate.isToday);
    final DateTime start = Utility.getTimeFromIndex(dayIndex);
    final DateTime end = start.endOfDay;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodayStatusScreen(
          timeline:
              Timeline(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch),
        ),
      ),
    );
  }

  Widget _dayPill(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Widget pill = Material(
      color: colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onDayLabelTapped(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 7, 10, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  currentDate.humanDate(context),
                  key: dayLabelKey,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 18, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
    final ValueListenable<double>? reveal = headerReveal;
    if (reveal == null) return pill;
    // Opacity-only cross-fade (no layout change) — and a hidden pill must
    // not be tappable.
    return ValueListenableBuilder<double>(
      valueListenable: reveal,
      builder: (context, progress, child) {
        final double opacity = (1.0 - progress).clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: opacity < 0.5,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: pill,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final bool showToggle = dayGridLayout != null && onDayGridLayoutToggle != null;
    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            // Left slot: the list/grid toggle (C19) — a fixed-width slot so
            // the centre never shifts when it is absent.
            SizedBox(
              width: 48,
              child: showToggle
                  ? IconButton(
                      key: layoutToggleKey,
                      icon: Icon(
                        dayGridLayout == DailyViewLayout.grid
                            ? Icons.view_list
                            : Icons.grid_view,
                        color: colorScheme.primary,
                      ),
                      onPressed: onDayGridLayoutToggle,
                      tooltip: l10n.switchDayGridLayout,
                    )
                  : null,
            ),
            // Centre: day pill + summary button.
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: _dayPill(context)),
                  IconButton(
                    key: summaryButtonKey,
                    icon: Icon(Icons.assessment_outlined,
                        color: colorScheme.primary),
                    onPressed: () => _onSummaryTapped(context),
                    tooltip: l10n.dayGridDaySummary,
                  ),
                ],
              ),
            ),
            // Right cluster: go-to-today (non-today only), search, settings.
            // The toggle is rendered in the left slot instead.
            HomeTopRightActionsRow(
              isViewingToday: currentDate.isToday,
              onSearch: onSearch,
              onSettings: onSettings,
              onGoToToday: onGoToToday,
            ),
          ],
        ),
      ),
    );
  }
}
