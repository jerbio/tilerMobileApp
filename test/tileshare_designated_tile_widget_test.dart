// The old invitation tile's forecast button (the binoculars). A pending task
// whose deadline has passed cannot be forecast - the forecast runs from now to
// the deadline - so instead of the button silently vanishing the binoculars
// stay, struck through and disabled, and the tile says "Deadline passed".
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/designatedTileWidget.dart';
import 'package:tiler_app/services/tileShare/tileShareForecastRequest.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const int _hour = 3600000;

DesignatedTile _tile({String status = 'none', required int end}) =>
    DesignatedTile.fromJson({
      'id': 'd1',
      'name': 'Review the deck',
      'invitationStatus': status,
      'template': {'id': 't1', 'duration': _hour, 'end': end},
    });

Future<void> _pump(WidgetTester tester, DesignatedTile tile,
    {double width = 390, ThemeData? theme}) async {
  tester.view.physicalSize = Size(width, 700);
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
    home: Scaffold(body: ListView(children: [DesignatedTileWidget(tile)])),
  ));
  await tester.pump();
}

Finder _key(String k) => find.byKey(Key(k));

void main() {
  final int now = Utility.msCurrentTime;

  testWidgets('a pending task with a future deadline offers the forecast',
      (tester) async {
    await _pump(tester, _tile(end: now + 24 * _hour));
    final button = tester.widget<ElevatedButton>(_key('forecast_binoculars'));
    expect(button.onPressed, isNotNull);
    expect(_key('forecast_binoculars_struck'), findsNothing);
    expect(find.text('Deadline passed'), findsNothing);
  });

  testWidgets('a pending task past its deadline still shows the binoculars, '
      'struck through and disabled, and says "Deadline passed"',
      (tester) async {
    await _pump(tester, _tile(end: now - _hour));
    expect(_key('forecast_binoculars'), findsNothing);
    final struck =
        tester.widget<ElevatedButton>(_key('forecast_binoculars_struck'));
    expect(struck.onPressed, isNull);
    expect(find.byTooltip('Deadline passed'), findsOneWidget);
    expect(find.text('Deadline passed'), findsOneWidget,
        reason: 'the struck icon and the words, both');
  });

  testWidgets('an accepted task shows neither', (tester) async {
    await _pump(tester, _tile(status: 'accepted', end: now - _hour));
    expect(_key('forecast_binoculars'), findsNothing);
    expect(_key('forecast_binoculars_struck'), findsNothing);
    expect(find.text('Deadline passed'), findsNothing);
  });

  testWidgets('fits a narrow phone in both themes', (tester) async {
    for (final theme in [TileThemeData.lightTheme, TileThemeData.darkTheme]) {
      await _pump(tester, _tile(end: now - _hour), width: 320, theme: theme);
      expect(tester.takeException(), isNull);
    }
  });

  test('overdue: pending, with a deadline that has passed', () {
    expect(TileShareForecastRequest.isOverdue(_tile(end: now - 1), now), isTrue);
    expect(TileShareForecastRequest.isOverdue(_tile(end: now + _hour), now),
        isFalse);
    expect(
        TileShareForecastRequest.isOverdue(
            _tile(status: 'accepted', end: now - 1), now),
        isFalse);
    expect(
        TileShareForecastRequest.isOverdue(
            DesignatedTile.fromJson({'id': 'x', 'invitationStatus': 'none'}),
            now),
        isFalse,
        reason: 'no deadline is not overdue');
  });
}
