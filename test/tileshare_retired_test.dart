// TileShare redesign Step 9.17: the old TileShare screens are retired - one
// code path per screen. The hub and the new detail are no longer behind build
// switches, the old detail / list / template screens and the helpers only
// they used are gone, and nothing imports them.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const String _tileShare = 'lib/routes/authenticatedUser/tileShare';

/// The retired files.
const List<String> _retired = [
  '$_tileShare/singleTiletteTileShareDetail.dart',
  '$_tileShare/multiTiletteTileShareDetail.dart',
  '$_tileShare/inboxMultiTiletteTileShareDetail.dart',
  '$_tileShare/tileShareListWidget.dart',
  '$_tileShare/tileShareSimpleWidget.dart',
  '$_tileShare/tileShareTemplateDetail.dart',
  '$_tileShare/tileShareTemplateListWidget.dart',
  '$_tileShare/simpleTileShareTemplareWidget.dart',
  '$_tileShare/designatedTileListWidget.dart',
  '$_tileShare/designatedTileWidget.dart',
  '$_tileShare/tileShareFlags.dart',
  'lib/routes/authenticatedUser/designatedUserCircle.dart',
  // the old name-and-date sheet, replaced by Edit share (9.16e)
  'lib/components/nameAndDateSheetWidget.dart',
  'lib/services/tileShare/tileShareForecastRequest.dart',
];

/// Names that only existed for the switches and the old screens.
const List<String> _retiredNames = [
  'TILESHARE_V2',
  'TILESHARE_DETAIL_V2',
  'kTileShareV2',
  'kTileShareDetailV2',
  'LegacyTileShareDetailWidget',
  '/DesignatedTileList',
];

Iterable<File> _dartFiles() => [
      for (final String root in ['lib', 'test'])
        ...Directory(root)
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart')),
    ];

String _slash(String path) => path.replaceAll('\\', '/');

void main() {
  const String self = 'test/tileshare_retired_test.dart';

  test('the retired files are gone', () {
    expect(_retired.where((p) => File(p).existsSync()), isEmpty);
  });

  test('nothing imports a retired file', () {
    final List<String> found = [
      for (final File f in _dartFiles())
        for (final String p in _retired)
          // package:, relative or bare - any import ending in the file's name.
          if (RegExp("^import '([^']*/)?${RegExp.escape(p.split('/').last)}'",
                  multiLine: true)
              .hasMatch(f.readAsStringSync()))
            '${_slash(f.path)} imports $p',
    ];
    expect(found, isEmpty);
  });

  test('no switch or old-screen name is left', () {
    final List<String> found = [
      for (final File f in _dartFiles())
        if (_slash(f.path) != self)
          for (final String name in _retiredNames)
            if (f.readAsStringSync().contains(name))
              '${_slash(f.path)} mentions $name',
    ];
    expect(found, isEmpty);
  });
}
