// welcome_explainer_test.dart
//
// TDD stage 4.4 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 4 item 5 "Welcome
// explainer").
//
// After the essentials pages (profession, location) — on Submit and on
// Skip alike — the user sees an animated "Tiles vs Blocks" demo before the
// schedule. Locks in:
//   1. The explainer plays three beats on a mini day timeline:
//        blocks  — two pinned blocks land (fixed time);
//        tiles   — three tiles slide into the free gaps (flexible);
//        replan  — a block moves and the tiles re-flow around it. The
//                  moving block announces itself ("Moved" badge from the
//                  start of the beat) and the caption names it and its new
//                  time, so the user sees the cause before the effect. Each
//                  tile Tiler re-seats picks up a Tiler mark ("Re-planned"
//                  + the app's AI glyph) as it moves; a tile Tiler leaves
//                  alone gets none.
//      Each beat has its own caption; tiles do not exist before their beat;
//      at rest nothing overlaps; the replan actually moves the block and
//      re-seats the tiles; the final state holds (no looping timers).
//   2. Reduced motion (`MediaQuery.disableAnimations`) shows the final
//      state immediately.
//   3. OnboardingExplainerScreen: shows headline + explainer + "Let's Go!";
//      never auto-routes; "Let's Go!" replaces the whole stack with the
//      destination (no onboarding underneath to go back to).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/welcome/tilesVsBlocksExplainer.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final _l10n = lookupAppLocalizations(const Locale('en'));

/// The re-plan caption names the dentist's new slot in the device's time
/// format (11:00 in the demo).
final String _replanCaption = _l10n.welcomeExplainerReplanCaption(
    const DefaultMaterialLocalizations()
        .formatTimeOfDay(const TimeOfDay(hour: 11, minute: 0)));

Widget _explainerHarness({bool disableAnimations = false}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: _l10nDelegates,
    supportedLocales: const [Locale('en', '')],
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        disableAnimations: disableAnimations,
      ),
      child: const Scaffold(
        body: Center(
          child: SizedBox(
            width: 340,
            height: 360,
            child: TilesVsBlocksExplainer(),
          ),
        ),
      ),
    ),
  );
}

/// Advances [beats] beats from wherever the clock is, ending 50ms short of
/// the boundary so assertions see the beat settled rather than the first
/// frame of the next one. Two pumps: the caption's AnimatedSwitcher only
/// notices a beat change on a built frame, so the first pump lets it see
/// the change and the later pumps let its cross-fade finish and clear.
Future<void> _pumpBeats(WidgetTester tester, int beats) async {
  await tester.pump(TilesVsBlocksExplainer.beatDuration * beats -
      const Duration(milliseconds: 450));
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump(const Duration(milliseconds: 50));
}

const _blockKeys = [
  TilesVsBlocksExplainerKeys.standupBlock,
  TilesVsBlocksExplainerKeys.dentistBlock,
];
const _tileKeys = [
  TilesVsBlocksExplainerKeys.workoutTile,
  TilesVsBlocksExplainerKeys.reportTile,
  TilesVsBlocksExplainerKeys.groceriesTile,
];

void _expectNoOverlap(WidgetTester tester, List<Key> keys, String when) {
  final rects = {for (final k in keys) k: tester.getRect(find.byKey(k))};
  for (final a in keys) {
    for (final b in keys) {
      if (a == b) continue;
      expect(rects[a]!.overlaps(rects[b]!), isFalse,
          reason: '$a and $b overlap $when — the timeline would read as '
              'double-booked.');
    }
  }
}

class _DestinationPage extends StatelessWidget {
  const _DestinationPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('DestinationPage'));
}

class _QuestionsPage extends StatelessWidget {
  const _QuestionsPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('QuestionsPage'));
}

/// Mounts the demo route the way OnboardingView pushes it: replacing the
/// questions, with the app as the destination.
Future<GlobalKey<NavigatorState>> _pushExplainer(WidgetTester tester) async {
  final navigatorKey = GlobalKey<NavigatorState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: navigatorKey,
    theme: TileThemeData.lightTheme,
    localizationsDelegates: _l10nDelegates,
    supportedLocales: const [Locale('en', '')],
    home: const _QuestionsPage(),
  ));
  navigatorKey.currentState!.pushReplacement(MaterialPageRoute(
    builder: (_) => const OnboardingExplainerScreen(
      destinationBuilder: _buildDestination,
    ),
  ));
  await tester.pumpAndSettle();
  return navigatorKey;
}

Widget _buildDestination(BuildContext _) => const _DestinationPage();

void main() {
  group('TilesVsBlocksExplainer — three beats', () {
    testWidgets('beat 1: blocks land with the "fixed" caption; no tiles yet',
        (tester) async {
      await tester.pumpWidget(_explainerHarness());
      await _pumpBeats(tester, 1);

      expect(find.text(_l10n.welcomeExplainerBlocksCaption), findsOneWidget);
      for (final k in _blockKeys) {
        expect(find.byKey(k), findsOneWidget);
      }
      for (final k in _tileKeys) {
        expect(find.byKey(k), findsNothing,
            reason: 'Tiles only appear in beat 2.');
      }
      expect(find.text(_l10n.welcomeExplainerBlockStandup), findsOneWidget);
      expect(find.text(_l10n.welcomeExplainerBlockDentist), findsOneWidget);
    });

    testWidgets(
        'beat 2: tiles slide into the gaps with the "flexible" caption; '
        'nothing overlaps', (tester) async {
      await tester.pumpWidget(_explainerHarness());
      await _pumpBeats(tester, 2);

      expect(find.text(_l10n.welcomeExplainerTilesCaption), findsOneWidget);
      expect(find.text(_l10n.welcomeExplainerBlocksCaption), findsNothing);
      for (final k in _tileKeys) {
        expect(find.byKey(k), findsOneWidget);
      }
      _expectNoOverlap(tester, [..._blockKeys, ..._tileKeys], 'after beat 2');
      expect(find.text(_l10n.welcomeExplainerMovedBadge), findsNothing,
          reason: 'Nothing has moved yet.');
      expect(find.text(_l10n.welcomeExplainerReplannedBadge), findsNothing,
          reason: 'Tiler has not re-planned anything yet.');
    });

    testWidgets(
        'beat 3: the dentist block moves earlier and the tiles re-seat '
        'around it with the "re-plan" caption', (tester) async {
      await tester.pumpWidget(_explainerHarness());
      await _pumpBeats(tester, 2);
      final dentistBefore =
          tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.dentistBlock));
      final tilesBefore = {
        for (final k in _tileKeys) k: tester.getRect(find.byKey(k))
      };

      await _pumpBeats(tester, 1);

      expect(find.text(_replanCaption), findsOneWidget,
          reason: 'The caption must say which block changed and to when.');
      expect(
        find.descendant(
            of: find.byKey(TilesVsBlocksExplainerKeys.dentistBlock),
            matching: find.text(_l10n.welcomeExplainerMovedBadge)),
        findsOneWidget,
        reason: 'The block that changed must announce it on the card.',
      );
      final dentistAfter =
          tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.dentistBlock));
      expect(dentistAfter.top, lessThan(dentistBefore.top),
          reason: 'The block must visibly move to an earlier slot.');
      final moved = _tileKeys
          .where((k) => tester.getRect(find.byKey(k)) != tilesBefore[k])
          .toList();
      expect(moved.length, greaterThanOrEqualTo(2),
          reason: 'Tiles must re-flow around the moved block — that is the '
              'point of the beat.');
      for (final k in _tileKeys) {
        final mark = find.descendant(
            of: find.byKey(k),
            matching: find.text(_l10n.welcomeExplainerReplannedBadge));
        expect(mark, moved.contains(k) ? findsOneWidget : findsNothing,
            reason: moved.contains(k)
                ? 'A tile Tiler re-seated must carry the Tiler mark.'
                : 'A tile Tiler left alone must not claim to be re-planned.');
      }
      expect(find.byIcon(Icons.auto_awesome), findsNWidgets(moved.length),
          reason: 'The mark uses the app\'s own AI glyph, one per re-seated '
              'tile.');
      _expectNoOverlap(tester, [..._blockKeys, ..._tileKeys], 'after beat 3');
      expect(
        tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.standupBlock)),
        tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.standupBlock)),
      );
    });

    testWidgets(
        'the "Moved" badge appears before the dentist block starts moving',
        (tester) async {
      await tester.pumpWidget(_explainerHarness());
      await _pumpBeats(tester, 2);
      final before =
          tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.dentistBlock));

      // Just inside beat 3: the badge is up, the card has not moved yet.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      expect(find.text(_l10n.welcomeExplainerMovedBadge), findsOneWidget,
          reason: 'Announce the change before showing it.');
      expect(
        tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.dentistBlock)).top,
        before.top,
        reason: 'The move starts only after the badge has landed.',
      );
      expect(find.text(_l10n.welcomeExplainerReplannedBadge), findsNothing,
          reason: 'Tiler re-plans in response to the change, so the marks '
              'come after the block has moved, never before.');
    });

    testWidgets('holds the final state — no looping timers', (tester) async {
      await tester.pumpWidget(_explainerHarness());
      await _pumpBeats(tester, 3);
      final rects = {
        for (final k in [..._blockKeys, ..._tileKeys])
          k: tester.getRect(find.byKey(k))
      };

      await tester.pump(const Duration(seconds: 5));

      for (final k in rects.keys) {
        expect(tester.getRect(find.byKey(k)), rects[k],
            reason: 'The explainer must settle, not loop.');
      }
      expect(find.text(_replanCaption), findsOneWidget);
      // pumpAndSettle would hang on a looping animation.
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion shows the final state immediately',
        (tester) async {
      await tester.pumpWidget(_explainerHarness(disableAnimations: true));
      await tester.pump();

      expect(find.text(_replanCaption), findsOneWidget);
      expect(find.text(_l10n.welcomeExplainerMovedBadge), findsOneWidget);
      expect(find.text(_l10n.welcomeExplainerReplannedBadge), findsNWidgets(2),
          reason: 'Final frame: the two re-seated tiles carry the mark.');
      for (final k in [..._blockKeys, ..._tileKeys]) {
        expect(find.byKey(k), findsOneWidget);
      }
      _expectNoOverlap(tester, [..._blockKeys, ..._tileKeys], 'at rest');
    });
  });

  group('OnboardingExplainerScreen — after the essentials pages (4.4)', () {
    testWidgets(
        "shows the headline, the demo and Let's Go, and never auto-routes",
        (tester) async {
      await _pushExplainer(tester);

      expect(find.byType(TilesVsBlocksExplainer), findsOneWidget);
      expect(find.text(_l10n.welcomeExplainerHeadline), findsOneWidget);
      expect(find.text(_l10n.tutorialNavLetsGo), findsOneWidget);
      expect(find.text('QuestionsPage'), findsNothing,
          reason: 'The questions are replaced, not covered.');

      // Long after the demo has settled the user is still here.
      await tester.pump(TilesVsBlocksExplainer.totalDuration * 2);
      expect(find.text('DestinationPage'), findsNothing);
      expect(find.byType(OnboardingExplainerScreen), findsOneWidget);
    });

    testWidgets("Let's Go replaces the stack with the destination",
        (tester) async {
      final navigatorKey = await _pushExplainer(tester);

      await tester.tap(find.text(_l10n.tutorialNavLetsGo));
      await tester.pumpAndSettle();

      expect(find.text('DestinationPage'), findsOneWidget);
      expect(find.byType(OnboardingExplainerScreen), findsNothing);
      expect(navigatorKey.currentState!.canPop(), isFalse,
          reason: 'Nothing underneath to go back to — no demo, no '
              'questions.');
    });
  });
}
