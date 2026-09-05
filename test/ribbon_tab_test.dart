// The day ribbon for today becomes a collapsed
// tap-to-expand tab instead of the hard hide (SizedBox.shrink) in
// AuthorizedRoute._ribbonCarousel: it starts collapsed while the viewed date
// is today, expands the DayRibbonCarousel on tap, and collapses again on
// re-tap or when a day is selected (a UiDateManagerBloc date change). The
// tab renders identically in list and grid modes; the day summary remains
// embedded in EnhancedWithinNowBatch (list) / the now-line (grid).
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonTab.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const _handleKey = Key('dayRibbonTabHandle');

/// The tab only makes sense while viewing today, so the fixture mirrors the
/// parent contract: the date manager starts on today and the tab is handed
/// today's date (exactly what AuthorizedRoute._ribbonCarousel computes).
Widget _buildApp({required UiDateManagerBloc dateBloc}) {
  final DateTime today = Utility.currentTime().dayDate;
  // The expanded ribbon listens to ScheduleBloc too (MultiBlocListener), so
  // the fixture must provide one; the no-op context callback mirrors the
  // existing bloc test convention.
  final ScheduleBloc scheduleBloc =
      ScheduleBloc(getContextCallBack: () => null);
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider.value(value: dateBloc),
        BlocProvider.value(value: scheduleBloc),
      ],
      child: Scaffold(
        // The tab is a top-aligned overlay on the day view, like the ribbon.
        body: Stack(children: [DayRibbonTab(dayRibbonDate: today)]),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Day ribbon tab', () {
    testWidgets('is collapsed when viewing today', (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(dateBloc: dateBloc));
      await tester.pump();

      // The slim collapsed handle is shown...
      expect(find.byKey(_handleKey), findsOneWidget);
      // ...and the ribbon itself is not rendered.
      expect(find.byType(DayRibbonCarousel), findsNothing);
    });

    testWidgets('expands the ribbon on tap', (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(dateBloc: dateBloc));
      await tester.pump();
      expect(find.byType(DayRibbonCarousel), findsNothing);

      await tester.tap(find.byKey(_handleKey));
      await tester.pumpAndSettle();

      expect(find.byType(DayRibbonCarousel), findsOneWidget);
      // The handle stays visible so the user can tap it again to collapse.
      expect(find.byKey(_handleKey), findsOneWidget);
    });

    testWidgets('collapses again on re-tap', (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(dateBloc: dateBloc));
      await tester.pump();

      await tester.tap(find.byKey(_handleKey));
      await tester.pumpAndSettle();
      expect(find.byType(DayRibbonCarousel), findsOneWidget);

      await tester.tap(find.byKey(_handleKey));
      await tester.pumpAndSettle();
      expect(find.byType(DayRibbonCarousel), findsNothing);
      expect(find.byKey(_handleKey), findsOneWidget);
    });

    testWidgets('collapses when a day is selected via the date manager',
        (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      await tester.pumpWidget(_buildApp(dateBloc: dateBloc));
      await tester.pump();

      await tester.tap(find.byKey(_handleKey));
      await tester.pumpAndSettle();
      expect(find.byType(DayRibbonCarousel), findsOneWidget);

      // Selecting a day routes a DateChangeEvent through UiDateManagerBloc
      // (same path as the ribbon's day buttons); the tab must fold back.
      final DateTime today = Utility.currentTime().dayDate;
      dateBloc.add(DateChangeEvent(
        previousSelectedDate: today,
        selectedDate: today.add(const Duration(days: 1)),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(DayRibbonCarousel), findsNothing);
      expect(find.byKey(_handleKey), findsOneWidget);
    });
  });
}