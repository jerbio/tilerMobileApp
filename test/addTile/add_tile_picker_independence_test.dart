// The pickers must stay reusable outside the Add Tile flow.
//
// They are destined for the edit-tile flow too (`EditTilerEvent`), so they
// must keep speaking plain domain values — `TilePriority`, `RepetitionData`,
// `Location` — rather than Add-Tile state. Today none of them imports the
// add-tile machinery, and that is easy to break by accident: reaching for
// `AddTileDraft` inside a picker would compile fine and silently make it
// unusable anywhere else.
//
// Decision D29 leaves these files under `newTile/` with their `AddTile*`
// names for now, so their location no longer signals the boundary. This test
// is what enforces it instead.
//
// It reads source rather than exercising behaviour, which is unusual — but the
// property being protected IS structural, and nothing else would catch its
// loss until the edit flow tried to reuse a picker and could not.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets and helpers intended for reuse beyond Add Tile.
const List<String> _sharedPickerFiles = <String>[
  'addTileColorScreen.dart',
  'addTilePredictionSource.dart',
  'addTilePriorityScreen.dart',
  'addTileRepeatScreen.dart',
  'repeatOptions.dart',
  'addTileLocationScreen.dart',
  'addTilePlaceEditor.dart',
  'addTileLocationSource.dart',
  'locationOwnership.dart',
  'addTileFormKit.dart',
];

/// Modules that belong to the Add Tile flow specifically. A shared picker
/// importing any of them has stopped being shared.
const List<String> _addTileOnlyModules = <String>[
  'addTileDraft.dart',
  'addTileRedesignShell.dart',
  'newTileRequestMapper.dart',
  'addTileMoreOptions.dart',
  'addTileAnalytics.dart',
  'flexibleTileForm.dart',
  'fixedBlockForm.dart',
  'addTile.dart',
];

const String _dir = 'lib/routes/authenticatedUser/newTile';

/// The file's CODE, with `//` comments stripped.
///
/// The scan below is a substring match, and a picker documenting the very
/// boundary this test enforces ("knows nothing about AddTileDraft") would
/// otherwise trip it — punishing the comment that explains the rule. Stripping
/// comments makes the guard test the API surface, which is what it means.
///
/// Naive about `//` inside a string literal; none of these files has one, and
/// the failure mode of the alternative (a false positive on prose) is the one
/// that actually bit.
String _codeOf(String fileName) =>
    File('$_dir/$fileName').readAsLinesSync().map((line) {
      final int comment = line.indexOf('//');
      return comment < 0 ? line : line.substring(0, comment);
    }).join('\n');

List<String> _importsOf(String fileName) {
  final File file = File('$_dir/$fileName');
  expect(file.existsSync(), isTrue, reason: '$fileName should exist');
  return file
      .readAsLinesSync()
      .where((line) => line.trimLeft().startsWith('import '))
      .toList();
}

void main() {
  group('Shared pickers do not depend on the Add Tile flow', () {
    for (final String fileName in _sharedPickerFiles) {
      test('$fileName imports no Add-Tile-only module', () {
        final List<String> imports = _importsOf(fileName);
        for (final String forbidden in _addTileOnlyModules) {
          final Iterable<String> offenders =
              imports.where((line) => line.contains(forbidden));
          expect(
            offenders,
            isEmpty,
            reason: '$fileName imports $forbidden, which ties it to the Add '
                'Tile flow. These pickers are meant for the edit-tile flow '
                'too — keep the API in plain domain values (TilePriority, '
                'RepetitionData, Location) and pass state in through '
                'constructor arguments and callbacks instead.',
          );
        }
      });
    }

    test('every shared picker file is actually covered by this guard', () {
      // Guards rot when files are added beside them, so fail loudly if a new
      // screen appears in the directory without a decision about which side
      // of the boundary it sits on.
      const Set<String> knownAddTileFlowFiles = <String>{
        'addTile.dart',
        'addTileDraft.dart',
        'addTileRedesignShell.dart',
        'addTileMoreOptions.dart',
        'addTileAnalytics.dart',
        'newTileRequestMapper.dart',
        'flexibleTileForm.dart',
        'fixedBlockForm.dart',
        'preferredTimeOfDay.dart',
        'tileRouteAdapters.dart',
        'autoAddTile.dart',
        'customTimeRestrictions.dart',
        'locationRoute.dart',
        'repetitionRoute.dart',
        'timeRestrictionRoute.dart',
      };

      final Set<String> onDisk = Directory(_dir)
          .listSync()
          .whereType<File>()
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('.dart'))
          .toSet();

      final Set<String> unaccounted = onDisk
          .difference(knownAddTileFlowFiles)
          .difference(_sharedPickerFiles.toSet());

      expect(
        unaccounted,
        isEmpty,
        reason: 'New file(s) in $_dir are neither listed as Add-Tile-flow nor '
            'as shared pickers: $unaccounted. Decide which they are and add '
            'them to the right list, so the reuse boundary stays explicit.',
      );
    });
  });

  group('Shared pickers speak domain values, not draft state', () {
    test('no picker exposes an AddTileDraft in its API', () {
      for (final String fileName in _sharedPickerFiles) {
        final String source = _codeOf(fileName);
        expect(source.contains('AddTileDraft'), isFalse,
            reason: '$fileName references AddTileDraft. A picker should take '
                'and return the value it edits, so any flow can supply it.');
      }
    });
  });
}
