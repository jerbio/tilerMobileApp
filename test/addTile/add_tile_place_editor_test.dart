// D19 — the place editor: name + address in one surface.
//
// A place is a NAME and an ADDRESS, and for somewhere search cannot find, the
// user may need to supply both ("my Walmart near work" at a specific street).
// One editor serves two entry points: the picker's "Use what you typed", and
// the Add form's edit affordance on an already-chosen location.
//
// The backend keys places by NAME and upserts: saving a name that already
// exists MOVES that name onto the new address (D19/D20). The editor therefore
// warns, naming the address about to be replaced — the user needs to see what
// they are about to lose, not merely that "a name will be updated".
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

Location existing(String name, String address, {String id = 'loc-1'}) =>
    Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.9)
      ..description = name
      ..address = address
      ..id = id
      ..source = 'none'
      ..isVerified = true;

class FakeEditorSource implements AddTileLocationSource {
  FakeEditorSource({this.byName = const <String, Location>{}});

  Map<String, Location> byName;
  final List<String> lookups = <String>[];

  @override
  Future<List<Location>> savedPlaces() async => const <Location>[];

  @override
  Future<List<Location>> search(String query) async => const <Location>[];

  @override
  Future<Location?> findByName(String name) async {
    lookups.add(name);
    return byName[name.trim().toLowerCase()];
  }
}

Future<void> pumpEditor(
  WidgetTester tester, {
  required FakeEditorSource source,
  String? initialName,
  String? initialAddress,
  Location? original,
}) async {
  tester.view.physicalSize =
      AddTileTestMatrix.physicalSizeOf(AddTileTestMatrix.standard);
  addTearDown(tester.view.reset);
  _captured = null;
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTilePlaceEditorScreen(
      source: source,
      initialName: initialName,
      initialAddress: initialAddress,
      original: original,
      onSaved: (l) => _captured = l,
    ),
  ));
  await tester.pumpAndSettle();
}

/// Reads the value currently in a keyed text field.
String fieldText(WidgetTester tester, String key) =>
    tester.widget<TextField>(find.byKey(ValueKey(key))).controller!.text;

Future<void> type(WidgetTester tester, String key, String value) async {
  await tester.enterText(find.byKey(ValueKey(key)), value);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  group('Prefill', () {
    testWidgets('the typed query prefills the ADDRESS, not the name',
        (tester) async {
      // The backend copies whichever field is present into the other, so
      // address-only still yields a name. Prefilling address means "bike shop"
      // behaves exactly as before, while a typed street address lands in the
      // right slot instead of becoming a name.
      await pumpEditor(tester,
          source: FakeEditorSource(), initialAddress: '532 Wylie Street');

      expect(fieldText(tester, 'placeAddressField'), '532 Wylie Street');
      expect(fieldText(tester, 'placeNameField'), isEmpty);
    });

    testWidgets('an existing place prefills both fields', (tester) async {
      await pumpEditor(
        tester,
        source: FakeEditorSource(),
        initialName: 'Walmart Supercenter',
        initialAddress: '745 us-287, lafayette, co',
      );

      expect(fieldText(tester, 'placeNameField'), 'Walmart Supercenter');
      expect(
          fieldText(tester, 'placeAddressField'), '745 us-287, lafayette, co');
    });
  });

  group('Saving', () {
    testWidgets('returns a location carrying both fields', (tester) async {
      final Location? saved;
      final source = FakeEditorSource();
      await pumpEditor(tester, source: source, initialAddress: '745 us-287');
      await type(tester, 'placeNameField', 'Walmart near work');
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();
      saved = _captured;

      expect(saved, isNotNull);
      expect(saved!.description, 'Walmart near work');
      expect(saved.address, '745 us-287');
      expect(saved.isNotNullAndNotDefault, isTrue);
    });

    testWidgets('save is unavailable while both fields are empty',
        (tester) async {
      await pumpEditor(tester, source: FakeEditorSource());
      expect(
        tester
            .widget<PlaceEditorSaveButton>(
                find.byKey(const ValueKey('placeSave')))
            .enabled,
        isFalse,
      );

      await type(tester, 'placeNameField', 'Somewhere');
      expect(
        tester
            .widget<PlaceEditorSaveButton>(
                find.byKey(const ValueKey('placeSave')))
            .enabled,
        isTrue,
        reason: 'either field alone is enough — the backend copies one to the '
            'other',
      );
    });

    testWidgets('cancelling returns nothing', (tester) async {
      _captured = null;
      await pumpEditor(tester,
          source: FakeEditorSource(), initialAddress: '745 us-287');
      await tester.tap(find.byKey(const ValueKey('placeCancel')));
      await tester.pumpAndSettle();
      expect(_captured, isNull);
    });
  });

  group('Name-collision warning', () {
    testWidgets('warns and names the address about to be replaced',
        (tester) async {
      final source = FakeEditorSource(byName: {
        'home': existing('home', '123 Maple St, Austin, TX'),
      });
      await pumpEditor(tester, source: source, initialAddress: '745 us-287');
      await type(tester, 'placeNameField', 'home');

      expect(find.byKey(const ValueKey('placeNameCollision')), findsOneWidget);
      expect(find.textContaining('123 Maple St, Austin, TX'), findsOneWidget,
          reason: 'the user must see the address they are about to lose');
    });

    testWidgets('no warning for a name that is free', (tester) async {
      final source = FakeEditorSource(byName: {
        'home': existing('home', '123 Maple St'),
      });
      await pumpEditor(tester, source: source, initialAddress: '745 us-287');
      await type(tester, 'placeNameField', 'Walmart near work');

      expect(find.byKey(const ValueKey('placeNameCollision')), findsNothing);
    });

    testWidgets('no warning when the match is the place being edited',
        (tester) async {
      final home = existing('home', '123 Maple St');
      final source = FakeEditorSource(byName: {'home': home});
      await pumpEditor(
        tester,
        source: source,
        initialName: 'home',
        initialAddress: '123 Maple St',
        original: home,
      );
      await type(tester, 'placeNameField', 'home');

      expect(find.byKey(const ValueKey('placeNameCollision')), findsNothing,
          reason: 'editing home is not a collision with home');
    });

    testWidgets('the warning does not block saving', (tester) async {
      _captured = null;
      final source = FakeEditorSource(byName: {
        'home': existing('home', '123 Maple St'),
      });
      await pumpEditor(tester, source: source, initialAddress: '745 us-287');
      await type(tester, 'placeNameField', 'home');

      expect(
        tester
            .widget<PlaceEditorSaveButton>(
                find.byKey(const ValueKey('placeSave')))
            .enabled,
        isTrue,
        reason: 'moving a name is a legitimate act, once understood',
      );
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();
      expect(_captured!.description, 'home');
    });

    testWidgets('a stale lookup cannot resurrect a cleared warning',
        (tester) async {
      final source = FakeEditorSource(byName: {
        'home': existing('home', '123 Maple St'),
      });
      await pumpEditor(tester, source: source, initialAddress: '745 us-287');
      await type(tester, 'placeNameField', 'home');
      expect(find.byKey(const ValueKey('placeNameCollision')), findsOneWidget);

      await type(tester, 'placeNameField', 'Walmart near work');
      expect(find.byKey(const ValueKey('placeNameCollision')), findsNothing);
    });
  });

  group('Wire rules', () {
    testWidgets('a changed name clears the id (legacy parity)', (tester) async {
      _captured = null;
      final original = existing('Some Place', '745 us-287', id: 'loc-123');
      await pumpEditor(
        tester,
        source: FakeEditorSource(),
        initialName: 'Some Place',
        initialAddress: '745 us-287',
        original: original,
      );
      await type(tester, 'placeNameField', 'Walmart near work');
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(_captured!.id, '');
    });

    testWidgets('an unchanged name preserves the id', (tester) async {
      _captured = null;
      final original = existing('Some Place', '745 us-287', id: 'loc-123');
      await pumpEditor(
        tester,
        source: FakeEditorSource(),
        initialName: 'Some Place',
        initialAddress: '745 us-287',
        original: original,
      );
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(_captured!.id, 'loc-123');
    });

    testWidgets('a hand-edited address is not provider-verified',
        (tester) async {
      // `isVerified` means "came from a provider". Typing an address by hand
      // means it did not.
      _captured = null;
      final original = existing('Walmart', '745 us-287', id: 'loc-1');
      await pumpEditor(
        tester,
        source: FakeEditorSource(),
        initialName: 'Walmart',
        initialAddress: '745 us-287',
        original: original,
      );
      await type(tester, 'placeAddressField', '500 summit blvd');
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(_captured!.isVerified, isFalse);
    });

    testWidgets('renaming without touching the address keeps verification',
        (tester) async {
      _captured = null;
      final original = existing('Walmart Supercenter', '745 us-287');
      await pumpEditor(
        tester,
        source: FakeEditorSource(),
        initialName: 'Walmart Supercenter',
        initialAddress: '745 us-287',
        original: original,
      );
      await type(tester, 'placeNameField', 'Walmart near work');
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(_captured!.isVerified, isTrue,
          reason: 'the address still came from the provider');
    });

    testWidgets('a place created from scratch is not verified', (tester) async {
      _captured = null;
      await pumpEditor(tester,
          source: FakeEditorSource(), initialAddress: '532 Wylie Street');
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(_captured!.isVerified, isFalse);
    });
  });

  group('Navigation (D12)', () {
    testWidgets('uses Back, never Close', (tester) async {
      await pumpEditor(tester, source: FakeEditorSource());
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });
}

/// Captures the editor's result across the pump helper.
Location? _captured;
