// DayGrid P1 step 1.7 (C7) — the pinned header strip renders the >=16h /
// all-day tiles that DayGridWidget excludes from the timeline, so they
// stay visible in grid mode: in the header, not on the timeline.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/bloc/dailyViewLayout/daily_view_layout_cubit.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridPinnedHeader.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/tileGridWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

SubCalendarEvent _tile(String id, String name, DateTime start, DateTime end) {
  final tile = SubCalendarEvent(
    id: id,
    name: name,
    start: start.millisecondsSinceEpoch,
    end: end.millisecondsSinceEpoch,
  );
  tile.isViable = true;
  return tile;
}

/// Grid mode renders the page with an Expanded grid, so the page needs a
/// bounded-height parent (the viewport) — no scroll wrapper here.
Widget _buildApp({
  required DailyViewLayoutCubit cubit,
  required List<TilerEvent> tiles,
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
        BlocProvider(create: (_) => cubit),
        BlocProvider(create: (_) => ScheduleBloc(getContextCallBack: () => null)),
        BlocProvider(
            create: (_) =>
                ScheduleSummaryBloc(getContextCallBack: () => null)),
      ],
      child: Scaffold(
        body: DayGridPage(
          dayIndex: 20500,
          tiles: tiles,
          key: const Key('day_20500'),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'dayGridLayout': 'grid'});
  });

  group('DayGrid pinned header (C7, step 1.7)', () {
    testWidgets('>=16h tile renders in the header, not the timeline',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final tiles = <TilerEvent>[
        _tile('regular', 'RegularEvent',
            DateTime(2026, 5, 15, 9), DateTime(2026, 5, 15, 10)),
        _tile('long', 'LongEvent',
            DateTime(2026, 5, 15, 0), DateTime(2026, 5, 15, 20)),
      ];
      await tester.pumpWidget(_buildApp(cubit: cubit, tiles: tiles));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      // The header is present and surfaces the long tile...
      expect(find.byType(DayGridPinnedHeader), findsOneWidget);
      expect(
        find.descendant(
            of: find.byType(DayGridPinnedHeader), matching: find.text('LongEvent')),
        findsOneWidget,
      );
      // ...and the long tile is NOT on the grid timeline: only the
      // regular tile renders as a grid tile.
      final timelineTiles = find.descendant(
          of: find.byType(DayGridWidget), matching: find.byType(TileGridWidget));
      expect(timelineTiles, findsOneWidget);
      expect(
        find.descendant(
            of: find.byType(DayGridPinnedHeader),
            matching: find.byType(TileGridWidget)),
        findsNothing,
      );
      cubit.close();
    });

    testWidgets('no excluded tiles -> header renders no content',
        (tester) async {
      final cubit = DailyViewLayoutCubit();
      final tiles = <TilerEvent>[
        _tile('regular', 'RegularEvent',
            DateTime(2026, 5, 15, 9), DateTime(2026, 5, 15, 10)),
      ];
      await tester.pumpWidget(_buildApp(cubit: cubit, tiles: tiles));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();

      expect(find.byType(DayGridPinnedHeader), findsOneWidget);
      // Empty header: no title, no tile names.
      expect(find.text('Extended Events'), findsNothing);
      expect(find.text('RegularEvent'), findsOneWidget);
      cubit.close();
    });
  });

  group('DayGridPinnedHeader.excludedTiles', () {
    test('keeps >=16h tiles, drops regular ones (boundary inclusive)', () {
      final tiles = <SubCalendarEvent>[
        _tile('short', 'Short', DateTime(2026, 5, 15, 9),
            DateTime(2026, 5, 15, 10)),
        _tile('justUnder', 'JustUnder', DateTime(2026, 5, 15, 0),
            DateTime(2026, 5, 15, 15, 59)),
        _tile('exact16', 'Exact16', DateTime(2026, 5, 15, 0),
            DateTime(2026, 5, 15, 16)),
      ];
      final excluded = DayGridPinnedHeader.excludedTiles(tiles);
      expect(excluded.map((t) => t.id), ['exact16']);
    });

    test('empty input -> empty output', () {
      expect(DayGridPinnedHeader.excludedTiles(<SubCalendarEvent>[]), isEmpty);
    });
  });
}