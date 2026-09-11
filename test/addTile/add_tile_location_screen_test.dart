// Phase 4.1 — Location picker (redesign).
//
// Contract settled with the user on 2026-09-05 after reviewing a real API
// response (see plan D16/D18):
//
//   * `source` types a result. `source == 'none'` is one of the USER'S SAVED
//     places (it also carries a `userId` and a Tiler GUID `id`); anything else
//     — in practice `'google'` — is a provider lookup whose `id` is the
//     `thirdPartyId`. The screen groups on that.
//   * `home` and `work` are the two specially-handled saved places, identified
//     by their description.
//   * A result with no street address is STILL VALID. Typing "bike shop" and
//     saving that generic name is a supported flow; the backend resolves it
//     later. Such rows are shown, not filtered.
//   * TAP COMMITS. Tapping a row returns it immediately — this supersedes
//     D10's select-then-confirm, so there is no bottom CTA.
//   * Naming is not part of this screen any more; it happens on the Add form
//     via an edit affordance.
//   * D12 still applies: Back, never Close.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/theme/theme_data.dart';

import 'add_tile_widget_harness.dart';
import 'l10n_fixture.dart';

const _delegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

Locale _resolve(Locale? requested, Iterable<Locale> supported) =>
    supported.first;

/// A saved place: `source: 'none'`, a Tiler GUID id, and a userId.
Location saved(String description, {String? address}) =>
    Location.fromLatitudeAndLongitude(latitude: 39.70, longitude: -104.78)
      ..description = description
      ..address = address ?? '700 s buckley rd b, aurora, co 80017, usa'
      ..id = 'e1209f2b-f2ec-4be0-9930-f08ec2d39eed'
      ..source = 'none'
      ..isVerified = true;

/// A provider lookup: `source: 'google'`, id == thirdPartyId, no userId.
Location lookup(String description, {String? address, String? id}) =>
    Location.fromLatitudeAndLongitude(latitude: 35.94, longitude: -79.97)
      ..description = description
      ..address = address ?? '$description 1901 brentwood st, high point, nc'
      ..id = id ?? 'ChIJ8Q3uS38fU4gR4XvGNU2LRm8'
      ..thirdPartyId = id ?? 'ChIJ8Q3uS38fU4gR4XvGNU2LRm8'
      ..source = 'google'
      ..isVerified = true;

class FakeLocationSource implements AddTileLocationSource {
  FakeLocationSource({
    this.savedPlacesResult = const <Location>[],
    this.searchResults = const <Location>[],
    this.savedDelay = Duration.zero,
    this.searchThrows = false,
  });

  List<Location> savedPlacesResult;
  List<Location> searchResults;
  Duration savedDelay;
  bool searchThrows;

  final List<String> searchQueries = <String>[];

  @override
  Future<List<Location>> savedPlaces() async {
    if (savedDelay != Duration.zero) await Future<void>.delayed(savedDelay);
    return savedPlacesResult;
  }

  @override
  Future<List<Location>> search(String query) async {
    searchQueries.add(query);
    if (searchThrows) throw Exception('network');
    return searchResults;
  }

  /// Name collisions are the place editor's concern, not the picker's.
  @override
  Future<Location?> findByName(String name) async => null;
}

Future<void> pumpScreen(
  WidgetTester tester, {
  required FakeLocationSource source,
  Location? initial,
  void Function(Location)? onSelected,
  Size viewSize = AddTileTestMatrix.standard,
}) async {
  tester.view.physicalSize = AddTileTestMatrix.physicalSizeOf(viewSize);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: TileThemeData.lightTheme,
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localeResolutionCallback: _resolve,
    localizationsDelegates: _delegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AddTileLocationScreen(
      source: source,
      initialLocation: initial,
      onSelected: onSelected,
    ),
  ));
}

Future<void> runSearch(
  WidgetTester tester,
  FakeLocationSource source,
  String query, {
  void Function(Location)? onSelected,
}) async {
  await pumpScreen(tester, source: source, onSelected: onSelected);
  await tester.pumpAndSettle();
  await tester.enterText(
      find.byKey(const ValueKey('locationSearchField')), query);
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  group('Result typing by `source`', () {
    testWidgets('saved places and provider lookups are grouped apart',
        (tester) async {
      final source = FakeLocationSource(searchResults: [
        saved('Barber shop'),
        lookup('Barber Edge'),
        lookup('LifeStyle Barber', id: 'ChIJhcidXGhrolQRIP8UeglTr8s'),
      ]);
      await runSearch(tester, source, 'barber');

      expect(find.text('YOUR PLACES'), findsOneWidget);
      expect(find.text('SUGGESTIONS'), findsOneWidget);
      expect(find.byKey(const ValueKey('savedResult_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('suggestion_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('suggestion_1')), findsOneWidget);
    });

    testWidgets('a saved place geocoded by Google is still YOURS (D58)',
        (tester) async {
      // The user's own "home" comes back as `source: 'google'`, because
      // that is who resolved its street address when it was saved. It was
      // being filed under SUGGESTIONS beside strangers' businesses — and the
      // mapper, keying on the same predicate, dropped its name from the
      // payload.
      final Location home = lookup('home', address: '482 sample ln')
        ..userId = 'user-1'
        ..id = 'tiler-guid-home';
      final source = FakeLocationSource(searchResults: [
        home,
        lookup('Home Depot', id: 'ChIJ-depot'),
      ]);
      await runSearch(tester, source, 'home');

      expect(find.text('YOUR PLACES'), findsOneWidget);
      expect(find.byKey(const ValueKey('savedResult_0')), findsOneWidget,
          reason: 'home belongs to the user and must be listed as theirs');
      expect(find.byKey(const ValueKey('suggestion_0')), findsOneWidget,
          reason: 'the unowned Home Depot is still a suggestion');
      expect(find.byKey(const ValueKey('suggestion_1')), findsNothing);
    });

    testWidgets('a group with no members is not rendered', (tester) async {
      final source = FakeLocationSource(searchResults: [lookup('Barber Edge')]);
      await runSearch(tester, source, 'barber');

      expect(find.text('SUGGESTIONS'), findsOneWidget);
      expect(find.text('YOUR PLACES'), findsNothing,
          reason: 'an empty group must not leave a dangling heading');
    });

    test('isSavedPlace keys on OWNERSHIP, not on source alone (D58)', () {
      expect(
        isSavedPlace(lookup('home')..userId = 'user-1'),
        isTrue,
        reason: 'a Google-resolved address the user saved is still theirs',
      );
      expect(isSavedPlace(saved('Barber shop')), isTrue);
      expect(isSavedPlace(lookup('Barber Edge')), isFalse);
      // Absent/empty source is treated as saved: that is the legacy meaning of
      // "not from a provider".
      final bare = Location.fromDefault()..description = 'Somewhere';
      expect(isSavedPlace(bare), isTrue);
    });
  });

  group('Tap commits (supersedes D10)', () {
    testWidgets('tapping a result returns it immediately', (tester) async {
      Location? returned;
      final source = FakeLocationSource(searchResults: [
        lookup('Barber Edge'),
        lookup('LifeStyle Barber', id: 'ChIJhcidXGhrolQRIP8UeglTr8s'),
      ]);
      await runSearch(tester, source, 'barber',
          onSelected: (l) => returned = l);

      await tester.tap(find.byKey(const ValueKey('suggestion_1')));
      await tester.pumpAndSettle();

      expect(returned, isNotNull);
      expect(returned!.description, 'LifeStyle Barber',
          reason: 'the tapped row is returned, not a same-named sibling');
    });

    testWidgets('there is no confirm CTA left to press', (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [saved('home')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('useLocationCta')), findsNothing);
      expect(find.text('Use selected location'), findsNothing);
    });

    testWidgets('tapping a quick pick returns it immediately', (tester) async {
      Location? returned;
      final source =
          FakeLocationSource(savedPlacesResult: [saved('home'), saved('work')]);
      await pumpScreen(tester, source: source, onSelected: (l) => returned = l);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('savedPlace_work')));
      await tester.pumpAndSettle();

      expect(returned!.description, 'work');
    });
  });

  group('Generic names are valid locations', () {
    testWidgets('a result with no address is shown and selectable',
        (tester) async {
      Location? returned;
      final thin =
          Location.fromLatitudeAndLongitude(latitude: 39.7, longitude: -104.7)
            ..description = 'Walmart'
            ..source = 'google';
      final source = FakeLocationSource(searchResults: [thin]);
      await runSearch(tester, source, 'walmart',
          onSelected: (l) => returned = l);

      expect(find.text('Walmart'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('suggestion_0')));
      await tester.pumpAndSettle();
      expect(returned!.description, 'Walmart');
    });

    testWidgets('the typed text opens the place editor, seeded as the address',
        (tester) async {
      // D19: an unfound place may need BOTH a name and an address, so the
      // typed text hands off to the editor rather than committing one field.
      // It seeds the ADDRESS — the backend copies a lone address into the
      // name, so "bike shop" still ends up named "bike shop" exactly as it did
      // before the editor existed.
      Location? returned;
      final source = FakeLocationSource(searchResults: const <Location>[]);
      await runSearch(tester, source, 'bike shop',
          onSelected: (l) => returned = l);

      await tester.tap(find.byKey(const ValueKey('useTypedAddress')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('placeAddressField')), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('placeAddressField')))
            .controller!
            .text,
        'bike shop',
      );
      expect(returned, isNull,
          reason: 'nothing is committed until the editor '
              'is saved');

      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(returned, isNotNull);
      expect(returned!.address, 'bike shop');
      expect(returned!.isNotNullAndNotDefault, isTrue);
      expect(returned!.isVerified, isFalse,
          reason: 'not provider-sourced, so not verified — legacy parity');
    });

    testWidgets('a name and an address can both be given for an unfound place',
        (tester) async {
      // The scenario that motivated D19: two Walmarts, distinguished only by
      // where they are.
      Location? returned;
      final source = FakeLocationSource(searchResults: const <Location>[]);
      await runSearch(tester, source, '745 us-287, lafayette, co',
          onSelected: (l) => returned = l);

      await tester.tap(find.byKey(const ValueKey('useTypedAddress')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const ValueKey('placeNameField')), 'Walmart near work');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const ValueKey('placeSave')));
      await tester.pumpAndSettle();

      expect(returned!.description, 'Walmart near work');
      expect(returned!.address, '745 us-287, lafayette, co');
    });

    testWidgets('the typed-text option is offered alongside real results too',
        (tester) async {
      final source =
          FakeLocationSource(searchResults: [lookup('Bike Shop Denver')]);
      await runSearch(tester, source, 'bike shop');

      expect(find.byKey(const ValueKey('suggestion_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('useTypedAddress')), findsOneWidget,
          reason: 'naming a generic place must not require zero results');
    });
  });

  group('Row content', () {
    testWidgets('home and work read as friendly names', (tester) async {
      final source =
          FakeLocationSource(savedPlacesResult: [saved('home'), saved('work')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('an address that repeats the name is not shown twice',
        (tester) async {
      final source = FakeLocationSource(
          searchResults: [lookup('Walmart', address: 'Walmart')]);
      await runSearch(tester, source, 'walmart');
      expect(find.text('Walmart'), findsOneWidget);
    });

    testWidgets('a raw identifier is never a row title', (tester) async {
      final source = FakeLocationSource(searchResults: [
        lookup('59b9b29c-0678-476f-bea2-a187a9b0ced6', address: 'Walmart'),
      ]);
      await runSearch(tester, source, 'walmart');
      expect(find.text('59b9b29c-0678-476f-bea2-a187a9b0ced6'), findsNothing);
      expect(find.text('Walmart'), findsOneWidget);
    });

    test('locationDisplayName falls back past an identifier', () {
      final guid = lookup('59b9b29c-0678-476f-bea2-a187a9b0ced6',
          address: '745 us-287, lafayette, co');
      expect(locationDisplayName(testL10n, guid), '745 us-287, lafayette, co');
    });
  });

  group('Browse, search states and navigation', () {
    testWidgets('quick picks show while nothing is typed', (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [saved('home')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('savedPlace_home')), findsOneWidget);
    });

    testWidgets('a place that is not set renders no row', (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [saved('home')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('savedPlace_work')), findsNothing);
    });

    testWidgets('duplicate nicknames do not collide', (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [
        saved('home', address: '1 First St'),
        saved('home')
      ]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('savedPlace_home')), findsOneWidget);
    });

    testWidgets('a loading state covers the quick-pick fetch', (tester) async {
      final source = FakeLocationSource(
        savedPlacesResult: [saved('home')],
        savedDelay: const Duration(milliseconds: 50),
      );
      await pumpScreen(tester, source: source);
      await tester.pump();
      expect(find.byKey(const ValueKey('savedPlacesLoading')), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('savedPlacesLoading')), findsNothing);
    });

    testWidgets('a failed search still offers the typed text', (tester) async {
      final source = FakeLocationSource()..searchThrows = true;
      await runSearch(tester, source, 'anything');
      expect(find.byKey(const ValueKey('locationSearchError')), findsOneWidget);
      expect(find.byKey(const ValueKey('useTypedAddress')), findsOneWidget);
    });

    testWidgets('same-named results render without a key collision',
        (tester) async {
      final source = FakeLocationSource(searchResults: [
        lookup('Walmart Supercenter', address: '745 us-287, lafayette, co'),
        lookup('Walmart Supercenter', address: '500 summit blvd, broomfield'),
        lookup('Walmart Supercenter', address: '4651 w 121st ave, broomfield'),
      ]);
      await runSearch(tester, source, 'walmart');
      expect(tester.takeException(), isNull);
      expect(find.byType(LocationOptionRow), findsNWidgets(3));
    });

    testWidgets('uses Back, never Close', (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [saved('home')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();
      expect(find.byTooltip('Back'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('there is no hand-off to a second location screen',
        (tester) async {
      final source = FakeLocationSource(savedPlacesResult: [saved('home')]);
      await pumpScreen(tester, source: source);
      await tester.pumpAndSettle();
      expect(find.text('Add custom location'), findsNothing);
    });
  });
}
