import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/travelDetail.dart';

void main() {
  group('TravelData.fromJson distance fields', () {
    test('fromJson reads distance and distanceUnit when present', () {
      final json = <String, dynamic>{
        'start': 1000,
        'end': 2000,
        'duration': 1000.0,
        'distance': 7543.2,
        'distanceUnit': 'meters',
      };

      final data = TravelData.fromJson(json);

      expect(data.distance, 7543.2);
      expect(data.distanceUnit, 'meters');
    });

    test('fromJson leaves distance null when absent', () {
      final json = <String, dynamic>{
        'start': 1000,
        'end': 2000,
        'duration': 1000.0,
      };

      final data = TravelData.fromJson(json);

      expect(data.distance, isNull);
    });

    test('fromJson leaves distanceUnit null when absent', () {
      final json = <String, dynamic>{
        'start': 1000,
        'end': 2000,
        'duration': 1000.0,
      };

      final data = TravelData.fromJson(json);

      expect(data.distanceUnit, isNull);
    });

    test('fromJson accepts integer distance values', () {
      final json = <String, dynamic>{
        'distance': 4200,
        'distanceUnit': 'meters',
      };

      final data = TravelData.fromJson(json);

      expect(data.distance, 4200.0);
    });

    test('toJson round-trips distance fields', () {
      const original = TravelData(
        start: 1000,
        end: 2000,
        duration: 1000.0,
        distance: 1234.5,
        distanceUnit: 'meters',
      );

      final encoded = original.toJson();
      final decoded = TravelData.fromJson(encoded);

      expect(decoded.distance, 1234.5);
      expect(decoded.distanceUnit, 'meters');
    });

    test('toJson omits null distance keys gracefully', () {
      const original = TravelData(
        start: 1000,
        end: 2000,
      );

      final encoded = original.toJson();

      expect(encoded['distance'], isNull);
      expect(encoded['distanceUnit'], isNull);
    });
  });
}
