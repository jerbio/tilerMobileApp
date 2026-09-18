// A named place with no resolved address must still be assignable (D53).
//
// Reported on device: searching for a keyword place like "home" or "work" that
// has no address set left the user unable to attach it to the tile.
//
// THE SEMANTICS, confirmed with the user 2026-09-09:
//   * `isNull: true`    — no location value was set
//   * `isDefault: true` — it is an entity's DEFAULT place
//
// Neither answers "did the user choose this?", which is the only question the
// form is actually asking. `isNotNullAndNotDefault` was standing in for it,
// and that is wrong in both directions: a name-only place the user explicitly
// picked reads as absent, and home/work — which ARE default places — were
// filtered out of the quick-pick list whose entire purpose is to show them.
//
// D18 already committed to name-only places being a first-class choice
// ("bike shop" is stored for the backend to resolve later), so the predicate
// has to be about CONTENT, not resolution.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';

/// A saved place as the search API returns one.
Location savedPlace(
        {String? description,
        String? address,
        bool? isNull,
        bool? isDefault}) =>
    Location.fromJson(<String, dynamic>{
      'id': 'guid-1',
      'source': 'none',
      'userId': 'u1',
      if (description != null) 'description': description,
      if (address != null) 'address': address,
      if (isNull != null) 'isNull': isNull,
      if (isDefault != null) 'isDefault': isDefault,
    });

void main() {
  group('What counts as a location the user chose', () {
    test('a name with no address counts', () {
      // The reported case. The backend resolves the address later; the user
      // has still made a choice.
      expect(locationHasContent(savedPlace(description: 'home')), isTrue);
    });

    test('an address with no name counts', () {
      expect(locationHasContent(savedPlace(address: '1 Main St')), isTrue);
    });

    test('a DEFAULT place still counts', () {
      // `isDefault` means "this is the entity's default place" — home and work
      // are exactly that, so rejecting them would empty the quick-pick list.
      expect(
        locationHasContent(savedPlace(description: 'home', isDefault: true)),
        isTrue,
      );
    });

    test('a place flagged isNull still counts when it carries a name', () {
      // The server may report an unresolved place as isNull; the name is the
      // thing the user picked and the thing the payload will carry.
      expect(
        locationHasContent(savedPlace(description: 'bike shop', isNull: true)),
        isTrue,
      );
    });

    test('the absent sentinel does NOT count', () {
      // `Location.fromDefault()` is the draft's "no location" state. It has
      // neither a name nor an address, so content is enough to reject it and
      // the flags are not needed.
      expect(locationHasContent(Location.fromDefault()), isFalse);
      expect(locationHasContent(null), isFalse);
    });

    test('blank strings do not count as content', () {
      expect(locationHasContent(savedPlace(description: '   ', address: '')),
          isFalse);
    });
  });

  group('The form shows a name-only place as assigned', () {
    test('summary is the name, not "Not set"', () {
      // The bug as the user experienced it: the row read "Not set" even though
      // the draft was holding the place, so there was no way to tell it had
      // been assigned.
      expect(locationSummary(savedPlace(description: 'home')), 'home');
    });

    test('summary survives the flags being absent from the JSON', () {
      // `Location.fromJson` leaves isNull/isDefault at their `true` defaults
      // when the keys are missing, which used to make EVERY such result read
      // as absent — including ones that had a full address.
      expect(
        locationSummary(savedPlace(description: 'work', address: '1 Main St')),
        'work',
      );
    });

    test('an address-only place summarises to its address', () {
      expect(locationSummary(savedPlace(address: '532 Wylie Street')),
          '532 Wylie Street');
    });

    test('the absent sentinel still summarises to null', () {
      expect(locationSummary(Location.fromDefault()), isNull);
      expect(locationSummary(null), isNull);
    });
  });
}
