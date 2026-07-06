// home_layout_test.dart
//
// TDD tests for the home-page layout redesign:
//   1. PreviewAddWidget modal row must NOT contain a chat button.
//   2. HomeFab always shows the chat icon (no Tiler-logo image).
//   3. HomeBottomNav has exactly 3 items; the center slot renders the Tiler logo.
//   4. HomeTopRightActions shows search + settings icons; the "Go to Today"
//      button is visible only when the user is NOT viewing today.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/previewAddWidget.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ── New widgets added by this feature (will not exist until implementation) ──
import 'package:tiler_app/components/homeFab.dart';
import 'package:tiler_app/components/homeBottomNav.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Shared test-app wrapper
//
// VibeChatBloc requires ScheduleBloc + ScheduleSummaryBloc at construction
// time, so we create those first and share them across providers.
// ─────────────────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) {
  final scheduleBloc = ScheduleBloc(getContextCallBack: () => null);
  final scheduleSummaryBloc =
      ScheduleSummaryBloc(getContextCallBack: () => null);
  final vibeChatBloc = VibeChatBloc(
    scheduleBloc: scheduleBloc,
    scheduleSummaryBloc: scheduleSummaryBloc,
    getContextCallBack: () => null,
  );

  return MultiBlocProvider(
    providers: [
      BlocProvider.value(value: scheduleBloc),
      BlocProvider.value(value: scheduleSummaryBloc),
      BlocProvider(
          create: (_) => ForecastBloc(getContextCallBack: () => null)),
      BlocProvider(
          create: (_) =>
              SubCalendarTileBloc(getContextCallBack: () => null)),
      BlocProvider(create: (_) => UiDateManagerBloc()),
      BlocProvider.value(value: vibeChatBloc),
    ],
    child: MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Group 1 — PreviewAddWidget: modal button row
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreviewAddWidget modal button row', () {
    Future<void> pumpModal(WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          SingleChildScrollView(
            child: PreviewAddWidget(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('does NOT contain a chat button', (tester) async {
      await pumpModal(tester);

      // The chat button previously used Icons.chat_outlined.
      expect(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.chat_outlined,
        ),
        findsNothing,
        reason: 'Chat should be removed from the modal button row',
      );
    });

    testWidgets('still contains shuffle, procrastinate-all, and more-settings buttons',
        (tester) async {
      await pumpModal(tester);

      // Shuffle button uses FontAwesomeIcons — find by its Icon ancestor.
      // We verify via the text labels that localisation resolves.
      expect(find.byIcon(Icons.more_time), findsOneWidget,
          reason: 'More-settings button must remain');
      // Procrastinate-all button uses the triple-chevron (chevron_right icons).
      expect(find.byIcon(Icons.chevron_right), findsWidgets,
          reason: 'Procrastinate-all triple-chevron must remain');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 2 — HomeFab
  // ─────────────────────────────────────────────────────────────────────────

  group('HomeFab', () {
    testWidgets('always shows the chat icon', (tester) async {
      await tester.pumpWidget(_wrap(HomeFab(onPressed: () {})));
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) => w is Icon && w.icon == Icons.chat_outlined),
        findsOneWidget,
        reason: 'HomeFab must display the chat icon',
      );
    });

    testWidgets('does NOT render Tiler logo image assets', (tester) async {
      await tester.pumpWidget(_wrap(HomeFab(onPressed: () {})));
      await tester.pump();

      expect(
        find.byWidgetPredicate((w) {
          if (w is Image) {
            final src = w.image;
            if (src is AssetImage) return src.assetName.contains('tilerLogo');
          }
          return false;
        }),
        findsNothing,
        reason: 'Tiler logo must not appear in the FAB',
      );
    });

    testWidgets('calls onPressed callback when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(_wrap(HomeFab(onPressed: () => called = true)));
      await tester.pump();

      await tester.tap(find.byType(HomeFab));
      expect(called, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 3 — HomeBottomNav
  // ─────────────────────────────────────────────────────────────────────────

  group('HomeBottomNav', () {
    Widget buildNav({VoidCallback? onShare, VoidCallback? onAddTile, VoidCallback? onCalendar}) {
      return _wrap(
        HomeBottomNav(
          onShare: onShare ?? () {},
          onAddTile: onAddTile ?? () {},
          onCalendar: onCalendar ?? () {},
        ),
      );
    }

    testWidgets('renders exactly 3 tappable items', (tester) async {
      await tester.pumpWidget(buildNav());
      await tester.pump();

      // Share icon + calendar icon = 2 IconButtons; Tiler logo = 1 GestureDetector.
      expect(find.byType(IconButton), findsNWidgets(2),
          reason: 'Bottom nav must have 2 IconButton items (share + calendar)');
      expect(find.byType(GestureDetector), findsAtLeastNWidgets(1),
          reason: 'Bottom nav must have at least 1 GestureDetector for the centre logo');
    });

    testWidgets('center item contains the animated Tiler logo', (tester) async {
      await tester.pumpWidget(buildNav());
      await tester.pump();

      // AutoSwitchingWidget starts on the first child (BlueBottom).
      final tilerLogoFinder = find.byWidgetPredicate((w) {
        if (w is Image) {
          final src = w.image;
          if (src is AssetImage) return src.assetName.contains('tilerLogo');
        }
        return false;
      });

      expect(tilerLogoFinder, findsOneWidget,
          reason: 'Centre nav item must show the animated Tiler logo');
    });

    testWidgets('left item has share icon', (tester) async {
      await tester.pumpWidget(buildNav());
      await tester.pump();

      expect(find.byIcon(Icons.share), findsOneWidget,
          reason: 'Left nav item must be the share icon');
    });

    testWidgets('right item has calendar icon', (tester) async {
      await tester.pumpWidget(buildNav());
      await tester.pump();

      expect(find.byIcon(Icons.calendar_month), findsOneWidget,
          reason: 'Right nav item must be the calendar-view switcher');
    });

    testWidgets('tapping center item triggers onAddTile callback', (tester) async {
      bool addTileCalled = false;
      await tester.pumpWidget(buildNav(onAddTile: () => addTileCalled = true));
      await tester.pump();

      final tilerLogoFinder = find.byWidgetPredicate((w) {
        if (w is Image) {
          final src = w.image;
          if (src is AssetImage) return src.assetName.contains('tilerLogo');
        }
        return false;
      });

      await tester.tap(tilerLogoFinder);
      expect(addTileCalled, isTrue,
          reason: 'Tapping center Tiler logo must invoke onAddTile');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group 4 — HomeTopRightActions overlay
  // ─────────────────────────────────────────────────────────────────────────

  group('HomeTopRightActions', () {
    Widget buildOverlay({bool isViewingToday = true, VoidCallback? onSearch, VoidCallback? onSettings, VoidCallback? onGoToToday}) {
      return _wrap(
        Stack(
          children: [
            HomeTopRightActions(
              isViewingToday: isViewingToday,
              onSearch: onSearch ?? () {},
              onSettings: onSettings ?? () {},
              onGoToToday: onGoToToday ?? () {},
            ),
          ],
        ),
      );
    }

    testWidgets('always shows the search icon', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      expect(find.byIcon(Icons.search), findsOneWidget,
          reason: 'Search icon must always be visible in top-right overlay');
    });

    testWidgets('always shows the settings icon', (tester) async {
      await tester.pumpWidget(buildOverlay());
      await tester.pump();

      expect(find.byIcon(Icons.settings), findsOneWidget,
          reason: 'Settings icon must always be visible in top-right overlay');
    });

    testWidgets('"Go to Today" button is hidden when viewing today', (tester) async {
      await tester.pumpWidget(buildOverlay(isViewingToday: true));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsNothing,
          reason: '"Go to Today" must be hidden when already on today');
    });

    testWidgets('"Go to Today" button is visible when NOT viewing today', (tester) async {
      await tester.pumpWidget(buildOverlay(isViewingToday: false));
      await tester.pump();

      expect(find.byIcon(Icons.calendar_today), findsOneWidget,
          reason: '"Go to Today" must be shown when user is on a different day');
    });

    testWidgets('tapping search calls onSearch callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildOverlay(onSearch: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.search));
      expect(called, isTrue);
    });

    testWidgets('tapping settings calls onSettings callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(buildOverlay(onSettings: () => called = true));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings));
      expect(called, isTrue);
    });

    testWidgets('tapping "Go to Today" calls onGoToToday callback', (tester) async {
      bool called = false;
      await tester.pumpWidget(
        buildOverlay(isViewingToday: false, onGoToToday: () => called = true),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.calendar_today));
      expect(called, isTrue);
    });
  });
}
