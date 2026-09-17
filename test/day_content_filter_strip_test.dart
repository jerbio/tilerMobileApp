// P7 Step 17.4 — the active-filter strip, its empty state, and auto-clear.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/dayContentFilterStrip.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);
  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) return;
    super.add(event);
  }
}

final DateTime _day = DateTime(2027, 1, 15); // Fri, Jan 15

SubCalendarEvent _tile(String id,
    {int dayOffset = 0, bool rigid = false, bool viable = true}) {
  final start = _day.add(Duration(days: dayOffset, hours: 9));
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: start.add(const Duration(hours: 1)).millisecondsSinceEpoch,
  );
  tile.isViable = viable;
  tile.isRigid = rigid;
  return tile;
}

int _evaluation = 0;

/// Each call is a NEW evaluation: `ScheduleLoadedState` is Equatable on
/// the evaluation id (not on subEvents), so equal ids would be dropped by
/// the bloc — as in production, an added tile arrives with a fresh id.
ScheduleLoadedState _loaded(List<SubCalendarEvent> tiles,
    {bool coversDay = true}) {
  final Timeline lookup = coversDay
      ? Timeline.fromDateTime(_day.subtract(const Duration(days: 3)),
          _day.add(const Duration(days: 3)))
      : Timeline.fromDateTime(_day.subtract(const Duration(days: 30)),
          _day.subtract(const Duration(days: 20)));
  return ScheduleLoadedState(
    subEvents: tiles,
    timelines: const [],
    lookupTimeline: lookup,
    scheduleStatus: ScheduleStatus()..evaluationId = 'eval-${++_evaluation}',
    previousLookupTimeline: null,
    currentView: AuthorizedRouteTileListPage.Daily,
  );
}

Widget _app(ScheduleBloc bloc, DayContentFilterCubit filter, Widget child) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleBloc>.value(value: bloc),
        BlocProvider<DayContentFilterCubit>.value(value: filter),
      ],
      child: MaterialApp(
        theme: TileThemeData.lightTheme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: Column(children: [child])),
      ),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final int dayIndex = _day.universalDayIndex;

  group('DayContentFilterStrip', () {
    testWidgets('nothing while the filter is all', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      bloc.emit(_loaded([_tile('a'), _tile('b', rigid: true)]));
      await tester.pumpWidget(
          _app(bloc, filter, DayContentFilterStrip(currentDate: _day)));
      await _settle(tester);
      expect(find.byKey(DayContentFilterStrip.stripKey), findsNothing);
      expect(tester.getSize(find.byType(DayContentFilterStrip)).height, 0);
    });

    testWidgets('shows "Showing blocks only · 1 of 3" and Show all clears',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      bloc.emit(_loaded([
        _tile('a'),
        _tile('b', rigid: true),
        _tile('c'),
        _tile('other-day', dayOffset: 2, rigid: true),
        // Non-viable (needs attention / unscheduled): never on the
        // timeline, so it must not count toward "of N".
        _tile('unscheduled', viable: false),
        _tile('unscheduled-block', rigid: true, viable: false),
      ]));
      await tester.pumpWidget(
          _app(bloc, filter, DayContentFilterStrip(currentDate: _day)));
      filter.set(DayContentFilter.blocks);
      await _settle(tester);

      expect(find.byKey(DayContentFilterStrip.stripKey), findsOneWidget);
      expect(find.text('Showing blocks only · 1 of 3'), findsOneWidget);

      await tester.tap(find.byKey(DayContentFilterStrip.showAllKey));
      await _settle(tester);
      expect(filter.state, DayContentFilter.all);
      expect(find.byKey(DayContentFilterStrip.stripKey), findsNothing);
    });

    testWidgets('empty result reads "No tiles on Fri, Jan 15"', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      bloc.emit(_loaded([_tile('b', rigid: true)]));
      await tester.pumpWidget(
          _app(bloc, filter, DayContentFilterStrip(currentDate: _day)));
      filter.set(DayContentFilter.tiles);
      await _settle(tester);
      expect(find.text('No tiles on Fri, Jan 15'), findsOneWidget);
      expect(find.byKey(DayContentFilterStrip.showAllKey), findsOneWidget);
    });
  });

  group('DayContentFilterAutoClear.addedTiles (pure)', () {
    test('returns the shown day\'s new ids only', () {
      final prev = _loaded([_tile('a')]);
      final cur = _loaded([_tile('a'), _tile('new'), _tile('x', dayOffset: 1)]);
      expect(DayContentFilterAutoClear.addedTiles(prev, cur, dayIndex)
              .map((t) => t.id),
          ['new']);
    });

    test('a non-viable addition is not an addition (never rendered)', () {
      final prev = _loaded([_tile('a')]);
      final cur = _loaded([_tile('a'), _tile('pending', viable: false)]);
      expect(DayContentFilterAutoClear.addedTiles(prev, cur, dayIndex),
          isEmpty);
    });

    test('an initial / edge load of the day is not an addition', () {
      final prev = _loaded(const [], coversDay: false);
      final cur = _loaded([_tile('a'), _tile('b')]);
      expect(DayContentFilterAutoClear.addedTiles(prev, cur, dayIndex),
          isEmpty);
    });
  });

  group('DayContentFilterAutoClear (widget)', () {
    Future<(ScheduleBloc, DayContentFilterCubit)> pump(
        WidgetTester tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      bloc.emit(_loaded([_tile('a'), _tile('b', rigid: true)]));
      await tester.pumpWidget(_app(
        bloc,
        filter,
        DayContentFilterAutoClear(
          currentDate: _day,
          child: const SizedBox(height: 10),
        ),
      ));
      await _settle(tester);
      return (bloc, filter);
    }

    testWidgets('an added tile the filter would hide clears it + toasts',
        (tester) async {
      final (bloc, filter) = await pump(tester);
      filter.set(DayContentFilter.blocks);
      await _settle(tester);

      bloc.emit(
          _loaded([_tile('a'), _tile('b', rigid: true), _tile('added')]));
      await _settle(tester);

      expect(filter.state, DayContentFilter.all);
      expect(find.text('Showing all — filter cleared'), findsOneWidget);
    });

    testWidgets('an added tile that matches keeps the filter', (tester) async {
      final (bloc, filter) = await pump(tester);
      filter.set(DayContentFilter.blocks);
      await _settle(tester);

      bloc.emit(_loaded(
          [_tile('a'), _tile('b', rigid: true), _tile('c', rigid: true)]));
      await _settle(tester);

      expect(filter.state, DayContentFilter.blocks);
      expect(find.text('Showing all — filter cleared'), findsNothing);
    });

    testWidgets('an addition on ANOTHER day never clears it', (tester) async {
      final (bloc, filter) = await pump(tester);
      filter.set(DayContentFilter.blocks);
      await _settle(tester);

      bloc.emit(_loaded(
          [_tile('a'), _tile('b', rigid: true), _tile('far', dayOffset: 2)]));
      await _settle(tester);

      expect(filter.state, DayContentFilter.blocks);
    });
  });
}
