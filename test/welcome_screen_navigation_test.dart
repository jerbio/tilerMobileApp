import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/welcomeScreen.dart';

// Lightweight stand-ins so tests don't require real BLoC/service dependencies.
class _FakeAuthorizedPage extends StatelessWidget {
  const _FakeAuthorizedPage();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('AuthorizedPage'));
}

class _FakeOnboardingPage extends StatelessWidget {
  const _FakeOnboardingPage();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('OnboardingPage'));
}

class _FakeSignInPage extends StatelessWidget {
  const _FakeSignInPage();
  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('SignInPage'));
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

void main() {
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

        // Pump one frame to mount WelcomeScreen without advancing the fake clock
        // past the 3-second delay.
        await tester.pump();

        // Advance past the 3-second delay and let navigation settle.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        // Regression assertion: the stack must be fully cleared.
        // If Navigator.pop+push was used instead of pushAndRemoveUntil,
        // SignInPage would still be on the stack and canPop() would be true.
        expect(navigatorKey.currentState!.canPop(), isFalse,
            reason: 'AuthorizedPage must be the only route — no SignIn underneath to swipe back to');

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
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        expect(navigatorKey.currentState!.canPop(), isFalse,
            reason: 'OnboardingPage must be the only route — no SignIn underneath');

        expect(find.text('OnboardingPage'), findsOneWidget);
      },
    );
  });
}
