// Step 6.6 / 5.4 — one entry for every push site.
//
// `TileDetailRoute` took the legacy `TileDetail(tileId:, loadSubEvents:)`
// arguments and chose by a flag until 5.4 deleted the legacy screen; now
// it is unconditional. A source scan keeps every push site on it.
//
// `TileDetailRoute.byDesignatedTileId` is the drop-in for the tile-share
// template path (2026-09-17): the same redesigned screen, loading its
// calendar event by template id.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
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
  Widget redesign(BuildContext _, TileDetailTarget target) =>
      TileDetailRedesignScreen(
        calendarEventId: target.calendarEventId,
        designatedTileTemplateId: target.designatedTileTemplateId,
        loader:
            shell.FakeLoader(TileDetailLoadResult.success(fx.loaded(), null)),
        submission: shell.FakeSubmission(),
      );

  Future<void> pumpEntry(WidgetTester tester, {bool template = false}) async {
    await tester.pumpWidget(MaterialApp(
      theme: TileThemeData.lightTheme,
      locale: const Locale('en'),
      localizationsDelegates: _delegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: template
          ? TileDetailRoute.byDesignatedTileId(
              designatedTileTemplateId: 'tpl-9',
              loadSubEvents: true,
              redesignBuilder: redesign)
          : TileDetailRoute(
              tileId: 'cal-1', loadSubEvents: false, redesignBuilder: redesign),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a calendar event id → the redesign for that id', (tester) async {
    await pumpEntry(tester);
    final TileDetailRedesignScreen screen =
        tester.widget<TileDetailRedesignScreen>(
            find.byType(TileDetailRedesignScreen));
    expect(screen.calendarEventId, 'cal-1');
    expect(screen.designatedTileTemplateId, isNull);
  });

  testWidgets('a designated tile template → the redesign, by template id',
      (tester) async {
    await pumpEntry(tester, template: true);
    final TileDetailRedesignScreen screen =
        tester.widget<TileDetailRedesignScreen>(
            find.byType(TileDetailRedesignScreen));
    expect(screen.calendarEventId, isNull);
    expect(screen.designatedTileTemplateId, 'tpl-9');
  });

  test(
      'the Time restriction row lands on the Phase 6 screen, never the '
      'legacy route (one editor)', () {
    final String screen = _code(File(
        'lib/routes/authenticatedUser/tileDetails/redesign/tileDetailRedesignScreen.dart'));
    expect(screen.contains('openAdvancedRestrictionRoute('), isFalse,
        reason: 'the legacy /TimeRestrictionRoute hop is gone');
    expect(screen.contains('AddTileTimeRestrictionScreen('), isTrue);
    expect(screen.contains('ApiAddTileRestrictionProfileSource('), isTrue,
        reason: 'the named profiles come from the same seam as Add Tile');
  });

  test('no production file constructs a TileDetail directly', () {
    // Every push site goes through TileDetailRoute — the one API.
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String path = e.path.replaceAll('\\', '/');
      if (path.contains('/tileDetails/redesign/')) continue;
      // Either constructor: `TileDetail(` or `TileDetail.byDesignatedTileId(`.
      final RegExp direct =
          RegExp(r'(?<![A-Za-z.])TileDetail(\.byDesignatedTileId)?\(');
      if (direct.hasMatch(_code(e))) offenders.add(path);
    }
    expect(offenders, isEmpty);
  });
}
