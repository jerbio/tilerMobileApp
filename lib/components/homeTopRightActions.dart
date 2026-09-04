import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';

/// Persistent top-right overlay shown on the home screen.
///
/// Always shows [Icons.search] and [Icons.settings].
/// The "Go to Today" button ([Icons.calendar_today]) is shown only when
/// [isViewingToday] is false (i.e. the user has navigated away from today).
class HomeTopRightActions extends StatelessWidget {
  final bool isViewingToday;
  final VoidCallback onSearch;
  final VoidCallback onSettings;
  final VoidCallback onGoToToday;

  /// P1 (step 1.5): the current Daily-view layout. When non-null (and
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
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 0,
      right: 8,
      child: Row(
        key: TutorialKeys.topRightActionsKey,
        mainAxisSize: MainAxisSize.min,
        children: [
          // P1 (step 1.5): list <-> grid toggle (Daily view only). The icon
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
      ),
    );
  }
}
