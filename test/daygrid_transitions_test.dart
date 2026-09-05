// Moved/resized tile position transitions.
//
// When the schedule changes, a tile must slide to its new position (animated
// `AnimatedPositioned`) rather than teleport, and only when the controller is
// idle — during a pinch/drag positions track the controller directly, and a
// reduced-motion setting yields a jump cut. Each tile keeps a stable
// `ValueKey` (scoped per day via `dayKey`) so Flutter reuses the element and
// animates the delta instead of remounting.
//
// Positions are measured as the relative top between two tiles
// (`B.top - A.top`), which cancels the scroll offset entirely (the grid
// re-syncs its initial scroll on every new tiles list, so absolute positions
// would be confounded by the scroll). The earliest tile stays fixed so its
// hour — which drives the initial scroll — never moves either.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestApp({required Widget child}) {
    return MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  SubCalendarEvent buildTile({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
  }) {
    return SubCalendarEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
    );
  }

  final DateTime day = DateTime(2026, 5, 15);
  // A clock on a different day than the grid day: no now-line renders, and a
  // fixed clock keeps the minute timer off (no pending-timer failures).
  final DateTime now = DateTime(2026, 5, 16, 9);

  /// Grid in a fixed 400x600 viewport (pxPerHour defaults to 80).
  Widget grid(
    List<SubCalendarEvent> tiles, {
    DayGridController? controller,
    String? dayKey,
  }) {
    return SizedBox(
      width: 400,
      height: 600,
      child: DayGridWidget(
        tiles: tiles,
        controller: controller,
        dayKey: dayKey,
        now: now,
      ),
    );
  }

  /// Relative on-screen top between two tiles: scroll-immune by construction.
  double dyBetween(WidgetTester tester, String aName, String bName) {
    final a = tester.getTopLeft(find.text(aName));
    final b = tester.getTopLeft(find.text(bName));
    return b.dy - a.dy;
  }

  // Alpha fixed at 8am (drives the constant initial scroll); Beta at
  // [bHours]. At pxPerHour 80, Beta's top is (bHours - 8) * 80 below Alpha.
  List<SubCalendarEvent> tilesWithBetaAt(double bHours) => <SubCalendarEvent>[
        buildTile(
          id: 'a',
          name: 'Alpha',
          start: day.add(const Duration(hours: 8)),
          end: day.add(const Duration(hours: 9)),
        ),
        buildTile(
          id: 'b',
          name: 'Beta',
          start: day.add(Duration(hours: bHours.toInt())),
          end: day.add(Duration(hours: bHours.toInt() + 1)),
        ),
      ];

  /// Pumps the grid inside a persistent `StatefulBuilder` and returns a
  /// `rebuild` callback that re-renders with the (mutated) current tiles. The
  /// same `StatefulBuilder` element survives across rebuilds so the
  /// `DayGridWidget` element (and each tile element) is reused, which is what
  /// makes the position animation observable.
  Future<void Function()> pumpGrid(
    WidgetTester tester,
    List<SubCalendarEvent> Function() tileSource, {
    DayGridController? controller,
    String? Function()? dayKey,
    Widget Function(BuildContext, Widget)? wrap,
  }) async {
    late void Function() rebuild;
    await tester.pumpWidget(
      buildTestApp(
        child: StatefulBuilder(
          builder: (context, setState) {
            rebuild = () => setState(() {});
            final body = grid(
              tileSource(),
              controller: controller,
              dayKey: dayKey?.call(),
            );
            return wrap?.call(context, body) ?? body;
          },
        ),
      ),
    );
    // Let the grid's post-frame initial-scroll callback run before measuring.
    await tester.pump();
    await tester.pump();
    return rebuild;
  }

  group('DayGridWidget tile position transitions', () {
    testWidgets('moved tile slides from its old top to its new top',
        (tester) async {
      List<SubCalendarEvent> tiles = tilesWithBetaAt(10); // Beta at 10am.
      final rebuild = await pumpGrid(tester, () => tiles);

      // At rest, Beta (10am) is 2h below Alpha (8am) -> 2 * 80 = 160px.
      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(160, 1));

      // Move Beta to 2pm (14:00) -> 6h below Alpha -> 480px. Same uniqueId.
      tiles = tilesWithBetaAt(14);
      rebuild();
      await tester.pump(); // animation starts from the old position

      // Mid-flight (150ms of a 300ms transition): strictly between.
      await tester.pump(const Duration(milliseconds: 150));
      final mid = dyBetween(tester, 'Alpha', 'Beta');
      expect(mid, greaterThan(160), reason: 'should have left the old top');
      expect(mid, lessThan(480), reason: 'should not have jumped to the new top');

      // Settle: reaches the new top.
      await tester.pump(const Duration(milliseconds: 400));
      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(480, 1));
    });

    testWidgets('the moved tile reuses its element (stable key, no duplicate)',
        (tester) async {
      List<SubCalendarEvent> tiles = tilesWithBetaAt(10);
      final rebuild = await pumpGrid(tester, () => tiles);

      const Key betaKey = ValueKey<String>('daygrid_tile_b');
      expect(find.byKey(betaKey), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);

      tiles = tilesWithBetaAt(14);
      rebuild();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Same key, still exactly one Beta — the element was reused, not
      // replaced, and no duplicate slipped in.
      expect(find.byKey(betaKey), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
    });

    testWidgets('positions are immediate while the controller is zooming',
        (tester) async {
      final controller = DayGridController()..mode = DayGridMode.zooming;
      List<SubCalendarEvent> tiles = tilesWithBetaAt(10);
      final rebuild =
          await pumpGrid(tester, () => tiles, controller: controller);

      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(160, 1));

      tiles = tilesWithBetaAt(14);
      rebuild();
      await tester.pump();

      // Not idle -> no animation: Beta is already at its new top after a
      // single frame (a 300ms animation would still be near the old top).
      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(480, 1));
    });

    testWidgets('disableAnimations yields a jump cut', (tester) async {
      List<SubCalendarEvent> tiles = tilesWithBetaAt(10);
      final rebuild = await pumpGrid(
        tester,
        () => tiles,
        wrap: (context, body) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: body,
        ),
      );

      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(160, 1));

      tiles = tilesWithBetaAt(14);
      rebuild();
      await tester.pump();

      // Reduced motion -> jump straight to the new top.
      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(480, 1));
    });

    testWidgets('a day change swaps keys so there is no cross-day slide',
        (tester) async {
      String dayKey = 'd1';
      // Same tile ids across both frames (uniqueId == id for tiler tiles), so
      // the ONLY thing that changes the keys is the day prefix.
      List<SubCalendarEvent> tiles = tilesWithBetaAt(10);
      final rebuild = await pumpGrid(tester, () => tiles, dayKey: () => dayKey);

      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(160, 1));

      // Switch to a different day AND move Beta. Because the keys are
      // day-scoped, both tiles remount fresh -> Beta appears at its new top
      // immediately (it never "flies" in from the previous day).
      dayKey = 'd2';
      tiles = tilesWithBetaAt(14);
      rebuild();
      await tester.pump();

      expect(dyBetween(tester, 'Alpha', 'Beta'), closeTo(480, 1));
    });
  });
}