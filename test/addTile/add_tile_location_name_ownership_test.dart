// D20 — do not ship a provider's business name as the place NAME.
//
// `LocationTag` and the backend Name are the same field, and the backend
// upserts places BY NAME. So sending a Google result's business name means
// every "Walmart Supercenter" a user visits overwrites the last one, leaving a
// single saved place pointing at whichever store they used most recently.
//
// The fix: send `LocationTag` only when the name is the USER'S. For a provider
// lookup we send the address and the identifiers that already pin the exact
// store, and let the backend derive the name from the address — which is
// unique per store, and reads well because provider addresses already embed
// the business name ("Barber Edge 1901 brentwood st, high point, nc").
//
// This deliberately breaks the mapper's legacy parity. The rule is encoded
// here so the intent is explicit rather than inferred from a diff.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

DateTime get _now => DateTime(2026, 9, 6, 9, 0);

Location providerPlace(String name, String address) =>
    Location.fromLatitudeAndLongitude(latitude: 40.0, longitude: -105.0)
      ..description = name
      ..address = address
      ..id = 'ChIJ8Q3uS38fU4gR4XvGNU2LRm8'
      ..thirdPartyId = 'ChIJ8Q3uS38fU4gR4XvGNU2LRm8'
      ..source = 'google'
      ..isVerified = true;

Location userPlace(String name, String address, {String? source}) =>
    Location.fromLatitudeAndLongitude(latitude: 40.0, longitude: -105.0)
      ..description = name
      ..address = address
      ..id = 'e1209f2b-f2ec-4be0-9930-f08ec2d39eed'
      ..source = source ?? 'none'
      ..isVerified = true;

NewTile mapWith(Location location) => NewTileRequestMapper.build(
      LegacyAddTileDraft(
        isAppointment: false,
        name: 'Groceries',
        duration: const Duration(minutes: 30),
        location: location,
        color: const Color(0xFF336699),
        now: _now,
      ),
    );

void main() {
  group('Who owns the name', () {
    test('a Google lookup is provider-named', () {
      expect(locationNameIsUserOwned(providerPlace('Walmart', '745 us-287')),
          isFalse);
    });

    test("a saved place carries the user's own name", () {
      expect(
          locationNameIsUserOwned(userPlace('home', '123 Maple St')), isTrue);
    });

    test('an absent or empty source is the user', () {
      final bare = Location.fromDefault()..description = 'bike shop';
      expect(locationNameIsUserOwned(bare), isTrue);
      expect(
        locationNameIsUserOwned(Location.fromDefault()
          ..description = 'bike shop'
          ..source = ''),
        isTrue,
      );
    });

    test('an unrecognised source is treated as the user, not a provider', () {
      // Only sources we KNOW name places for the user are excluded. `custom`
      // is a user-created location, and defaulting an unknown source to
      // "provider" would silently drop names the user chose.
      expect(
        locationNameIsUserOwned(
            userPlace('Office', '123 Main St', source: 'custom')),
        isTrue,
      );
    });

    test('provider matching ignores case and padding', () {
      expect(
        locationNameIsUserOwned(
            userPlace('Walmart', '745 us-287', source: '  GOOGLE  ')),
        isFalse,
      );
    });
  });

  group('What reaches the wire', () {
    test('a provider pick ships no name, but keeps address and identifiers',
        () {
      final tile = mapWith(providerPlace(
          'Walmart Supercenter', 'walmart supercenter 745 us-287, lafayette'));

      expect(tile.LocationTag, isNull,
          reason: 'a provider business name is not the user\'s place name');
      expect(tile.LocationAddress, 'walmart supercenter 745 us-287, lafayette');
      expect(tile.LocationId, 'ChIJ8Q3uS38fU4gR4XvGNU2LRm8');
      expect(tile.LocationSource, 'google');
      expect(tile.LocationIsVerified, 'true');
    });

    test("a user's place ships its name", () {
      final tile = mapWith(userPlace('Walmart near work', '745 us-287'));
      expect(tile.LocationTag, 'Walmart near work');
      expect(tile.LocationAddress, '745 us-287');
    });

    test('two same-brand stores no longer collide', () {
      // The defect this change exists to fix: both results are called
      // "Walmart Supercenter", so shipping that name made the second
      // overwrite the first.
      final a = mapWith(providerPlace(
          'Walmart Supercenter', 'walmart supercenter 745 us-287, lafayette'));
      final b = mapWith(providerPlace('Walmart Supercenter',
          'walmart supercenter 500 summit blvd, broomfield'));

      expect(a.LocationTag, isNull);
      expect(b.LocationTag, isNull);
      expect(a.LocationAddress, isNot(b.LocationAddress),
          reason: 'the addresses are what distinguish them, and the backend '
              'derives a unique name from each');
    });

    test('a place with no address still ships its user name', () {
      // "bike shop" — a generic name the backend resolves later. Dropping the
      // name here would leave the tile with no location at all.
      final bare = Location.fromDefault()
        ..description = 'bike shop'
        ..isDefault = false
        ..isNull = false;
      final tile = mapWith(bare);

      expect(tile.LocationTag, 'bike shop');
    });

    test('an absent location still ships nothing', () {
      final tile = NewTileRequestMapper.build(LegacyAddTileDraft(
        isAppointment: false,
        name: 'Groceries',
        duration: const Duration(minutes: 30),
        color: const Color(0xFF336699),
        now: _now,
      ));
      expect(tile.LocationTag, isNull);
      expect(tile.LocationAddress, isNull);
    });
  });

  group('Legacy behaviour that must NOT change', () {
    test('priority, split and colour are untouched by this change', () {
      final tile = NewTileRequestMapper.build(LegacyAddTileDraft(
        isAppointment: false,
        name: 'Groceries',
        duration: const Duration(minutes: 30),
        location: providerPlace('Walmart', '745 us-287'),
        priority: TilePriority.high,
        splitCount: '3',
        color: const Color(0xFF336699),
        now: _now,
      ));

      expect(tile.Priority, 'high');
      expect(tile.Count, '3');
      expect(tile.RColor, '51');
    });
  });
}
