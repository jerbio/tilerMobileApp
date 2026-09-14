// essentials_onboarding_schedule_prefetch_test.dart
//
// TDD stage 3.5 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 3 "Slim essentials
// onboarding", item 5 "schedule prefetch").
//
// The schedule should be loading while the essentials pages are on screen,
// so the user lands on a populated schedule the moment they Skip or
// Submit. Locks in:
//   1. `primeScheduleAfterLogin` — the single helper both launch paths use
//      once credentials verify — dispatches LogIn -> GetSchedule (initial
//      timeline, fresh load) on the ScheduleBloc and the day summary on
//      the ScheduleSummaryBloc, in that order. (The sign-in path already
//      did this inline; the cold-start path in main.dart only reset the
//      bloc and never fetched.)
//   2. Submit buzzes the schedule (server-side revise with the new
//      profession/location); a schedule prefetched before that is stale.
//      Once the buzz completes, the onboarding view asks the ScheduleBloc
//      for a quiet forced refresh — never before the buzz resolves, and
//      exactly once.
//   3. A failed buzz leaves the (still valid) prefetched schedule alone:
//      no refresh, no crash.
//   4. Skip never buzzes, so it never triggers a refresh either.
//   5. The view tolerates a missing ScheduleBloc (no provider, no seam):
//      submit still navigates.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/data/onBoarding.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/onBoarding.dart';
import 'package:tiler_app/routes/authentication/onboardingExplainerRoute.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/schedulePrimer.dart';
import 'package:tiler_app/theme/theme_data.dart';
import 'package:tiler_app/util.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

/// Records every event added to the schedule bloc without processing it,
/// so nothing reaches the network and the dispatch contract can be
/// asserted exactly.
class RecordingScheduleBloc extends ScheduleBloc {
  RecordingScheduleBloc() : super(getContextCallBack: () => null);

  final List<ScheduleEvent> events = [];

  @override
  void add(ScheduleEvent event) => events.add(event);

  Iterable<GetScheduleEvent> get fetches =>
      events.whereType<GetScheduleEvent>();
}

class RecordingScheduleSummaryBloc extends ScheduleSummaryBloc {
  RecordingScheduleSummaryBloc() : super(getContextCallBack: () => null);

  final List<ScheduleSummaryEvent> events = [];

  @override
  void add(ScheduleSummaryEvent event) => events.add(event);
}

class FakeOnBoardingApi extends OnBoardingApi {
  int sendCalls = 0;

  @override
  Future<OnboardingContent?> fetchOnboardingData() async => null;

  @override
  Future<OnboardingContent?> sendOnboardingData(
      OnboardingContent onboardingContent) async {
    sendCalls++;
    return null;
  }
}

/// Buzz is gated behind [release] so a test controls exactly when the
/// server-side revise "completes" (or fails).
class GatedBuzzScheduleApi extends ScheduleApi {
  GatedBuzzScheduleApi() : super(getContextCallBack: () => null);

  final Completer<void> release = Completer<void>();
  int buzzCalls = 0;

  @override
  Future buzzSchedule() async {
    buzzCalls++;
    await release.future;
  }
}

class FakeGeolocatorPlatform extends GeolocatorPlatform {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.denied;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.denied;
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

const _l10nDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

OnboardingBloc _seededBloc(FakeOnBoardingApi api) => OnboardingBloc(
    onBoardingApi: api,
    settingsApi: SettingsApi(getContextCallBack: () => null));

Widget _wrapOnboarding(
  OnboardingBloc bloc, {
  required ScheduleApi scheduleApi,
  RecordingScheduleBloc? scheduleBloc,
}) {
  return MaterialApp(
    theme: TileThemeData.lightTheme,
    localizationsDelegates: _l10nDelegates,
    supportedLocales: const [Locale('en', '')],
    home: OnboardingView(
      bloc: bloc,
      scheduleApi: scheduleApi,
      scheduleBloc: scheduleBloc,
      skipDestinationBuilder: (_) => const _DestinationMarker(),
      submitDestinationBuilder: (_) => const _DestinationMarker(),
    ),
  );
}

void _mockTimezoneChannel(WidgetTester tester) {
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('flutter_timezone'),
    (call) async => 'America/New_York',
  );
}

Future<void> _advanceToLocationPage(
    WidgetTester tester, OnboardingBloc bloc) async {
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pumpAndSettle();
  expect(bloc.state.pageNumber, 1);
}

/// Taps Next on the final page and advances past the 700ms text-change
/// debounce so the (faked) submit handler runs to completion.
Future<void> _submitFinalPage(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.arrow_forward));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 800));
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
    GeolocatorPlatform.instance = FakeGeolocatorPlatform();
  });

  group('primeScheduleAfterLogin (stage 3.5)', () {
    testWidgets(
        'dispatches LogIn -> GetSchedule(initial timeline, fresh) and the '
        'day summary', (tester) async {
      final scheduleBloc = RecordingScheduleBloc();
      final summaryBloc = RecordingScheduleSummaryBloc();
      addTearDown(scheduleBloc.close);
      addTearDown(summaryBloc.close);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ScheduleBloc>.value(value: scheduleBloc),
            BlocProvider<ScheduleSummaryBloc>.value(value: summaryBloc),
          ],
          child: Builder(
            builder: (context) {
              primeScheduleAfterLogin(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(scheduleBloc.events.map((e) => e.runtimeType).toList(),
          [LogInScheduleEvent, GetScheduleEvent],
          reason: 'Reset the session, then fetch — the same order the '
              'sign-in path always used.');

      final fetch = scheduleBloc.fetches.single;
      final Timeline expected = Utility.initialScheduleTimeline;
      expect(fetch.scheduleTimeline, isNotNull);
      expect(fetch.scheduleTimeline!.isStartAndEndEqual(expected), isTrue,
          reason: 'The prefetch must cover the initial schedule window.');
      expect(fetch.isAlreadyLoaded, isFalse,
          reason: 'A session prime is a fresh load, never a refresh.');
      expect(fetch.previousSubEvents, isEmpty);

      expect(summaryBloc.events.whereType<GetScheduleDaySummaryEvent>(),
          hasLength(1),
          reason: 'The day summary is primed alongside the schedule.');
    });
  });

  group('post-submit schedule refresh (stage 3.5)', () {
    testWidgets(
        'refreshes the schedule exactly once, only after the buzz completes',
        (tester) async {
      _mockTimezoneChannel(tester);
      final api = FakeOnBoardingApi();
      final scheduleApi = GatedBuzzScheduleApi();
      final scheduleBloc = RecordingScheduleBloc();
      addTearDown(scheduleBloc.close);
      final bloc = _seededBloc(api);

      await tester.pumpWidget(_wrapOnboarding(bloc,
          scheduleApi: scheduleApi, scheduleBloc: scheduleBloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);

      await _submitFinalPage(tester);
      expect(bloc.state.step, OnboardingStep.submitted);
      await tester.pumpAndSettle();
      expect(find.byType(OnboardingExplainerScreen), findsOneWidget,
          reason: 'Submit navigates immediately; it never waits on the buzz.');
      await _tapThroughExplainer(tester);
      expect(find.byType(_DestinationMarker), findsOneWidget);
      expect(scheduleApi.buzzCalls, 1);
      expect(scheduleBloc.fetches, isEmpty,
          reason: 'The schedule is stale until the revise finishes; '
              'refreshing earlier would just re-read the pre-buzz schedule.');

      scheduleApi.release.complete();
      await tester.pump();
      await tester.pump();

      final fetch = scheduleBloc.fetches.single;
      expect(fetch.forceRefresh, isTrue,
          reason: 'The revised schedule must be re-read from the server, '
              'not served from local state.');
      expect(fetch.emitOnlyLoadedStated, isTrue,
          reason: 'Quiet refresh: the user keeps seeing the prefetched '
              'schedule until the revised one arrives.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('a failed buzz leaves the prefetched schedule alone',
        (tester) async {
      _mockTimezoneChannel(tester);
      final api = FakeOnBoardingApi();
      final scheduleApi = GatedBuzzScheduleApi();
      final scheduleBloc = RecordingScheduleBloc();
      addTearDown(scheduleBloc.close);
      final bloc = _seededBloc(api);

      await tester.pumpWidget(_wrapOnboarding(bloc,
          scheduleApi: scheduleApi, scheduleBloc: scheduleBloc));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);
      await _submitFinalPage(tester);
      await _tapThroughExplainer(tester);
      expect(find.byType(_DestinationMarker), findsOneWidget);

      scheduleApi.release.completeError(StateError('buzz failed'));
      await tester.pump();
      await tester.pump();

      expect(scheduleBloc.fetches, isEmpty,
          reason: 'Nothing was revised, so there is nothing to re-read.');
      expect(tester.takeException(), isNull,
          reason: 'A failed buzz must never surface as an uncaught error.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Skip never buzzes and never refreshes', (tester) async {
      _mockTimezoneChannel(tester);
      final api = FakeOnBoardingApi();
      final scheduleApi = GatedBuzzScheduleApi();
      final scheduleBloc = RecordingScheduleBloc();
      addTearDown(scheduleBloc.close);
      final bloc = _seededBloc(api);
      final l10n = lookupAppLocalizations(const Locale('en'));

      await tester.pumpWidget(_wrapOnboarding(bloc,
          scheduleApi: scheduleApi, scheduleBloc: scheduleBloc));
      await tester.pump();

      await tester.tap(find.text(l10n.skip));
      await _tapThroughExplainer(tester);

      expect(find.byType(_DestinationMarker), findsOneWidget);
      expect(scheduleApi.buzzCalls, 0);
      expect(api.sendCalls, 0);
      expect(scheduleBloc.fetches, isEmpty,
          reason: 'The schedule prefetched during onboarding is already '
              'correct after a Skip.');

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('submit still navigates when no ScheduleBloc is reachable',
        (tester) async {
      _mockTimezoneChannel(tester);
      final api = FakeOnBoardingApi();
      final scheduleApi = GatedBuzzScheduleApi();
      final bloc = _seededBloc(api);

      // No seam and no provider above the view.
      await tester.pumpWidget(_wrapOnboarding(bloc, scheduleApi: scheduleApi));
      await tester.pump();
      await _advanceToLocationPage(tester, bloc);
      await _submitFinalPage(tester);
      await _tapThroughExplainer(tester);

      expect(find.byType(_DestinationMarker), findsOneWidget);
      scheduleApi.release.complete();
      await tester.pump();
      expect(tester.takeException(), isNull,
          reason: 'The refresh is best-effort; a missing bloc is not an '
              'error.');

      await tester.pumpWidget(const SizedBox());
    });
  });
}
