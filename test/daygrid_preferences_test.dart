import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DayGridPreferences', () {
    test('layout round-trips', () async {
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.list);
      await DayGridPreferences.setLayout(DailyViewLayout.grid);
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.grid);
      await DayGridPreferences.setLayout(DailyViewLayout.list);
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.list);
    });

    test('pxPerHour round-trips', () async {
      expect(await DayGridPreferences.getPxPerHour(), isNull);
      await DayGridPreferences.setPxPerHour(150);
      expect(await DayGridPreferences.getPxPerHour(), 150);
    });

    test('absent layout defaults to list', () async {
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.list);
    });

    test('absent zoom returns null so auto-fit (C8) can run', () async {
      expect(await DayGridPreferences.getPxPerHour(), isNull);
    });

    test('corrupt layout value falls back to list without throwing',
        () async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'bogus'});
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.list);
    });

    test('corrupt zoom value falls back to null without throwing', () async {
      SharedPreferences.setMockInitialValues({'dayGridPxPerHour': -5});
      expect(await DayGridPreferences.getPxPerHour(), isNull);
    });

    test('out-of-range stored zoom falls back to null (auto-fit wins)',
        () async {
      SharedPreferences.setMockInitialValues({'dayGridPxPerHour': 999999});
      expect(await DayGridPreferences.getPxPerHour(), isNull);
    });

    test('storing a value overwrites a corrupt one', () async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'bogus'});
      await DayGridPreferences.setLayout(DailyViewLayout.grid);
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.grid);
    });
  });
}