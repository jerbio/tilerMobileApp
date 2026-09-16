// DayContentFilter (P7 Step 17.1): the UI-only Daily content filter —
// `all` / `blocks` / `tiles` — its pure predicate and its session cubit.
//
//   * block = `isRigid == true` (C29); third-party events are rigid, so they
//     are blocks (C30); a null/false `isRigid` is a tile.
//   * `apply` preserves input order and never mutates it.
//   * the cubit starts at `all` (C32), `set` switches, `clear` returns to
//     `all`, and `clearIfHides` clears only when an ADDED tile would be hidden.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

SubCalendarEvent _tile(String id, {bool? rigid, TileSource? source}) {
  final tile = SubCalendarEvent(id: id, name: id, start: 0, end: 1);
  if (rigid != null) tile.isRigid = rigid;
  if (source != null) tile.thirdpartyType = source;
  return tile;
}

void main() {
  group('DayContentFilter.matches (C29 / C30)', () {
    final block = _tile('block', rigid: true);
    final google = _tile('google', rigid: true, source: TileSource.google);
    final flexible = _tile('flex', rigid: false);
    final unknown = _tile('unknown');

    test('all matches everything', () {
      for (final t in [block, google, flexible, unknown]) {
        expect(DayContentFilter.all.matches(t), isTrue);
      }
    });

    test('blocks matches rigid tiles only (third-party rigid included)', () {
      expect(DayContentFilter.blocks.matches(block), isTrue);
      expect(DayContentFilter.blocks.matches(google), isTrue);
      expect(DayContentFilter.blocks.matches(flexible), isFalse);
      expect(DayContentFilter.blocks.matches(unknown), isFalse);
    });

    test('tiles matches non-rigid tiles only', () {
      expect(DayContentFilter.tiles.matches(block), isFalse);
      expect(DayContentFilter.tiles.matches(google), isFalse);
      expect(DayContentFilter.tiles.matches(flexible), isTrue);
      expect(DayContentFilter.tiles.matches(unknown), isTrue);
    });

    test('apply preserves order and does not mutate the input', () {
      final input = <TilerEvent>[flexible, block, unknown, google];
      final out = DayContentFilter.tiles.apply(input);
      expect(out.map((t) => t.id), ['flex', 'unknown']);
      expect(input, hasLength(4));
      expect(identical(DayContentFilter.all.apply(input), input), isTrue,
          reason: 'all is the identity — no copy, so the grid diff sees the '
              'same instance and does not re-sync');
    });
  });

  group('DayContentFilterCubit (C31 / C32)', () {
    test('starts at all; set switches; clear returns to all', () {
      final cubit = DayContentFilterCubit();
      expect(cubit.state, DayContentFilter.all);
      cubit.set(DayContentFilter.blocks);
      expect(cubit.state, DayContentFilter.blocks);
      cubit.set(DayContentFilter.tiles);
      expect(cubit.state, DayContentFilter.tiles);
      cubit.clear();
      expect(cubit.state, DayContentFilter.all);
      cubit.close();
    });

    test('clearIfHides clears only when an added tile would be hidden', () {
      final cubit = DayContentFilterCubit();
      cubit.set(DayContentFilter.blocks);
      // A matching addition keeps the filter.
      expect(cubit.clearIfHides([_tile('b', rigid: true)]), isFalse);
      expect(cubit.state, DayContentFilter.blocks);
      // A hidden addition clears it.
      expect(cubit.clearIfHides([_tile('t', rigid: false)]), isTrue);
      expect(cubit.state, DayContentFilter.all);
      // Nothing to clear at all.
      expect(cubit.clearIfHides([_tile('t2', rigid: false)]), isFalse);
      cubit.close();
    });
  });
}
