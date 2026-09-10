// Pinch-to-zoom with adaptive rendering and safe
// coexistence with carousel paging, vertical scrolling and tile taps.
//
// Covers:
//   * `DayGridController.settlePxPerHour` — settle a finished pinch to the
//     nearest clean step, clamped to the [40, 240] range.
//   * `DayGridWidget.gutterLabelStride` — adaptive gutter label density.
//   * The gesture-arena SPIKE: a two-finger pinch drives `pxPerHour`.
//   * Coexistence: a single-finger drag scrolls and does NOT zoom; the zoom
//     settles back to `idle` and persists.
//   * `DayGridController.restoreFromPrefs` — restores a stored zoom and is a
//     no-op / safe when the value is absent or out of range.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/timeOfDayTimeCell.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/theme/theme_data.dart';

/// Records `ScheduleBloc` events WITHOUT running the [GetScheduleEvent]
/// handler (no API calls in tests). Same idiom as the tap-to-add suite.
class _RecordingScheduleBloc extends ScheduleBloc {
  _RecordingScheduleBloc() : super(getContextCallBack: () => null);

  @override
  void add(ScheduleEvent event) {
    if (event is GetScheduleEvent) {
      return;
    }
    super.add(event);
  }
}

SubCalendarEvent _tile(String id, DateTime start, DateTime end) {
  final tile = SubCalendarEvent(
    id: id,
    name: id,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = true;
  return tile;
}

/// Enlarges the test surface to a tall phone so the grid viewport (and the
/// now-line / tile layout) is realistic for the pinch and scroll assertions.
void _setSurface(WidgetTester tester) {
  final originalPhysicalSize = tester.view.physicalSize;
  final originalDpr = tester.view.devicePixelRatio;
  tester.view.devicePixelRatio = 2.0;
  tester.view.physicalSize = const Size(1080, 2160); // logical 540 x 1080.
  addTearDown(() {
    tester.view.devicePixelRatio = originalDpr;
    tester.view.physicalSize = originalPhysicalSize;
  });
}

/// Closes [bloc] from the real async zone (same idiom as the DayGrid
/// refresh / now-line suite).
Future<void> _closeBloc(WidgetTester tester, ScheduleBloc bloc) async {
  await tester.runAsync(() async {
    final closeFuture = bloc.close();
    int pumps = 0;
    for (; pumps < 20; pumps++) {
      try {
        await closeFuture.timeout(const Duration(milliseconds: 50));
        return;
      } on TimeoutException {
        await tester.pump(const Duration(milliseconds: 16));
      }
    }
    throw StateError(
      'bloc.close() stalled after $pumps fake-zone drains; '
      'isClosed=${bloc.isClosed}',
    );
  });
}

/// Builds the grid with an **injected** [DayGridController] so the test can
/// observe (and drive) the zoom state directly.
Widget _buildApp({
  required ScheduleBloc bloc,
  required DayGridController controller,
  required List<SubCalendarEvent> tiles,
  DateTime? now,
  DateTime? day,
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
    home: BlocProvider<ScheduleBloc>(
      create: (_) => bloc,
      child: Scaffold(
        body: DayGridWidget(
          tiles: tiles,
          now: now,
          day: day,
          controller: controller,
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DayGridController.settlePxPerHour', () {
    test('applies clean multiples of the settle step unchanged', () {
      expect(DayGridController.settlePxPerHour(80), 80);
      expect(DayGridController.settlePxPerHour(120), 120);
      expect(DayGridController.settlePxPerHour(240), 240);
    });

    test('snaps to the nearest step', () {
      expect(DayGridController.settlePxPerHour(83), 85); // 85 is nearer
      expect(DayGridController.settlePxPerHour(82), 80); // 80 is nearer
    });

    test('clamps below the minimum to 40', () {
      expect(DayGridController.settlePxPerHour(10), 40);
    });

    test('clamps above the maximum to 240', () {
      expect(DayGridController.settlePxPerHour(999), 240);
    });
  });

  group('DayGridWidget.gutterLabelStride (adaptive gutter)', () {
    test('labels every hour at/above the threshold', () {
      expect(
          DayGridWidget.gutterLabelStride(
              DayGridWidget.gutterThinLabelThreshold),
          1);
      expect(DayGridWidget.gutterLabelStride(80), 1);
      expect(DayGridWidget.gutterLabelStride(240), 1);
    });

    test('thins to every 2nd hour below the threshold', () {
      expect(DayGridWidget.gutterLabelStride(40), 2);
      expect(
          DayGridWidget.gutterLabelStride(
              DayGridWidget.gutterThinLabelThreshold - 0.1),
          2);
    });
  });

  group('DayGridController.restoreFromPrefs', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('restores a stored zoom and marks it explicit', () async {
      // Seed a real double (setPxPerHour stores via setDouble) so the
      // type check in getPxPerHour passes.
      await DayGridPreferences.setPxPerHour(150);
      final controller = DayGridController();
      await controller.restoreFromPrefs();
      expect(controller.pxPerHour, 150);
      expect(controller.hasExplicitZoom, isTrue);
      controller.dispose();
    });

    test('keeps the default when no value is stored (auto-fit can run)',
        () async {
      final controller = DayGridController();
      await controller.restoreFromPrefs();
      expect(controller.pxPerHour, DayGridController.defaultPxPerHour);
      expect(controller.hasExplicitZoom, isFalse);
      controller.dispose();
    });

    test('ignores an out-of-range stored value (falls back to default)',
        () async {
      // A double so the type check passes and the RANGE check rejects it.
      SharedPreferences.setMockInitialValues({'dayGridPxPerHour': 999999.0});
      final controller = DayGridController();
      await controller.restoreFromPrefs();
      expect(controller.pxPerHour, DayGridController.defaultPxPerHour);
      expect(controller.hasExplicitZoom, isFalse);
      controller.dispose();
    });
  });

  group('DayGrid pinch-to-zoom', () {
    // A future grid day (no past-time prefill) with a 0–1h tile that pins the
    // initial scroll offset to 0 (midnight at the viewport top), leaving the
    // mid-day region (y ~ 300) free of tiles for a clean two-finger pinch.
    final dayStart = DateTime(2027, 1, 15);
    final now = DateTime(2026, 5, 15, 14, 30);
    final anchorTiles = <SubCalendarEvent>[
      _tile('t0', DateTime(2027, 1, 15, 0), DateTime(2027, 1, 15, 1)),
    ];

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('two-finger pinch zooms in and settles to a clean step',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(80);

      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump(); // post-frame: initial scroll settles.
      expect(controller.pxPerHour, 80);

      // Two fingers ~200px apart, both in the empty mid-day region (the anchor
      // tile occupies y 0–80; y=300 is clear of it).
      final g1 = await tester.startGesture(const Offset(150, 300));
      final g2 = await tester.startGesture(const Offset(350, 300));
      await tester.pump();
      // Spread apart in steps -> the total scale ratio grows (> 1).
      for (int i = 0; i < 4; i++) {
        await g1.moveBy(const Offset(-15, 0));
        await g2.moveBy(const Offset(15, 0));
        await tester.pump();
      }
      await g1.up();
      await g2.up();
      await tester.pump(); // _onScaleEnd: settle + fire-and-forget persist.
      await tester.pump();

      // The pinch increased the zoom, stayed in range, and is a clean step.
      expect(controller.pxPerHour, greaterThan(80));
      expect(controller.pxPerHour,
          lessThanOrEqualTo(DayGridController.maxPxPerHour));
      expect(controller.pxPerHour % DayGridController.settleStep,
          closeTo(0, 1e-9));
      // Back to idle once the pinch ended.
      expect(controller.mode, DayGridMode.idle);

      // The settled zoom persisted. Read in the real async zone so the
      // mock SharedPreferences future resolves.
      final stored = await tester
          .runAsync<double?>(() => DayGridPreferences.getPxPerHour());
      expect(stored, isNotNull);
      expect(stored!, closeTo(controller.pxPerHour, 1e-9));

      await _closeBloc(tester, bloc);
      controller.dispose();
    });

    testWidgets('a single-finger vertical drag scrolls and does NOT zoom',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(80);

      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump();
      final before = controller.pxPerHour;

      // One finger, vertical: this must go to the scroll view, not the scale.
      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(controller.pxPerHour, before); // no zoom from a single finger.
      expect(controller.mode, DayGridMode.idle);

      await _closeBloc(tester, bloc);
      controller.dispose();
    });

    testWidgets('gutter labels thin out at low zoom (adaptive)',
        (tester) async {
      _setSurface(tester);
      final bloc = _RecordingScheduleBloc();
      final controller = DayGridController();
      controller.setPxPerHour(80);

      await tester.pumpWidget(_buildApp(
        bloc: bloc,
        controller: controller,
        tiles: anchorTiles,
        now: now,
        day: dayStart,
      ));
      await tester.pump();

      // At 80 px/h every hour row gets a label (24).
      expect(find.byType(TimeOfDayTimeCellWidget), findsNWidgets(24));

      // Zoom out below the threshold -> labels every 2nd hour (12).
      controller.setPxPerHour(50);
      await tester.pump();
      expect(find.byType(TimeOfDayTimeCellWidget), findsNWidgets(12));

      // Zoom back up -> all 24 labels return.
      controller.setPxPerHour(80);
      await tester.pump();
      expect(find.byType(TimeOfDayTimeCellWidget), findsNWidgets(24));

      await _closeBloc(tester, bloc);
      controller.dispose();
    });

    group('pinch with fingers landing on tiles', () {
      // Regression: the scale recognizer must see BOTH pointers even when the
      // fingers land on event tiles (which sit above the empty-background
      // layer in the grid Stack). A 0-14h tile pins the initial scroll to 0
      // (midnight at the viewport top) and covers the whole upper viewport,
      // so y=300 — previously the clean empty region — is ON the tile.
      final dayStart = DateTime(2027, 1, 15);
      final now = DateTime(2026, 5, 15, 14, 30);

      testWidgets('pinch with BOTH fingers on a tile zooms', (tester) async {
        _setSurface(tester);
        final bloc = _RecordingScheduleBloc();
        final controller = DayGridController();
        controller.setPxPerHour(80);

        await tester.pumpWidget(_buildApp(
          bloc: bloc,
          controller: controller,
          tiles: <SubCalendarEvent>[
            _tile(
                't-big', DateTime(2027, 1, 15, 0), DateTime(2027, 1, 15, 14)),
          ],
          now: now,
          day: dayStart,
        ));
        await tester.pump();

        // Both fingers start on the 0-14h tile (y 0-1120 at 80 px/h).
        final g1 = await tester.startGesture(const Offset(150, 300));
        final g2 = await tester.startGesture(const Offset(350, 300));
        await tester.pump();
        for (int i = 0; i < 4; i++) {
          await g1.moveBy(const Offset(-15, 0));
          await g2.moveBy(const Offset(15, 0));
          await tester.pump();
        }
        await g1.up();
        await g2.up();
        await tester.pump();

        expect(controller.pxPerHour, greaterThan(80));
        expect(controller.pxPerHour,
            lessThanOrEqualTo(DayGridController.maxPxPerHour));
        expect(controller.mode, DayGridMode.idle);

        await _closeBloc(tester, bloc);
        controller.dispose();
      });

      testWidgets(
          'pinch with ONE finger on a tile and one in empty space zooms',
          (tester) async {
        _setSurface(tester);
        final bloc = _RecordingScheduleBloc();
        final controller = DayGridController();
        controller.setPxPerHour(80);

        await tester.pumpWidget(_buildApp(
          bloc: bloc,
          controller: controller,
          tiles: <SubCalendarEvent>[
            _tile('t0-2', DateTime(2027, 1, 15, 0), DateTime(2027, 1, 15, 2)),
          ],
          now: now,
          day: dayStart,
        ));
        await tester.pump();

        // g1 on the tile (y 0-160 at 80 px/h), g2 in the empty region below.
        final g1 = await tester.startGesture(const Offset(150, 50));
        final g2 = await tester.startGesture(const Offset(350, 300));
        await tester.pump();
        for (int i = 0; i < 4; i++) {
          await g1.moveBy(const Offset(-15, 0));
          await g2.moveBy(const Offset(15, 0));
          await tester.pump();
        }
        await g1.up();
        await g2.up();
        await tester.pump();

        expect(controller.pxPerHour, greaterThan(80));
        expect(controller.mode, DayGridMode.idle);

        await _closeBloc(tester, bloc);
        controller.dispose();
      });

      testWidgets('a single-finger tap on a tile does NOT zoom',
          (tester) async {
        _setSurface(tester);
        final bloc = _RecordingScheduleBloc();
        final controller = DayGridController();
        controller.setPxPerHour(80);

        await tester.pumpWidget(_buildApp(
          bloc: bloc,
          controller: controller,
          tiles: <SubCalendarEvent>[
            _tile(
                't-big', DateTime(2027, 1, 15, 0), DateTime(2027, 1, 15, 14)),
          ],
          now: now,
          day: dayStart,
        ));
        await tester.pump();

        await tester.tapAt(const Offset(250, 300)); // on the tile.
        await tester.pump();

        expect(controller.pxPerHour, 80);
        expect(controller.mode, DayGridMode.idle);

        await _closeBloc(tester, bloc);
        controller.dispose();
      });

      testWidgets('tap-to-add on the empty background still works',
          (tester) async {
        _setSurface(tester);
        final bloc = _RecordingScheduleBloc();
        final controller = DayGridController();
        controller.setPxPerHour(80);

        await tester.pumpWidget(_buildApp(
          bloc: bloc,
          controller: controller,
          tiles: anchorTiles,
          now: now,
          day: dayStart,
        ));
        await tester.pump();

        // One finger on empty background: the pinch overlay must not
        // swallow the tap-to-add (a single pointer never satisfies the
        // scale recognizer).
        await tester.tapAt(const Offset(200, 320));
        await tester.pump();
        // Advance the fake clock past AddTile's 700ms auto-result Timer so
        // its callback runs and is consumed (same idiom as the tap-to-add
        // suite).
        await tester.pump(const Duration(milliseconds: 750));
        expect(find.byType(AddTile), findsOneWidget);

        await _closeBloc(tester, bloc);
        controller.dispose();
      });
    });
  });
}
