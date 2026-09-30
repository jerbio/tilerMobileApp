// TileShare redesign Step 9.5 (T7): the Attention chips. Pure rules for which
// item belongs to which chip, the counts on the chips, and where a card opens.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileShareAttention.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/attention/attentionFilter.dart';

AttentionItem _item(AttentionType type, [String cluster = 'c']) =>
    AttentionItem(type: type, clusterId: cluster);

void main() {
  final all = [
    for (final type in AttentionType.values) _item(type, type.name),
  ];

  group('AttentionFilter.matches', () {
    test('All matches everything', () {
      expect(all.every(AttentionFilter.all.matches), isTrue);
    });

    test('each chip takes exactly its types', () {
      Set<AttentionType> typesOf(AttentionFilter f) =>
          all.where(f.matches).map((i) => i.type).toSet();
      expect(typesOf(AttentionFilter.invitations), {AttentionType.invitation});
      expect(typesOf(AttentionFilter.changes), {AttentionType.changed});
      expect(typesOf(AttentionFilter.atRisk), {AttentionType.atRisk});
      expect(typesOf(AttentionFilter.responses), {
        AttentionType.declined,
        AttentionType.completed,
        AttentionType.deliveryFailed,
      });
    });

    test('every item type is reachable from a chip other than All', () {
      for (final item in all) {
        expect(
            AttentionFilter.values
                .where((f) => f != AttentionFilter.all)
                .any((f) => f.matches(item)),
            isTrue,
            reason: '${item.type} would only ever show under All');
      }
    });
  });

  group('AttentionFilter.apply / counts', () {
    test('apply keeps the order', () {
      final items = [
        _item(AttentionType.invitation, 'a'),
        _item(AttentionType.changed, 'b'),
        _item(AttentionType.invitation, 'c'),
      ];
      expect(
          AttentionFilter.invitations.apply(items).map((i) => i.clusterId),
          ['a', 'c']);
      expect(AttentionFilter.all.apply(items).length, 3);
    });

    test('counts per chip, including zero', () {
      final counts = AttentionFilter.counts([
        _item(AttentionType.invitation, 'a'),
        _item(AttentionType.invitation, 'b'),
        _item(AttentionType.declined, 'c'),
      ]);
      expect(counts[AttentionFilter.all], 3);
      expect(counts[AttentionFilter.invitations], 2);
      expect(counts[AttentionFilter.responses], 1);
      expect(counts[AttentionFilter.changes], 0);
      expect(counts[AttentionFilter.atRisk], 0);
    });

    test('an empty list counts zero everywhere', () {
      final counts = AttentionFilter.counts(const []);
      expect(counts.values.every((c) => c == 0), isTrue);
      expect(counts.keys.toSet(), AttentionFilter.values.toSet());
    });
  });

  group('where an item opens (old detail screens until 9.12)', () {
    test('what I am invited to / affected by opens the recipient view', () {
      for (final type in [
        AttentionType.invitation,
        AttentionType.atRisk,
        AttentionType.changed,
      ]) {
        expect(attentionOpensOutbox(_item(type)), isFalse, reason: '$type');
      }
    });

    test('what people did to MY share opens the owner view', () {
      for (final type in [
        AttentionType.declined,
        AttentionType.completed,
        AttentionType.deliveryFailed,
      ]) {
        expect(attentionOpensOutbox(_item(type)), isTrue, reason: '$type');
      }
    });
  });
}
