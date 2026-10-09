import 'package:shared_preferences/shared_preferences.dart';

/// How much motion a schedule change gets.
///
/// Ordered least to most: the effective mode for a change is the lowest of
/// the user's setting, the OS reduced-motion cap and the change-origin cap.
/// Lives next to its persistence so the cubit, the resolver and the settings
/// screen share one definition.
enum ScheduleUpdateMode {
  /// Positions, sizes, enters and exits change in one frame.
  off,

  /// One plain slide / fade for everything, no choreography.
  minimal,

  /// The full lift / ghost / batch choreography. The default.
  detailed,
}

extension ScheduleUpdateModeMotion on ScheduleUpdateMode {
  /// Anything moves at all.
  bool get animates => this != ScheduleUpdateMode.off;

  /// Lift, ghost, rail, batches, flashes.
  bool get choreographs => this == ScheduleUpdateMode.detailed;

  /// The lower of this and [other].
  ScheduleUpdateMode capAt(ScheduleUpdateMode other) =>
      index <= other.index ? this : other;
}

/// SharedPreferences persistence for [ScheduleUpdateMode].
///
/// Follows the `ThemeManager` / `DayGridPreferences` idiom: static
/// accessors, one `SharedPreferences.getInstance()` per call, never throws
/// on absent or corrupt values. Local to the device, not synced.
class ScheduleMotionPreferences {
  static const String modeKey = 'scheduleUpdateMode';
  static const ScheduleUpdateMode defaultMode = ScheduleUpdateMode.detailed;

  /// Returns the stored mode, or [defaultMode] when it is absent, the wrong
  /// type, or an unknown name.
  static Future<ScheduleUpdateMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.get(modeKey);
    if (stored is! String) return defaultMode;
    return ScheduleUpdateMode.values.firstWhere(
        (value) => value.name == stored,
        orElse: () => defaultMode);
  }

  static Future<void> setMode(ScheduleUpdateMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(modeKey, mode.name);
  }
}
