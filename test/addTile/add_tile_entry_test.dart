// Step 5.2 — staged rollout: one entry, one flag, legacy fallback (D65).
//
// Every place that opens Add Tile goes through `AddTileEntry`, which renders
// the redesign when `AddTileFeatureFlags.addTileRedesignEnabled` is on and
// the legacy `AddTile` when it is off. The flag defaults from the BUILD
// (`--dart-define=ADD_TILE_REDESIGN=`; else debug on, release off) and can
// be overridden at runtime, so a cohort is a build away and a rollback is a
// flag away.
//
// The arguments the push sites use are all different — a bare `PreTile`,
// a `{newTile}` result-slot map, that map with a `preTile` inside it, or
// constructor `preTile` + `autoDeadline` — and `AddTileRouteArgs` folds
// them into one shape so both screens receive the same prefill.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRedesignShell.dart';

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
  setUp(() => AddTileFeatureFlags.reset());
  tearDown(() => AddTileFeatureFlags.reset());

  group('The flag', () {
    test('defaults from the build, and a runtime override wins', () {
      expect(AddTileFeatureFlags.addTileRedesignEnabled,
          AddTileFeatureFlags.buildDefault);

      AddTileFeatureFlags.addTileRedesignEnabled = true;
      expect(AddTileFeatureFlags.addTileRedesignEnabled, isTrue);
      AddTileFeatureFlags.addTileRedesignEnabled = false;
      expect(AddTileFeatureFlags.addTileRedesignEnabled, isFalse);

      AddTileFeatureFlags.reset();
      expect(AddTileFeatureFlags.addTileRedesignEnabled,
          AddTileFeatureFlags.buildDefault,
          reason: 'reset must return to the build default, not to false');
    });
  });

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
      // Legacy `AddTile` took `autoDeadline` beside the PreTile and used it
      // as the deadline. The redesign reads a deadline from
      // `preTile.endTime`, so the entry folds one into the other.
      final pre = SimpleAdditionTile(duration: const Duration(minutes: 30))
        ..startTime = DateTime(2026, 9, 20, 9, 0);
      final AddTileRouteArgs args =
          AddTileRouteArgs.from(null, preTile: pre, autoDeadline: deadline);
      expect(args.preTile?.duration, const Duration(minutes: 30));
      expect(args.preTile?.startTime, DateTime(2026, 9, 20, 9, 0));
      expect(args.preTile?.endTime, deadline);
      expect(args.autoDeadline, deadline,
          reason: 'legacy still wants it as its own argument');
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

  group('The entry renders by the flag', () {
    Future<void> pumpEntry(
      WidgetTester tester, {
      Object? arguments,
      PreTile? preTile,
      DateTime? autoDeadline,
      required AddTileRedesignBuilder redesign,
      required AddTileLegacyBuilder legacy,
    }) async {
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (RouteSettings s) => MaterialPageRoute<void>(
          settings: RouteSettings(name: '/AddTile', arguments: arguments),
          builder: (_) => AddTileEntry(
            preTile: preTile,
            autoDeadline: autoDeadline,
            redesignBuilder: redesign,
            legacyBuilder: legacy,
          ),
        ),
      ));
      await tester.pump();
    }

    testWidgets('on: the redesign, with the folded arguments', (tester) async {
      AddTileFeatureFlags.addTileRedesignEnabled = true;
      AddTileRouteArgs? seen;
      bool legacyBuilt = false;
      final pre = SimpleAdditionTile(description: 'Dentist');

      await pumpEntry(
        tester,
        arguments: pre,
        redesign: (BuildContext _, AddTileRouteArgs a) {
          seen = a;
          return const Text('redesign');
        },
        legacy: (BuildContext _, AddTileRouteArgs a) {
          legacyBuilt = true;
          return const Text('legacy');
        },
      );

      expect(find.text('redesign'), findsOneWidget);
      expect(legacyBuilt, isFalse);
      expect(seen?.preTile?.description, 'Dentist');
    });

    testWidgets('off: the legacy screen, with the same arguments',
        (tester) async {
      AddTileFeatureFlags.addTileRedesignEnabled = false;
      AddTileRouteArgs? seen;
      final pre = SimpleAdditionTile(description: 'Dentist');

      await pumpEntry(
        tester,
        arguments: pre,
        redesign: (BuildContext _, AddTileRouteArgs a) =>
            const Text('redesign'),
        legacy: (BuildContext _, AddTileRouteArgs a) {
          seen = a;
          return const Text('legacy');
        },
      );

      expect(find.text('legacy'), findsOneWidget);
      expect(find.text('redesign'), findsNothing);
      expect(seen?.preTile?.description, 'Dentist');
    });

    testWidgets('the default builders are the real screens', (tester) async {
      // The seams above must not hide a wrong default.
      const AddTileEntry entry = AddTileEntry();
      expect(entry.redesignBuilder, same(buildAddTileRedesign));
      expect(entry.legacyBuilder, same(buildAddTileLegacy));
    });

    testWidgets('constructor prefill reaches both branches', (tester) async {
      AddTileFeatureFlags.addTileRedesignEnabled = true;
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
        legacy: (BuildContext _, AddTileRouteArgs a) => const SizedBox(),
      );

      expect(seen?.preTile?.duration, const Duration(minutes: 30));
      expect(seen?.preTile?.endTime, deadline);
    });
  });

  group('The legacy screen tolerates every argument shape', () {
    testWidgets('a PreTile argument does not throw a cast error',
        (tester) async {
      // Legacy `AddTile.build` did `settings.arguments as Map?`. With the
      // preview sheet now pushing through `/AddTile`, its bare `PreTile`
      // argument reached that cast when the flag was off.
      expect(
        () => readLegacyResultSlot(SimpleAdditionTile(description: 'x')),
        returnsNormally,
      );
      expect(readLegacyResultSlot(SimpleAdditionTile()), isNull);
      final Map<String, dynamic> slot = <String, dynamic>{'newTile': null};
      expect(identical(readLegacyResultSlot(slot), slot), isTrue);
    });
    test('and the legacy screen actually reads through it', () {
      // The helper alone proves nothing if the screen still hard-casts.
      final String code =
          _code(File('lib/routes/authenticatedUser/newTile/addTile.dart'));
      expect(code.contains('settings.arguments as Map'), isFalse);
      expect(code.contains('readLegacyResultSlot('), isTrue);
    });
  });

  group('Every entry point goes through the entry', () {
    test('no production file pushes /AddTileRedesign except the debug entry',
        () {
      // The direct route is the debug long-press's. A production push site
      // using it would bypass the flag — on for that one path, whatever
      // the rollout says.
      final List<String> offenders = <String>[];
      for (final File f in _libFiles()) {
        if (f.path.endsWith('main.dart')) continue;
        if (f.path.endsWith('AuthorizedRoute.dart')) continue;
        if (_code(f).contains("'/AddTileRedesign'")) offenders.add(f.path);
      }
      expect(offenders, isEmpty);
    });

    test('no production file constructs the legacy AddTile directly', () {
      final List<String> offenders = <String>[];
      for (final File f in _libFiles()) {
        if (f.path.endsWith('addTileEntry.dart')) continue;
        if (f.path.endsWith('${Platform.pathSeparator}addTile.dart')) continue;
        final String code = _code(f);
        if (RegExp(r'\bAddTile\(').hasMatch(code)) offenders.add(f.path);
      }
      expect(offenders, isEmpty,
          reason: 'a direct construction bypasses the flag');
    });

    test('no production file constructs the redesign screen directly', () {
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

  // Keeps the legacy import live so the "real screens" assertion above can
  // name the type without an unused-import warning.
  test('legacy AddTile is still the type the fallback renders', () {
    expect(AddTile, isNotNull);
  });
}
