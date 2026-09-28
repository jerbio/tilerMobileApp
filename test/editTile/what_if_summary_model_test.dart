// WhatIfSummary — the grouped, capped shape the edit-tile what-if sheet
// renders: affected tiles tiered by day (max 3 dated days), high priority
// first inside a day, unplaceable overflow tiles in their own trailing
// group.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/whatIfSummaryModel.dart';
import 'package:tiler_app/util.dart';

SubCalendarEvent _tile(
  String name, {
  DateTime? start,
  Duration duration = const Duration(hours: 1),
  String priority = 'medium',
}) {
  return SubCalendarEvent.fromJson(<String, dynamic>{
    'id': name,
    'name': name,
    'thirdPartyType': 'tiler',
    'priority': priority,
    if (start != null) 'start': start.millisecondsSinceEpoch,
    if (start != null)
      'end': start.add(duration).millisecondsSinceEpoch,
  });
}

void main() {
  final DateTime day1 = DateTime(2027, 1, 15);
  final DateTime day2 = DateTime(2027, 1, 16);
  final DateTime day3 = DateTime(2027, 1, 17);
  final DateTime day4 = DateTime(2027, 1, 18);

  test('groups affected tiles by day, ascending', () {
    final summary = WhatIfSummary.from(
      tardy: [
        _tile('d2', start: day2.add(const Duration(hours: 9))),
        _tile('d1', start: day1.add(const Duration(hours: 9))),
      ],
      overflow: [_tile('d1b', start: day1.add(const Duration(hours: 14)))],
    );
    expect(summary.days, hasLength(2));
    expect(summary.days[0].day!.universalDayIndex, day1.universalDayIndex);
    expect(summary.days[0].entries.map((e) => e.tile.name), ['d1', 'd1b']);
    expect(summary.days[1].entries.map((e) => e.tile.name), ['d2']);
    expect(summary.undated, isNull);
    expect(summary.hiddenDayCount, 0);
  });

  test('keeps each entry\'s impact (late vs overflow)', () {
    final summary = WhatIfSummary.from(
      tardy: [_tile('late', start: day1.add(const Duration(hours: 9)))],
      overflow: [_tile('over', start: day1.add(const Duration(hours: 10)))],
    );
    final entries = summary.days.single.entries;
    expect(entries[0].impact, WhatIfImpact.late);
    expect(entries[1].impact, WhatIfImpact.overflow);
  });

  test('caps the list at three dated days and counts the rest', () {
    final summary = WhatIfSummary.from(
      tardy: [
        for (final d in [day1, day2, day3, day4])
          _tile('t${d.day}', start: d.add(const Duration(hours: 9))),
      ],
      overflow: const [],
    );
    expect(summary.days, hasLength(WhatIfSummary.maxDays));
    expect(summary.days.map((g) => g.day!.day), [15, 16, 17]);
    expect(summary.hiddenDayCount, 1);
  });

  test('high-priority entries sort first inside their day', () {
    final summary = WhatIfSummary.from(
      tardy: [
        _tile('early', start: day1.add(const Duration(hours: 8))),
        _tile('urgent',
            start: day1.add(const Duration(hours: 17)), priority: 'high'),
      ],
      overflow: const [],
    );
    final group = summary.days.single;
    expect(group.entries.map((e) => e.tile.name), ['urgent', 'early']);
    expect(group.entries.first.isHighPriority, isTrue);
    expect(group.highPriorityCount, 1);
  });

  test('tiles with no start land in the undated group, outside the cap', () {
    final summary = WhatIfSummary.from(
      tardy: const [],
      overflow: [
        _tile('nowhere'),
        _tile('placed', start: day1.add(const Duration(hours: 9))),
      ],
    );
    expect(summary.days, hasLength(1));
    expect(summary.undated, isNotNull);
    expect(summary.undated!.isUndated, isTrue);
    expect(summary.undated!.entries.map((e) => e.tile.name), ['nowhere']);
    expect(summary.hiddenDayCount, 0);
  });

  test('an undated group alone still yields a non-empty summary', () {
    final summary =
        WhatIfSummary.from(tardy: const [], overflow: [_tile('nowhere')]);
    expect(summary.days, isEmpty);
    expect(summary.isEmpty, isFalse);
  });

  test('no affected tiles -> empty', () {
    final summary = WhatIfSummary.from(tardy: const [], overflow: const []);
    expect(summary.isEmpty, isTrue);
  });

  test('entries expose start and end for the row time range', () {
    final DateTime start = day1.add(const Duration(hours: 9, minutes: 30));
    final summary = WhatIfSummary.from(
      tardy: [_tile('t', start: start, duration: const Duration(minutes: 45))],
      overflow: const [],
    );
    final entry = summary.days.single.entries.single;
    expect(entry.start, start);
    expect(entry.end, start.add(const Duration(minutes: 45)));
  });
}
