// Step 6.6 — one entry for every push site, one flag (D25).
//
// `TileDetailRoute` is a drop-in for the legacy `TileDetail(tileId:,
// loadSubEvents:)` constructor: the redesign when
// `EditTileFeatureFlags.editTileRedesignEnabled` is on (the SAME flag as
// Edit Tile — the two ship together), the legacy screen when it is off,
// with the same arguments. A source scan keeps every push site on it.
//
// Out of scope, deliberately: `TileDetail.byDesignatedTileId` (the tile
// share template path) loads by template id, not calendar-event id, and
// stays on the legacy screen.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'tile_detail_draft_test.dart' as fx;
import 'tile_detail_shell_test.dart' as shell;

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

/// Strips `//` comments so a mention in prose does not count.
String _code(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  setUp(() => EditTileFeatureFlags.editTileRedesignEnabled = false);
  tearDown(() => EditTileFeatureFlags.editTileRedesignEnabled = false);

  Future<void> pumpEntry(WidgetTester tester,
      {required Widget Function(String, bool) legacy}) async {
    await tester.pumpWidget(MaterialApp(
      theme: TileThemeData.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: TileDetailRoute(
        tileId: 'cal-1',
        loadSubEvents: false,
        legacyBuilder: legacy,
        redesignBuilder: (BuildContext _, String id) =>
            TileDetailRedesignScreen(
          calendarEventId: id,
          loader:
              shell.FakeLoader(TileDetailLoadResult.success(fx.loaded(), null)),
          submission: shell.FakeSubmission(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('flag off → the legacy screen, with the same arguments',
      (tester) async {
    final List<String> built = <String>[];
    await pumpEntry(tester, legacy: (String id, bool loadSubEvents) {
      built.add('$id:$loadSubEvents');
      return const Scaffold(body: Text('legacy'));
    });
    expect(built, <String>['cal-1:false']);
    expect(find.text('legacy'), findsOneWidget);
    expect(find.byType(TileDetailRedesignScreen), findsNothing);
  });

  testWidgets('flag on → the redesign, for the same id', (tester) async {
    EditTileFeatureFlags.editTileRedesignEnabled = true;
    await pumpEntry(tester,
        legacy: (_, __) => const Scaffold(body: Text('legacy')));
    expect(find.text('legacy'), findsNothing);
    final TileDetailRedesignScreen screen =
        tester.widget<TileDetailRedesignScreen>(
            find.byType(TileDetailRedesignScreen));
    expect(screen.calendarEventId, 'cal-1');
  });

  test('no production file constructs the legacy TileDetail directly', () {
    // Every push site goes through TileDetailRoute, so the ONE flag governs
    // both screens and 5.4 can delete the legacy screens in one move.
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String path = e.path.replaceAll('\\', '/');
      if (path.endsWith('/tileDetails/tileDetail.dart')) continue;
      if (path.contains('/tileDetails/redesign/')) continue;
      // `TileDetail(` — not `TileDetail.byDesignatedTileId(` (out of scope).
      final RegExp direct = RegExp(r'(?<![A-Za-z.])TileDetail\(');
      if (direct.hasMatch(_code(e))) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });

  test('there is exactly one flag for the two screens (D25)', () {
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      if (_code(e).contains('tileDetailRedesignEnabled')) {
        offenders.add(e.path);
      }
    }
    expect(offenders, isEmpty);
    final String entry = _code(File(
        'lib/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart'));
    expect(
        entry.contains('EditTileFeatureFlags.editTileRedesignEnabled'), isTrue);
  });
}
