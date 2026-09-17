// DailyViewLayoutCubit: restore from prefs, toggle
// persistence, and round-trip across a simulated app restart.
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DailyViewLayoutCubit', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts on list when no layout is stored', () async {
      final cubit = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, DailyViewLayout.list);
      cubit.close();
    });

    test('restores grid from stored prefs', () async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
      final cubit = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, DailyViewLayout.grid);
      cubit.close();
    });

    test('corrupt stored value degrades to list (no throw)', () async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'nonsense'});
      final cubit = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, DailyViewLayout.list);
      cubit.close();
    });

    test('toggle list -> grid persists the choice', () async {
      final cubit = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state, DailyViewLayout.list);

      await cubit.toggle(dayIndex: 10000);
      expect(cubit.state, DailyViewLayout.grid);
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.grid);
      cubit.close();
    });

    test('toggle grid -> list round-trips across a simulated app restart',
        () async {
      // First run: user switches to grid.
      final firstRun = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await firstRun.toggle(dayIndex: 10000);
      expect(firstRun.state, DailyViewLayout.grid);
      firstRun.close(); // app "exits"

      // Second run: a fresh cubit must restore the stored grid layout.
      final secondRun = DailyViewLayoutCubit();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(secondRun.state, DailyViewLayout.grid);

      // And toggling back to list persists that too.
      await secondRun.toggle(dayIndex: 10001);
      expect(secondRun.state, DailyViewLayout.list);
      expect(await DayGridPreferences.getLayout(), DailyViewLayout.list);
      secondRun.close();
    });
  });
}