// welcome_screen_navigation_test.dart
//
// WelcomeScreen is the brand beat between sign-in and the launch gate.
// Stage 4.2 (product-tour-onboarding-redesign.md, Phase 4 item 1) cut its
// hard-coded 3s sleep to a named, short [WelcomeScreen.displayDuration]
// and runs the gate check concurrently with it, so the beat is the only
// thing the user waits for. Locks in:
//   1. The stack is fully cleared on exit (pushAndRemoveUntil) — no SignIn
//      underneath to swipe back to (pre-existing regression tests).
//   2. The screen stays up for exactly displayDuration (≤ 1s), then routes.
//   3. A slow gate check overlaps the beat instead of adding to it.
//   4. Without a checker override the real local gate decides: the legacy
//      skip flag or the essentials done flag -> authorized; neither ->
//      essentials onboarding.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/welcomeScreen.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';

// Lightweight stand-ins so tests don't require real BLoC/service dependencies.
class _FakeAuthorizedPage extends StatelessWidget {
  const _FakeAuthorizedPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('AuthorizedPage'));
}

class _FakeOnboardingPage extends StatelessWidget {
  const _FakeOnboardingPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('OnboardingPage'));
}

class _FakeSignInPage extends StatelessWidget {
  const _FakeSignInPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('SignInPage'));
}

Widget _buildTestApp({
  required GlobalKey<NavigatorState> navigatorKey,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: _FakeSignInPage(),
  );
}

/// Pushes a WelcomeScreen the way sign-in does, with fake destinations.
/// [checker] null -> the production local gate runs against mock prefs.
Future<void> _pushWelcome(
  WidgetTester tester,
  GlobalKey<NavigatorState> navigatorKey, {
  Future<bool> Function()? checker,
  WelcomeType welcomeType = WelcomeType.login,
}) async {
  await tester.pumpWidget(_buildTestApp(navigatorKey: navigatorKey));
  navigatorKey.currentState!.push(
    MaterialPageRoute(
      builder: (_) => WelcomeScreen(
        welcomeType: welcomeType,
        firstName: 'Test',
        onboardingStatusChecker: checker,
        authorizedRouteBuilder: (_) => const _FakeAuthorizedPage(),
        onboardingRouteBuilder: (_) => const _FakeOnboardingPage(),
      ),
    ),
  );
  // Mount WelcomeScreen without advancing the fake clock.
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WelcomeScreen display duration (stage 4.2)', () {
    test('is a short brand beat, not a multi-second sleep', () {
      expect(WelcomeScreen.displayDuration,
          lessThanOrEqualTo(const Duration(seconds: 1)),
          reason: 'The gate is a local read and the schedule is prefetched; '
              'anything longer just delays the schedule.');
      expect(WelcomeScreen.displayDuration, greaterThan(Duration.zero));
    });

    testWidgets('stays on screen for the full beat, then routes',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await _pushWelcome(tester, navigatorKey, checker: () async => true);
      await tester.pump(const Duration(milliseconds: 300)); // route transition

      // Just short of the beat: still the welcome screen.
      await tester.pump(
          WelcomeScreen.displayDuration - const Duration(milliseconds: 350));
      await tester.pump();
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('AuthorizedPage'), findsNothing);

      // The beat elapses: routed.
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      expect(find.text('AuthorizedPage'), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    });

    testWidgets('a slow gate check overlaps the beat instead of adding to it',
        (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final slowCheck =
          WelcomeScreen.displayDuration - const Duration(milliseconds: 100);
      await _pushWelcome(tester, navigatorKey,
          checker: () => Future.delayed(slowCheck, () => true));

      // Only the beat has to elapse, even though the check took almost as
      // long: total wait == max(beat, check), never beat + check.
      await tester.pump(WelcomeScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('AuthorizedPage'), findsOneWidget);
    });
  });

  group('WelcomeScreen routes by the local gate (stage 4.2)', () {
    testWidgets('essentialsOnboardingDone -> authorized app', (tester) async {
      SharedPreferences.setMockInitialValues({
        OnBoardingSharedPreferencesHelper.essentialsOnboardingDoneKey: true,
      });
      final navigatorKey = GlobalKey<NavigatorState>();
      await _pushWelcome(tester, navigatorKey); // real gate

      await tester.pump(WelcomeScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('AuthorizedPage'), findsOneWidget);
    });

    testWidgets('legacy skipOnboarding -> authorized app', (tester) async {
      SharedPreferences.setMockInitialValues({'skipOnboarding': true});
      final navigatorKey = GlobalKey<NavigatorState>();
      await _pushWelcome(tester, navigatorKey);

      await tester.pump(WelcomeScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('AuthorizedPage'), findsOneWidget);
    });

    testWidgets('fresh device -> essentials onboarding', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await _pushWelcome(tester, navigatorKey,
          welcomeType: WelcomeType.register);

      await tester.pump(WelcomeScreen.displayDuration);
      await tester.pumpAndSettle();
      expect(find.text('OnboardingPage'), findsOneWidget);
      expect(navigatorKey.currentState!.canPop(), isFalse);
    });
  });

  group('WelcomeScreen navigation', () {
    testWidgets(
      'clears navigation stack so AuthorizedPage cannot be swiped back to SignIn',
      (WidgetTester tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(_buildTestApp(
          navigatorKey: navigatorKey,
        ));

        // Simulate what happens after sign-in: SignIn pushes WelcomeScreen.
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              welcomeType: WelcomeType.login,
              firstName: 'Test',
              onboardingStatusChecker: () async => true,
              authorizedRouteBuilder: (_) => const _FakeAuthorizedPage(),
              onboardingRouteBuilder: (_) => const _FakeOnboardingPage(),
            ),
          ),
        );

        // Pump one frame to mount WelcomeScreen without advancing the fake
        // clock past the display beat.
        await tester.pump();

        // Advance past the display beat and let navigation settle.
        await tester.pump(WelcomeScreen.displayDuration);
        await tester.pumpAndSettle();

        // Regression assertion: the stack must be fully cleared.
        // If Navigator.pop+push was used instead of pushAndRemoveUntil,
        // SignInPage would still be on the stack and canPop() would be true.
        expect(navigatorKey.currentState!.canPop(), isFalse,
            reason:
                'AuthorizedPage must be the only route — no SignIn underneath to swipe back to');

        expect(find.text('AuthorizedPage'), findsOneWidget);
      },
    );

    testWidgets(
      'clears navigation stack and shows OnboardingPage when onboarding not complete',
      (WidgetTester tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();

        await tester.pumpWidget(_buildTestApp(
          navigatorKey: navigatorKey,
        ));

        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => WelcomeScreen(
              welcomeType: WelcomeType.register,
              firstName: 'New User',
              onboardingStatusChecker: () async => false,
              authorizedRouteBuilder: (_) => const _FakeAuthorizedPage(),
              onboardingRouteBuilder: (_) => const _FakeOnboardingPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        await tester.pump(WelcomeScreen.displayDuration);
        await tester.pumpAndSettle();

        expect(navigatorKey.currentState!.canPop(), isFalse,
            reason:
                'OnboardingPage must be the only route — no SignIn underneath');

        expect(find.text('OnboardingPage'), findsOneWidget);
      },
    );
  });
}
