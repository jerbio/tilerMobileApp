// tour_host_test.dart
//
// TDD stage 1.3 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 1 "Multi-tour engine foundation").
//
// Locks in the TourHost contract (extracted from AuthorizedRoute's
// _TutorialWrapper, generalized per tour):
//   1. Starts its tour (StartTutorialEvent) when the per-tour completion key
//      is unset — after a post-frame settle delay so the surface renders
//      first.
//   2. Does not start when the per-tour key is already set (completion/skip
//      is terminal until an explicit reset).
//   3. Does not start while another tour is active (one-tour-at-a-time
//      coordinator guard); a blocked tour is NOT marked complete.
//   4. A blocked tour retries on the next surface visit (fresh mount after
//      the active tour ends); a tour that was skipped releases the
//      coordinator so another tour can start.
//   5. Home parity: the legacy `hasCompletedAppTutorial` flag suppresses the
//      home tour via migration; an explicit home reset replays it.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/components/tutorial/tourCoordinator.dart';
import 'package:tiler_app/components/tutorial/tourHost.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

const _settle = Duration(milliseconds: 100);

/// Captures the per-tour [TutorialBloc] that [TourHost] must provide above
/// its child.
late TutorialBloc capturedBloc;

/// Counts how many times the hosted surface is (re)mounted. A tour must
/// never remount its surface: a page that creates its bloc and fetches in
/// `initState`/`create` would load again every time the tour starts or
/// ends.
int surfaceMounts = 0;

class _MountCountingSurface extends StatefulWidget {
  const _MountCountingSurface();

  @override
  State<_MountCountingSurface> createState() => _MountCountingSurfaceState();
}

class _MountCountingSurfaceState extends State<_MountCountingSurface> {
  @override
  void initState() {
    super.initState();
    surfaceMounts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

Widget host({
  required String tourId,
  int stepCount = 2,
  Key? key,
  Widget surface = const SizedBox.shrink(),
}) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [Locale('en', '')],
    // The home tour's overlay injects dummy tiles into the ScheduleBloc.
    home: BlocProvider(
      create: (_) => ScheduleBloc(getContextCallBack: (context) => context),
      child: TourHost(
        key: key,
        tourId: tourId,
        stepCount: stepCount,
        settleDelay: _settle,
        child: Builder(
          builder: (context) {
            capturedBloc = context.read<TutorialBloc>();
            return surface;
          },
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // The coordinator is in-memory app state; reset it between tests.
    TourCoordinator.instance.clear();
  });

  group('TourHost — start decisions', () {
    testWidgets('starts the tour after the settle delay when the key is unset',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(host(tourId: 'settings'));
      expect(capturedBloc.state.isActive, isFalse,
          reason: 'The tour must wait for the settle delay, not start '
              'mid-frame.');

      await tester.pump(_settle);

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'An uncompleted tour must auto-start after the settle '
              'delay.');
    });

    testWidgets('does not start when the per-tour key is already set',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'hasCompletedTour_settings': true});

      await tester.pumpWidget(host(tourId: 'settings'));
      await tester.pump(_settle);
      await tester.pump(const Duration(seconds: 1));

      expect(capturedBloc.state.isActive, isFalse,
          reason: 'Completion/skip is terminal until an explicit reset.');
    });

    testWidgets(
        'does not start while another tour is active, and is not marked '
        'complete', (tester) async {
      SharedPreferences.setMockInitialValues({});
      TourCoordinator.instance.requestStart('home'); // home tour in progress

      await tester.pumpWidget(host(tourId: 'settings'));
      await tester.pump(_settle);
      await tester.pump(const Duration(seconds: 1));

      expect(capturedBloc.state.isActive, isFalse,
          reason: 'Only one tour may be active at a time.');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isNull,
          reason: 'A tour blocked from starting must not be marked '
              'complete — it retries on the next visit.');
    });

    testWidgets('retries on the next visit after the other tour ends',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      TourCoordinator.instance.requestStart('home');

      await tester
          .pumpWidget(host(tourId: 'settings', key: const ValueKey('first')));
      await tester.pump(_settle);
      expect(capturedBloc.state.isActive, isFalse);

      // Next surface visit: the other tour has since ended.
      TourCoordinator.instance.release('home');
      await tester
          .pumpWidget(host(tourId: 'settings', key: const ValueKey('second')));
      await tester.pump(_settle);

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'The blocked tour must retry on its next visit.');
    });

    testWidgets('a second tour can start after the first tour is skipped',
        (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(host(
          tourId: TourPreferencesHelper.homeTourId,
          key: const ValueKey('home')));
      await tester.pump(_settle);
      expect(capturedBloc.state.isActive, isTrue);

      capturedBloc.add(SkipTutorialEvent());
      // Flush the skip through the bloc and the overlay's completion
      // listener. (Fake-async clock: a bare Future.delayed would hang.)
      await tester.pump();
      await tester.pump();

      // Settings surface visit: home was skipped, so the coordinator must
      // have been released.
      await tester.pumpWidget(
          host(tourId: 'settings', key: const ValueKey('settings')));
      await tester.pump(_settle);

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'Skipping a tour must release the coordinator so another '
              'tour can start.');
    });
  });

  group('TourHost — surface stability', () {
    testWidgets(
        'the hosted surface is not remounted when the tour starts or ends',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      surfaceMounts = 0;

      await tester.pumpWidget(host(
        tourId: 'settings',
        surface: const _MountCountingSurface(),
      ));
      expect(surfaceMounts, 1);

      // Tour starts: the overlay is layered on top of the surface.
      await tester.pump(_settle);
      await tester.pump();
      expect(capturedBloc.state.isActive, isTrue);
      expect(surfaceMounts, 1,
          reason: 'Starting the tour must layer the overlay over the '
              'existing surface, not rebuild the surface underneath it — a '
              'page that fetches on mount would load twice.');

      // Tour ends: the overlay is removed.
      capturedBloc.add(SkipTutorialEvent());
      await tester.pump();
      await tester.pump();
      expect(capturedBloc.state.isActive, isFalse);
      expect(surfaceMounts, 1,
          reason: 'Ending the tour must not remount the surface either.');
    });
  });

  group('TourHost — home parity (legacy migration)', () {
    testWidgets('legacy hasCompletedAppTutorial suppresses the home tour',
        (tester) async {
      SharedPreferences.setMockInitialValues({'hasCompletedAppTutorial': true});

      await tester.pumpWidget(host(tourId: TourPreferencesHelper.homeTourId));
      await tester.pump(_settle);
      await tester.pump(const Duration(seconds: 1));

      expect(capturedBloc.state.isActive, isFalse,
          reason: 'Legacy users (pre multi-tour flag) must not replay the '
              'home tour.');
    });

    testWidgets('an explicit home reset replays the home tour', (tester) async {
      // "How to use Tiler" resets the home tour even for legacy users.
      SharedPreferences.setMockInitialValues({
        'hasCompletedAppTutorial': true,
        'hasCompletedTour_home': false,
      });

      await tester.pumpWidget(host(tourId: TourPreferencesHelper.homeTourId));
      await tester.pump(_settle);

      expect(capturedBloc.state.isActive, isTrue,
          reason: 'An explicit reset must win over the legacy flag.');
    });
  });
}
