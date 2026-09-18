// No-deadline ("Anytime") Flexible Tile wire contract: a Flexible Tile with no
// deadline maps to a WELL-FORMED request that the server is expected to
// accept, and the client parses it back as "no deadline".
//
// Why a dedicated suite (beyond the parity case that already exists):
//   * The parity test (add_tile_request_mapper_parity_test.dart) proves the
//     NEW mapper equals the LEGACY mapper for a no-deadline draft — i.e. we
//     did not REGRESS the legacy behavior. It does not independently assert
//     the payload is the shape the server contract expects.
//   * This suite asserts that shape directly: End* fields are present as null,
//     `NewTile.getEndDateTime()` returns null, AutoReviseDeadline stays true,
//     and the tile is non-Rigid (a Flexible Tile, not a Fixed Block).
//
// Server ACCEPTANCE (the live half of this contract) cannot be exercised in
// the unit suite — it needs a valid auth token + network — so it is captured
// as a skip-gated seam in add_tile_draft_contract_test.dart ("server
// acceptance of a no-deadline Flexible Tile"). The offline assertions here are
// the committable evidence that the omitted deadline is *correctly mapped*,
// which is the precondition for that live check.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

DateTime get _now => DateTime(2026, 9, 4, 14, 30);

/// Builds the no-deadline Flexible draft (Complete by: Anytime) exactly as the
/// redesigned form will when the user leaves "Complete by" at its default.
AddTileDraft _noDeadlineFlexible() => AddTileDraft.flexible(
      now: _now,
      name: 'Anytime task',
      duration: const Duration(minutes: 30),
      // No endTime -> "Complete by: Anytime" -> deadline left unset.
      // Explicit color so the random-color fallback never runs (deterministic).
      color: const Color(0xFF336699),
    );

void main() {
  group('no-deadline Flexible Tile wire contract', () {
    test('End* fields are present as null (deadline omitted, not zeroed)', () {
      final NewTile tile = NewTileRequestMapper.buildFromSnapshot(
          _noDeadlineFlexible().snapshot,
          now: _now);
      final Map<String, dynamic> json = tile.toJson();

      // Every end-date/time part is a key that maps to null — the payload says
      // "no deadline" explicitly rather than omitting or zero-filling it.
      expect(json.containsKey('EndDay'), isTrue,
          reason: 'EndDay must be present in the wire payload');
      expect(json['EndDay'], isNull);
      expect(json['EndMonth'], isNull);
      expect(json['EndYear'], isNull);
      expect(json['EndHour'], isNull);
      expect(json['EndMinute'], isNull);

      expect(tile.EndDay, isNull);
      expect(tile.EndMonth, isNull);
      expect(tile.EndYear, isNull);
      expect(tile.EndHour, isNull);
      expect(tile.EndMinute, isNull);
    });

    test('getEndDateTime() returns null (client parses it as no deadline)', () {
      final NewTile tile = NewTileRequestMapper.buildFromSnapshot(
          _noDeadlineFlexible().snapshot,
          now: _now);
      expect(tile.getEndDateTime(), isNull,
          reason:
              'The client must read a no-deadline payload back as "no deadline" '
              '(null), not as epoch/zero.');
    });

    test('AutoReviseDeadline stays true and the tile is non-Rigid', () {
      final NewTile tile = NewTileRequestMapper.buildFromSnapshot(
          _noDeadlineFlexible().snapshot,
          now: _now);
      // Wire field is the string "true" (not a bool) — legacy behavior: a
      // no-deadline Flexible Tile lets the scheduler revise (deadline
      // flexibility preserved).
      expect(tile.AutoReviseDeadline, 'true',
          reason:
              'Legacy behavior: a no-deadline Flexible Tile lets the scheduler '
              'revise (deadline flexibility preserved).');
      // The wire field Rigid is a String? and the mapper only ever sets it to
      // 'true' for Fixed Blocks. A Flexible Tile leaves it unset (null) —
      // "Rigid unset/false".
      expect(tile.Rigid, isNull,
          reason: 'Flexible Tiles are non-Rigid; the mapper leaves Rigid unset '
              '(null) rather than sending a Rigid flag.');
    });

    test('name + duration still map (deadline omission drops nothing else)',
        () {
      final NewTile tile = NewTileRequestMapper.buildFromSnapshot(
          _noDeadlineFlexible().snapshot,
          now: _now);
      expect(tile.Name, 'Anytime task');
      // Duration round-trips through the getDuration() helper (0d/0h/30m).
      expect(tile.getDuration(), const Duration(minutes: 30));
    });
  });
}
