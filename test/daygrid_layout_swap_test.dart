// Day page swaps EnhancedTileBatch <-> DayGridWidget
// via the DailyViewLayoutCubit, with list-view parity filtering applied to
// the grid input.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/components/tilelist/dailyView/enhancedTileBatch.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  SubCalendarEvent buildTile({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
    RsvpStatus? rsvp,
    bool? isViable = true,
    TileSource? thirdpartyType,
  }) {
    final tile = SubCalendarEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      rsvp: rsvp,
    );
    tile.isViable = isViable;
    tile.thirdpartyType = thirdpartyType;
    return tile;
  }

  /// Parity fixture: every class of tile EnhancedTileBatch treats
  /// differently.
  List<TilerEvent> buildFixtureTiles() {
    return <TilerEvent>[
      buildTile(
          id: 'viable',
          name: 'Viable',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9)),
      // Third-party declined -> hidden from main list (and grid).
      buildTile(
          id: 'declined',
          name: 'Declined',
          start: DateTime(2026, 5, 15, 10),
          end: DateTime(2026, 5, 15, 11),
          rsvp: RsvpStatus.declined),
      // Third-party pending RSVP -> hidden from main list (and grid).
      buildTile(
          id: 'pending',
          name: 'PendingRsvp',
          start: DateTime(2026, 5, 15, 12),
          end: DateTime(2026, 5, 15, 13),
          rsvp: RsvpStatus.needsAction),
      // Non-viable -> hidden from main list (and grid).
      buildTile(
          id: 'non-viable',
          name: 'NonViable',
          start: DateTime(2026, 5, 15, 14),
          end: DateTime(2026, 5, 15, 15),
          isViable: false),
      // Tiler-sourced declined -> RSVP filters do NOT apply to tiler
      // tiles (parity: renders in main list AND grid).
      buildTile(
          id: 'tiler-declined',
          name: 'TilerDeclined',
          start: DateTime(2026, 5, 15, 16),
          end: DateTime(2026, 5, 15, 17),
          rsvp: RsvpStatus.declined,
          thirdpartyType: TileSource.tiler),
      // Third-party accepted -> normal tile.
      buildTile(
          id: 'accepted',
          name: 'Accepted',
          start: DateTime(2026, 5, 15, 18),
          end: DateTime(2026, 5, 15, 19),
          rsvp: RsvpStatus.accepted),
    ];
  }

  /// Grid input parity: not pending-RSVP, not declined (third-party),
  /// and viable — mirroring EnhancedTileBatch's main-list filtering.
  const expectedGridIds = ['accepted', 'tiler-declined', 'viable'];

  /// Swap fixture: plain viable tiles with no active alerts.
  ///
  /// The toggle test hosts the page in a bounded body (the grid-mode
  /// contract). ETB's list-mode body is a fixed-height
  /// `MediaQuery.height - daySummaryToHeightBuffer` container plus the
  /// DaySummary header (which is exactly what the buffer reserves); the
  /// alert banner the parity fixture would surface (pending + declined
  /// tiles) overflows that bounded body in the test environment — a
  /// pre-existing ETB sizing nuance. Keeping the
  /// list frame alert-free lets the bounded host carry both modes, so
  /// the test asserts the swap itself with the page in place.
  List<TilerEvent> buildSwapTiles() {
    return <TilerEvent>[
      buildTile(
          id: 'swap-a',
          name: 'SwapA',
          start: DateTime(2026, 5, 15, 8),
          end: DateTime(2026, 5, 15, 9)),
      buildTile(
          id: 'swap-b',
          name: 'SwapB',
          start: DateTime(2026, 5, 15, 12),
          end: DateTime(2026, 5, 15, 13)),
    ];
  }

  Widget buildTestApp(
      {required DailyViewLayoutCubit cubit,
      required List<TilerEvent> tiles,
      // Grid mode builds its body with an Expanded grid, which
      // needs a bounded parent; list mode keeps the scrollable-parent
      // convention so the batch's natural-height Column lays out without
      // overflowing.
      bool scrollableParent = true}) {
    final dayPage = DayGridPage(
      dayIndex: 20500,
      tiles: tiles,
      key: const Key('day_20500'),
    );
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
          BlocProvider(create: (_) => cubit),
          // The grid page's scroll header hosts the day strip, which reads
          // UiDateManagerBloc (always provided in the app).
          BlocProvider(create: (_) => UiDateManagerBloc()),
          BlocProvider(
              create: (_) => ScheduleBloc(getContextCallBack: () => null)),
          BlocProvider(
              create: (_) =>
                  ScheduleSummaryBloc(getContextCallBack: () => null)),
        ],
        child: Scaffold(
          // List mode: the existing ETB convention (scrollable parent,
          // natural-height Column). Grid mode: a bounded parent
          // so the page's Expanded grid lays out.
          body: scrollableParent
              ? SingleChildScrollView(child: dayPage)
              : dayPage,
        ),
      ),
    );
  }

  group('DayGridPage layout swap', () {
    Future<void> pumpSwapPage(WidgetTester tester, DailyViewLayoutCubit cubit,
        List<TilerEvent> tiles,
        {bool scrollableParent = true}) async {
      // EnhancedTileBatch needs a real-size viewport (same convention as
      // enhanced_tile_batch_test). 5000 physical px (3750 logical) keeps
      // the batch's natural height (~3000px) under the bounded parent the
      // grid-mode cases rely on.
      tester.view.physicalSize = const Size(1080, 5000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      await tester.pumpWidget(buildTestApp(
        cubit: cubit,
        tiles: tiles,
        scrollableParent: scrollableParent,
      ));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
    }

    testWidgets('cubit=list renders the list view (EnhancedTileBatch)',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final tiles = buildFixtureTiles();
      await pumpSwapPage(tester, cubit, tiles);

      expect(find.byType(EnhancedTileBatch), findsOneWidget);
      expect(find.byType(DayGridWidget), findsNothing);
      cubit.close();
    });

    testWidgets('cubit=grid renders the grid with parity-filtered tiles',
        (tester) async {
      SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
      final cubit = DailyViewLayoutCubit();
      final tiles = buildFixtureTiles();
      await pumpSwapPage(tester, cubit, tiles, scrollableParent: false);

      expect(find.byType(DayGridWidget), findsOneWidget);
      expect(find.byType(EnhancedTileBatch), findsNothing);

      // The grid input carries exactly the parity-filtered set.
      final grid = tester.widget<DayGridWidget>(find.byType(DayGridWidget));
      final gridIds = grid.tiles.map((t) => t.id).toList()..sort();
      expect(gridIds, expectedGridIds);
      // And they render as grid tiles (this day's tiles are all renderable
      // — >=16h/out-of-day exclusions are a separate grid concern).
      expect(
          find.descendant(
              of: find.byType(DayGridWidget),
              matching: find.byType(TileGridWidget)),
          findsNWidgets(3));
      cubit.close();
    });

    testWidgets('toggling the cubit swaps the page in place', (tester) async {
      final cubit = DailyViewLayoutCubit();
      // Alert-free fixture: with a bounded body, ETB's list frame fits only
      // while no alert banner stacks on top of its fixed-height timeline
      // (see buildSwapTiles). The swap is what's under test here.
      final tiles = buildSwapTiles();
      // Bounded parent throughout: the page starts in list mode and is
      // toggled to grid mode (Expanded) in place.
      await pumpSwapPage(tester, cubit, tiles, scrollableParent: false);
      expect(find.byType(EnhancedTileBatch), findsOneWidget);
      expect(find.byType(DayGridWidget), findsNothing);

      await cubit.toggle(dayIndex: 20500);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(DayGridWidget), findsOneWidget);
      expect(find.byType(EnhancedTileBatch), findsNothing);
      cubit.close();
    });

    test('gridTiles filter matches EnhancedTileBatch main-list rules',
        () async {
      final tiles = buildFixtureTiles();
      final filtered = DayGridPage.gridTiles(tiles);
      final ids = filtered.map((t) => t.id).toList()..sort();
      expect(ids, expectedGridIds);
    });
  });
}
