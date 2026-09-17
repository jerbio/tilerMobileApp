// onboarding_gate_test.dart
//
// TDD stage 4.1 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 4 "Gate simplification &
// decommission", section 3.5).
//
// The launch gate (`Utility.checkOnboardingStatus`) decides between the
// essentials onboarding and the authorized app. It used to sleep 700ms and
// then ask the server whether the onboarding record was complete — a
// blocking round-trip on every launch and sign-in. Locks in:
//   1. The gate is a local preference read: it resolves from microtasks
//      alone (no timers, no network). Under fake async the result is
//      available after flushing microtasks without advancing the clock;
//      with the old implementation the 700ms delay keeps it pending, and
//      in the test environment the server call throws — which the old
//      fail-open catch turned into `true`, so a fresh device wrongly
//      skipped onboarding.
//   2. Legacy `skipOnboarding == true` (users who skipped on the old flow)
//      is honoured: no essentials flow.
//   3. The new `essentialsOnboardingDone == true` (set by Submit and by
//      Skip on the essentials flow) is honoured.
//   4. A fresh device (neither flag) goes to the essentials flow.
//   5. Skip on the essentials flow writes `essentialsOnboardingDone` as
//      well as the legacy flag, so one canonical flag gates everything
//      going forward (the legacy flag stays read-only for old installs).

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/bloc/onBoarding/on_boarding_bloc.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tiler_app/util.dart';

/// Resolves the gate inside a fake-async zone, flushing only microtasks:
/// any timer or platform round-trip leaves the result unresolved.
bool? _resolveGateWithoutAdvancingTime() {
  bool? result;
  fakeAsync((async) {
    Utility.checkOnboardingStatus().then((value) => result = value);
    async.flushMicrotasks();
    expect(async.pendingTimers, isEmpty,
        reason: 'The gate must not schedule timers (no artificial delay).');
  });
  return result;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Utility.checkOnboardingStatus — local-only gate (stage 4.1)', () {
    test('fresh device: neither flag -> essentials onboarding (false)', () {
      SharedPreferences.setMockInitialValues({});

      final result = _resolveGateWithoutAdvancingTime();

      expect(result, isNotNull,
          reason: 'The gate must resolve from local reads alone — no 700ms '
              'delay and no server round-trip.');
      expect(result, isFalse,
          reason: 'A device with neither flag has not completed onboarding.');
    });

    test('legacy skipOnboarding == true -> skip essentials (true)', () {
      SharedPreferences.setMockInitialValues({'skipOnboarding': true});

      expect(_resolveGateWithoutAdvancingTime(), isTrue,
          reason:
              'Users who skipped on the old flow must not be re-onboarded.');
    });

    test('essentialsOnboardingDone == true -> skip essentials (true)', () {
      SharedPreferences.setMockInitialValues({
        OnBoardingSharedPreferencesHelper.essentialsOnboardingDoneKey: true
      });

      expect(_resolveGateWithoutAdvancingTime(), isTrue);
    });

    test('explicit false flags -> essentials onboarding (false)', () {
      SharedPreferences.setMockInitialValues({
        'skipOnboarding': false,
        OnBoardingSharedPreferencesHelper.essentialsOnboardingDoneKey: false,
      });

      expect(_resolveGateWithoutAdvancingTime(), isFalse);
    });
  });

  group('Skip writes the canonical flag (stage 4.1)', () {
    test('SkipOnboardingEvent sets essentialsOnboardingDone and skipOnboarding',
        () async {
      SharedPreferences.setMockInitialValues({});
      final bloc = OnboardingBloc(
          onBoardingApi: OnBoardingApi(),
          settingsApi: SettingsApi(getContextCallBack: () => null));
      addTearDown(bloc.close);

      bloc.add(SkipOnboardingEvent());
      await bloc.stream.firstWhere((s) => s.step == OnboardingStep.skipped);

      expect(
          await OnBoardingSharedPreferencesHelper.getEssentialsOnboardingDone(),
          isTrue,
          reason: 'Skip must set the canonical done flag so the gate has one '
              'source of truth going forward.');
      expect(
          await OnBoardingSharedPreferencesHelper.getSkipOnboarding(), isTrue,
          reason: 'The legacy flag is still written for readers that predate '
              'the essentials flow.');
    });
  });
}
