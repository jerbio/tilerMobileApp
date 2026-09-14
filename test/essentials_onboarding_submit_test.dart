// essentials_onboarding_submit_test.dart
//
// TDD stage 3.4 for the product-tour onboarding redesign
// (product-tour-onboarding-redesign.md): atomic submit for the two-page
// Profession -> Location essentials flow. These tests pin the stage-3.4
// contract:
//
//   1. Submit is only available on page 2 -- the page-1 Next merely
//      advances and never sends.
//   2. Submit sends the essentials payload only: profession + primary
//      location (+ optional device coords / timezone when captured).
//      The legacy payload fields (hours, day sections, recurring tasks,
//      suggestion tiles, usage) are no longer collected and must not be
//      sent. No fetch happens on submit.
//   3. Submit never triggers the intro slider (the legacy slider was cut
//      from the essentials flow and deleted in stage 4.3); the exit is
//      the Tiles vs Blocks demo.
//   4. On success, submit navigates (pushReplacement) directly to the
//      exit destination route (AuthorizedRoute in production) -- verified
//      through the OnboardingView.submitDestinationBuilder seam with a
//      marker stand-in, because AuthorizedRoute's initState needs
//      ancestor providers and platform channels unavailable in tests.
//   5. On success, submit persists the local essentialsOnboardingDone
//      flag (the skip preference is not written) and buzzes the schedule
//      exactly once.
//   6. A failed submit stays in the flow: the existing error/toast path,
//      the location page remains, Skip stays available, no navigation, no
//      buzz, no retry, flag not set.
//
// Test mechanics: the submit handler waits 700ms (the text-change
// debounce, Constants.onTextChangeDelayInMs) before sending, so the tests
// advance the fake clock with bounded pumps (never pumpAndSettle while
// the 2.5s toast timer is live).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/data/onBoarding.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tiler_app/theme/theme_data.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Records which onboarding API endpoints were touched and captures the
/// submit payload so tests can assert the essentials payload shape
/// (profession + location only) and that submit never triggers a fetch.
class FakeOnBoardingApi extends OnBoardingApi {
  int fetchCalls = 0;
  int sendCalls = 0;
  OnboardingContent? lastPayload;

  /// When non-null, [sendOnboardingData] throws a [TilerError] with this
  /// message (the failed-submit path).
  final String? sendErrorMessage;

  FakeOnBoardingApi({this.sendErrorMessage});

  @override
  Future<OnboardingContent?> fetchOnboardingData() async {
    fetchCalls++;
    return null;
  }

  @override
  Future<OnboardingContent?> sendOnboardingData(
      OnboardingContent onboardingContent) async {
    sendCalls++;
    lastPayload = onboardingContent;
    if (sendErrorMessage != null) {
      throw TilerError(Message: sendErrorMessage!);
    }
    return null;
  }
}

/// Records buzz-schedule calls. Overrides [ScheduleApi.buzzSchedule] so the
/// submit path never performs a real network request in tests.
class FakeScheduleApi extends ScheduleApi {
  int buzzCalls = 0;

  FakeScheduleApi() : super(getContextCallBack: () => null);

  @override
  Future buzzSchedule() async {
    buzzCalls++;
  }
}

/// Records submit-destination navigation. Instead of building the
/// destination (AuthorizedRoute cannot be rendered directly in a widget
/// test), the onboarding view pushes a MaterialPageRoute whose builder
/// only flips [destinationBuilt] when the destination is actually built,
/// and the test supplies a closure that returns the real destination
/// widget.
class SubmitDestinationObserver {
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

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

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

/// Test stand-in for the submit-destination route. In production the exit
/// route builds AuthorizedRoute (via
/// OnboardingView.submitDestinationBuilder), which requires ancestor
/// providers and platform channels unavailable in widget tests. The test
/// supplies this marker as the destination instead, so the navigation
/// target can be verified without rendering the real route.
class _SubmitDestinationMarker extends StatelessWidget {
  const _SubmitDestinationMarker();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// Widget built by the submit-destination route; configured per test.
Widget? _submitDestination;

/// Bloc the production route would create: a real API (never called -- no
/// test adds a fetch event) and an in-memory settings API.
OnboardingBloc _seededBloc({OnBoardingApi? onBoardingApi}) {
  return OnboardingBloc(
      onBoardingApi: onBoardingApi ?? OnBoardingApi(),
      settingsApi: SettingsApi(getContextCallBack: () => null));
}

Widget _wrapOnboarding(
  OnboardingBloc bloc, {
  FakeScheduleApi? scheduleApi,
  SubmitDestinationObserver? submitObserver,
}) {
  final Widget Function() destinationBuilder =
      () => _submitDestination ?? const SizedBox.shrink();
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
      // Seam: tests never touch the real schedule API on submit.
      scheduleApi: scheduleApi ?? FakeScheduleApi(),
      submitDestinationBuilder: (context) {
        submitObserver?.destinationBuilt = true;
        return destinationBuilder();
      },
    ),
  );
}

void _mockTimezoneChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (call) async => 'America/New_York',
  );
}

/// Advances from the profession page to the location page (page-1 Next).
Future<void> _advanceToLocationPage(
    WidgetTester tester, OnboardingBloc bloc, AppLocalizations l10n) async {
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pumpAndSettle();
  expect(bloc.state.pageNumber, 1);
  expect(find.text(l10n.primaryLocationQuestion), findsOneWidget);
}

/// Taps the Next button on the final page and advances the fake clock past
/// the 700ms text-change debounce so the (faked) submit handler runs to
/// completion. Bounded pumps only -- never pumpAndSettle here: the error
/// toast carries a 2.5s timer that would never settle.
Future<void> _submitFinalPage(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
}

/// Flushes the error toast's bounded timers before the test ends.
Future<void> _flushToasts(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 2600));
  await tester.pump(const Duration(milliseconds: 600));
}

/// Stage 4.4: every exit from the essentials pages passes through the
/// animated "Tiles vs Blocks" demo. Waits for the onboarding route to be
/// replaced by it, then taps "Let's Go!" so the exit destination builds.
Future<void> _tapThroughExplainer(WidgetTester tester) async {
  await tester.pumpAndSettle();
  expect(find.byType(OnboardingExplainerScreen), findsOneWidget,
      reason: 'The demo must sit between the essentials pages and the app.');
  await tester.tap(
      find.text(lookupAppLocalizations(const Locale('en')).tutorialNavLetsGo));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    _submitDestination = null;
  });

  group('essentials onboarding submit (stage 3.4)', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final skipText = l10n.skip;
    final primaryLocationQuestion = l10n.primaryLocationQuestion;
    final useDeviceLocation = l10n.useDeviceLocation;

    testWidgets('submit is only available on page 2', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(onBoardingApi: api);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      // Page 1: Next merely advances; it never submits.
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(bloc.state.pageNumber, 1);
      expect(api.sendCalls, 0, reason: 'Page-1 Next must not submit.');

      // Page 2: Next submits.
      await _submitFinalPage(tester);
      expect(api.sendCalls, 1, reason: 'Page-2 Next must submit exactly once.');
      expect(bloc.state.step, OnboardingStep.submitted);

      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submit sends profession and location only', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(onBoardingApi: api);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();

      // Pick a profession (state-driven, like a page-1 checkbox tap).
      bloc.add(SelectProfessionEvent(profession: 'Carpenter', isCustom: false));
      await tester.pump();
      expect(bloc.state.profession, 'Carpenter');

      await _advanceToLocationPage(tester, bloc, l10n);
      await _submitFinalPage(tester);

      expect(api.sendCalls, 1);
      final payload = api.lastPayload!;
      expect(payload.profession, 'Carpenter');
      expect(payload.workLocation, isNotNull);
      expect(payload.workLocation!.isDefault, isTrue,
          reason: 'No address was searched, so the default location is sent.');

      // The two-page flow no longer collects the legacy fields; the payload
      // must not carry them.
      expect(payload.personalHoursStart, isNull);
      expect(payload.workHoursStart, isNull);
      expect(payload.preferredDaySections, isNull);
      expect(payload.recurringTasks, isNull);
      expect(payload.tileSuggestions, isNull);
      expect(payload.usage, isNull);
      expect(payload.userLatitude, isNull);
      expect(payload.userLongitude, isNull);
      expect(payload.timeZoneOffset, isNull);
      expect(payload.timeZone, isNull);

      expect(api.fetchCalls, 0, reason: 'Submit must not trigger a fetch.');

      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submit includes device coords and timezone when captured',
        (tester) async {
      _mockTimezoneChannel(tester);
      final geolocator = FakeGeolocatorPlatform(position: _testPosition);
      GeolocatorPlatform.instance = geolocator;
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(onBoardingApi: api);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc, l10n);

      // Capture the device location via the in-page consent button.
      await tester.tap(find.text(useDeviceLocation));
      await tester.pumpAndSettle();
      expect(bloc.state.userLatitude, '40.7128');
      expect(bloc.state.timeZone, 'America/New_York');

      await _submitFinalPage(tester);
      await tester.pumpAndSettle();

      final payload = api.lastPayload!;
      expect(payload.userLatitude, '40.7128');
      expect(payload.userLongitude, '-74.006');
      expect(payload.timeZone, 'America/New_York');
      expect(payload.timeZoneOffset, isNotNull);
      expect(payload.profession, 'Medical Professional',
          reason: 'The seeded default profession is sent when unchanged.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submit does not trigger the intro slider', (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(onBoardingApi: api);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc, l10n);

      await _submitFinalPage(tester);
      expect(bloc.state.step, OnboardingStep.submitted);
      await tester.pumpAndSettle();

      // The legacy intro slider (OnBoardingDescriptionSlider) was deleted
      // in the stage-4.3 decommission; the exit is the Tiles vs Blocks
      // demo, never a slider.
      expect(find.byType(OnboardingExplainerScreen), findsOneWidget,
          reason: 'Submit exits through the demo, not the old intro slider.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'submit navigates to the exit destination and buzzes the schedule once',
        (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final scheduleApi = FakeScheduleApi();
      final submitObserver = SubmitDestinationObserver();
      final bloc = _seededBloc(onBoardingApi: api);
      _submitDestination = const _SubmitDestinationMarker();

      await tester.pumpWidget(_wrapOnboarding(bloc,
          scheduleApi: scheduleApi, submitObserver: submitObserver));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc, l10n);

      expect(find.byType(_SubmitDestinationMarker), findsNothing);

      await _submitFinalPage(tester);
      expect(bloc.state.step, OnboardingStep.submitted);
      await tester.pumpAndSettle();
      expect(find.text(skipText), findsNothing,
          reason: 'The onboarding flow is replaced by the demo.');
      expect(submitObserver.destinationBuilt, isFalse,
          reason: "The app is not entered until the user taps Let's Go.");
      await _tapThroughExplainer(tester);

      expect(submitObserver.destinationBuilt, isTrue,
          reason: 'A successful submit must navigate to the exit '
              'destination (AuthorizedRoute in production).');
      expect(find.byType(_SubmitDestinationMarker), findsOneWidget);
      expect(find.text(skipText), findsNothing,
          reason: 'The onboarding flow is replaced after submit.');
      expect(scheduleApi.buzzCalls, 1,
          reason: 'A successful submit must buzz the schedule exactly once.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'successful submit sets the local essentialsOnboardingDone flag',
        (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api = FakeOnBoardingApi();
      final bloc = _seededBloc(onBoardingApi: api);

      expect(
          await OnBoardingSharedPreferencesHelper.getEssentialsOnboardingDone(),
          isFalse);

      await tester.pumpWidget(_wrapOnboarding(bloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc, l10n);

      await _submitFinalPage(tester);
      await tester.pumpAndSettle();

      expect(
          await OnBoardingSharedPreferencesHelper.getEssentialsOnboardingDone(),
          isTrue,
          reason:
              'Submit must persist the local done flag for the launch gate.');
      expect(
          await OnBoardingSharedPreferencesHelper.getSkipOnboarding(), isFalse,
          reason: 'Submit must not write the skip preference.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
        'failed submit stays in the flow with the error path and leaves Skip available',
        (tester) async {
      GeolocatorPlatform.instance =
          FakeGeolocatorPlatform(position: _testPosition);
      final api =
          FakeOnBoardingApi(sendErrorMessage: 'Onboarding submit failed');
      final scheduleApi = FakeScheduleApi();
      final submitObserver = SubmitDestinationObserver();
      final bloc = _seededBloc(onBoardingApi: api);

      await tester.pumpWidget(_wrapOnboarding(bloc,
          scheduleApi: scheduleApi, submitObserver: submitObserver));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc, l10n);

      await _submitFinalPage(tester);
      await tester.pump();

      expect(api.sendCalls, 1, reason: 'A failed submit must not retry.');
      expect(bloc.state.step, OnboardingStep.error);
      expect(bloc.state.error, contains('Onboarding submit failed'),
          reason: 'The error toast path must surface the API error message.');
      expect(bloc.state.pageNumber, 1,
          reason: 'The flow stays on the location page.');
      expect(find.text(primaryLocationQuestion), findsOneWidget);
      expect(find.text(skipText), findsOneWidget,
          reason: 'Skip must remain available after a failed submit.');
      expect(submitObserver.destinationBuilt, isFalse,
          reason: 'A failed submit must not navigate.');
      expect(scheduleApi.buzzCalls, 0,
          reason: 'A failed submit must not buzz the schedule.');
      expect(
          await OnBoardingSharedPreferencesHelper.getEssentialsOnboardingDone(),
          isFalse,
          reason: 'The done flag must not be set on a failed submit.');

      // The error toast carries bounded 2.5s timers; flush them before
      // finishing.
      await _flushToasts(tester);
      await tester.pumpWidget(const SizedBox());
    });
  });
}
