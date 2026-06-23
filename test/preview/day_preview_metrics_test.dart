import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/preview/day_preview_metrics.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/travelDetail.dart';

/// Builds a [SubCalendarEvent] via JSON so we can set private flags like
/// `isRigid`, `isComplete`, etc. without modifying production code.
SubCalendarEvent _buildSub({
  required String id,
  required int startMs,
  required int endMs,
  bool isRigid = false,
  bool isComplete = false,
  bool isEnabled = true,
  bool isViable = true,
  String? tileShareDesignatedId,
  String? locationId,
  String? address,
  double? travelTimeBeforeMs,
  double? travelTimeAfterMs,
  TravelDetail? travelDetail,
}) {
  final json = <String, dynamic>{
    'id': id,
    'start': startMs,
    'end': endMs,
    'isRigid': isRigid,
    'isComplete': isComplete,
    'isEnabled': isEnabled,
    'isViable': isViable,
    if (tileShareDesignatedId != null)
      'tileShareDesignatedId': tileShareDesignatedId,
    if (locationId != null) 'locationId': locationId,
    if (address != null) 'address': address,
    if (travelTimeBeforeMs != null) 'travelTimeBefore': travelTimeBeforeMs,
    if (travelTimeAfterMs != null) 'travelTimeAfter': travelTimeAfterMs,
  };
  final sub = SubCalendarEvent.fromJson(json);
  if (travelDetail != null) {
    sub.travelDetail = travelDetail;
  }
  return sub;
}

TravelDetail _td({
  double? beforeMs,
  double? afterMs,
  double? beforeDistance,
  double? afterDistance,
  String? unit,
}) {
  return TravelDetail(
    before: beforeMs == null && beforeDistance == null
        ? null
        : TravelData(
            duration: beforeMs,
            distance: beforeDistance,
            distanceUnit: unit,
          ),
    after: afterMs == null && afterDistance == null
        ? null
        : TravelData(
            duration: afterMs,
            distance: afterDistance,
            distanceUnit: unit,
          ),
  );
}

Timeline _today() {
  final start = DateTime.utc(2026, 6, 21, 0, 0, 0);
  final end = DateTime.utc(2026, 6, 21, 23, 59, 59, 999);
  return Timeline(start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
}

int _at(int hour, [int minute = 0]) {
  return DateTime.utc(2026, 6, 21, hour, minute).millisecondsSinceEpoch;
}

void main() {
  group('DayPreviewMetrics.from', () {
    test('counts tiles, blocks, tileshares within today only', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        _buildSub(id: 't2', startMs: _at(11), endMs: _at(12)),
        _buildSub(id: 'b1', startMs: _at(13), endMs: _at(14), isRigid: true),
        _buildSub(id: 'b2', startMs: _at(15), endMs: _at(16), isRigid: true),
        _buildSub(
          id: 's1',
          startMs: _at(17),
          endMs: _at(18),
          tileShareDesignatedId: 'share-1',
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.tilesCount, 3); // t1, t2, s1
      expect(m.blocksCount, 2);
      expect(m.tileSharesCount, 1);
    });

    test('excludes events outside today timeline', () {
      final today = _today();
      final outsideStart = DateTime.utc(2026, 6, 22, 9).millisecondsSinceEpoch;
      final outsideEnd = DateTime.utc(2026, 6, 22, 10).millisecondsSinceEpoch;
      final subs = [
        _buildSub(id: 'in', startMs: _at(9), endMs: _at(10)),
        _buildSub(id: 'out', startMs: outsideStart, endMs: outsideEnd),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.tilesCount, 1);
    });

    test('work duration sums non-rigid, viable, non-complete tile durations',
        () {
      final today = _today();
      final subs = [
        // 1h non-rigid viable -> counted
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        // 30m non-rigid viable -> counted
        _buildSub(id: 't2', startMs: _at(11), endMs: _at(11, 30)),
        // 1h rigid -> NOT counted (block)
        _buildSub(id: 'b1', startMs: _at(13), endMs: _at(14), isRigid: true),
        // 1h non-rigid but complete -> NOT counted
        _buildSub(id: 'tc', startMs: _at(15), endMs: _at(16), isComplete: true),
        // 1h non-rigid not viable -> NOT counted
        _buildSub(id: 'tn', startMs: _at(17), endMs: _at(18), isViable: false),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.workDuration, const Duration(minutes: 90));
    });

    test('transit duration sums travelDetail before+after when present', () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          travelDetail: _td(beforeMs: 5 * 60 * 1000, afterMs: 3 * 60 * 1000),
        ),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          travelDetail: _td(beforeMs: 4 * 60 * 1000),
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.transitDuration, const Duration(minutes: 12));
    });

    test(
        'transit duration falls back to travelTimeBefore/After when no travelDetail',
        () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          travelTimeBeforeMs: 6 * 60 * 1000,
          travelTimeAfterMs: 2 * 60 * 1000,
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.transitDuration, const Duration(minutes: 8));
    });

    test('day clears by returns max end of viable, non-complete events', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        _buildSub(id: 't2', startMs: _at(14), endMs: _at(17)),
        // not viable -> ignored
        _buildSub(id: 'tn', startMs: _at(18), endMs: _at(19), isViable: false),
        // completed -> ignored
        _buildSub(id: 'tc', startMs: _at(20), endMs: _at(21), isComplete: true),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.dayClearsBy,
          DateTime.fromMillisecondsSinceEpoch(_at(17), isUtc: true));
    });

    test('day clears by is null when no viable non-complete tiles', () {
      final today = _today();
      final subs = [
        _buildSub(id: 'tn', startMs: _at(9), endMs: _at(10), isViable: false),
        _buildSub(id: 'tc', startMs: _at(11), endMs: _at(12), isComplete: true),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.dayClearsBy, isNull);
    });

    test('completion pct is duration-weighted, not count-weighted', () {
      final today = _today();
      // remaining viable, non-complete: 1h
      final subs = [
        _buildSub(id: 'r1', startMs: _at(14), endMs: _at(15)),
      ];

      // completed durations: 3h total (e.g. one 2h + one 1h)
      final completed = [
        _buildSub(id: 'c1', startMs: _at(9), endMs: _at(11), isComplete: true),
        _buildSub(id: 'c2', startMs: _at(12), endMs: _at(13), isComplete: true),
      ];
      final summary = TimelineSummary()..complete = completed;

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
        timelineSummary: summary,
      );

      // 3h / (3h + 1h) = 0.75
      expect(m.completionPct, closeTo(0.75, 1e-9));
    });

    test('completion pct is 0 when no completed durations', () {
      final today = _today();
      final subs = [
        _buildSub(id: 'r1', startMs: _at(14), endMs: _at(15)),
      ];
      final summary = TimelineSummary()..complete = [];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
        timelineSummary: summary,
      );

      expect(m.completionPct, 0.0);
    });

    test('completion pct is 1.0 when only completed tiles exist', () {
      final today = _today();
      final completed = [
        _buildSub(id: 'c1', startMs: _at(9), endMs: _at(10), isComplete: true),
      ];
      final summary = TimelineSummary()..complete = completed;

      final m = DayPreviewMetrics.from(
        subEvents: const [],
        dayTimeline: today,
        timelineSummary: summary,
      );

      expect(m.completionPct, 1.0);
    });

    test('distance sums distance from before+after when present', () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          travelDetail: _td(beforeDistance: 1000.0, afterDistance: 500.0),
        ),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          travelDetail: _td(beforeDistance: 2500.0),
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.distance, 4000.0);
    });

    test('distance is null when no travelDetail distances exist', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          travelDetail: _td(beforeMs: 500),
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.distance, isNull);
    });

    test('distance unit picks first non-null unit across events', () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          travelDetail: _td(beforeDistance: 100.0),
        ),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          travelDetail: _td(beforeDistance: 200.0, unit: 'miles'),
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.distanceUnit, 'miles');
    });

    test('distance unit defaults to meters when all null', () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          travelDetail: _td(beforeDistance: 100.0),
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.distanceUnit, 'meters');
    });

    test('locations count dedups by locationId first', () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          locationId: 'loc-A',
          address: '1 Main St',
        ),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          locationId: 'loc-A',
          address: 'different address text',
        ),
        _buildSub(
          id: 't3',
          startMs: _at(13),
          endMs: _at(14),
          locationId: 'loc-B',
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.locationsCount, 2);
    });

    test('locations count falls back to normalized address when no locationId',
        () {
      final today = _today();
      final subs = [
        _buildSub(
          id: 't1',
          startMs: _at(9),
          endMs: _at(10),
          address: '  1 Main St  ',
        ),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          address: '1 MAIN ST',
        ),
        _buildSub(
          id: 't3',
          startMs: _at(13),
          endMs: _at(14),
          address: '2 Oak Ave',
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.locationsCount, 2);
    });

    test('locations count ignores events with no locationId or address', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        _buildSub(
          id: 't2',
          startMs: _at(11),
          endMs: _at(12),
          locationId: '   ',
          address: '',
        ),
        _buildSub(
          id: 't3',
          startMs: _at(13),
          endMs: _at(14),
          locationId: 'loc-A',
        ),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.locationsCount, 1);
    });

    test('sleep duration reads from timeline summary when present', () {
      final today = _today();
      final summary = TimelineSummary()
        ..sleepDuration = const Duration(hours: 5);

      final m = DayPreviewMetrics.from(
        subEvents: const [],
        dayTimeline: today,
        timelineSummary: summary,
      );

      expect(m.sleepDuration, const Duration(hours: 5));
    });

    test('null timeline summary yields null completion and sleep', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.completionPct, isNull);
      expect(m.sleepDuration, isNull);
    });

    test('non-viable count reflects sub events in today timeline', () {
      final today = _today();
      final subs = [
        _buildSub(id: 't1', startMs: _at(9), endMs: _at(10)),
        _buildSub(id: 'n1', startMs: _at(11), endMs: _at(12), isViable: false),
        _buildSub(id: 'n2', startMs: _at(13), endMs: _at(14), isViable: false),
      ];

      final m = DayPreviewMetrics.from(
        subEvents: subs,
        dayTimeline: today,
      );

      expect(m.nonViableCount, 2);
    });
  });
}
