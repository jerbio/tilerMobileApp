import 'package:flutter/material.dart';

import 'package:tiler_app/components/homeTopRightActions.dart';
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

/// Grid-mode top chrome row.
///
/// Leading: the currently-selected day, rendered via
/// [DateTimeHuman.humanDate] (Today / Tomorrow / Yesterday / a localized date).
/// Trailing: the shared [HomeTopRightActionsRow] icon cluster (list/grid
/// toggle, go-to-today, search, settings) — the exact same icons the legacy
/// [HomeTopRightActions] overlay shows, now laid out in-flow rather than as a
/// [Positioned] Stack overlay.
///
/// The day label is tappable: tapping it opens a date picker so the user
/// can jump to an arbitrary date, not just the days visible in the ribbon/tab
/// window or "today". On a confirmed selection the row calls [onDateSelected]
/// with the picked date; cancelling (a null result) invokes nothing.
///
/// This widget deliberately knows nothing about `UiDateManagerBloc` — the
/// date-picker wiring is injected via [onDateSelected], so the row stays
/// testable in isolation.
class DayGridTopChromeRow extends StatelessWidget {
  /// Spotlight / test key for the tappable day label.
  static const Key dayLabelKey = ValueKey('dayGridTopChromeDayLabel');

  /// The day the grid is currently showing. Rendered as the leading label and
  /// used as the date picker's initial date.
  final DateTime currentDate;

  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// Mirrors [HomeTopRightActionsRow]: when non-null (and
  /// [onDayGridLayoutToggle] is set) the list/grid toggle button is shown.
  final DailyViewLayout? dayGridLayout;
  final VoidCallback? onDayGridLayoutToggle;

  /// Invoked with the picked date when the user confirms a date in the picker.
  /// NOT invoked when the user cancels (null result). Wired to
  /// `UiDateManagerBloc` by its parent.
  final ValueChanged<DateTime>? onDateSelected;

  /// Seam for the date-picker dialog. When non-null it is called instead
  /// of Flutter's built-in `showDatePicker`, so tests never need the real
  /// platform dialog.
  final DayGridDatePicker? pickDate;

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
  });

  /// Tappable day-label handler: opens the date picker and, on a
  /// confirmed selection, reports the picked date via [onDateSelected].
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _onDayLabelTapped(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  currentDate.humanDate(context),
                  key: dayLabelKey,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          HomeTopRightActionsRow(
            isViewingToday: currentDate.isToday,
            onSearch: onSearch,
            onSettings: onSettings,
            onGoToToday: onGoToToday,
            dayGridLayout: dayGridLayout,
            onDayGridLayoutToggle: onDayGridLayoutToggle,
          ),
        ],
      ),
    );
  }
}