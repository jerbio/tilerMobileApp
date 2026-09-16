// DayQuickActionsRow — Show route · Re-optimize (+ loading bar) in the
// shared Daily chrome, so list and grid get them from ONE place.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/dayQuickActionsRow.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/todaysRoute/todaysRoutePage.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

/// Records events; never runs the network-bound handlers.
class _RecordingScheduleBloc extends ScheduleBloc {
  final List<ScheduleEvent> events = <ScheduleEvent>[];
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    events.add(event);
    if (event is GetScheduleEvent || event is ReviseScheduleEvent) return;
    super.add(event);
  }
}

SubCalendarEvent _tile(String id, DateTime start, DateTime end,
    {bool viable = true}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = viable;
  return tile;
}

ScheduleLoadedState _loaded(List<SubCalendarEvent> subEvents, DateTime day) {
  final Timeline lookup = Timeline.fromDateTime(
      day.subtract(const Duration(days: 3)), day.add(const Duration(days: 3)));
  return ScheduleLoadedState(
    subEvents: subEvents,
    timelines: const [],
    lookupTimeline: lookup,
    scheduleStatus: ScheduleStatus(),
    previousLookupTimeline: null,
    currentView: AuthorizedRouteTileListPage.Daily,
  );
}

Widget _app(ScheduleBloc bloc, DateTime day,
        {DayContentFilterCubit? filter, bool preview = false}) =>
    MultiBlocProvider(
      providers: [
        BlocProvider<ScheduleBloc>.value(value: bloc),
        BlocProvider<DayContentFilterCubit>.value(
            value: filter ?? DayContentFilterCubit()),
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
        home: Scaffold(
          body: Column(children: [
            DayQuickActionsRow(currentDate: day, preview: preview),
          ]),
        ),
      ),
    );

/// The selected segment: the one whose text is rendered in `onPrimary`
/// (its background is the filled `primary` pill).
DayContentFilter _selectedSegment(WidgetTester tester) {
  final onPrimary = TileThemeData.lightTheme.colorScheme.onPrimary;
  for (final (filter, key) in [
    (DayContentFilter.all, DayQuickActionsRow.filterAllKey),
    (DayContentFilter.blocks, DayQuickActionsRow.filterBlocksKey),
    (DayContentFilter.tiles, DayQuickActionsRow.filterTilesKey),
  ]) {
    final Text text = tester.widget<Text>(find.descendant(
        of: find.byKey(key), matching: find.byType(Text)));
    if (text.style?.color == onPrimary) return filter;
  }
  throw StateError('no selected segment');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final DateTime day = DateTime(2027, 1, 15);

  test('tilesForDay keeps only the shown day\'s viable tiles', () {
    final tiles = [
      _tile('a', day.add(const Duration(hours: 9)),
          day.add(const Duration(hours: 10))),
      _tile('b', day.add(const Duration(hours: 11)),
          day.add(const Duration(hours: 12)),
          viable: false),
      _tile('c', day.add(const Duration(days: 1, hours: 9)),
          day.add(const Duration(days: 1, hours: 10))),
    ];
    final picked = DayQuickActionsRow.tilesForDay(
        _loaded(tiles, day), day.universalDayIndex);
    expect(picked.map((t) => t.id), ['a']);
    expect(DayQuickActionsRow.tilesForDay(
            ScheduleInitialState(currentView: AuthorizedRouteTileListPage.Daily), 1),
        isEmpty);
  });

  testWidgets('renders both chips at a constant height', (tester) async {
    final bloc = _RecordingScheduleBloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc, day));
    await tester.pump();
    expect(find.byKey(DayQuickActionsRow.showRouteKey), findsOneWidget);
    expect(find.byKey(DayQuickActionsRow.reOptimizeKey), findsOneWidget);
    expect(tester.getSize(find.byType(DayQuickActionsRow)).height,
        DayQuickActionsRow.height);
    // Left-aligned: the first chip starts at the row's left padding, not
    // centred.
    final double rowLeft = tester.getTopLeft(find.byType(DayQuickActionsRow)).dx;
    final double chipLeft =
        tester.getTopLeft(find.byKey(DayQuickActionsRow.showRouteKey)).dx;
    expect(chipLeft - rowLeft, lessThanOrEqualTo(16.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Re-optimize dispatches ReviseScheduleEvent', (tester) async {
    final bloc = _RecordingScheduleBloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc, day));
    await tester.pump();
    await tester.tap(find.byKey(DayQuickActionsRow.reOptimizeKey));
    await tester.pump();
    expect(bloc.events.whereType<ReviseScheduleEvent>(), hasLength(1));
  });

  testWidgets('Show route opens TodaysRoutePage with the shown day\'s tiles',
      (tester) async {
    final bloc = _RecordingScheduleBloc();
    addTearDown(bloc.close);
    final tiles = [
      _tile('a', day.add(const Duration(hours: 9)),
          day.add(const Duration(hours: 10))),
      _tile('other', day.add(const Duration(days: 2, hours: 9)),
          day.add(const Duration(days: 2, hours: 10))),
    ];
    bloc.emit(_loaded(tiles, day));
    await tester.pumpWidget(_app(bloc, day));
    await tester.pump();

    await tester.tap(find.byKey(DayQuickActionsRow.showRouteKey));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(TodaysRoutePage), findsOneWidget);
    final page = tester.widget<TodaysRoutePage>(find.byType(TodaysRoutePage));
    expect(page.tiles.map((t) => t.id), ['a']);
  });

  group('content filter segmented control (P7 Step 17.2)', () {
    testWidgets('renders All · Blocks · Tiles, right of the chips, All selected',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();

      expect(find.byKey(DayQuickActionsRow.filterAllKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterBlocksKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterTilesKey), findsOneWidget);
      expect(_selectedSegment(tester), DayContentFilter.all);
      // The Blocks segment carries the lock glyph — the control is the
      // legend for the lock on block cards.
      expect(
          find.descendant(
              of: find.byKey(DayQuickActionsRow.filterBlocksKey),
              matching: find.byIcon(Icons.lock_outline)),
          findsOneWidget);
      // Right of the action chips; the row keeps its fixed height.
      expect(
          tester.getTopLeft(find.byKey(DayQuickActionsRow.filterKey)).dx,
          greaterThan(tester
              .getBottomRight(find.byKey(DayQuickActionsRow.reOptimizeKey))
              .dx));
      expect(tester.getSize(find.byType(DayQuickActionsRow)).height,
          DayQuickActionsRow.height);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tapping Blocks / Tiles / All drives the cubit',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();

      await tester.tap(find.byKey(DayQuickActionsRow.filterBlocksKey));
      await tester.pump();
      expect(filter.state, DayContentFilter.blocks);
      await tester.tap(find.byKey(DayQuickActionsRow.filterTilesKey));
      await tester.pump();
      expect(filter.state, DayContentFilter.tiles);
      await tester.tap(find.byKey(DayQuickActionsRow.filterAllKey));
      await tester.pump();
      expect(filter.state, DayContentFilter.all);
    });

    testWidgets('the control follows the cubit (external changes)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();
      filter.set(DayContentFilter.tiles);
      await tester.pump();
      await tester.pump();
      expect(_selectedSegment(tester), DayContentFilter.tiles);
    });

    testWidgets('hidden in preview (read-only surfaces)', (tester) async {
      final bloc = _RecordingScheduleBloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc, day, preview: true));
      await tester.pump();
      expect(find.byKey(DayQuickActionsRow.filterKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.showRouteKey), findsOneWidget);
    });
  });
}
