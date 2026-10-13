import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

import 'schedule_delta_test.dart' show tile, at, day;

void main() {
  test(
      'replacement IDs remain added/removed while churn diagnostics count shared parents',
      () {
    final before = [
      tile('old-secret-id', at(9, 0), 30)
        ..calendarEvent = TilerEvent(id: 'secret-parent')
        ..name = 'Private event',
      tile('old-2', at(10, 0), 30)
        ..calendarEvent = TilerEvent(id: 'secret-parent'),
    ];
    final after = [
      tile('new-secret-id', at(11, 0), 30)
        ..calendarEvent = TilerEvent(id: 'secret-parent')
        ..name = 'Private event',
    ];
    final delta = ScheduleDelta.compute(before: before, after: after, day: day);
    expect(delta.changes.where((c) => c.kind == TileChangeKind.added),
        hasLength(1));
    expect(delta.changes.where((c) => c.kind == TileChangeKind.removed),
        hasLength(2));
    expect(delta.identityChurn.pairs, 1);
    expect(delta.identityChurn.calendarEventCount, 1);
  });

  test('churn logs once per day with counts and no event contents', () {
    final lines = <String>[];
    final previousPrint = debugPrint;
    debugPrint = (message, {wrapWidth}) {
      if (message != null) lines.add(message);
    };
    addTearDown(() => debugPrint = previousPrint);
    final change = ScheduleChange(
        id: 1,
        revision: const ScheduleRevision('a', 'e'),
        attribution:
            const ScheduleChangeAttribution(ScheduleChangeOrigin.tilerRevise),
        before: [
          tile('old-secret-id', at(9, 0), 30)
            ..calendarEvent = TilerEvent(id: 'secret-parent')
        ],
        after: [
          tile('new-secret-id', at(10, 0), 30)
            ..calendarEvent = TilerEvent(id: 'secret-parent')
        ]);
    change.deltaFor(day);
    change.deltaFor(day);
    expect(
        lines.where((line) => line.contains('identity_churn')), hasLength(1));
    expect(lines.join(), contains('"pairs":1'));
    expect(lines.join(), contains('"calendarEventIds":1'));
    expect(lines.join(), isNot(contains('secret')));
  });

  test('unrelated and missing calendar IDs produce no churn', () {
    final delta = ScheduleDelta.compute(before: [
      tile('a', at(9, 0), 30)..calendarEvent = TilerEvent(id: 'a')
    ], after: [
      tile('b', at(10, 0), 30)..calendarEvent = TilerEvent(id: 'b'),
      tile('c', at(11, 0), 30)
    ], day: day);
    expect(delta.identityChurn.pairs, 0);
    expect(delta.identityChurn.calendarEventCount, 0);
  });
}
