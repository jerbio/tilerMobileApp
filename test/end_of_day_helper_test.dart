import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/components/tilelist/dailyView/dailyTileList.dart';

void main() {
  group('endOfDayDateTimeFor', () {
    test('combines day with TimeOfDay into a DateTime', () {
      final day = DateTime(2024, 6, 10);
      const timeOfDay = TimeOfDay(hour: 22, minute: 0);
      final result = endOfDayDateTimeFor(day, timeOfDay);
      expect(result, equals(DateTime(2024, 6, 10, 22, 0)));
    });

    test('preserves minutes', () {
      final day = DateTime(2024, 3, 15);
      const timeOfDay = TimeOfDay(hour: 21, minute: 30);
      final result = endOfDayDateTimeFor(day, timeOfDay);
      expect(result, equals(DateTime(2024, 3, 15, 21, 30)));
    });

    test('returns null when TimeOfDay is null', () {
      final day = DateTime(2024, 6, 10);
      final result = endOfDayDateTimeFor(day, null);
      expect(result, isNull);
    });

    test('ignores time component of the day param — uses only date', () {
      final dayWithTime = DateTime(2024, 6, 10, 14, 35, 22);
      const timeOfDay = TimeOfDay(hour: 22, minute: 0);
      final result = endOfDayDateTimeFor(dayWithTime, timeOfDay);
      expect(result, equals(DateTime(2024, 6, 10, 22, 0)));
    });
  });
}
