// Deleting a location's name must not ship an empty one (D55).
//
// Reported from a device recording. Clearing the name in the place editor
// produced `LocationTag: ""` — an empty string is PRESENT on the wire, and the
// contract the user described is about presence:
//
//   * both `LocationAddress` and `LocationTag` absent  -> null location
//   * only one present                                 -> copied into the other
//
// So an empty tag is not "no name"; it is a name, and the backend upserts
// places by name. Clearing the name of a place that had no address is worse
// still: the result carries nothing at all, yet the mapper kept emitting
// location fields for it.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

final now = DateTime(2026, 9, 9, 9, 0);

NewTile mapWith(Location location) {
  final draft = AddTileDraft.flexible(now: now);
  draft.name = 'Something';
  draft.setUserDuration(const Duration(hours: 1));
  draft.setLocation(location);
  return NewTileRequestMapper.buildFromSnapshot(draft.snapshot, now: now);
}

Location savedPlace({String? description, String? address}) =>
    Location.fromJson(<String, dynamic>{
      'id': 'tiler-guid',
      'source': 'none',
      'isNull': false,
      'isDefault': false,
      if (description != null) 'description': description,
      if (address != null) 'address': address,
    });

void main() {
  group('Clearing the name, keeping the address', () {
    test('no empty LocationTag reaches the wire', () {
      // An empty string is present. The backend upserts by name, so a blank
      // one is a place called "".
      final Location cleared = buildEditedPlace(
        name: '',
        address: '745 us-287',
        original: savedPlace(description: 'work', address: '745 us-287'),
      );

      final NewTile tile = mapWith(cleared);
      expect(tile.LocationTag, isNull);
      expect(tile.LocationAddress, '745 us-287',
          reason: 'the address survives — only the name was deleted');
    });
  });

  group('Clearing the name of a place with no address', () {
    test('nothing location-shaped is sent at all', () {
      // The result carries neither a name nor an address, which is exactly the
      // "both absent -> null location" case.
      final Location emptied = buildEditedPlace(
        name: '',
        address: '',
        original: savedPlace(description: 'work'),
      );

      final NewTile tile = mapWith(emptied);
      expect(tile.LocationTag, isNull);
      expect(tile.LocationAddress, isNull);
      expect(tile.LocationId, isNull);
      expect(tile.LocationSource, isNull,
          reason: 'a location with no content is not a location');
      expect(tile.LocationIsVerified, isNull);
    });

    test('the absent sentinel is treated the same way', () {
      final NewTile tile = mapWith(Location.fromDefault());
      expect(tile.LocationTag, isNull);
      expect(tile.LocationAddress, isNull);
      expect(tile.LocationSource, isNull);
    });
  });

  group('A blank address does not reach the wire either', () {
    test('a name-only place sends the name and no empty address', () {
      // The mirror of the reported bug: `LocationAddress: ""` would be just as
      // present as an empty tag.
      final Location nameOnly = buildEditedPlace(
        name: 'bike shop',
        address: '',
        original: null,
      );

      final NewTile tile = mapWith(nameOnly);
      expect(tile.LocationTag, 'bike shop');
      expect(tile.LocationAddress, isNull);
    });
  });

  group('A fully specified place is unaffected', () {
    test('both fields still ship', () {
      final NewTile tile =
          mapWith(savedPlace(description: 'work', address: '745 us-287'));
      expect(tile.LocationTag, 'work');
      expect(tile.LocationAddress, '745 us-287');
      expect(tile.LocationSource, 'none');
    });
  });
}
