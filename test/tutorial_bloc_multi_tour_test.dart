// tutorial_bloc_multi_tour_test.dart
//
// TDD stage 1.2 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 1 "Multi-tour engine foundation").
//
// Locks in the multi-tour TutorialBloc contract:
//   1. The bloc is parameterized by a `tourId` (in addition to `stepCount`),
//      and completing or skipping the tour persists
//      `hasCompletedTour_<tourId>` — never the legacy
//      `hasCompletedAppTutorial` flag.
//   2. One tour's completion never touches another tour's key.
//   3. Omitting `tourId` defaults to the existing `home` tour, so the
//      current AuthorizedRoute wiring keeps working during the transition.
//   4. Step navigation semantics (start/next/previous/complete/reset) are
//      unchanged from the single-tour engine.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/tutorial/tutorial_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_state.dart';

/// Flushes pending microtasks so the bloc's fire-and-forget prefs writes
/// finish before the test asserts on SharedPreferences.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 10));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TutorialBloc — per-tour persistence', () {
    test('completing the tour writes hasCompletedTour_<tourId>', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 3);

      bloc.add(NextTutorialStepEvent()); // final step -> auto-complete
      await _settle();

      expect(bloc.state.status, TutorialStatus.completed);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue);
    });

    test('completing one tour does not touch another tour key', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 1, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(CompleteTutorialEvent());
      await _settle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue);
      expect(prefs.getBool('hasCompletedTour_home'), isNull,
          reason: 'Tours are per-device flags; completing settings must not '
              'mark home.');
    });

    test('skipping the tour writes the same per-tour key', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(SkipTutorialEvent());
      await _settle();

      expect(bloc.state.status, TutorialStatus.skipped);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue);
      expect(prefs.getBool('hasCompletedTour_home'), isNull);
    });

    test('defaults to the home tour when tourId is omitted', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 8);
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(SkipTutorialEvent());
      await _settle();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_home'), isTrue);
    });

    test('reset clears only that tour key and never writes the legacy flag',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(SkipTutorialEvent());
      await _settle();
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue);

      bloc.add(ResetTutorialEvent());
      await _settle();

      prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isFalse);
      expect(prefs.getBool('hasCompletedAppTutorial'), isNull,
          reason: 'The multi-tour engine must not pollute the legacy flag.');
    });
  });

  group('TutorialBloc — step navigation unchanged', () {
    test('start activates the tour at step 0 with the tour step count',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      expect(bloc.state.status, TutorialStatus.initial);
      expect(bloc.state.totalSteps, 4);

      bloc.add(StartTutorialEvent());
      await _settle();

      expect(bloc.state.status, TutorialStatus.active);
      expect(bloc.state.currentStepIndex, 0);
      expect(bloc.state.isFirstStep, isTrue);
      expect(bloc.state.totalSteps, 4);
    });

    test('next advances step by step and completes on the final step',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();

      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 1);

      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 2);

      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 3);
      expect(bloc.state.isLastStep, isTrue);

      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.status, TutorialStatus.completed);
    });

    test('previous steps back but never below step 0', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 1);

      bloc.add(PreviousTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 0);

      bloc.add(PreviousTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 0,
          reason: 'Previous on the first step is a no-op.');
      expect(bloc.state.status, TutorialStatus.active);
    });

    test('reset returns the tour to active at step 0', () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = TutorialBloc(stepCount: 4, tourId: 'settings');
      addTearDown(bloc.close);

      bloc.add(StartTutorialEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      bloc.add(NextTutorialStepEvent());
      await _settle();
      expect(bloc.state.currentStepIndex, 2);

      bloc.add(ResetTutorialEvent());
      await _settle();

      expect(bloc.state.status, TutorialStatus.active);
      expect(bloc.state.currentStepIndex, 0);
      expect(bloc.state.totalSteps, 4);
    });
  });
}
