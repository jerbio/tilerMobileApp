// tour_preferences_helper_test.dart
//
// TDD stage 1.1 for the product tour & slim onboarding redesign
// (product-tour-onboarding-redesign.md, Phase 1 "Multi-tour engine foundation").
//
// Locks in the per-tour completion persistence contract:
//   1. Per-tour keys are independent: completing (or resetting) one tour never
//      affects any other tour.
//   2. Legacy migration: a stored `hasCompletedAppTutorial == true` (the
//      single-tour flag used before the multi-tour engine) counts as the
//      `home` tour being completed, and is persisted into the new
//      `hasCompletedTour_home` key so the legacy flag is never consulted
//      again for that device.
//   3. Per-tour reset: clearing a tour's completion only affects that tour,
//      and a reset is never undone by the legacy migration.
//
// Key format locked here (used by TutorialBloc in stage 1.2 and TourHost in
// stage 1.3): `hasCompletedTour_<tourId>`.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TourPreferencesHelper — per-tour keys', () {
    test('defaults to not completed for any tour when nothing is stored',
        () async {
      SharedPreferences.setMockInitialValues({});

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse);
      expect(await TourPreferencesHelper.hasCompletedTour('settings'), isFalse);
    });

    test('completing the home tour does not complete the settings tour',
        () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.setTourCompleted('home');

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue);
      expect(
        await TourPreferencesHelper.hasCompletedTour('settings'),
        isFalse,
        reason: 'Tours are per-device flags; home completion must not leak '
            'into settings.',
      );
    });

    test('completing the settings tour does not affect the home tour',
        () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.setTourCompleted('settings');

      expect(await TourPreferencesHelper.hasCompletedTour('settings'), isTrue);
      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse);
    });

    test('persists under the per-tour key hasCompletedTour_<tourId>', () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.setTourCompleted('settings');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_settings'), isTrue);
      expect(prefs.getBool('hasCompletedTour_home'), isNull,
          reason: 'Only the completed tour may write its own key.');
    });
  });

  group('TourPreferencesHelper — legacy hasCompletedAppTutorial migration', () {
    test('legacy flag true counts as home completed', () async {
      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: true,
      });

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue);
    });

    test(
        'migration persists hasCompletedTour_home so it survives the legacy '
        'flag', () async {
      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: true,
      });

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_home'), isTrue,
          reason: 'The migrated value must be persisted so a later read does '
              'not depend on the legacy key still being present.');
    });

    test('legacy flag does not count for any tour other than home', () async {
      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: true,
      });

      expect(
        await TourPreferencesHelper.hasCompletedTour('settings'),
        isFalse,
        reason: 'The settings tour is new; legacy users must see it once.',
      );
    });

    test('legacy flag absent or false leaves home incomplete', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse);

      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: false,
      });
      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse);
    });

    test(
        'resetting home after migration is not re-migrated from the legacy '
        'flag', () async {
      // Regression lock: the migration must only apply while the per-tour
      // key is absent. Once a tour has been explicitly reset, the stale
      // legacy flag must not bring the tour back.
      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: true,
      });

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue);

      await TourPreferencesHelper.resetTour('home');

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse,
          reason: 'A reset must win over the legacy flag, otherwise '
              '"How to use Tiler" could never replay the home tour for '
              'legacy users.');
    });
  });

  group('TourPreferencesHelper — per-tour reset', () {
    test('reset clears only the target tour', () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.setTourCompleted('home');
      await TourPreferencesHelper.setTourCompleted('settings');

      await TourPreferencesHelper.resetTour('settings');

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue);
      expect(await TourPreferencesHelper.hasCompletedTour('settings'), isFalse);
    });

    test('reset on a never-completed tour keeps it incomplete', () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.resetTour('settings');

      expect(await TourPreferencesHelper.hasCompletedTour('settings'), isFalse);
    });
  });

  group('TourPreferencesHelper — resetTours replay-all (stage 2.4)', () {
    test('the registry covers the home and settings tours', () {
      // Locks the registry contents behind the "How to use Tiler" row: the
      // manual replay must cover every tour the user can currently see.
      expect(
        TourPreferencesHelper.allTourIds,
        containsAll([
          TourPreferencesHelper.homeTourId,
          TourPreferencesHelper.settingsTourId,
        ]),
      );
    });

    test('default reset clears every registered tour', () async {
      SharedPreferences.setMockInitialValues({});

      for (final tourId in TourPreferencesHelper.allTourIds) {
        await TourPreferencesHelper.setTourCompleted(tourId);
      }

      await TourPreferencesHelper.resetTours();

      for (final tourId in TourPreferencesHelper.allTourIds) {
        expect(await TourPreferencesHelper.hasCompletedTour(tourId), isFalse,
            reason: 'Replay-all must clear the "$tourId" tour.');
      }
    });

    test('a custom tour-id list resets only those tours', () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.setTourCompleted('home');
      await TourPreferencesHelper.setTourCompleted('settings');

      await TourPreferencesHelper.resetTours([
        TourPreferencesHelper.settingsTourId,
      ]);

      expect(await TourPreferencesHelper.hasCompletedTour('home'), isTrue,
          reason: 'A partial replay must leave other tours untouched.');
      expect(await TourPreferencesHelper.hasCompletedTour('settings'), isFalse);
    });

    test('never writes the legacy hasCompletedAppTutorial flag', () async {
      SharedPreferences.setMockInitialValues({});

      await TourPreferencesHelper.resetTours();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(TourPreferencesHelper.legacyCompletedKey), isNull,
          reason:
              'The multi-tour path must not touch the legacy flag (1.2).');
    });

    test('reset writes false so the legacy migration cannot re-apply',
        () async {
      // Regression lock for legacy users: after a replay-all, a stale
      // `hasCompletedAppTutorial == true` must not bring the home tour
      // completion back (the migration only applies while the per-tour key
      // is absent).
      SharedPreferences.setMockInitialValues({
        TourPreferencesHelper.legacyCompletedKey: true,
      });

      await TourPreferencesHelper.hasCompletedTour('home'); // migrate
      await TourPreferencesHelper.resetTours();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('hasCompletedTour_home'), isFalse,
          reason: 'The key must exist as false, not be absent.');
      expect(await TourPreferencesHelper.hasCompletedTour('home'), isFalse);
    });
  });
}
