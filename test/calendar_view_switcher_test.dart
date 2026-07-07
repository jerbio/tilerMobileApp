// calendar_view_switcher_test.dart
//
// Phase 2 (TDD) — the bottom-nav calendar-view switcher widget behaviour.
//
// Contract:
//   * The right nav item renders an icon that REFLECTS the active view
//     (Daily -> view_day, Weekly -> view_week, Monthly -> calendar_view_month),
//     never the old generic calendar_month.
//   * Tapping it opens an anchored pop-out (a menu, not a dialog) listing the
//     TWO other views — the active view is skipped.
//   * Picking a view invokes onSelectView with that view.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/homeBottomNav.dart';
import 'package:tiler_app/components/calendarViewSwitcher/calendarViewOptions.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: Scaffold(bottomNavigationBar: child),
  );
}

HomeBottomNav _nav({
  required AuthorizedRouteTileListPage currentView,
  ValueChanged<AuthorizedRouteTileListPage>? onSelectView,
}) {
  return HomeBottomNav(
    onShare: () {},
    onAddTile: () {},
    currentView: currentView,
    onSelectView: onSelectView ?? (_) {},
  );
}

// Opens the anchored pop-out without pumpAndSettle (AutoSwitchingWidget in the
// centre logo runs a periodic timer, so we advance a fixed amount instead).
Future<void> _openMenu(
  WidgetTester tester,
  AuthorizedRouteTileListPage currentView,
) async {
  await tester.tap(find.byIcon(currentView.navIcon));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resting icon reflects the active view', () {
    testWidgets('Daily -> view_day', (tester) async {
      await tester.pumpWidget(
          _wrap(_nav(currentView: AuthorizedRouteTileListPage.Daily)));
      await tester.pump();

      expect(find.byIcon(Icons.view_day), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month), findsNothing,
          reason: 'The switcher must no longer use the generic calendar icon.');
    });

    testWidgets('Weekly -> view_week', (tester) async {
      await tester.pumpWidget(
          _wrap(_nav(currentView: AuthorizedRouteTileListPage.Weekly)));
      await tester.pump();

      expect(find.byIcon(Icons.view_week), findsOneWidget);
    });

    testWidgets('Monthly -> calendar_view_month', (tester) async {
      await tester.pumpWidget(
          _wrap(_nav(currentView: AuthorizedRouteTileListPage.Monthly)));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_view_month), findsOneWidget);
    });
  });

  group('pop-out lists the two other views', () {
    testWidgets('from Daily shows Weekly + Monthly, not Daily', (tester) async {
      await tester.pumpWidget(
          _wrap(_nav(currentView: AuthorizedRouteTileListPage.Daily)));
      await tester.pump();

      await _openMenu(tester, AuthorizedRouteTileListPage.Daily);

      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Daily'), findsNothing,
          reason: 'The active view is skipped in the pop-out.');
    });

    testWidgets('from Monthly shows Daily + Weekly, not Monthly',
        (tester) async {
      await tester.pumpWidget(
          _wrap(_nav(currentView: AuthorizedRouteTileListPage.Monthly)));
      await tester.pump();

      await _openMenu(tester, AuthorizedRouteTileListPage.Monthly);

      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsNothing);
    });
  });

  group('selecting a view', () {
    testWidgets('invokes onSelectView with the chosen view', (tester) async {
      AuthorizedRouteTileListPage? picked;
      await tester.pumpWidget(_wrap(_nav(
        currentView: AuthorizedRouteTileListPage.Daily,
        onSelectView: (view) => picked = view,
      )));
      await tester.pump();

      await _openMenu(tester, AuthorizedRouteTileListPage.Daily);
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(picked, AuthorizedRouteTileListPage.Monthly);
    });
  });
}
