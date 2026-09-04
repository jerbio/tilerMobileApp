import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridController.dart';

/// User's daily-view layout choice (P1, C9).
///
/// Lives next to its persistence so both the cubit and the helper share one
/// definition.
enum DailyViewLayout { list, grid }

/// SharedPreferences persistence for the day grid (P1, step 1.2).
///
/// Follows the existing `ThemeManager` / `TutorialPreferencesHelper` idiom:
/// static accessors, one `SharedPreferences.getInstance()` per call, never
/// throws on absent or corrupt values.
///
/// A **missing** zoom value is significant: it is the sentinel that tells
/// [DayGridController.autoFit] (C8) to compute the first-launch zoom from
/// the viewport. Corrupt values behave the same way (default / null).
class DayGridPreferences {
  static const String _layoutKey = 'dayGridLayout';
  static const String _pxPerHourKey = 'dayGridPxPerHour';

  /// Returns the persisted layout, or [DailyViewLayout.list] when the value
  /// is absent or unparseable.
  static Future<DailyViewLayout> getLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.get(_layoutKey);
    if (stored is! String) return DailyViewLayout.list;
    return DailyViewLayout.values.firstWhere((value) => value.name == stored,
        orElse: () => DailyViewLayout.list);
  }

  static Future<void> setLayout(DailyViewLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_layoutKey, layout.name);
  }

  /// Returns the persisted zoom, or `null` when absent, unparseable, or
  /// outside the valid `[DayGridController.minPxPerHour,
  /// DayGridController.maxPxPerHour]` range (auto-fit wins in that case).
  static Future<double?> getPxPerHour() async {
    final prefs = await SharedPreferences.getInstance();
    // `get` + type check (rather than `getDouble`) so a value of the wrong
    // type degrades to "absent" instead of throwing — the auto-fit (C8)
    // path then runs on the next launch.
    final stored = prefs.get(_pxPerHourKey);
    if (stored is! double) return null;
    if (stored.isNaN ||
        stored < DayGridController.minPxPerHour ||
        stored > DayGridController.maxPxPerHour) {
      return null;
    }
    return stored;
  }

  static Future<void> setPxPerHour(double pxPerHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pxPerHourKey, pxPerHour);
  }
}
