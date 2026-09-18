// Step 5.3 — the legacy Add Tile UI is gone and the redesign is the app (D66).
//
// Source-level guards, in the shape of `edit_tile_legacy_removed_test.dart`:
// the deleted files stay deleted, nothing imports them, no route or flag
// survives to reach them, and the callers that used the legacy location
// picker (P5-1) use the shared `AddTileLocationScreen` instead.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips `//` comments so a mention in prose does not count.
String _code(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.trimLeft().startsWith('//'))
    .join('\n');

Iterable<File> _dartFiles(String root) => Directory(root)
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'));

const List<String> _deleted = <String>[
  'lib/routes/authenticatedUser/newTile/addTile.dart',
  'lib/routes/authenticatedUser/newTile/locationRoute.dart',
  'lib/routes/authenticatedUser/newTile/repetitionRoute.dart',
  'lib/routes/authenticatedUser/pickColor.dart',
];

void main() {
  test('the legacy files are gone', () {
    for (final String path in _deleted) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('nothing imports a deleted file', () {
    final List<String> offenders = <String>[];
    for (final String root in <String>['lib', 'test']) {
      for (final File f in _dartFiles(root)) {
        if (f.path.endsWith('add_tile_legacy_removed_test.dart')) continue;
        final String code = _code(f);
        for (final String gone in <String>[
          'newTile/addTile.dart',
          'newTile/locationRoute.dart',
          'newTile/repetitionRoute.dart',
          'authenticatedUser/pickColor.dart',
        ]) {
          if (code.contains(gone)) offenders.add('${f.path} -> $gone');
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('no route reaches a legacy screen', () {
    // The routes the legacy screen and the dead adapters pushed. A surviving
    // string would be a push to nowhere at runtime.
    final List<String> offenders = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String code = _code(f);
      for (final String route in <String>[
        "'/LocationRoute'",
        "'/AddTileRedesign'",
        "'/RepetitionRoute'",
        "'/PickColor'",
      ]) {
        if (code.contains(route)) offenders.add('${f.path} -> $route');
      }
    }
    expect(offenders, isEmpty);
  });

  test('there is no flag left: the redesign is the app', () {
    final List<String> offenders = <String>[];
    for (final File f in _dartFiles('lib')) {
      final String code = _code(f);
      if (code.contains('AddTileFeatureFlags') ||
          code.contains('addTileRedesignEnabled') ||
          code.contains('ADD_TILE_REDESIGN') ||
          code.contains('buildAddTileLegacy') ||
          code.contains('readLegacyResultSlot')) {
        offenders.add(f.path.replaceAll('\\', '/'));
      }
    }
    expect(offenders, isEmpty);
  });

  test(
      'the legacy time-restriction screens and the route adapters are gone '
      '(Phase 6, Step 6.7)', () {
    for (final String gone in <String>[
      'lib/routes/authenticatedUser/newTile/tileRouteAdapters.dart',
      'lib/routes/authenticatedUser/newTile/timeRestrictionRoute.dart',
      'lib/routes/authenticatedUser/newTile/customTimeRestrictions.dart',
    ]) {
      expect(File(gone).existsSync(), isFalse, reason: gone);
    }
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String code = _code(e);
      if (code.contains('/TimeRestrictionRoute') ||
          code.contains('/CustomRestrictionsRoute') ||
          code.contains('openAdvancedRestrictionRoute') ||
          code.contains('AdvancedRestrictionResult') ||
          code.contains('tileRouteAdapters.dart') ||
          code.contains('timeRestrictionRoute.dart') ||
          code.contains('customTimeRestrictions.dart')) {
        offenders.add(e.path.replaceAll('\\', '/'));
      }
    }
    expect(offenders, isEmpty);
    // The strings only those screens spoke.
    for (final String arb in Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .map((File f) => f.path)
        .where((String p) => p.endsWith('.arb'))) {
      final String text = File(arb).readAsStringSync();
      expect(text.contains('"customRestrictionTitle"'), isFalse, reason: arb);
      expect(text.contains('"customRestrictionHeader"'), isFalse, reason: arb);
    }
  });

  test('every former /LocationRoute caller uses the shared picker (P5-1)', () {
    for (final String path in <String>[
      'lib/components/tileUI/newTileSheet.dart',
      'lib/routes/authenticatedUser/newTile/autoAddTile.dart',
      'lib/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart',
    ]) {
      expect(_code(File(path)).contains('AddTileLocationScreen('), isTrue,
          reason: path);
    }
  });

  test('no debug-only entry to the redesign remains', () {
    // The long-press on the home add button existed to reach the redesign
    // while the legacy screen was the app. With one screen, it is a second
    // gesture to the same place.
    for (final File f in _dartFiles('lib')) {
      expect(_code(f).contains('onAddTileLongPress'), isFalse, reason: f.path);
    }
  });
}
