import 'package:flutter/foundation.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/gridPositionableWidgetWidget.dart';
import 'package:tiler_app/services/dayGridPreferences.dart';
import 'package:tiler_app/util.dart';

/// Interaction modes of the day grid. Positions track the controller
/// directly (no animated transitions) while a gesture is active.
enum DayGridMode { idle, dragging, zooming }

/// The reactive core of the day grid (P1, step 1.1).
///
/// Owns the pixels-per-hour zoom level [pxPerHour], the current interaction
/// [mode], and the zoom-derived [snapInterval] (C4). Pure state — no widget
/// dependencies — because a pinch gesture mutates it at frame rate (P2).
///
/// Layout math (see [GridPositionableWidget]) derives every position from
/// [pxPerHour]:
///
/// ```
/// top(t)      = pxPerHour * 24 * msSinceMidnight(t) / msPerDay
/// height(d)   = pxPerHour * d_hours
/// time(y)     = y / pxPerHour
/// ```
class DayGridController extends ChangeNotifier {
  /// C8: "whole day on screen" floor.
  static const double minPxPerHour = 40;

  /// C8: "~5-min precision" ceiling.
  static const double maxPxPerHour = 240;

  /// Default zoom; matches the historical `heightPerCell` constant.
  static const double defaultPxPerHour =
      GridPositionableWidget.defaultHeigtPerDuration;

  /// C4 snap band boundary: below this the grid is too coarse for 15-min
  /// snaps.
  static const double _snapCoarseBoundary = 80;

  /// C4 snap band boundary: at or above this the grid is fine enough for
  /// 5-min snaps.
  static const double _snapFineBoundary = 160;

  double _pxPerHour = defaultPxPerHour;
  DayGridMode _mode = DayGridMode.idle;
  bool _hasExplicitZoom = false;
  bool _disposed = false;

  /// Pixels rendered per hour of the day. Always within
  /// `[minPxPerHour, maxPxPerHour]`.
  double get pxPerHour => _pxPerHour;

  /// Current interaction mode. Assignments notify only on change.
  DayGridMode get mode => _mode;

  set mode(DayGridMode value) {
    if (value == _mode) return;
    _mode = value;
    notifyListeners();
  }

  /// True once the user (or a restored preference) has set a zoom that must
  /// survive relaunches. An auto-fit seed does **not** count — a stored
  /// value restored later still wins (C8).
  bool get hasExplicitZoom => _hasExplicitZoom;

  /// C4: zoom-dependent snap granularity, shared by tap-to-add (P2) and
  /// drag-and-drop (P4).
  ///
  /// | pxPerHour | snap     |
  /// |-----------|----------|
  /// | < 80      | 30 min   |
  /// | 80–159    | 15 min   |
  /// | ≥ 160     | 5 min    |
  Duration get snapInterval {
    if (_pxPerHour < _snapCoarseBoundary) {
      return const Duration(minutes: 30);
    }
    if (_pxPerHour < _snapFineBoundary) {
      return const Duration(minutes: 15);
    }
    return const Duration(minutes: 5);
  }

  /// Sets [value] clamped to the C8 range. Notifies only when the effective
  /// value changes. Marks the zoom explicit so a later auto-fit cannot
  /// overwrite it.
  void setPxPerHour(double value) {
    double clamped = value.clamp(minPxPerHour, maxPxPerHour).toDouble();
    if (clamped != _pxPerHour) {
      if (value < minPxPerHour || value > maxPxPerHour) {
        Utility.debugPrint(
            'DayGrid:: pxPerHour clamped $value -> $clamped');
      }
      _pxPerHour = clamped;
      notifyListeners();
    }
    _hasExplicitZoom = true;
  }

  /// C8 first-launch seed: fit ~4 hours into [viewportHeight]
  /// (`viewportHeight / 4`, clamped). No-op once an explicit zoom exists.
  void autoFit(double viewportHeight) {
    if (_hasExplicitZoom) return;
    if (viewportHeight <= 0) return;
    double seed = (viewportHeight / 4).clamp(minPxPerHour, maxPxPerHour).toDouble();
    if (seed != _pxPerHour) {
      Utility.debugPrint(
          'DayGrid:: auto-fit pxPerHour -> $seed (viewport $viewportHeight)');
      _pxPerHour = seed;
      notifyListeners();
    }
    // Deliberately does not set [_hasExplicitZoom]: this is a layout seed,
    // not a user action, so a restored stored value still wins.
  }

  /// Applies a stored zoom (from [DayGridPreferences]), if any. Marks the
  /// zoom explicit so auto-fit will not overwrite the user's saved level.
  void restoreStoredPxPerHour(double? stored) {
    if (stored == null) return;
    _hasExplicitZoom = true;
    setPxPerHour(stored);
  }

  /// Restores the last persisted zoom (C6: global across all days).
  /// Absent/corrupt values leave the default in place so auto-fit (C8) can
  /// run on first launch.
  Future<void> restoreFromPrefs() async {
    final stored = await DayGridPreferences.getPxPerHour();
    Utility.debugPrint(
        'DayGrid:: restore pxPerHour: ${stored ?? 'default (auto-fit)'} '
        '(source: ${stored == null ? 'default' : 'stored'})');
    if (!_disposed) {
      restoreStoredPxPerHour(stored);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}