// essentials_onboarding_flow_test.dart
//
// TDD stage 3.1 for the product-tour onboarding redesign
// (product-tour-onboarding-redesign.md): the onboarding flow is reduced to a
// two-page essentials flow. These tests pin the stage-3.1 contract:
//
//   1. The essentials onboarding is exactly TWO pages.
//   2. Page order is Profession first, Location second.
//   3. Progression is blocked until a custom ("Other") profession has at
//      least 3 characters (state-driven, not keyed to a page index).
//   4. Swiping / Next never invokes the geolocator permission flow.
//   5. The geolocator permission flow is invoked ONLY by tapping the
//      in-page "use my device location" button on the Location page, and it
//      records coordinates/timezone without navigating.
//   6. Declining the device location is a no-op (location stays optional) —
//      no error state, no coordinates, no navigation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/components/onBoarding/onBoardingProgressIndicator.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test doubles
// ─────────────────────────────────────────────────────────────────────────────

/// Records every geolocator interaction so tests can assert on which
/// code paths touched the platform. All methods that the onboarding
/// consent flow may call are recorded; anything else throws loudly.
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

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// A bloc in the steady "ready to render page 0" state. No fetch event is
/// added, so no network traffic happens in the tests.
OnboardingBloc _seededBloc() => OnboardingBloc(
      onBoardingApi: OnBoardingApi(),
      settingsApi: SettingsApi(getContextCallBack: () => null),
    );

Widget _wrapOnboarding(OnboardingBloc bloc) => MaterialApp(
      theme: TileThemeData.lightTheme,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      home: OnboardingView(bloc: bloc),
    );

void _mockTimezoneChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (call) async => 'America/New_York',
  );
}

/// The error toast (notification_overlay) runs a 2.5s delayed timer and a
/// 500ms fade-out before removing itself. Advancing time by bounded pumps
/// (instead of pumpAndSettle) guarantees the timer is flushed so it cannot
/// leak past the end of a test.
Future<void> _flushToasts(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pump(const Duration(milliseconds: 600));
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

  group('essentials onboarding flow (stage 3.1)', () {
    testWidgets('essentials onboarding is exactly two pages', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      final indicator = tester
          .widget<OnBoardingProgressIndicator>(
              find.byType(OnBoardingProgressIndicator));
      expect(indicator.totalPages, 2,
          reason: 'The essentials flow must consist of exactly 2 pages.');

      // Page 1 (index 0) is the profession page.
      expect(find.text(l10n.yourProfessionQuestion), findsOneWidget);
      expect(find.text(l10n.primaryLocationQuestion), findsNothing);
    });

    testWidgets('page order is profession then location', (tester) async {
      final geolocator = FakeGeolocatorPlatform(position: _testPosition);
      GeolocatorPlatform.instance = geolocator;
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      // Page 0: profession.
      expect(find.text(l10n.yourProfessionQuestion), findsOneWidget);
      expect(find.text(l10n.primaryLocationQuestion), findsNothing);

      // Next -> page 1: location.
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget);
      expect(find.text(l10n.yourProfessionQuestion), findsNothing);
      expect(find.text(l10n.useDeviceLocation), findsOneWidget,
          reason: 'The location page must expose the device-location button.');
      expect(bloc.state.pageNumber, 1);

      // Merely navigating to the location page must not consent to location.
      expect(geolocator.wasInvoked, isFalse,
          reason: 'Navigation alone must never touch the geolocator.');
    });

testWidgets(
        'progression is blocked until a custom profession has 3 characters',
        (tester) async {
      final geolocator = FakeGeolocatorPlatform(position: _testPosition);
      GeolocatorPlatform.instance = geolocator;
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      // Choose "Other" so the free-text profession field appears.
      // The "Other" row sits below the fold of the page's scroll view, so
      // scroll it into view first.
      await tester.scrollUntilVisible(
        find.text(l10n.other),
        -100.0,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text(l10n.other));
      await tester.pump();
      expect(find.byType(TextField), findsOneWidget);

      // Two characters -> Next is blocked with the validation message.
      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump();

      expect(find.text(l10n.yourProfessionQuestion), findsOneWidget,
          reason: 'Still on the profession page after a blocked Next.');
      expect(find.text(l10n.primaryLocationQuestion), findsNothing);
      expect(find.text(l10n.enter3chars), findsOneWidget,
          reason: 'The 3-character validation message must be shown.');
      expect(geolocator.wasInvoked, isFalse);
      await _flushToasts(tester);

      // Three characters -> Next advances to the location page.
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget);
      expect(bloc.state.pageNumber, 1);
      await _flushToasts(tester);
    });

    testWidgets('swiping to the next page never triggers geolocator',
        (tester) async {
      final geolocator = FakeGeolocatorPlatform(position: _testPosition);
      GeolocatorPlatform.instance = geolocator;
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

      expect(geolocator.checkPermissionCalls, 0);
      expect(geolocator.requestPermissionCalls, 0);
      expect(geolocator.getCurrentPositionCalls, 0);
      expect(geolocator.openLocationSettingsCalls, 0);
      expect(bloc.state.userLatitude, isNull,
          reason: 'A swipe must not fetch device coordinates.');
    });

    testWidgets(
        'device location consent is triggered only by the in-page button',
        (tester) async {
      _mockTimezoneChannel(tester);
      final geolocator = FakeGeolocatorPlatform(position: _testPosition);
      GeolocatorPlatform.instance = geolocator;
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);

      // Being on the location page is not consent.
      expect(geolocator.wasInvoked, isFalse);

      // Tapping the button is.
      await tester.tap(find.text(l10n.useDeviceLocation));
      await tester.pumpAndSettle();

      expect(geolocator.checkPermissionCalls, 1);
      expect(geolocator.requestPermissionCalls, 1);
      expect(geolocator.getCurrentPositionCalls, 1);
      expect(geolocator.openLocationSettingsCalls, 0);

      // Coordinates and timezone are recorded in state.
      expect(bloc.state.userLatitude, '40.7128');
      expect(bloc.state.userLongitude, '-74.006');
      expect(bloc.state.timeZone, 'America/New_York');
      expect(bloc.state.timeZoneOffset, isNotNull);
      expect(bloc.state.step, OnboardingStep.getTimeAndLocation);

      // The button must not navigate: the location page is still showing.
      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget);
      expect(bloc.state.pageNumber, 1);
    });

    testWidgets('declining device location is a no-op and stays on page',
        (tester) async {
      final geolocator = FakeGeolocatorPlatform(
        afterCheck: LocationPermission.denied,
        afterRequest: LocationPermission.denied,
        position: _testPosition,
      );
      GeolocatorPlatform.instance = geolocator;
      final bloc = _seededBloc();

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);

      await tester.tap(find.text(l10n.useDeviceLocation));
      await tester.pumpAndSettle();

      expect(geolocator.checkPermissionCalls, 1);
      expect(geolocator.requestPermissionCalls, 1);
      expect(geolocator.getCurrentPositionCalls, 0,
          reason: 'A declined permission must not attempt a position fix.');
      expect(geolocator.openLocationSettingsCalls, 0);

      expect(bloc.state.userLatitude, isNull);
      expect(bloc.state.step, isNot(OnboardingStep.error),
          reason: 'Declining an optional input must not error the flow.');
      expect(find.text(l10n.primaryLocationQuestion), findsOneWidget,
          reason: 'The flow must remain on the location page.');
    });
  });
}