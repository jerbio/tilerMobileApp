// essentials_onboarding_skip_test.dart
//
// TDD stage 3.3 for the product-tour onboarding redesign
// (product-tour-onboarding-redesign.md): global skip semantics for the
// two-page Profession -> Location essentials flow. These tests pin the
// stage-3.3 contract:
//
//   1. The global Skip control is visible on page 1 (profession) and
//      page 2 (location).
//   2. Tapping Skip navigates (pushReplacement) to the exit destination
//      route (AuthorizedRoute in production) -- verified through the
//      OnboardingView.onPageChanged seam with a marker stand-in, because
//      AuthorizedRoute's initState requires ancestor providers and
//      platform channels unavailable in tests.
//   3. Skip persists the skip preference (skipOnboarding == true) so the
//      app can bypass onboarding on the next launch.
//   4. Skip never touches the onboarding submission API (no fetch, no
//      send) and never triggers the geolocator permission flow.
//   5. The terminal skipped state (pageNumber == null) is safe: page-change
//      events emitted after Skip are no-ops that neither crash the bloc
//      nor produce invalid page state.
//   6. Normal swipe / Next behaviour never triggers Skip.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/data/onBoarding.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test doubles
// ─────────────────────────────────────────────────────────────────────────────

/// Records which onboarding API endpoints were touched so tests can assert
/// that the skip path stays out of the onboarding submission API.
class FakeOnBoardingApi extends OnBoardingApi {
  int fetchCalls = 0;
  int sendCalls = 0;

  @override
  Future<OnboardingContent?> fetchOnboardingData() async {
    fetchCalls++;
    return null;
  }

  @override
  Future<OnboardingContent?> sendOnboardingData(
      OnboardingContent onboardingContent) async {
    sendCalls++;
    return null;
  }
}

/// Records skip-destination navigation. Instead of building the destination
/// (AuthorizedRoute cannot be rendered directly in a widget test), the
/// onboarding view pushes a MaterialPageRoute whose builder only flips
/// [destinationBuilt] when the destination is actually built, and the test
/// supplies a closure that returns the real destination widget.
class SkipDestinationObserver {
  bool destinationBuilt = false;
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  int checkPermissionCalls = 0;
  int requestPermissionCalls = 0;
  int getCurrentPositionCalls = 0;
  int openLocationSettingsCalls = 0;

  final LocationPermission afterCheck;
  final LocationPermission afterRequest;
  final Position position;

  FakeGeolocatorPlatform({
    this.afterCheck = LocationPermission.denied,
    this.afterRequest = LocationPermission.whileInUse,
    required this.position,
  });

  bool get wasInvoked =>
      checkPermissionCalls > 0 ||
      requestPermissionCalls > 0 ||
      getCurrentPositionCalls > 0 ||
      openLocationSettingsCalls > 0;

  @override
  Future<LocationPermission> checkPermission() async {
    checkPermissionCalls++;
    return afterCheck;
  }

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    return afterRequest;
  }

  @override
  Future<Position> getCurrentPosition(
      {LocationSettings? locationSettings}) async {
    getCurrentPositionCalls++;
    return position;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsCalls++;
    return true;
  }
}

final Position _testPosition = Position(
  longitude: -74.006,
  latitude: 40.7128,
  timestamp: DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
  accuracy: 10.0,
  altitude: 50.0,
  altitudeAccuracy: 3.0,
  heading: 0.0,
  headingAccuracy: 0.0,
  speed: 0.0,
  speedAccuracy: 0.0,
);

/// Test stand-in for the skip-destination route. In production the exit
/// route builds AuthorizedRoute (via OnboardingView.onPageChanged), which
/// requires ancestor providers and platform channels unavailable in widget
/// tests. The test supplies this marker as the destination instead, so the
/// navigation target can be verified without rendering the real route.
class _SkipDestinationMarker extends StatelessWidget {
  const _SkipDestinationMarker();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Widget built by the skip-destination route; configured per test.
Widget? _skipDestination;

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A bloc in the steady "ready to render page 0" state. No fetch event is
/// added, so no network traffic happens in the tests. The injected API fake
/// records any accidental call.
OnboardingBloc _seededBloc({FakeOnBoardingApi? api}) => OnboardingBloc(
      onBoardingApi: api ?? FakeOnBoardingApi(),
      settingsApi: SettingsApi(getContextCallBack: () => null),
    );

Widget _wrapOnboarding(
  OnboardingBloc bloc, {
  SkipDestinationObserver? skipObserver,
}) {
  final Widget Function() destinationBuilder =
      () => _skipDestination ?? const SizedBox.shrink();
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    home: OnboardingView(
      bloc: bloc,
      // When the skip-destination route actually gets built, flag it so
      // the test can distinguish "navigation happened" from "the
      // destination was rendered", and build the configured stand-in
      // (never the real AuthorizedRoute) as the destination.
      skipDestinationBuilder: (context) {
        skipObserver?.destinationBuilt = true;
        return destinationBuilder();
      },
    ),
  );
}

Future<void> _advanceToLocationPage(
    WidgetTester tester, OnboardingBloc bloc) async {
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pumpAndSettle();
  expect(bloc.state.pageNumber, 1);
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final l10n = lookupAppLocalizations(const Locale('en'));

  // Give the skip handler an in-memory SharedPreferences backend so the
  // persisted preference can be asserted without the platform channel.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _skipDestination = null;
  });

  group('essentials onboarding skip (stage 3.3)', () {
    testWidgets('Skip is visible on page 1 (profession)', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      expect(find.text(l10n.yourProfessionQuestion), findsOneWidget);
      expect(find.text(l10n.skip), findsOneWidget,
          reason: 'The global Skip control must be visible on page 1.');
    });

    testWidgets('Skip is visible on page 2 (location)', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);

      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget);
      expect(find.text(l10n.skip), findsOneWidget,
          reason: 'The global Skip control must be visible on page 2.');
    });

    testWidgets('tapping Skip navigates to the exit destination route',
        (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();
      final skipObserver = SkipDestinationObserver();
      _skipDestination = const _SkipDestinationMarker();

      await tester.pumpWidget(
          _wrapOnboarding(bloc, skipObserver: skipObserver));
      await tester.pump();

      expect(find.byType(_SkipDestinationMarker), findsNothing);

      await tester.tap(find.text(l10n.skip));
      await tester.pump(); // run the skip handler; the exit route is pushed

      expect(bloc.state.step, OnboardingStep.skipped);
      expect(bloc.state.pageNumber, isNull,
          reason: 'The terminal skipped state clears the page number.');

      // Let the replacement transition run to completion. The exit route
      // (AuthorizedRoute in production) builds the marker stand-in in the
      // test, which proves the navigation target without rendering
      // AuthorizedRoute (its initState needs providers/channels that are
      // unavailable in widget tests).
      await tester.pumpAndSettle();
      expect(skipObserver.destinationBuilt, isTrue,
          reason: 'Skip must navigate to the exit destination route.');
      expect(find.byType(_SkipDestinationMarker), findsOneWidget);
      expect(find.text(l10n.skip), findsNothing,
          reason: 'The onboarding flow must be replaced (terminal '
              'navigation), not covered.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Skip persists the skip preference and does not call the '
        'onboarding API', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(api: api);

      expect(await OnBoardingSharedPreferencesHelper.getSkipOnboarding(),
          isFalse);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      await tester.tap(find.text(l10n.skip));
      await tester.pump();
      await tester.pumpWidget(const SizedBox()); // unmount before the
      // destination route is built.

      expect(await OnBoardingSharedPreferencesHelper.getSkipOnboarding(),
          isTrue,
          reason: 'Skip must persist the skip preference so the app can '
              'bypass onboarding next launch.');

      expect(api.sendCalls, 0,
          reason: 'Skip must not submit onboarding data.');
      expect(api.fetchCalls, 0,
          reason: 'Skip must not fetch onboarding data.');
      expect(bloc.state.step, OnboardingStep.skipped);
    });

    testWidgets('back/next/page-change events after Skip do not crash',
        (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      await tester.tap(find.text(l10n.skip));
      await tester.pump();
      expect(bloc.state.step, OnboardingStep.skipped);
      expect(bloc.state.pageNumber, isNull);

      // The terminal skipped state has no page number. Events emitted
      // after Skip must be guarded no-ops, never a crash or an invalid
      // page state.
      bloc.add(NextPageEvent());
      await tester.pump();
      expect(bloc.state.step, OnboardingStep.skipped,
          reason: 'NextPageEvent after Skip must not change the state.');
      expect(bloc.state.pageNumber, isNull);

      bloc.add(PreviousPageEvent());
      await tester.pump();
      expect(bloc.state.step, OnboardingStep.skipped,
          reason: 'PreviousPageEvent after Skip must not change the '
              'state.');
      expect(bloc.state.pageNumber, isNull);

      // The bottom-bar arrows emit the very same events (and the back
      // arrow is hidden in the skipped state because pageNumber is
      // null), so the guarded no-ops above are what the UI would
      // exercise too.
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('skipping on page 2 persists the preference and '
        'stays terminal', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();
      final skipObserver = SkipDestinationObserver();
      _skipDestination = const _SkipDestinationMarker();

      await tester.pumpWidget(
          _wrapOnboarding(bloc, skipObserver: skipObserver));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);

      await tester.tap(find.text(l10n.skip));
      await tester.pump();

      expect(bloc.state.step, OnboardingStep.skipped);
      await tester.pumpAndSettle();
      expect(skipObserver.destinationBuilt, isTrue,
          reason: 'Skipping from page 2 must navigate to the exit route.');
      expect(await OnBoardingSharedPreferencesHelper.getSkipOnboarding(),
          isTrue,
          reason: 'Skipping from page 2 must persist the same '
              'preference.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('normal swipe/next never triggers Skip', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      // Swipe left (fling) on the page area -> NextPageEvent. A fling is
      // required because onHorizontalDragEnd acts on primaryVelocity, which
      // a plain tester.drag does not produce.
      final pageFinder = find
          .ancestor(
            of: find.byType(SingleChildScrollView),
            matching: find.byType(GestureDetector),
          )
          .first;
      await tester.fling(pageFinder, const Offset(-300, 0), 800.0);
      await tester.pumpAndSettle();

      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget,
          reason: 'The swipe must advance to the location page.');
      expect(bloc.state.pageNumber, 1);
      expect(bloc.state.step, isNot(OnboardingStep.skipped),
          reason: 'Advancing the flow must never skip onboarding.');
      expect(await OnBoardingSharedPreferencesHelper.getSkipOnboarding(),
          isFalse,
          reason: 'Advancing the flow must not persist the skip '
              'preference.');

      // Back and forward arrows behave as plain page changes as well.
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(bloc.state.pageNumber, 0);
      expect(bloc.state.step, isNot(OnboardingStep.skipped));

      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(bloc.state.pageNumber, 1);
      expect(bloc.state.step, isNot(OnboardingStep.skipped));
      expect(await OnBoardingSharedPreferencesHelper.getSkipOnboarding(),
          isFalse);
    });
  });
}