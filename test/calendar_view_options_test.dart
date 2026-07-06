// calendar_view_options_test.dart
//
// Phase 1 (TDD) — pure logic behind the calendar-view switcher pop-out.
//
// The right-hand bottom-nav button reflects the active view and, when tapped,
// opens an anchored pop-out listing the *other* two views (the active one is
// skipped because the nav icon already represents it).
//
// This suite pins down the two pure pieces that power that behaviour:
//   1. `otherCalendarViews(current)` — the fixed-order list of views to offer.
//   2. `AuthorizedRouteTileListPage.navIcon` — the glyph shown per view.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/calendarViewSwitcher/calendarViewOptions.dart';

void main() {
  group('otherCalendarViews', () {
    test('from Daily offers Weekly then Monthly (fixed order)', () {
      expect(
        otherCalendarViews(AuthorizedRouteTileListPage.Daily),
        [
          AuthorizedRouteTileListPage.Weekly,
          AuthorizedRouteTileListPage.Monthly,
        ],
      );
    });

    test('from Weekly offers Daily then Monthly (fixed order)', () {
      expect(
        otherCalendarViews(AuthorizedRouteTileListPage.Weekly),
        [
          AuthorizedRouteTileListPage.Daily,
          AuthorizedRouteTileListPage.Monthly,
        ],
      );
    });

    test('from Monthly offers Daily then Weekly (fixed order)', () {
      expect(
        otherCalendarViews(AuthorizedRouteTileListPage.Monthly),
        [
          AuthorizedRouteTileListPage.Daily,
          AuthorizedRouteTileListPage.Weekly,
        ],
      );
    });

    test('always excludes the active view and offers exactly two', () {
      for (final view in AuthorizedRouteTileListPage.values) {
        final others = otherCalendarViews(view);
        expect(others, hasLength(2));
        expect(others, isNot(contains(view)));
      }
    });
  });

  group('navIcon', () {
    test('maps each view to its distinct glyph', () {
      expect(AuthorizedRouteTileListPage.Daily.navIcon, Icons.view_day);
      expect(AuthorizedRouteTileListPage.Weekly.navIcon, Icons.view_week);
      expect(
        AuthorizedRouteTileListPage.Monthly.navIcon,
        Icons.calendar_view_month,
      );
    });

    test('every view has a unique icon', () {
      final icons = AuthorizedRouteTileListPage.values
          .map((v) => v.navIcon)
          .toSet();
      expect(icons, hasLength(AuthorizedRouteTileListPage.values.length));
    });
  });
}
