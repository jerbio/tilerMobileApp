import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/services/api/calendarEventApi.dart';

void main() {
  group('buildSubEventsQueryParameters', () {
    test('includes only EventID when no optional params are provided', () {
      final params = buildSubEventsQueryParameters('event-1');

      expect(params, {'EventID': 'event-1'});
    });

    test('forwards batchSize and index as stringified values', () {
      final params =
          buildSubEventsQueryParameters('event-1', batchSize: 20, index: 3);

      expect(params['EventID'], 'event-1');
      expect(params['BatchSize'], '20');
      expect(params['Index'], '3');
    });

    test('forwards ordering engine and cursor ids when provided', () {
      final params = buildSubEventsQueryParameters(
        'event-1',
        batchSize: 20,
        orderingEngine: 'Id',
        afterSubEventId: 'sub_7',
        beforeSubEventId: 'sub_2',
      );

      expect(params['OrderingEngine'], 'Id');
      expect(params['AfterSubEventId'], 'sub_7');
      expect(params['BeforeSubEventId'], 'sub_2');
    });

    test('omits null optional keys entirely', () {
      final params = buildSubEventsQueryParameters(
        'event-1',
        orderingEngine: 'ProximityToNow',
      );

      expect(params['OrderingEngine'], 'ProximityToNow');
      expect(params.containsKey('AfterSubEventId'), isFalse);
      expect(params.containsKey('BeforeSubEventId'), isFalse);
      expect(params.containsKey('Index'), isFalse);
      expect(params.containsKey('BatchSize'), isFalse);
    });
  });
}
