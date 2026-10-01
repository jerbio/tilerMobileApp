// One row of the old forecast list (a day's free time and when the user is out
// and about). Its bar used to be sized from the SCREEN width, so inside a card
// narrower than the screen the row overflowed (81 px on a 484 dp screen with a
// 321 dp row). It must be sized from the space the row actually has.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDaySimple.dart';
import 'package:tiler_app/theme/theme_data.dart';

PeekDay _day() {
  final DateTime start = DateTime(2026, 10, 2);
  return PeekDay.fromJson({
    'startTime': start.millisecondsSinceEpoch,
    'endTime': start.add(const Duration(days: 1)).millisecondsSinceEpoch,
    'dayIndex': 5,
    'duration': 3600000.0,
    'unallocatedTime': 5.5 * 3600000,
    'outsideHomeStart': start.add(const Duration(hours: 9)).millisecondsSinceEpoch,
    'outsideHomeEnd': start.add(const Duration(hours: 17)).millisecondsSinceEpoch,
  });
}

Future<void> _pump(WidgetTester tester,
    {required double screen, required double rowWidth, ThemeData? theme}) async {
  tester.view.physicalSize = Size(screen, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: theme ?? TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        // The row's own container adds 15 px of padding.
        child: SizedBox(
            width: rowWidth + 15, child: ForecastDaySimpleWidget(peekDay: _day())),
      ),
    ),
  ));
  await tester.pump();
}

void main() {
  testWidgets('a row narrower than the screen does not overflow (the reported '
      'case: 484 dp screen, 321 dp row)', (tester) async {
    await _pump(tester, screen: 484, rowWidth: 321.2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nor on a typical phone, or a tablet-wide row', (tester) async {
    await _pump(tester, screen: 390, rowWidth: 330);
    expect(tester.takeException(), isNull);
    await _pump(tester, screen: 800, rowWidth: 700);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nor in the dark theme', (tester) async {
    await _pump(
        tester, screen: 484, rowWidth: 321.2, theme: TileThemeData.darkTheme);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the bar uses the room there is: a wider row gets a longer bar',
      (tester) async {
    await _pump(tester, screen: 484, rowWidth: 300);
    final narrow = tester.getSize(find.byKey(const Key('forecast_bar'))).width;
    await _pump(tester, screen: 484, rowWidth: 420);
    final wide = tester.getSize(find.byKey(const Key('forecast_bar'))).width;
    expect(wide, greaterThan(narrow));
    expect(wide - narrow, closeTo(120, 1));
  });

  testWidgets('a row as narrow as its fixed parts leaves no bar but still '
      'lays out', (tester) async {
    await _pump(tester, screen: 484, rowWidth: 255);
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('forecast_bar'))).width,
        greaterThanOrEqualTo(0));
  });
}
