// Step 5.4 — the legacy screens are gone.
//
// After the device round with the flag on, both legacy editors — `EditTile`
// and `TileDetail` — and everything only they used are deleted, the flag
// with them. `EditTileRoute` and `TileDetailRoute` stay as the ONE way to
// open either screen (every push site already goes through them), now
// unconditional.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Strips `//` comments so a mention in prose does not count.
String _code(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.trimLeft().startsWith('//'))
    .join('\n');

void main() {
  test('the legacy screens and their private widgets no longer exist', () {
    for (final String path in <String>[
      'lib/routes/authenticatedUser/editTile/editTile.dart',
      'lib/routes/authenticatedUser/tileDetails/tileDetail.dart',
      'lib/routes/authenticatedUser/tileDetails/colorSelectorWidget.dart',
      'lib/routes/authenticatedUser/tileDetails/repetitionSelectorWidget.dart',
      'lib/routes/authenticatedUser/tileDetails/restrictionProfileSelectorWidget.dart',
      'lib/routes/authenticatedUser/tileCarousel.dart',
      'lib/routes/authenticatedUser/nextTileSuggestionCarousel.dart',
      'lib/routes/authenticatedUser/editTile/nextTileSuggestionWidget.dart',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('there is no flag left: the redesign is the app', () {
    final List<String> offenders = <String>[];
    for (final FileSystemEntity e
        in Directory('lib').listSync(recursive: true)) {
      if (e is! File || !e.path.endsWith('.dart')) continue;
      final String code = _code(e);
      if (code.contains('EditTileFeatureFlags') ||
          code.contains('editTileRedesignEnabled') ||
          code.contains('legacyBuilder') ||
          code.contains('legacyTemplateBuilder')) {
        offenders.add(e.path.replaceAll('\\', '/'));
      }
    }
    expect(offenders, isEmpty);
  });

  test('nothing imports a deleted file', () {
    final List<String> offenders = <String>[];
    for (final Directory dir in <Directory>[
      Directory('lib'),
      Directory('test')
    ]) {
      for (final FileSystemEntity e in dir.listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.endsWith('edit_tile_legacy_removed_test.dart')) continue;
        final String code = _code(e);
        for (final String gone in <String>[
          'editTile/editTile.dart',
          'tileDetails/tileDetail.dart',
          'colorSelectorWidget.dart',
          'repetitionSelectorWidget.dart',
          'restrictionProfileSelectorWidget.dart',
          'tileCarousel.dart',
          'nextTileSuggestionCarousel.dart',
          'nextTileSuggestionWidget.dart',
        ]) {
          if (code.contains("/$gone'")) {
            offenders.add('${e.path.replaceAll('\\', '/')} → $gone');
          }
        }
      }
    }
    expect(offenders, isEmpty);
  });
}
