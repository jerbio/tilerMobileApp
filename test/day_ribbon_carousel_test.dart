// day_ribbon_carousel_test.dart
//
// P5 Step 15.1: DayRibbonCarousel currently bakes a fixed 50px top margin into
// its overlay layout (AuthorizedRoute renders it on top of the day view's
// Stack). Grid mode (P5) needs the ribbon in-flow inside a Column, where that
// margin must be reducible. This step adds a `topMargin` parameter defaulting
// to `50` so every existing overlay call site is pixel-identical; these tests
// pin the default and the override.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

/// Mirrors ribbon_tab_test.dart's harness: DayRibbonCarousel listens to both
/// UiDateManagerBloc and ScheduleBloc (MultiBlocListener), so both must be
/// provided. The ribbon is pumped into a top-aligned Stack, like the real
/// overlay call site (AuthorizedRoute._ribbonCarousel).
Widget _buildApp({required UiDateManagerBloc dateBloc, required Widget ribbon}) {
  final ScheduleBloc scheduleBloc = ScheduleBloc(getContextCallBack: () => null);
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
        body: Stack(children: [ribbon]),
      ),
    ),
  );
}

/// The ribbon body is the unique `height: 130` Container inside
/// DayRibbonCarousel; its `margin.top` is the effective top margin.
Finder _ribbonBody() => find.byWidgetPredicate((w) =>
    w is Container && w.constraints?.maxHeight == 130);

/// Asserts the ribbon body's top margin resolves to [expected].
void _expectTopMargin(WidgetTester tester, double expected) {
  expect(_ribbonBody(), findsOneWidget,
      reason: 'the 130px ribbon body must render');
  final body = tester.widget<Container>(_ribbonBody());
  final margin = body.margin;
  expect(margin, isA<EdgeInsets>(),
      reason: 'topMargin must be applied as the ribbon body Container margin');
  final insets = margin! as EdgeInsets;
  expect(insets.top, expected,
      reason: 'the ribbon body top margin must resolve to the effective topMargin');
  expect(insets.left, 0, reason: 'left margin must stay 0');
  expect(insets.right, 0, reason: 'right margin must stay 0');
  expect(insets.bottom, 0, reason: 'bottom margin must stay 0');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayRibbonCarousel topMargin', () {
    testWidgets('defaults to 50 when topMargin is omitted', (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      final DateTime today = Utility.currentTime().dayDate;

      await tester.pumpWidget(_buildApp(
        dateBloc: dateBloc,
        ribbon: DayRibbonCarousel(today),
      ));
      await tester.pump();

      // Omitting topMargin must preserve the existing 50px overlay margin so
      // every legacy list/Weekly/Monthly call site stays pixel-identical.
      _expectTopMargin(tester, 50);
    });

    testWidgets('honors a custom topMargin', (tester) async {
      final dateBloc = UiDateManagerBloc();
      addTearDown(dateBloc.close);
      final DateTime today = Utility.currentTime().dayDate;

      await tester.pumpWidget(_buildApp(
        dateBloc: dateBloc,
        ribbon: DayRibbonCarousel(today, topMargin: 100),
      ));
      await tester.pump();

      // A custom topMargin must replace the default 50px margin.
      _expectTopMargin(tester, 100);
    });
  });
}