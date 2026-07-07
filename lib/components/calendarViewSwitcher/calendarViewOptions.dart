import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Canonical, fixed display order for the calendar views.
///
/// The switcher pop-out always presents views in this order (minus the active
/// one), so the two offered choices stay in a predictable position regardless
/// of which view is currently active.
const List<AuthorizedRouteTileListPage> kOrderedCalendarViews = [
  AuthorizedRouteTileListPage.Daily,
  AuthorizedRouteTileListPage.Weekly,
  AuthorizedRouteTileListPage.Monthly,
];

/// The views to offer in the switcher pop-out for the given [current] view.
///
/// The active view is excluded (the nav icon already represents it), leaving
/// exactly the two other views in [kOrderedCalendarViews] order.
List<AuthorizedRouteTileListPage> otherCalendarViews(
  AuthorizedRouteTileListPage current,
) =>
    kOrderedCalendarViews.where((view) => view != current).toList(
          growable: false,
        );

/// Presentation helpers for a calendar view.
extension CalendarViewPresentation on AuthorizedRouteTileListPage {
  /// The glyph shown in the bottom-nav switcher (and pop-out rows) for the view.
  IconData get navIcon {
    switch (this) {
      case AuthorizedRouteTileListPage.Daily:
        return Icons.view_day;
      case AuthorizedRouteTileListPage.Weekly:
        return Icons.view_week;
      case AuthorizedRouteTileListPage.Monthly:
        return Icons.calendar_view_month;
    }
  }

  /// The localized label shown for the view in the switcher pop-out.
  String label(AppLocalizations l10n) {
    switch (this) {
      case AuthorizedRouteTileListPage.Daily:
        return l10n.daily;
      case AuthorizedRouteTileListPage.Weekly:
        return l10n.weekly;
      case AuthorizedRouteTileListPage.Monthly:
        return l10n.monthly;
    }
  }
}
