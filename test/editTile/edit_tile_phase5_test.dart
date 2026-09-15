// Phase 5 — hardening (5.1) and the entry point (5.2).
//
//   5.1 Guards that do not depend on a device: no `dart:io` in the redesign
//       (the legacy `EditTileName` used `Platform.isAndroid` and threw on
//       web), the full frame at 320pt under large text, and in the dark
//       theme, without overflow.
//   5.2 One entry for every push site — `EditTileRoute`, a drop-in for the
//       legacy `EditTile` constructor — that renders the redesign when the
//       flag is on and the legacy screen when it is off; and a source scan
//       that no production file still constructs `EditTile(` directly.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRedesignScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/theme/theme_data.dart';

import '../addTile/add_tile_widget_harness.dart';
import 'edit_tile_phase2_test.dart' as p2;
import 'edit_tile_shell_test.dart' as shell;

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
  // ------------------------------------------------------------------ 5.1
  group('5.1 Hardening', () {
    test('the redesign never touches dart:io', () {
      final Directory dir =
          Directory('lib/routes/authenticatedUser/editTile/redesign');
      for (final FileSystemEntity e in dir.listSync()) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String code = _code(e);
        expect(code.contains("import 'dart:io'"), isFalse, reason: e.path);
        expect(code.contains('Platform.'), isFalse, reason: e.path);
      }
    });

    testWidgets('the full frame survives 320pt with large text',
        (tester) async {
      await shell.pumpEdit(tester,
          tile: p2.tile(
              isRecurring: true, calendarEvent: p2.series(), note: 'A note'),
          viewSize: AddTileTestMatrix.narrow,
          textScale: AddTileTestMatrix.largeTextScale);
      await p2.reveal(tester, shell.save);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the full frame renders in the dark theme', (tester) async {
      await shell.pumpEdit(tester,
          tile: p2.tile(isRecurring: true, calendarEvent: p2.series()),
          viewSize: AddTileTestMatrix.narrow,
          dark: true);
      await p2.reveal(tester, shell.save);
      expect(tester.takeException(), isNull);
    });
  });

  // ------------------------------------------------------------------ 5.2
  group('5.2 Entry point', () {
    setUp(() => EditTileFeatureFlags.editTileRedesignEnabled = false);
    tearDown(() => EditTileFeatureFlags.editTileRedesignEnabled = false);

    Future<void> pumpEntry(WidgetTester tester,
        {required Widget Function(String, TileSource?, String?) legacy}) async {
      await tester.pumpWidget(MaterialApp(
        theme: TileThemeData.lightTheme,
        locale: const Locale('en'),
        localizationsDelegates: _delegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: EditTileRoute(
          tileId: 'sub-1',
          tileSource: TileSource.google,
          thirdPartyUserId: 'gcal-user-3',
          legacyBuilder: legacy,
          redesignBuilder: (BuildContext _, EditTileRedesignRouteArgs args) =>
              EditTileRedesignScreen(
            tileId: args.tileId,
            source: args.source,
            thirdPartyUserId: args.thirdPartyUserId,
            loader: shell.FakeLoader(EditTileLoadResult.success(
                p2.tile(), const <NextTileSuggestion>[])),
            submission: shell.FakeSubmission(),
          ),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('flag off → the legacy screen, with the same arguments',
        (tester) async {
      final List<String> built = <String>[];
      await pumpEntry(tester, legacy: (String id, TileSource? src, String? u) {
        built.add('$id:${src?.name}:$u');
        return const Scaffold(body: Text('legacy'));
      });
      expect(built, <String>['sub-1:google:gcal-user-3']);
      expect(find.text('legacy'), findsOneWidget);
      expect(find.byType(EditTileRedesignScreen), findsNothing);
    });

    testWidgets('flag on → the redesign, with the same arguments',
        (tester) async {
      EditTileFeatureFlags.editTileRedesignEnabled = true;
      await pumpEntry(tester,
          legacy: (_, __, ___) => const Scaffold(body: Text('legacy')));
      expect(find.text('legacy'), findsNothing);
      final EditTileRedesignScreen screen = tester
          .widget<EditTileRedesignScreen>(find.byType(EditTileRedesignScreen));
      expect(screen.tileId, 'sub-1');
      expect(screen.source, 'google');
      expect(screen.thirdPartyUserId, 'gcal-user-3');
    });

    test('no production file constructs the legacy EditTile directly', () {
      // Every push site goes through EditTileRoute, so the flag governs all
      // of them and Step 5.4 can delete the legacy screen in one move.
      final List<String> offenders = <String>[];
      for (final FileSystemEntity e
          in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        final String path = e.path.replaceAll('\\', '/');
        if (path.contains('/editTile/')) continue;
        final RegExp direct = RegExp(r'(?<![A-Za-z])EditTile\(');
        if (direct.hasMatch(_code(e))) offenders.add(path);
      }
      expect(offenders, isEmpty);
    });

    test('the debug route and the entry build the redesign the same way', () {
      // One wiring function serves both: `main.dart`'s /EditTileRedesign
      // and EditTileRoute. A second copy would drift.
      final String main = _code(File('lib/main.dart'));
      expect(main.contains('buildEditTileRedesign('), isTrue);
      expect(main.contains('ApiEditTileSubmission('), isFalse,
          reason: 'main.dart must not wire the submission by hand');
    });
  });
}
