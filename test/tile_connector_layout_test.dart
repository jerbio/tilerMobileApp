import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/dailyView/tileConnectorLayout.dart';
import 'package:tiler_app/components/tilelist/returnConnector.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/travelDetail.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SubCalendarEvent _tile({
  required String id,
  required DateTime start,
  required DateTime end,
  double? travelTimeAfter,
  TravelDetail? travelDetail,
}) {
  final t = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  t.travelTimeAfter = travelTimeAfter;
  t.travelDetail = travelDetail;
  return t;
}

Location _homeLocation() {
  final loc =
      Location.fromLatitudeAndLongitude(latitude: 37.7, longitude: -122.4);
  loc.description = Location.homeLocationNickName;
  loc.address = '1 Home Lane';
  return loc;
}

/// Calls [buildTileListWithConnectors] with minimal no-op callbacks.
/// [wrapConnector] is the identity by default so connector widgets appear
/// unmodified in the result list, making type-checks straightforward.
TileConnectorLayoutResult _build(
  List<SubCalendarEvent> tiles, {
  DateTime? endOfDayTime,
  bool showTravelConnectors = true,
}) {
  return buildTileListWithConnectors(
    orderedTiles: tiles,
    showTravelConnectors: showTravelConnectors,
    showConflictAlerts: false,
    excludeDeclinedFromConflicts: false,
    now: DateTime(2026, 6, 28, 12),
    endOfDayTime: endOfDayTime,
    buildTile: (tile,
            {required hour, required showHourMarker, required isCurrentHour}) =>
        SizedBox(key: ValueKey(tile.id)),
    buildConflictGroup: (group,
            {required hour, required showHourMarker, required isCurrentHour}) =>
        const SizedBox(),
    wrapConnector: (connector) => connector,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Group 1: Emission conditions
  // -------------------------------------------------------------------------

  group('buildTileListWithConnectors — post-loop ReturnConnector emission', () {
    test('emits ReturnConnector when travelDetail.after is non-null', () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelDetail: TravelDetail(
            after: TravelData(
              travelMedium: 'driving',
              endLocation: _homeLocation(),
              duration: const Duration(minutes: 20).inMilliseconds.toDouble(),
            ),
          ),
        ),
      ];

      final result = _build(tiles);

      expect(result.widgets.last, isA<ReturnConnector>());
    });

    test('emits ReturnConnector when travelTimeAfter is non-zero', () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelTimeAfter:
              const Duration(minutes: 15).inMilliseconds.toDouble(),
        ),
      ];

      final result = _build(tiles);

      expect(result.widgets.last, isA<ReturnConnector>());
    });

    test(
        'emits ReturnConnector when travelTimeAfter is zero (data present, duration zero)',
        () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelTimeAfter: 0,
          travelDetail: TravelDetail(
            after: TravelData(
              endLocation: _homeLocation(),
              duration: 0,
            ),
          ),
        ),
      ];

      final result = _build(tiles);

      expect(result.widgets.last, isA<ReturnConnector>());
    });

    test('emits ReturnConnector even when no after-travel data is present', () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          // no travelTimeAfter, no travelDetail
        ),
      ];

      final result = _build(tiles);

      expect(result.widgets.last, isA<ReturnConnector>());
    });

    test('does NOT emit ReturnConnector when tile list is empty', () {
      final result = _build([]);

      expect(result.widgets.whereType<ReturnConnector>(), isEmpty);
    });

    test('does NOT emit ReturnConnector when showTravelConnectors is false',
        () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelTimeAfter:
              const Duration(minutes: 20).inMilliseconds.toDouble(),
          travelDetail: TravelDetail(
            after: TravelData(endLocation: _homeLocation()),
          ),
        ),
      ];

      final result = _build(tiles, showTravelConnectors: false);

      expect(result.widgets.whereType<ReturnConnector>(), isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Group 2: Ordering
  // -------------------------------------------------------------------------

  group('buildTileListWithConnectors — ReturnConnector position', () {
    test('ReturnConnector is appended after the last tile widget', () {
      final tiles = [
        _tile(
          id: 'first',
          start: DateTime(2026, 6, 28, 9),
          end: DateTime(2026, 6, 28, 10),
        ),
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 11),
          end: DateTime(2026, 6, 28, 12),
          travelTimeAfter:
              const Duration(minutes: 20).inMilliseconds.toDouble(),
          travelDetail: TravelDetail(
            after: TravelData(endLocation: _homeLocation()),
          ),
        ),
      ];

      final result = _build(tiles);

      // Last widget must be the ReturnConnector
      expect(result.widgets.last, isA<ReturnConnector>());

      // The second-to-last widget must be the last tile (SizedBox keyed 'last')
      final secondToLast = result.widgets[result.widgets.length - 2];
      expect(secondToLast, isA<SizedBox>());
      expect((secondToLast as SizedBox).key, isA<ValueKey>());
      expect(((secondToLast).key as ValueKey).value, equals('last'));
    });

    test(
        'ReturnConnector is the only extra widget added (widget count = tiles + 1)',
        () {
      // Neither tile has travel data — the only extra widget is the ReturnConnector
      // emitted for the last tile.
      final tiles = [
        _tile(
          id: 'a',
          start: DateTime(2026, 6, 28, 9),
          end: DateTime(2026, 6, 28, 10),
        ),
        _tile(
          id: 'b',
          start: DateTime(2026, 6, 28, 11),
          end: DateTime(2026, 6, 28, 12),
        ),
      ];

      final result = _build(tiles);

      // 2 tile widgets + 1 ReturnConnector = 3
      expect(result.widgets.length, equals(3));
      expect(result.widgets.whereType<ReturnConnector>().length, equals(1));
    });
  });

  // -------------------------------------------------------------------------
  // Group 3: endOfDayTime threading
  // -------------------------------------------------------------------------

  group(
      'buildTileListWithConnectors — endOfDayTime is passed to ReturnConnector',
      () {
    test('ReturnConnector receives the provided endOfDayTime', () {
      final endOfDay = DateTime(2026, 6, 28, 22, 0);
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelTimeAfter:
              const Duration(minutes: 20).inMilliseconds.toDouble(),
          travelDetail: TravelDetail(
            after: TravelData(endLocation: _homeLocation()),
          ),
        ),
      ];

      final result = _build(tiles, endOfDayTime: endOfDay);

      final connector = result.widgets.last as ReturnConnector;
      expect(connector.endOfDayTime, equals(endOfDay));
    });

    test('ReturnConnector receives null endOfDayTime when none is provided',
        () {
      final tiles = [
        _tile(
          id: 'last',
          start: DateTime(2026, 6, 28, 18),
          end: DateTime(2026, 6, 28, 19),
          travelTimeAfter:
              const Duration(minutes: 20).inMilliseconds.toDouble(),
        ),
      ];

      final result = _build(tiles);

      final connector = result.widgets.last as ReturnConnector;
      expect(connector.endOfDayTime, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Group 4: lastTile reference on ReturnConnector
  // -------------------------------------------------------------------------

  group(
      'buildTileListWithConnectors — ReturnConnector holds the correct lastTile',
      () {
    test('ReturnConnector.lastTile is the last tile in the ordered list', () {
      final first = _tile(
        id: 'first',
        start: DateTime(2026, 6, 28, 9),
        end: DateTime(2026, 6, 28, 10),
      );
      final last = _tile(
        id: 'last',
        start: DateTime(2026, 6, 28, 11),
        end: DateTime(2026, 6, 28, 12),
        travelTimeAfter: const Duration(minutes: 15).inMilliseconds.toDouble(),
      );

      final result = _build([first, last]);

      final connector = result.widgets.last as ReturnConnector;
      expect(connector.lastTile.id, equals('last'));
    });
  });
}
