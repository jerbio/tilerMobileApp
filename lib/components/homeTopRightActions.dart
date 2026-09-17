import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';

/// Reusable, non-Positioned row of the home screen's top-right icon cluster.
///
/// Extracted from [HomeTopRightActions] so it can be used both by the legacy
/// overlay call site (list/Weekly/Monthly, where [HomeTopRightActions] wraps
/// this in a [Positioned]) and by the grid-mode DayGridTopChromeRow, which
/// needs the same icons in a real in-flow row instead of a Stack overlay.
/// Renders the exact same icons/callbacks as [HomeTopRightActions] did before
/// this extraction.
class HomeTopRightActionsRow extends StatelessWidget {
  final bool isViewingToday;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// The current Daily-view layout. When non-null (and
  /// [onDayGridLayoutToggle] is set) the list/grid toggle button is shown.
  final DailyViewLayout? dayGridLayout;
  final VoidCallback? onDayGridLayoutToggle;

  const HomeTopRightActionsRow({
    super.key,
    required this.isViewingToday,
    required this.onSearch,
    required this.onSettings,
    required this.onGoToToday,
    this.dayGridLayout,
    this.onDayGridLayoutToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      key: TutorialKeys.topRightActionsKey,
      mainAxisSize: MainAxisSize.min,
      children: [
        // list <-> grid toggle (Daily view only). The icon
        // shows the layout the user would switch TO.
        if (dayGridLayout != null && onDayGridLayoutToggle != null)
          IconButton(
            icon: Icon(
              dayGridLayout == DailyViewLayout.grid
                  ? Icons.view_list
                  : Icons.grid_view,
              color: colorScheme.primary,
            ),
            onPressed: onDayGridLayoutToggle,
            tooltip: AppLocalizations.of(context)!.switchDayGridLayout,
          ),
        if (!isViewingToday)
          IconButton(
            icon: Icon(Icons.calendar_today, color: colorScheme.primary),
            onPressed: onGoToToday,
            tooltip: AppLocalizations.of(context)!.goToToday,
          ),
        IconButton(
          icon: Icon(Icons.search, color: colorScheme.primary),
          onPressed: onSearch,
          tooltip: AppLocalizations.of(context)!.search,
        ),
        IconButton(
          icon: Icon(Icons.settings, color: colorScheme.primary),
          onPressed: onSettings,
          tooltip: AppLocalizations.of(context)!.settings,
        ),
      ],
    );
  }
}

/// Persistent top-right overlay shown on the home screen.
///
/// Always shows [Icons.search] and [Icons.settings].
/// The "Go to Today" button ([Icons.calendar_today]) is shown only when
/// [isViewingToday] is false (i.e. the user has navigated away from today).
///
/// This is now a thin [Positioned] wrapper around
/// [HomeTopRightActionsRow] so the icon logic can also be reused in-flow by
/// the grid-mode top chrome row. Renders identically to the pre-extraction
/// overlay for every existing list/Weekly/Monthly call site.
class HomeTopRightActions extends StatelessWidget {
  final bool isViewingToday;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// The current Daily-view layout. When non-null (and
  /// [onDayGridLayoutToggle] is set) the list/grid toggle button is shown.
  final DailyViewLayout? dayGridLayout;
  final VoidCallback? onDayGridLayoutToggle;

  const HomeTopRightActions({
    super.key,
    required this.isViewingToday,
    required this.onSearch,
    required this.onSettings,
    required this.onGoToToday,
    this.dayGridLayout,
    this.onDayGridLayoutToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 8,
      child: HomeTopRightActionsRow(
        isViewingToday: isViewingToday,
        onSearch: onSearch,
        onSettings: onSettings,
        onGoToToday: onGoToToday,
        dayGridLayout: dayGridLayout,
        onDayGridLayoutToggle: onDayGridLayoutToggle,
      ),
    );
  }
}
