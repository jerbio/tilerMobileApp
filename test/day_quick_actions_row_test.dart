// DayQuickActionsRow — Show route · Re-optimize (+ loading bar) in the
// shared Daily chrome, so list and grid get them from ONE place.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/dayContentFilter/day_content_filter_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/dayQuickActionsRow.dart';
import 'package:tiler_app/components/tilelist/dailyView/components/quickActionChipsRow.dart';
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
    final Text text = tester.widget<Text>(
        find.descendant(of: find.byKey(key), matching: find.byType(Text)));
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
    expect(
        DayQuickActionsRow.tilesForDay(
            ScheduleInitialState(
                currentView: AuthorizedRouteTileListPage.Daily),
            1),
        isEmpty);
  });

  testWidgets('renders both chips at the row\'s resting height',
      (tester) async {
    final bloc = _RecordingScheduleBloc();
    addTearDown(bloc.close);
    await tester.pumpWidget(_app(bloc, day));
    await tester.pump();
    expect(find.byKey(DayQuickActionsRow.showRouteKey), findsOneWidget);
    expect(find.byKey(DayQuickActionsRow.reOptimizeKey), findsOneWidget);
    // 48 + the 3px bar is the MINIMUM; the row grows with its content
    // rather than clamping it (see the centring test below).
    // (The test font is taller than the app's, so the row may already be
    // above its resting height here.)
    expect(tester.getSize(find.byType(DayQuickActionsRow)).height,
        greaterThanOrEqualTo(DayQuickActionsRow.height));
    // Left-aligned: the first chip starts at the row's left padding, not
    // centred.
    final double rowLeft =
        tester.getTopLeft(find.byType(DayQuickActionsRow)).dx;
    final double chipLeft =
        tester.getTopLeft(find.byKey(DayQuickActionsRow.showRouteKey)).dx;
    expect(chipLeft - rowLeft, lessThanOrEqualTo(16.0));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the chips and the filter sit on the row\'s vertical centre, at any '
      'text scale (2026-09-19)', (tester) async {
    // Seen on device: the chips rode the bottom of the row. The row was a
    // fixed 48 with 32 for content, so anything taller — a larger font
    // scale, a taller chip — was clamped and its text spilled downward.
    for (final double scale in <double>[1.0, 1.5]) {
      final bloc = _RecordingScheduleBloc();
      addTearDown(bloc.close);
      // Through the platform, so MaterialApp's own MediaQuery carries it.
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(_app(bloc, day));
      await tester.pump();
      final Rect chips = tester.getRect(find.byType(QuickActionChipsRow));
      final Rect chip =
          tester.getRect(find.byKey(DayQuickActionsRow.showRouteKey));
      final Rect text = tester.getRect(find.text('Show Route'));
      final Rect filter =
          tester.getRect(find.byKey(DayQuickActionsRow.filterKey));
      expect(chip.center.dy, closeTo(chips.center.dy, 1.0),
          reason: 'scale $scale: chip centred in the chips row');
      expect(filter.center.dy, closeTo(chips.center.dy, 1.0),
          reason: 'scale $scale: filter centred in the chips row');
      // The chip is as tall as its label needs (13sp line + 8/8 padding);
      // a clamped chip paints its glyphs below the box, which is what read
      // as "bottom aligned" on device.
      expect(chip.height, greaterThanOrEqualTo(16 + 13 * scale),
          reason: 'scale $scale: the chip is not clamped');
      expect(text.height, greaterThanOrEqualTo(13 * scale),
          reason: 'scale $scale: the label keeps its line height');
      expect(chips.height, greaterThanOrEqualTo(chip.height + 16),
          reason: 'scale $scale: the row grows with its chips');
      expect(chips.height, greaterThanOrEqualTo(QuickActionChipsRow.height));
      expect(tester.takeException(), isNull);
    }
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

  group('content filter (P7) — collapsible, expand to select', () {
    testWidgets(
        'collapsed by default; tapping expands to All · Blocks · Tiles (All selected)',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();

      // Collapsed by default: only the toggle chip, not the three segments.
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterAllKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterBlocksKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterTilesKey), findsNothing);
      // The collapsed chip names the current selection (All) with the expand
      // affordance.
      expect(find.text('All'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      // Right of the action chips; the row keeps its fixed height.
      expect(
          tester.getTopLeft(find.byKey(DayQuickActionsRow.filterKey)).dx,
          greaterThan(tester
              .getBottomRight(find.byKey(DayQuickActionsRow.reOptimizeKey))
              .dx));
      expect(tester.getSize(find.byType(DayQuickActionsRow)).height,
          greaterThanOrEqualTo(DayQuickActionsRow.height));
      expect(tester.takeException(), isNull);

      // Tap the chip: the three segments appear, All selected, and the Blocks
      // segment carries the lock glyph (the legend for block cards).
      await tester.tap(find.byKey(DayQuickActionsRow.filterToggleKey));
      await tester.pump();
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterAllKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterBlocksKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterTilesKey), findsOneWidget);
      expect(_selectedSegment(tester), DayContentFilter.all);
      expect(
          find.descendant(
              of: find.byKey(DayQuickActionsRow.filterBlocksKey),
              matching: find.byIcon(Icons.lock_outline)),
          findsOneWidget);
    });

    testWidgets('tapping a segment selects it and collapses again',
        (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();

      await tester.tap(find.byKey(DayQuickActionsRow.filterToggleKey));
      await tester.pump();
      // Let the expand animation settle so the segments sit at their final
      // (right-aligned) positions before we tap one.
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(DayQuickActionsRow.filterBlocksKey));
      await tester.pump();
      expect(filter.state, DayContentFilter.blocks);
      // Collapsed again, now naming the active (Blocks) filter.
      expect(find.byKey(DayQuickActionsRow.filterBlocksKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsOneWidget);
      expect(find.text('Blocks'), findsOneWidget);
    });

    testWidgets('auto-collapses after 5s if left expanded', (tester) async {
      final bloc = _RecordingScheduleBloc();
      final filter = DayContentFilterCubit();
      addTearDown(bloc.close);
      addTearDown(filter.close);
      await tester.pumpWidget(_app(bloc, day, filter: filter));
      await tester.pump();

      await tester.tap(find.byKey(DayQuickActionsRow.filterToggleKey));
      await tester.pump();
      expect(find.byKey(DayQuickActionsRow.filterAllKey), findsOneWidget);
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsNothing);

      await tester.pump(const Duration(seconds: 5));
      expect(find.byKey(DayQuickActionsRow.filterAllKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsOneWidget);
    });

    testWidgets('the collapsed chip follows the cubit (external changes)',
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
      expect(find.text('Tiles'), findsOneWidget);
    });

    testWidgets('hidden in preview (read-only surfaces)', (tester) async {
      final bloc = _RecordingScheduleBloc();
      addTearDown(bloc.close);
      await tester.pumpWidget(_app(bloc, day, preview: true));
      await tester.pump();
      expect(find.byKey(DayQuickActionsRow.filterKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.filterToggleKey), findsNothing);
      expect(find.byKey(DayQuickActionsRow.showRouteKey), findsOneWidget);
    });
  });
}
