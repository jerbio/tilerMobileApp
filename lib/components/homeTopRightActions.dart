import 'package:flutter/material.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

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

  const HomeTopRightActions({
    super.key,
    required this.isViewingToday,
    required this.onSearch,
    required this.onSettings,
    required this.onGoToToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
