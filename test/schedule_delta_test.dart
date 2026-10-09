import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

final DateTime _day = DateTime(2026, 10, 8);

int at(int hour, int minute, {int dayOffset = 0}) => _day
    .add(Duration(days: dayOffset, hours: hour, minutes: minute))
    .millisecondsSinceEpoch;

SubCalendarEvent tile(String id, int start, int minutes,
    {int travel = 0, String? thirdPartyId}) {
  final t = SubCalendarEvent(
      id: id, name: id, start: start, end: start + minutes * 60000);
  t.travelTimeBefore = travel * 60000.0;
  if (thirdPartyId != null) {
    t.thirdpartyType = TileSource.google;
    t.thirdpartyId = thirdPartyId;
  }
  return t;
}

final Timeline day = Timeline(at(0, 0), at(0, 0, dayOffset: 1));

/// The storyboard's Thursday: sync, groceries, Vit.D, dinner, read, plan.
List<SubCalendarEvent> base({Map<String, int>? starts, Map<String, int>? travel}) {
  SubCalendarEvent t(String id, int h, int m, int minutes, [int tr = 0]) =>
      tile(id, starts?[id] ?? at(h, m), minutes, travel: travel?[id] ?? tr);
  return [
    t('sync', 16, 0, 45),
    t('groc', 17, 15, 40, 12),
    t('vitd', 18, 11, 30, 7),
    t('dinner', 19, 0, 45),
    t('read', 20, 30, 30),
    t('plan', 21, 15, 15),
  ];
}

ScheduleDelta diff(List<SubCalendarEvent> before, List<SubCalendarEvent> after,
        {Timeline? beforeWindow, Timeline? afterWindow}) =>
    ScheduleDelta.compute(
        before: before,
        after: after,
        day: day,
        beforeWindow: beforeWindow,
        afterWindow: afterWindow);

void main() {
  group('classification', () {
    test('identical snapshots produce no changes', () {
      final delta = diff(base(), base());
      expect(delta.isEmpty, isTrue);
      expect(delta.tier, ScheduleDeltaTier.none);
      expect(delta.batches, isEmpty);
    });

    test('a new start is a move', () {
      final delta = diff(base(), base(starts: {'vitd': at(19, 55)}));
      expect(delta.changes.single.kind, TileChangeKind.moved);
      expect(delta.changes.single.id, 'vitd');
      expect(delta.changes.single.startShift,
          const Duration(hours: 1, minutes: 44));
      expect(delta.tier, ScheduleDeltaTier.single);
    });

    test('a new duration is a resize; both is movedAndResized', () {
      final resized = [
        for (final t in base())
          t.uniqueId == 'read' ? tile('read', at(20, 30), 45) : t
      ];
      expect(diff(base(), resized).changes.single.kind, TileChangeKind.resized);
      expect(diff(base(), resized).changes.single.durationShift,
          const Duration(minutes: 15));

      final both = [
        for (final t in base())
          t.uniqueId == 'read' ? tile('read', at(20, 40), 45) : t
      ];
      expect(diff(base(), both).changes.single.kind,
          TileChangeKind.movedAndResized);
    });

    test('shifts under a minute are noise', () {
      final after = base(starts: {'vitd': at(18, 11) + 30000});
      expect(diff(base(), after).isEmpty, isTrue);
    });

    test('a travel change without a move is reported but not a TileChange',
        () {
      final delta = diff(base(), base(travel: {'groc': 20}));
      expect(delta.changes, isEmpty);
      expect(delta.travelChanges.single.id, 'groc');
      expect(delta.travelChanges.single.delta, const Duration(minutes: 8));
      expect(delta.isEmpty, isFalse);
    });

    test('moves across days in both directions', () {
      final out = base(starts: {'read': at(20, 30, dayOffset: 1)});
      expect(diff(base(), out).changeFor('read')!.kind,
          TileChangeKind.movedToOtherDay);

      final before = base(starts: {'read': at(20, 30, dayOffset: -1)});
      expect(diff(before, base()).changeFor('read')!.kind,
          TileChangeKind.movedFromOtherDay);
    });

    test('a missing Tile is removed only when the new window covers it', () {
      final after = base()..removeWhere((t) => t.uniqueId == 'plan');
      expect(diff(base(), after).changeFor('plan')!.kind,
          TileChangeKind.removed);

      // The new snapshot no longer loads this day: unloaded, not removed.
      final elsewhere = Timeline(at(0, 0, dayOffset: 1), at(0, 0, dayOffset: 3));
      expect(diff(base(), after, afterWindow: elsewhere).isEmpty, isTrue);
    });

    test('a new Tile is added only when the old window covered it', () {
      final before = base()..removeWhere((t) => t.uniqueId == 'plan');
      expect(
          diff(before, base()).changeFor('plan')!.kind, TileChangeKind.added);

      // The old snapshot never loaded this day: newly loaded, not added.
      final earlier =
          Timeline(at(0, 0, dayOffset: -3), at(0, 0, dayOffset: -1));
      expect(diff(before, base(), beforeWindow: earlier).isEmpty, isTrue);
    });

    test('all-day Tiles are left out', () {
      final before = [...base(), tile('allday', at(1, 0), 17 * 60)];
      final after = [...base(), tile('allday', at(2, 0), 17 * 60)];
      final delta = diff(before, after);
      expect(delta.isEmpty, isTrue);
      expect(delta.tileCountBefore, 6);
    });

    test('a third-party Tile matches on thirdpartyId when its id changes', () {
      final before = [tile('evt-1', at(9, 0), 30, thirdPartyId: 'g-1')];
      final after = [tile('evt-2', at(10, 0), 30, thirdPartyId: 'g-1')];
      final change = diff(before, after).changes.single;
      expect(change.kind, TileChangeKind.moved);
      expect(change.id, 'g-1');
    });

    test('a Tiler Tile with a new id is a new sub-event', () {
      final before = [tile('a', at(9, 0), 30)];
      final after = [tile('b', at(10, 0), 30)];
      final kinds = diff(before, after).changes.map((c) => c.kind).toSet();
      expect(kinds, {TileChangeKind.removed, TileChangeKind.added});
    });
  });

  group('clusters and batches', () {
    test('a travel cause pushes a cluster that fits one batch', () {
      // Scenario B: the drive to groceries grows 12 -> 30 min, pushing
      // groceries and then Vit.D.
      final after = base(
          starts: {'groc': at(17, 33), 'vitd': at(18, 20)},
          travel: {'groc': 30});
      final delta = diff(base(), after);
      expect(delta.clusters, hasLength(1));
      expect(delta.clusters.single.tiles.map((c) => c.id), ['groc', 'vitd']);
      expect(delta.clusters.single.cause!.id, 'groc');
      expect(delta.batches, hasLength(1));
      expect(delta.batches.single.causes.single.id, 'groc');
      expect(delta.tier, ScheduleDeltaTier.batched);
    });

    test('an unchanged Tile splits clusters', () {
      final after = base(starts: {'groc': at(17, 20), 'read': at(20, 40)});
      final delta = diff(base(), after);
      expect(delta.clusters.map((c) => c.tiles.map((t) => t.id).toList()), [
        ['groc'],
        ['read'],
      ]);
      // Two single-Tile clusters still share one batch of up to 3.
      expect(delta.batches, hasLength(1));
      expect(delta.batches.single.tiles.map((c) => c.id), ['groc', 'read']);
    });

    List<SubCalendarEvent> row(int count, {int shift = 0}) => [
          for (var i = 0; i < count; i++)
            tile('t$i', at(8, 0) + (i * 60 + shift) * 60000, 30)
        ];

    test('seven movers make batches of 3, 3 and 1', () {
      final delta = diff(row(7), row(7, shift: 15));
      expect(delta.batches.map((b) => b.tiles.length), [3, 3, 1]);
      expect(delta.batches.map((b) => b.index), [0, 1, 2]);
      expect(delta.tier, ScheduleDeltaTier.batched);
    });

    test('a 4-Tile cluster splits 3 + 1 and keeps its cause in batch 0', () {
      final before = row(4);
      final after = row(4, shift: 15);
      after.first.travelTimeBefore = 10 * 60000.0;
      final delta = diff(before, after);
      expect(delta.clusters, hasLength(1));
      expect(delta.batches.map((b) => b.tiles.length), [3, 1]);
      expect(delta.batches[0].causes.single.id, 't0');
      expect(delta.batches[1].causes, isEmpty);
    });

    test('a later cluster cause plays with the batch holding its first Tile',
        () {
      // Cluster 1: t0..t2 (fills batch 0). t3 unchanged. Cluster 2: t4
      // with a travel change -> batch 1.
      final before = row(5);
      final after = [
        for (final t in row(5))
          ['t0', 't1', 't2', 't4'].contains(t.uniqueId)
              ? tile(t.uniqueId, t.start! + 15 * 60000, 30,
                  travel: t.uniqueId == 't4' ? 10 : 0)
              : t
      ];
      final delta = diff(before, after);
      expect(delta.clusters, hasLength(2));
      expect(delta.batches.map((b) => b.tiles.map((c) => c.id).toList()), [
        ['t0', 't1', 't2'],
        ['t4'],
      ]);
      expect(delta.batches[1].causes.single.id, 't4');
    });

    test('more than 9 movers is the compressed tier', () {
      final delta = diff(row(10), row(10, shift: 15));
      expect(delta.tilesMoved, 10);
      expect(delta.tier, ScheduleDeltaTier.compressed);
    });
  });

  group('tiers for empty days', () {
    test('emptied and filled', () {
      final out = [
        for (final t in base())
          tile(t.uniqueId, t.start! + const Duration(days: 1).inMilliseconds,
              30)
      ];
      expect(diff(base(), out).tier, ScheduleDeltaTier.dayEmptied);
      expect(diff(out, base()).tier, ScheduleDeltaTier.dayFilled);
    });

    test('an empty day staying empty is not a change', () {
      final delta = diff(const [], const []);
      expect(delta.tier, ScheduleDeltaTier.none);
      expect(delta.isEmpty, isTrue);
    });
  });

  test('free time net of travel', () {
    // Scenario A: Vit.D 6:11 -> 7:55 PM joins two gaps into 65 min.
    final delta = diff(base(), base(starts: {'vitd': at(19, 55)}));
    expect(delta.longestFreeMinutesBefore, 45);
    expect(delta.longestFreeMinutesAfter, 65);
    expect(delta.freeMinutesBefore, 106);
    expect(delta.freeMinutesDelta, 0);
  });

  group('anchorFor', () {
    final moveVitD = diff(base(), base(starts: {'vitd': at(19, 55)}));

    test('1. the subject Tile when it is visible and still on the day', () {
      expect(
          moveVitD.anchorFor(
              visibleIds: ['groc', 'vitd', 'dinner'], subjectId: 'vitd'),
          'vitd');
    });

    test('a subject that is not visible is ignored', () {
      expect(
          moveVitD.anchorFor(visibleIds: ['groc', 'vitd'], subjectId: 'plan'),
          'groc');
    });

    test('2. the stable Tile just before the first visible change', () {
      expect(
          moveVitD.anchorFor(visibleIds: ['sync', 'groc', 'vitd', 'dinner']),
          'groc');
    });

    test('2. else the stable Tile just after it', () {
      expect(moveVitD.anchorFor(visibleIds: ['vitd', 'dinner']), 'dinner');
    });

    test('3. nothing visible changed: the first stable Tile in view', () {
      expect(moveVitD.anchorFor(visibleIds: ['read', 'plan']), 'read');
    });

    test('4. every visible Tile changed: the first one still on the day', () {
      final delta = diff(
          base(), base(starts: {'groc': at(17, 33), 'vitd': at(18, 20)}));
      expect(delta.anchorFor(visibleIds: ['groc', 'vitd']), 'groc');
    });

    test('5. no anchor when the day was empty or is now empty', () {
      final out = [
        for (final t in base())
          tile(t.uniqueId, t.start! + const Duration(days: 1).inMilliseconds,
              30)
      ];
      expect(diff(base(), out).anchorFor(visibleIds: ['sync']), isNull);
      expect(diff(out, base()).anchorFor(visibleIds: const []), isNull);
    });
  });
}
