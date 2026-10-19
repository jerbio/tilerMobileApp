import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileRequestMapper.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';

import '../addTile/l10n_fixture.dart';
import 'edit_tile_phase2_test.dart' as fixtures;
import 'edit_tile_shell_test.dart' as shell;

Location place(String name, [String? address]) =>
    Location.fromJson(<String, dynamic>{
      'description': name,
      'address': address,
    });

Finder key(String value) => find.byKey(ValueKey(value));

void expectNoLocationUpdate(Map<String, dynamic> params) {
  expect(params.keys.where((key) => key.startsWith('SubEvent')), isEmpty);
}

void main() {
  group('Occurrence location draft and request', () {
    test('seeds the occurrence location without changing the original', () {
      final original = fixtures.tile(location: place('Work', '456 Market St'));
      final draft = EditTileDraft.fromLoaded(original);
      expect(draft.location?.description, 'Work');
      expect(draft.isDirty, isFalse);
      draft.location!.description = 'HQ';
      expect(original.location?.description, 'Work');
      expect(draft.dirtyFields, {EditTileField.location});
      draft.setLocation(place('Work', '456 Market St'));
      expect(draft.isDirty, isFalse);
    });

    test('flat occurrence address fields are supported', () {
      final original = fixtures.tile()
        ..address = '456 Market St'
        ..addressDescription = 'Work';
      final draft = EditTileDraft.fromLoaded(original);
      expect(draft.location?.address, '456 Market St');
      expect(draft.location?.description, 'Work');
      draft.clearLocation();
      expect(editTileUpdateParams(draft)['SubEventIsLocationCleared'], isTrue);
    });

    test('blank locations normalize to absent', () {
      final draft = EditTileDraft.fromLoaded(fixtures.tile());
      draft.setLocation(place('   ', ' '));
      expect(draft.location, isNull);
      expect(draft.canSave, isFalse);
      expectNoLocationUpdate(editTileUpdateParams(draft));
    });

    test('adding a location saves only this occurrence', () {
      final draft = EditTileDraft.fromLoaded(fixtures.tile())
        ..setLocation(place('Work', '456 Market St'));
      expect(draft.dirtyFields, {EditTileField.location});
      expect(draft.canSave, isTrue);
      expect(draft.timeIsDirty, isFalse);
      final params = editTileUpdateParams(draft);
      expect(params['SubEventIsLocationCleared'], isFalse);
      expect(params['SubEventAddress'], '456 Market St');
      expect(params['SubEventAddressDescription'], 'Work');
      expect(params['ApplicableOccurence'], 'Single');
      expect(params.containsKey('CalAddress'), isFalse);
      expect(params.containsKey('IsLocationCleared'), isFalse);
    });

    test('name-only places send an empty address', () {
      final draft = EditTileDraft.fromLoaded(fixtures.tile())
        ..setLocation(place('Bike shop'));
      final params = editTileUpdateParams(draft);
      expect(params['SubEventIsLocationCleared'], isFalse);
      expect(params['SubEventAddress'], '');
      expect(params['SubEventAddressDescription'], 'Bike shop');
    });

    test('renaming and replacing a place each send the new values', () {
      final draft = EditTileDraft.fromLoaded(
          fixtures.tile(location: place('Work', '456 Market St')));
      draft.setLocation(place('HQ', '456 Market St'));
      expect(editTileUpdateParams(draft)['SubEventAddressDescription'], 'HQ');
      draft.setLocation(place('Home', '123 Main St'));
      final params = editTileUpdateParams(draft);
      expect(params['SubEventIsLocationCleared'], isFalse);
      expect(params['SubEventAddress'], '123 Main St');
      expect(params['SubEventAddressDescription'], 'Home');
    });

    test('removing a loaded location sends the explicit clear flag', () {
      final draft = EditTileDraft.fromLoaded(
          fixtures.tile(location: place('Work', '456 Market St')))
        ..clearLocation();
      final params = editTileUpdateParams(draft);
      expect(draft.canSave, isTrue);
      expect(params['SubEventIsLocationCleared'], isTrue);
      expect(params['SubEventAddress'], '');
      expect(params['SubEventAddressDescription'], '');
    });

    test('unrelated edits and reverting location omit location fields', () {
      final draft = EditTileDraft.fromLoaded(
          fixtures.tile(location: place('Work', '456 Market St')))
        ..setName('Edited');
      expectNoLocationUpdate(editTileUpdateParams(draft));
      draft.clearLocation();
      draft.setLocation(place('Work', '456 Market St'));
      expectNoLocationUpdate(editTileUpdateParams(draft));
      final empty = EditTileDraft.fromLoaded(fixtures.tile())
        ..setLocation(place('Work', '456 Market St'))
        ..clearLocation();
      expect(empty.isDirty, isFalse);
      expectNoLocationUpdate(editTileUpdateParams(empty));
    });
  });

  group('Occurrence location form', () {
    testWidgets('selecting a place enables Save and reaches submission',
        (tester) async {
      Location? seed;
      await shell.pumpEdit(tester, pickLocation: (_, value) async {
        seed = value;
        return place('Work', '456 Market St');
      });
      await shell.scrollTo(tester, key('editLocationRow'));
      expect(find.text(testL10n.addTileValueNotSet), findsWidgets);
      await tester.tap(key('editLocationRow'));
      await tester.pumpAndSettle();
      expect(seed, isNull);
      expect(find.text('Work'), findsOneWidget);
      expect(shell.draftOf(tester).canSave, isTrue);
      expect(shell.submission.previews, isEmpty);
      await tester.tap(shell.save);
      await tester.pumpAndSettle();
      expect(shell.submission.saved, hasLength(1));
      expect(
          editTileUpdateParams(
              shell.submission.saved.single)['SubEventAddress'],
          '456 Market St');
    });

    testWidgets('dismissing a picker preserves the loaded location',
        (tester) async {
      Location? seed;
      await shell.pumpEdit(tester,
          tile: fixtures.tile(location: place('Work', '456 Market St')),
          pickLocation: (_, value) async {
        seed = value;
        return null;
      });
      await shell.scrollTo(tester, key('editLocationRow'));
      await tester.tap(key('editLocationRow'));
      await tester.pumpAndSettle();
      expect(seed?.description, 'Work');
      expect(shell.draftOf(tester).isDirty, isFalse);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('naming and removing a loaded place change the draft',
        (tester) async {
      Location? seed;
      await shell.pumpEdit(tester,
          tile: fixtures.tile(location: place('Work', '456 Market St')),
          editPlace: (_, value) async {
        seed = value;
        return place('HQ', '456 Market St');
      });
      await shell.scrollTo(tester, key('editLocationRow'));
      await tester.tap(find.byType(NameLocationButton));
      await tester.pumpAndSettle();
      expect(seed?.description, 'Work');
      expect(shell.draftOf(tester).location?.description, 'HQ');
      await tester.tap(key('editLocationClear'));
      await tester.pump();
      expect(shell.draftOf(tester).locationCleared, isTrue);
      expect(key('editLocationClear'), findsNothing);
      await tester.tap(key('editTileClose'));
      await tester.pumpAndSettle();
      expect(find.text(testL10n.editTileDiscardTitle), findsOneWidget);
    });

    testWidgets('location is locked for completed, provider and blocked tiles',
        (tester) async {
      int calls = 0;
      for (final tile in [
        fixtures.tile(isComplete: true),
        fixtures.tile(thirdPartyType: 'google'),
        fixtures.tile(isProcrastinate: true),
      ]) {
        tile.location = place('Work', '456 Market St');
        await shell.pumpEdit(tester, tile: tile, pickLocation: (_, __) async {
          calls++;
          return place('Home');
        });
        await shell.scrollTo(tester, key('editLocationRow'));
        await tester.tap(key('editLocationRow'));
        await tester.pumpAndSettle();
        expect(key('editLocationClear'), findsNothing);
        expect(find.byType(NameLocationButton), findsNothing);
        expect(shell.draftOf(tester).isDirty, isFalse);
      }
      expect(calls, 0);
    });

    testWidgets('saving locks location and a failure retains the selection',
        (tester) async {
      await shell.pumpEdit(tester,
          pickLocation: (_, __) async => place('Work', '456 Market St'));
      await shell.scrollTo(tester, key('editLocationRow'));
      await tester.tap(key('editLocationRow'));
      await tester.pumpAndSettle();
      final gate = Completer<EditTileSaveResult>();
      shell.submission.gate = gate;
      await tester.tap(shell.save);
      await tester.pump();
      await tester.tap(key('editLocationClear'), warnIfMissed: false);
      expect(shell.draftOf(tester).location?.description, 'Work');
      gate.complete(const EditTileSaveResult.failure(editTileFailureNetwork));
      await tester.pumpAndSettle();
      expect(shell.draftOf(tester).location?.description, 'Work');
      expect(shell.draftOf(tester).canSave, isTrue);
    });
  });
}
