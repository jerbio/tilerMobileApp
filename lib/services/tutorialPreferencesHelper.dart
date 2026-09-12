import 'package:shared_preferences/shared_preferences.dart';

/// Per-tour completion state for the multi-tour engine
/// (product-tour-onboarding-redesign.md, Phase 1).
///
/// Each tour owns an independent SharedPreferences flag named
/// `hasCompletedTour_<tourId>` (e.g. `hasCompletedTour_home`,
/// `hasCompletedTour_settings`), so completing, skipping, or replaying one
/// tour never affects the others.
///
/// Legacy migration: before the multi-tour engine there was a single
/// `hasCompletedAppTutorial` flag. While the `home` per-tour key is absent,
/// a stored `hasCompletedAppTutorial == true` counts as the home tour being
/// completed, and the value is persisted into `hasCompletedTour_home` so the
/// legacy flag is never consulted again for that device. A reset writes
/// `false` (it never removes the key), so the migration cannot re-apply
/// after a user explicitly replays a tour.
class TourPreferencesHelper {
  /// Tour id for the existing 8-step home tour.
  static const String homeTourId = 'home';

  /// Tour id for the 1-step Settings-list pointer that points users at the
  /// Tile Preferences row (Phase 2 / stage 2.5, section 3.4).
  static const String settingsTourId = 'settings';

  /// Tour id for the 3-step Tile Preferences tour — the tour that teaches
  /// how to update AI preferences (stage 2.5, section 3.4).
  static const String tilePreferencesTourId = 'tile_preferences';

  /// Legacy single-tour flag written by the pre-multi-tour engine.
  static const String legacyCompletedKey = 'hasCompletedAppTutorial';

  /// The SharedPreferences key that stores [tourId]'s completion state.
  static String completedKeyFor(String tourId) => 'hasCompletedTour_$tourId';

  /// Returns true if [tourId]'s tour has been completed or skipped on this
  /// device.
  ///
  /// Applies the one-time legacy migration for [homeTourId]: while its
  /// per-tour key is absent, a stored legacy `true` counts as completed and
  /// is persisted into the per-tour key.
  static Future<bool> hasCompletedTour(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getBool(completedKeyFor(tourId));
    if (stored != null) return stored;

    if (tourId == homeTourId) {
      final legacyCompleted = prefs.getBool(legacyCompletedKey) ?? false;
      if (legacyCompleted) {
        await prefs.setBool(completedKeyFor(homeTourId), true);
        return true;
      }
    }
    return false;
  }

  /// Marks [tourId]'s tour as completed on this device.
  static Future<void> setTourCompleted(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKeyFor(tourId), true);
  }

  /// Clears [tourId]'s completion so the tour can be replayed.
  ///
  /// Only affects [tourId]. Writes `false` rather than removing the key so
  /// the legacy migration (which only applies while the key is absent) can
  /// never re-complete a tour the user explicitly reset.
  static Future<void> resetTour(String tourId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(completedKeyFor(tourId), false);
  }

  /// Every tour id registered with the multi-tour engine.
  ///
  /// This is the registry behind the manual "How to use Tiler" replay
  /// (settings row, product-tour-onboarding-redesign.md section 1 "Manual
  /// replay" + Phase 2 item 4). New tours MUST append their id here so the
  /// replay-all behavior covers them too.
  static const List<String> allTourIds = [
    homeTourId,
    settingsTourId,
    tilePreferencesTourId,
  ];

  /// Clears completion for [tourIds] (default: every registered tour) so the
  /// tours can be replayed — the "How to use Tiler" settings row behavior
  /// (replay-all). Each tour then replays the next time its own surface is
  /// visited; this method never triggers a tour by itself.
  ///
  /// Writes `false` per tour (it never removes keys), so the legacy
  /// migration can never re-complete the home tour afterwards. The legacy
  /// `hasCompletedAppTutorial` flag is never written, consistent with the
  /// multi-tour path (stage 1.2).
  static Future<void> resetTours([List<String> tourIds = allTourIds]) async {
    final prefs = await SharedPreferences.getInstance();
    for (final tourId in tourIds) {
      await prefs.setBool(completedKeyFor(tourId), false);
    }
  }
}

/// Legacy single-tour completion API.
///
/// Kept only for the Phase 1 transition: existing callers (`TutorialBloc`,
/// `AuthorizedRoute._TutorialWrapper`) still use it until they are re-wired
/// through the per-tour API (stages 1.2/1.3). It delegates to
/// [TourPreferencesHelper] for the `home` tour and keeps the legacy flag in
/// sync so both old and new readers agree.
class TutorialPreferencesHelper {
  /// Marks the (home) tutorial as completed.
  static Future<void> setTutorialCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TourPreferencesHelper.legacyCompletedKey, value);
    await prefs.setBool(
      TourPreferencesHelper.completedKeyFor(TourPreferencesHelper.homeTourId),
      value,
    );
  }

  /// Returns true if the user has already completed the (home) tutorial.
  ///
  /// Reads through the per-tour helper so a completion persisted by the
  /// multi-tour engine is honoured by the legacy readers as well.
  static Future<bool> hasCompletedTutorial() {
    return TourPreferencesHelper.hasCompletedTour(
      TourPreferencesHelper.homeTourId,
    );
  }

  /// Resets tutorial state so it can be shown again.
  static Future<void> resetTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(TourPreferencesHelper.legacyCompletedKey, false);
    await prefs.setBool(
      TourPreferencesHelper.completedKeyFor(TourPreferencesHelper.homeTourId),
      false,
    );
  }
}
