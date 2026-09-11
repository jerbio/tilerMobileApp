// DayGrid no-snap regression harness (P6 Step 16.8, C27 — §16.2 contract).
//
// "Snap" = a single-frame, non-animated change of >= 4 px in the on-screen
// position of a visible tile, or of the grid's scroll offset, that the user
// did not cause with a gesture. This suite hosts the PRODUCTION grid-mode
// composition (GridDailyPageBody -> DayGridPage -> scroll header + pinned
// card + DayGridWidget), scrolls to mid-day, applies one perturbation per
// case, and asserts at t = 0 (the very next frame) that:
//   * `position.pixels` is unchanged, and
//   * every tile that was visible before is at the same Rect (or, where a
//     change is EXPECTED to move it, that it has not yet jumped — it
//     animates over the following frames).
// Perturbations: same-tile refresh; add non-overlapping tile; add an
// overlapping tile (widths animate); remove a tile; conflicts -> 0 (header
// shrinks, grid does not); RSVP appears; all-day tile appears (pinned card
// AnimatedSize); pxPerHour change while zooming (immediate by design — the
// gate is what is asserted); the clock ticks a minute.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/dayGridPageBody.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
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

SubCalendarEvent _tile(String id, DateTime start, DateTime end,
    {RsvpStatus? rsvp, TileSource? source}) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
    rsvp: rsvp,
  );
  tile.isViable = true;
  if (source != null) tile.thirdpartyType = source;
  return tile;
}

/// Baseline: two conflicting tiles at 9–11 / 10–12 (so the header has a
/// conflict row), one lone tile at 14–15.
List<TilerEvent> _baseline(DateTime day) => [
      _tile('c1', day.add(const Duration(hours: 9)),
          day.add(const Duration(hours: 11))),
      _tile('c2', day.add(const Duration(hours: 10)),
          day.add(const Duration(hours: 12))),
      _tile('lone', day.add(const Duration(hours: 14)),
          day.add(const Duration(hours: 15))),
    ];

const double _snapTolerancePx = 4.0;

/// Rects of every tile card keyed by tile id.
Map<String, Rect> _tileRects(WidgetTester tester) {
  final rects = <String, Rect>{};
  for (final element in find.byType(TileGridWidget).evaluate()) {
    final widget = element.widget as TileGridWidget;
    final id = widget.tilerEvent.id;
    if (id == null) continue;
    rects[id] = tester.getRect(find.byWidget(widget));
  }
  return rects;
}

void _expectNoJump(Map<String, Rect> before, Map<String, Rect> after,
    {Set<String> allowedToMove = const {}}) {
  for (final entry in before.entries) {
    final id = entry.key;
    if (!after.containsKey(id)) continue; // removed: exit ghost path
    final a = entry.value;
    final b = after[id]!;
    final maxDelta = [
      (a.left - b.left).abs(),
      (a.top - b.top).abs(),
      (a.width - b.width).abs(),
      (a.height - b.height).abs(),
    ].reduce((x, y) => x > y ? x : y);
    if (allowedToMove.contains(id)) {
      // Expected to change eventually — but never in one frame.
      expect(maxDelta, lessThan(_snapTolerancePx),
          reason: 'tile "$id" must animate, not jump, at t=0');
    } else {
      expect(maxDelta, lessThan(0.5), reason: 'tile "$id" must not move');
    }
  }
}

class _Harness {
  final WidgetTester tester;
  final DateTime day;
  final int dayIndex;
  final _RecordingScheduleBloc bloc = _RecordingScheduleBloc();
  final UiDateManagerBloc dateBloc = UiDateManagerBloc();
  final DailyViewLayoutCubit cubit = DailyViewLayoutCubit();
  late List<TilerEvent> tiles;
  late void Function() rebuild;

  _Harness(this.tester)
      : day = Utility.currentTime().dayDate,
        dayIndex = Utility.currentTime().universalDayIndex {
    tiles = _baseline(day);
  }

  Future<void> pump() async {
    SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
    // Grid from the FIRST frame (toggle emits synchronously) so the list
    // branch — irrelevant here — never renders.
    cubit.toggle();
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(MaterialApp(
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
          BlocProvider.value(value: cubit),
          BlocProvider.value(value: dateBloc),
          BlocProvider<ScheduleBloc>.value(value: bloc),
          // The list branch renders for the first frame (before the cubit
          // restores grid) and reads this.
          BlocProvider(
              create: (_) => ScheduleSummaryBloc(getContextCallBack: () => null)),
        ],
        child: Scaffold(
          body: GridDailyPageBody(
            currentDate: day,
            onSearch: () {},
            onSettings: () {},
            onGoToToday: () {},
            gridBodyBuilder: (double maxHeight) => StatefulBuilder(
              builder: (context, setState) {
                rebuild = () => setState(() {});
                return SizedBox(
                  height: maxHeight,
                  child: DayGridPage(
                    key: ValueKey('day_$dayIndex'),
                    dayIndex: dayIndex,
                    tiles: tiles,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // settle enter anims
  }

  ScrollController get scroll => tester
      .widget<CustomScrollView>(find.byType(CustomScrollView))
      .controller!;

  DayGridController get gridController => tester
      .widget<DayGridScope>(find.byType(DayGridScope))
      .controller;

  /// Scroll to mid-day and settle.
  Future<void> scrollToMidDay() async {
    scroll.jumpTo(600);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(scroll.position.pixels, 600.0);
  }

  Future<void> teardown() async {
    await tester.runAsync(() async {
      await bloc.close();
      await dateBloc.close();
      await cubit.close();
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> assertNoSnap(
    WidgetTester tester, {
    required void Function(_Harness h) perturb,
    Set<String> allowedToMove = const {},
    String? reason,
  }) async {
    final h = _Harness(tester);
    await h.pump();
    expect(find.byType(TileGridWidget), findsNWidgets(3));
    await h.scrollToMidDay();

    final before = _tileRects(tester);
    expect(before.keys, containsAll(['c1', 'c2', 'lone']));

    perturb(h);
    h.rebuild();
    await tester.pump(); // t = 0: the first frame after the change

    expect(h.scroll.position.pixels, 600.0,
        reason: '${reason ?? 'the perturbation'} must not move the scroll');
    _expectNoJump(before, _tileRects(tester), allowedToMove: allowedToMove);

    // Let any animation finish; still no exceptions.
    await tester.pump(const Duration(milliseconds: 500));
    expect(h.scroll.position.pixels, 600.0);
    expect(tester.takeException(), isNull);
    await h.teardown();
  }

  group('DayGrid no-snap contract (§16.2)', () {
    testWidgets('(1) same-tile refresh', (tester) async {
      await assertNoSnap(tester,
          perturb: (h) => h.tiles = _baseline(h.day), reason: 'a refresh');
    });

    testWidgets('(2) add a non-overlapping tile', (tester) async {
      await assertNoSnap(tester, perturb: (h) {
        h.tiles = [
          ...h.tiles,
          _tile('new', h.day.add(const Duration(hours: 16)),
              h.day.add(const Duration(hours: 17))),
        ];
      });
    });

    testWidgets('(3) add an overlapping tile → neighbour width animates',
        (tester) async {
      await assertNoSnap(tester, perturb: (h) {
        h.tiles = [
          ...h.tiles,
          _tile('over', h.day.add(const Duration(hours: 14, minutes: 15)),
              h.day.add(const Duration(hours: 15, minutes: 15))),
        ];
      }, allowedToMove: {'lone'});
    });

    testWidgets('(4) remove a tile', (tester) async {
      await assertNoSnap(tester,
          perturb: (h) =>
              h.tiles = h.tiles.where((t) => t.id != 'c2').toList());
    });

    testWidgets('(5) conflicts → 0: the header shrinks, the grid does not',
        (tester) async {
      final h = _Harness(tester);
      await h.pump();
      await h.scrollToMidDay();
      final minBefore = h.scroll.position.minScrollExtent;
      final before = _tileRects(tester);

      // Resolve the conflict by moving c2 away.
      h.tiles = [
        _tile('c1', h.day.add(const Duration(hours: 9)),
            h.day.add(const Duration(hours: 11))),
        _tile('c2', h.day.add(const Duration(hours: 18)),
            h.day.add(const Duration(hours: 19))),
        _tile('lone', h.day.add(const Duration(hours: 14)),
            h.day.add(const Duration(hours: 15))),
      ];
      h.rebuild();
      await tester.pump();
      expect(h.scroll.position.pixels, 600.0);
      _expectNoJump(before, _tileRects(tester),
          allowedToMove: {'c1', 'c2'});
      await tester.pump(const Duration(milliseconds: 500));
      // The header (negative extent) shrank; the grid stayed put.
      expect(h.scroll.position.minScrollExtent, greaterThan(minBefore));
      expect(h.scroll.position.pixels, 600.0);
      expect(tester.takeException(), isNull);
      await h.teardown();
    });

    testWidgets('(6) a pending RSVP appears (header row grows)',
        (tester) async {
      await assertNoSnap(tester, perturb: (h) {
        h.tiles = [
          ...h.tiles,
          _tile('rsvp', h.day.add(const Duration(hours: 20)),
              h.day.add(const Duration(hours: 21)),
              rsvp: RsvpStatus.needsAction, source: TileSource.google),
        ];
      });
    });

    testWidgets('(7) an all-day tile appears: the pinned card animates in',
        (tester) async {
      final h = _Harness(tester);
      await h.pump();
      await h.scrollToMidDay();
      final before = _tileRects(tester);

      h.tiles = [
        ...h.tiles,
        _tile('allday', h.day, h.day.add(const Duration(hours: 24))),
      ];
      h.rebuild();
      await tester.pump();
      // AnimatedSize: the pinned card starts at zero height, so at t=0 the
      // grid viewport has not shrunk and the tiles have not moved.
      expect(h.scroll.position.pixels, 600.0);
      _expectNoJump(before, _tileRects(tester));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(DayGridPinnedHeader), findsOneWidget);
      expect(find.byKey(const Key('daygrid_pinned_card')), findsOneWidget);
      expect(h.scroll.position.pixels, 600.0);
      expect(tester.takeException(), isNull);
      await h.teardown();
    });

    testWidgets('(8) pxPerHour change while zooming is immediate (gate)',
        (tester) async {
      final h = _Harness(tester);
      await h.pump();
      await h.scrollToMidDay();
      final before = _tileRects(tester);

      h.gridController.mode = DayGridMode.zooming;
      h.gridController.setPxPerHour(120);
      await tester.pump();
      // By design: no position animation while zooming (the pinch owns the
      // motion frame by frame), so the tile re-lays immediately.
      final after = _tileRects(tester);
      expect((after['lone']!.top - before['lone']!.top).abs(),
          greaterThan(_snapTolerancePx));
      h.gridController.mode = DayGridMode.idle;
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      await h.teardown();
    });

    testWidgets('(9) the clock ticks a minute (now-line timer rebuild)',
        (tester) async {
      final h = _Harness(tester);
      await h.pump();
      await h.scrollToMidDay();
      final before = _tileRects(tester);

      // The grid's minute Timer fires -> setState -> rebuild in place.
      await tester.pump(const Duration(seconds: 61));
      expect(h.scroll.position.pixels, 600.0);
      _expectNoJump(before, _tileRects(tester));
      expect(tester.takeException(), isNull);
      await h.teardown();
    });
  });
}
