// daygrid_date_picker_navigation_test.dart
//
// Grid-mode date selection is dispatched through `UiDateManagerBloc`, mirroring
// the DayRibbonCarousel pattern: tapping the tappable day label in
// [GridDailyPageBody] opens the picker (via the injectable [pickDate] seam so
// the real `showDatePicker` platform dialog is never needed) and, on a
// confirmed selection that actually changes the shown day, the body dispatches
// a [DateChangeEvent] with [DateChangeTrigger.buttonPress].
//
// A spy [UiDateManagerBloc] records the events the body adds, so these tests
// assert exactly what the body emits. The chrome row / ribbon are the real
// production widgets; the grid region is a lightweight keyed stand-in via
// [GridDailyPageBody.gridBodyBuilder] so the schedule-loading side effects of
// the real list stay out of scope.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridPageBody.dart';
import 'package:tiler_app/components/dayGridTopChromeRow.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

const _gridRegionKey = Key('dayGridRegion');

/// Records every event the body dispatches and forwards it to the real bloc,
/// so [events] is a faithful log of what `onDateSelected` produced.
class _SpyUiDateManagerBloc extends UiDateManagerBloc {
  final List<UiDateManagerEvent> events = <UiDateManagerEvent>[];

  @override
  void add(UiDateManagerEvent event) {
    events.add(event);
    super.add(event);
  }
}

/// Bounded harness hosting [GridDailyPageBody]. The grid region is a
/// lightweight keyed stand-in; the chrome row (with the tappable day label) and
/// the ribbon are the real production widgets. A [pickDate] mock drives the
/// date picker.
Widget _buildGridHarness({
  required DailyViewLayoutCubit cubit,
  required _SpyUiDateManagerBloc dateBloc,
  required DateTime currentDate,
  required DayGridDatePicker pickDate,
}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: MultiBlocProvider(
      providers: [
        BlocProvider<DailyViewLayoutCubit>.value(value: cubit),
        BlocProvider<UiDateManagerBloc>.value(value: dateBloc),
        BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
      ],
      child: Scaffold(
        body: GridDailyPageBody(
          currentDate: currentDate,
          onSearch: () {},
          onSettings: () {},
          onGoToToday: () {},
          gridBodyBuilder: (double maxHeight) => SizedBox(
            key: _gridRegionKey,
            width: double.infinity,
            height: maxHeight,
          ),
          pickDate: pickDate,
        ),
      ),
    ),
  );
}

/// Taps the tappable day label to open (and drive) the picker seam.
Future<void> _tapDayLabel(WidgetTester tester) async {
  await tester.tap(find.byKey(DayGridTopChromeRow.dayLabelKey));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group(
      'GridDailyPageBody — date-picker dispatch through UiDateManagerBloc', () {
    testWidgets(
        'a confirmed pick of a different day dispatches DateChangeEvent(buttonPress)',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final spy = _SpyUiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(spy.close);

      final DateTime today = Utility.currentTime().dayDate;
      final DateTime picked = today.add(const Duration(days: 30));

      await tester.pumpWidget(_buildGridHarness(
        cubit: cubit,
        dateBloc: spy,
        currentDate: today,
        pickDate: (context,
            {required initialDate,
            required firstDate,
            required lastDate}) async {
          return picked;
        },
      ));
      await tester.pump();

      expect(spy.events, isEmpty,
          reason: 'nothing is dispatched until the user confirms a pick');

      await _tapDayLabel(tester);

      expect(spy.events, hasLength(1),
          reason: 'one confirmed pick must dispatch exactly one event');
      final event = spy.events.single;
      expect(event, isA<DateChangeEvent>());
      final change = event as DateChangeEvent;
      expect(
        change.selectedDate.universalDayIndex,
        picked.universalDayIndex,
        reason: "the picked day must be the event's selectedDate",
      );
      expect(
        change.previousSelectedDate?.universalDayIndex,
        Utility.currentTime().universalDayIndex,
        reason: "previousSelectedDate must be the bloc's current (shown) day",
      );
      expect(
        change.dateChangeTrigger,
        DateChangeTrigger.buttonPress,
        reason: 'grid date selection is a button press',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('cancelling the picker (null) dispatches no event',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final spy = _SpyUiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(spy.close);

      final DateTime today = Utility.currentTime().dayDate;

      await tester.pumpWidget(_buildGridHarness(
        cubit: cubit,
        dateBloc: spy,
        currentDate: today,
        pickDate: (context,
            {required initialDate,
            required firstDate,
            required lastDate}) async {
          return null; // user dismissed the dialog without choosing.
        },
      ));
      await tester.pump();

      await _tapDayLabel(tester);

      expect(spy.events, isEmpty,
          reason: 'a cancelled picker must not dispatch a DateChangeEvent');
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking the already-shown day dispatches no event',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final spy = _SpyUiDateManagerBloc();
      addTearDown(cubit.close);
      addTearDown(spy.close);

      final DateTime today = Utility.currentTime().dayDate;

      await tester.pumpWidget(_buildGridHarness(
        cubit: cubit,
        dateBloc: spy,
        currentDate: today,
        pickDate: (context,
            {required initialDate,
            required firstDate,
            required lastDate}) async {
          // Confirm the same day the grid is already showing (today).
          return today;
        },
      ));
      await tester.pump();

      await _tapDayLabel(tester);

      expect(spy.events, isEmpty,
          reason:
              're-selecting the current day is a no-op and must not dispatch');
      expect(tester.takeException(), isNull);
    });
  });
}