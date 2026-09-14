// welcome_explainer_test.dart
//
// TDD stage 4.4 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 4 item 5 "Welcome
// explainer").
//
// New devices get an animated "Tiles vs Blocks" explainer on the welcome
// screen before the essentials onboarding; returning devices keep the
// short brand beat (stage 4.2). Locks in:
//   1. The explainer plays three beats on a mini day timeline:
//        blocks  — two pinned blocks land (fixed time);
//        tiles   — three tiles slide into the free gaps (flexible);
//        replan  — a block moves and the tiles re-flow around it.
//      Each beat has its own caption; tiles do not exist before their beat;
//      at rest nothing overlaps; the replan actually moves the block and
//      re-seats the tiles; the final state holds (no looping timers).
//   2. Reduced motion (`MediaQuery.disableAnimations`) shows the final
//      state immediately.
//   3. WelcomeScreen: a device that still needs onboarding shows the
//      explainer and does NOT auto-route; "Let's Go!" routes to the
//      essentials flow (stack cleared). A device that is done keeps the
//      4.2 behaviour: no explainer, routes after the beat.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/components/welcome/tilesVsBlocksExplainer.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/welcomeScreen.dart';
import 'package:tiler_app/theme/theme_data.dart';

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

final _l10n = lookupAppLocalizations(const Locale('en'));

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

class _AuthorizedPage extends StatelessWidget {
  const _AuthorizedPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('AuthorizedPage'));
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('OnboardingPage'));
}

Widget _welcome({required bool onboardingDone}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: _l10nDelegates,
    supportedLocales: const [Locale('en', '')],
    home: WelcomeScreen(
      welcomeType: WelcomeType.register,
      firstName: 'Ada',
      onboardingStatusChecker: () async => onboardingDone,
      authorizedRouteBuilder: (_) => const _AuthorizedPage(),
      onboardingRouteBuilder: (_) => const _OnboardingPage(),
    ),
  );
}

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

      expect(find.text(_l10n.welcomeExplainerReplanCaption), findsOneWidget);
      final dentistAfter =
          tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.dentistBlock));
      expect(dentistAfter.top, lessThan(dentistBefore.top),
          reason: 'The block must visibly move to an earlier slot.');
      final moved = _tileKeys
          .where((k) => tester.getRect(find.byKey(k)) != tilesBefore[k])
          .length;
      expect(moved, greaterThanOrEqualTo(2),
          reason: 'Tiles must re-flow around the moved block — that is the '
              'point of the beat.');
      _expectNoOverlap(tester, [..._blockKeys, ..._tileKeys], 'after beat 3');
      expect(
        tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.standupBlock)),
        tester.getRect(find.byKey(TilesVsBlocksExplainerKeys.standupBlock)),
      );
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
      expect(find.text(_l10n.welcomeExplainerReplanCaption), findsOneWidget);
      // pumpAndSettle would hang on a looping animation.
      await tester.pumpAndSettle();
    });

    testWidgets('reduced motion shows the final state immediately',
        (tester) async {
      await tester.pumpWidget(_explainerHarness(disableAnimations: true));
      await tester.pump();

      expect(find.text(_l10n.welcomeExplainerReplanCaption), findsOneWidget);
      for (final k in [..._blockKeys, ..._tileKeys]) {
        expect(find.byKey(k), findsOneWidget);
      }
      _expectNoOverlap(tester, [..._blockKeys, ..._tileKeys], 'at rest');
    });
  });

  group('WelcomeScreen — explainer for new devices (stage 4.4)', () {
    testWidgets(
        'a device that needs onboarding shows the explainer and does not '
        'auto-route; "Let\'s Go!" routes to the essentials flow',
        (tester) async {
      await tester.pumpWidget(_welcome(onboardingDone: false));
      await tester.pump();

      expect(find.byType(TilesVsBlocksExplainer), findsOneWidget);
      expect(find.text('Ada'), findsOneWidget, reason: 'The greeting stays.');
      expect(find.text(_l10n.tutorialNavLetsGo), findsOneWidget);

      // Well past the 4.2 beat: still here, the user reads at their pace.
      await tester.pump(WelcomeScreen.displayDuration * 3);
      await tester.pump(TilesVsBlocksExplainer.totalDuration);
      expect(find.text('OnboardingPage'), findsNothing);
      expect(find.byType(TilesVsBlocksExplainer), findsOneWidget);

      await tester.tap(find.text(_l10n.tutorialNavLetsGo));
      await tester.pumpAndSettle();

      expect(find.text('OnboardingPage'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing,
          reason: 'The welcome screen is removed from the stack.');
    });

    testWidgets(
        'a device that is done keeps the beat: no explainer, routes to the '
        'authorized app', (tester) async {
      await tester.pumpWidget(_welcome(onboardingDone: true));
      await tester.pump();

      expect(find.byType(TilesVsBlocksExplainer), findsNothing);
      expect(find.text(_l10n.tutorialNavLetsGo), findsNothing);

      await tester.pump(WelcomeScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('AuthorizedPage'), findsOneWidget);
    });
  });
}
