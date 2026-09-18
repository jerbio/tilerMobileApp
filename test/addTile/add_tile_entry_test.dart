// The one Add Tile entry (Step 5.2, D65; unconditional since 5.3, D66).
//
// Every place that opens Add Tile goes through `AddTileEntry`. The arguments
// the push sites use are all different — a bare `PreTile`, a `{newTile}`
// result-slot map, that map with a `preTile` inside it, or constructor
// `preTile` + `autoDeadline` — and `AddTileRouteArgs` folds them into one
// shape so the screen receives the same prefill whichever way it was opened.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileEntry.dart';

/// Strips `//` comments so a mention in prose does not count.
String _code(File f) => f
    .readAsLinesSync()
    .where((String l) => !l.trimLeft().startsWith('//'))
    .join('\n');

/// Every production Dart file under lib/.
Iterable<File> _libFiles() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((File f) => f.path.endsWith('.dart'));

void main() {
  group('Route arguments fold into one shape', () {
    final DateTime deadline = DateTime(2026, 9, 20, 17, 0);

    test('a bare PreTile (the preview sheet)', () {
      final pre = SimpleAdditionTile(description: 'Dentist');
      final AddTileRouteArgs args = AddTileRouteArgs.from(pre);
      expect(args.preTile?.description, 'Dentist');
      expect(args.newTileParams, isNull);
    });

    test('a result-slot map (empty day, forecast preview)', () {
      final Map<String, dynamic> slot = <String, dynamic>{'newTile': null};
      final AddTileRouteArgs args = AddTileRouteArgs.from(slot);
      expect(args.preTile, isNull);
      expect(identical(args.newTileParams, slot), isTrue,
          reason: 'the SAME map: the caller reads the created tile back '
              'out of it');
    });

    test('a map carrying a preTile (Edit Tile suggestions)', () {
      final pre = SimpleAdditionTile(description: 'Follow-up');
      final Map<String, dynamic> slot = <String, dynamic>{
        'newTile': null,
        'preTile': pre,
      };
      final AddTileRouteArgs args = AddTileRouteArgs.from(slot);
      expect(identical(args.preTile, pre), isTrue);
      expect(identical(args.newTileParams, slot), isTrue);
    });

    test('nothing at all', () {
      final AddTileRouteArgs args = AddTileRouteArgs.from(null);
      expect(args.preTile, isNull);
      expect(args.newTileParams, isNull);
    });

    test('constructor prefill + autoDeadline (free slot, auto-tile)', () {
      // These sites hand over the deadline beside the prefill; the screen
      // reads a deadline from `preTile.endTime`, so the entry folds one
      // into the other.
      final pre = SimpleAdditionTile(duration: const Duration(minutes: 30))
        ..startTime = DateTime(2026, 9, 20, 9, 0);
      final AddTileRouteArgs args =
          AddTileRouteArgs.from(null, preTile: pre, autoDeadline: deadline);
      expect(args.preTile?.duration, const Duration(minutes: 30));
      expect(args.preTile?.startTime, DateTime(2026, 9, 20, 9, 0));
      expect(args.preTile?.endTime, deadline);
    });

    test('autoDeadline alone still prefills the deadline', () {
      final AddTileRouteArgs args =
          AddTileRouteArgs.from(null, autoDeadline: deadline);
      expect(args.preTile?.endTime, deadline);
    });

    test('a PreTile deadline is not overwritten by a null autoDeadline', () {
      final pre = SimpleAdditionTile(endTime: deadline);
      final AddTileRouteArgs args = AddTileRouteArgs.from(null, preTile: pre);
      expect(args.preTile?.endTime, deadline);
    });

    test('folding never mutates the caller\'s PreTile', () {
      final pre = SimpleAdditionTile(description: 'Gym');
      AddTileRouteArgs.from(null, preTile: pre, autoDeadline: deadline);
      expect(pre.endTime, isNull);
    });
  });

  group('The entry renders the screen with the folded arguments', () {
    Future<void> pumpEntry(
      WidgetTester tester, {
      Object? arguments,
      PreTile? preTile,
      DateTime? autoDeadline,
      required AddTileRedesignBuilder redesign,
    }) async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (RouteSettings s) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/AddTile', arguments: arguments),
          builder: (_) => AddTileEntry(
            preTile: preTile,
            autoDeadline: autoDeadline,
            redesignBuilder: redesign,
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('a route argument reaches the screen', (tester) async {
      AddTileRouteArgs? seen;
      await pumpEntry(
        tester,
        arguments: SimpleAdditionTile(description: 'Dentist'),
        redesign: (BuildContext _, AddTileRouteArgs a) {
          seen = a;
          return const Text('redesign');
        },
      );

      expect(find.text('redesign'), findsOneWidget);
      expect(seen?.preTile?.description, 'Dentist');
    });

    testWidgets('constructor prefill reaches the screen', (tester) async {
      AddTileRouteArgs? seen;
      final DateTime deadline = DateTime(2026, 9, 20, 17, 0);

      await pumpEntry(
        tester,
        preTile: SimpleAdditionTile(duration: const Duration(minutes: 30)),
        autoDeadline: deadline,
        redesign: (BuildContext _, AddTileRouteArgs a) {
          seen = a;
          return const SizedBox();
        },
      );

      expect(seen?.preTile?.duration, const Duration(minutes: 30));
      expect(seen?.preTile?.endTime, deadline);
    });

    testWidgets('the default builder is the real screen', (tester) async {
      // The seam above must not hide a wrong default.
      const AddTileEntry entry = AddTileEntry();
      expect(entry.redesignBuilder, same(buildAddTileRedesign));
    });
  });

  group('Every entry point goes through the entry', () {
    test('no production file constructs the screen directly', () {
      final List<String> offenders = <String>[];
      for (final File f in _libFiles()) {
        if (f.path.endsWith('addTileEntry.dart')) continue;
        if (f.path.endsWith('addTileRedesignShell.dart')) continue;
        if (_code(f).contains('AddTileRedesignScreen(')) offenders.add(f.path);
      }
      expect(offenders, isEmpty,
          reason: 'the production wiring lives in ONE builder');
    });
  });
}
