// onboarding_tour_sync_test.dart
//
// Guardrails that detect drift between the onboarding tour and the actual
// home-screen functionality. If a button is moved, renamed, or removed — or a
// tour step is added/retargeted without updating the UI — one of these tests
// should fail.
//
// What is covered:
//   1. Tour step-list integrity: count matches `kTutorialStepCount`, ids are
//      unique, and every step targets a known TutorialKey (or null for the
//      sheet step).
//   2. Each step is bound to the EXPECTED TutorialKey (id -> key contract).
//   3. The TutorialKeys used by the tour are actually attached to the live home
//      widgets (HomeFab, HomeBottomNav, HomeTopRightActions).
//   4. The icons/actions a step advertises still exist on the widget it points
//      at (e.g. Chat step <-> chat FAB, Toolkit step <-> search/settings).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/homeFab.dart';
import 'package:tiler_app/components/homeBottomNav.dart';
import 'package:tiler_app/components/homeTopRightActions.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/components/tutorial/tutorialOverlay.dart';
import 'package:tiler_app/components/tutorial/tutorialStep.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: Scaffold(body: child),
    );

/// Pumps a throwaway widget purely to obtain a localised BuildContext, then
/// returns the tour steps built from it.
Future<List<TutorialStep>> _loadSteps(WidgetTester tester) async {
  late List<TutorialStep> steps;
  await tester.pumpWidget(
    _wrap(
      Builder(
        builder: (context) {
          steps = buildTutorialSteps(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pump();
  return steps;
}

TutorialStep _stepById(List<TutorialStep> steps, String id) =>
    steps.firstWhere((s) => s.id == id);

Set<IconData> _renderedIcons(WidgetTester tester) => tester
    .widgetList<Icon>(find.byType(Icon))
    .where((i) => i.icon != null)
    .map((i) => i.icon!)
    .toSet();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The GlobalKeys the tour spotlights, and the widgets that OWN them.
  // `scheduleViewKey` and `currentTileKey` are attached deep inside
  // AuthorizedRoute / the tile list (not cheaply renderable in isolation), so
  // they are validated via the id->key contract rather than a live mount check.
  final Set<GlobalKey> knownTargetKeys = {
    TutorialKeys.scheduleViewKey,
    TutorialKeys.bottomNavKey,
    TutorialKeys.bottomNavAddTileKey,
    TutorialKeys.topRightActionsKey,
    TutorialKeys.currentTileKey,
    TutorialKeys.fabKey,
  };

  // The exact step-id -> target-key contract. Changing where a step points
  // (or renaming a step) must be a deliberate update here.
  final Map<String, GlobalKey?> expectedTargets = {
    'schedule_view': TutorialKeys.scheduleViewKey,
    'add_tile_button': TutorialKeys.bottomNavAddTileKey,
    'quick_add': null, // full-screen sheet step
    'smart_scheduling': TutorialKeys.bottomNavKey,
    'tile_interactions': TutorialKeys.currentTileKey,
    'switch_views': TutorialKeys.bottomNavKey,
    'quick_tools': TutorialKeys.topRightActionsKey,
    'chat_fab': TutorialKeys.fabKey,
  };

  // ───────────────────────────────────────────────────────────────────────
  // Group 1 — Step list integrity
  // ───────────────────────────────────────────────────────────────────────
  group('Onboarding step list integrity', () {
    testWidgets('step count matches kTutorialStepCount', (tester) async {
      final steps = await _loadSteps(tester);
      expect(
        steps.length,
        kTutorialStepCount,
        reason:
            'buildTutorialSteps() length must equal kTutorialStepCount. If you '
            'added/removed a step, update kTutorialStepCount so TutorialBloc and '
            'the "x/N" counter stay correct.',
      );
    });

    testWidgets('every step id is unique', (tester) async {
      final steps = await _loadSteps(tester);
      final ids = steps.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length,
          reason: 'Duplicate tour step ids: $ids');
    });

    testWidgets('every step targets a known key (or null for the sheet step)',
        (tester) async {
      final steps = await _loadSteps(tester);
      for (final step in steps) {
        if (step.targetKey == null) continue;
        expect(
          knownTargetKeys.contains(step.targetKey),
          isTrue,
          reason:
              'Step "${step.id}" points at an unknown GlobalKey. Add it to '
              'TutorialKeys and attach it to a real widget.',
        );
      }
    });

    testWidgets('only the quick_add step is allowed to have a null target',
        (tester) async {
      final steps = await _loadSteps(tester);
      final nullTargetIds =
          steps.where((s) => s.targetKey == null).map((s) => s.id).toList();
      expect(nullTargetIds, ['quick_add'],
          reason:
              'Only the quick_add sheet step may have a null spotlight target.');
    });

    testWidgets('each step is bound to its expected target key',
        (tester) async {
      final steps = await _loadSteps(tester);
      expect(steps.map((s) => s.id).toSet(), expectedTargets.keys.toSet(),
          reason: 'Tour step ids changed — update the expectedTargets map.');
      for (final step in steps) {
        expect(
          step.targetKey,
          expectedTargets[step.id],
          reason: 'Step "${step.id}" is spotlighting the wrong widget.',
        );
      }
    });

    testWidgets('every step has non-empty title and body', (tester) async {
      final steps = await _loadSteps(tester);
      for (final step in steps) {
        expect(step.title.trim(), isNotEmpty,
            reason: 'Step "${step.id}" has an empty title (missing l10n?)');
        expect(step.body.trim(), isNotEmpty,
            reason: 'Step "${step.id}" has an empty body (missing l10n?)');
      }
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Group 2 — Tour keys are attached to the live home widgets
  // ───────────────────────────────────────────────────────────────────────
  group('Tour keys resolve to live home widgets', () {
    testWidgets('fabKey is attached to HomeFab', (tester) async {
      await tester.pumpWidget(_wrap(HomeFab(onPressed: () {})));
      await tester.pump();
      expect(TutorialKeys.fabKey.currentContext, isNotNull,
          reason: 'The Chat step spotlights fabKey — it must live on HomeFab.');
    });

    testWidgets('bottomNavKey and bottomNavAddTileKey are attached to HomeBottomNav',
        (tester) async {
      await tester.pumpWidget(_wrap(
        HomeBottomNav(
          onShare: () {},
          onAddTile: () {},
          currentView: AuthorizedRouteTileListPage.Daily,
          onSelectView: (_) {},
        ),
      ));
      await tester.pump();
      expect(TutorialKeys.bottomNavKey.currentContext, isNotNull,
          reason: 'bottomNavKey must live on the bottom nav bar.');
      expect(TutorialKeys.bottomNavAddTileKey.currentContext, isNotNull,
          reason:
              'The Create-a-Tile step spotlights the centre logo — '
              'bottomNavAddTileKey must live on it.');
    });

    testWidgets('topRightActionsKey is attached to HomeTopRightActions',
        (tester) async {
      await tester.pumpWidget(_wrap(
        Stack(children: [
          HomeTopRightActions(
            isViewingToday: true,
            onSearch: () {},
            onSettings: () {},
            onGoToToday: () {},
          ),
        ]),
      ));
      await tester.pump();
      expect(TutorialKeys.topRightActionsKey.currentContext, isNotNull,
          reason:
              'The Toolkit step spotlights the top-right cluster — '
              'topRightActionsKey must live on it.');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Group 3 — Step content matches the widget it points at
  // ───────────────────────────────────────────────────────────────────────
  group('Step content matches the real UI', () {
    testWidgets('chat_fab step icon matches the chat FAB', (tester) async {
      final steps = await _loadSteps(tester);
      final chatStep = _stepById(steps, 'chat_fab');
      expect(chatStep.headerIcon, Icons.chat_outlined);

      await tester.pumpWidget(_wrap(HomeFab(onPressed: () {})));
      await tester.pump();
      expect(_renderedIcons(tester), contains(chatStep.headerIcon),
          reason: 'Chat step advertises an icon the FAB no longer shows.');
    });

    testWidgets('quick_tools callouts match the top-right actions', (tester) async {
      final steps = await _loadSteps(tester);
      final toolkit = _stepById(steps, 'quick_tools');
      final calloutIcons = toolkit.callouts.map((c) => c.icon).toSet();
      expect(calloutIcons, {Icons.search, Icons.settings},
          reason:
              'Toolkit step should describe exactly Search + Settings; the Chat '
              'button now has its own step.');

      await tester.pumpWidget(_wrap(
        Stack(children: [
          HomeTopRightActions(
            isViewingToday: true,
            onSearch: () {},
            onSettings: () {},
            onGoToToday: () {},
          ),
        ]),
      ));
      await tester.pump();
      final rendered = _renderedIcons(tester);
      for (final icon in calloutIcons) {
        expect(rendered, contains(icon),
            reason:
                'Toolkit step advertises $icon but the top-right actions no '
                'longer render it.');
      }
    });

    testWidgets('switch_views step icon matches the calendar switcher in the bottom nav',
        (tester) async {
      final steps = await _loadSteps(tester);
      final switchViews = _stepById(steps, 'switch_views');
      expect(switchViews.headerIcon, Icons.calendar_view_month);

      await tester.pumpWidget(_wrap(
        HomeBottomNav(
          onShare: () {},
          onAddTile: () {},
          currentView: AuthorizedRouteTileListPage.Monthly,
          onSelectView: (_) {},
        ),
      ));
      await tester.pump();
      expect(_renderedIcons(tester), contains(Icons.calendar_view_month),
          reason:
              'Switch-views step points at the calendar toggle; on Monthly the '
              'switcher renders the month-grid icon the step advertises.');
    });

    testWidgets('add_tile_button spotlight actually triggers add-tile',
        (tester) async {
      bool addTileCalled = false;
      await tester.pumpWidget(_wrap(
        HomeBottomNav(
          onShare: () {},
          onAddTile: () => addTileCalled = true,
          currentView: AuthorizedRouteTileListPage.Daily,
          onSelectView: (_) {},
        ),
      ));
      await tester.pump();

      final ctx = TutorialKeys.bottomNavAddTileKey.currentContext;
      expect(ctx, isNotNull);
      await tester.tap(find.byKey(TutorialKeys.bottomNavAddTileKey));
      expect(addTileCalled, isTrue,
          reason:
              'The Create-a-Tile step highlights bottomNavAddTileKey, so that '
              'widget must invoke onAddTile when tapped.');
    });
  });
}
