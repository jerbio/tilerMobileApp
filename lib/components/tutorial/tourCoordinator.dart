/// In-memory one-tour-at-a-time guard for the multi-tour engine
/// (product-tour-onboarding-redesign.md, Phase 1).
///
/// At most one tour may be active at a time across all surfaces. A tour that
/// is blocked from starting is NOT marked complete — it retries on its next
/// surface visit. The owning [TourHost] releases the coordinator when its
/// tour completes or is skipped.
///
/// In-memory by design: it must not survive an app restart (tours are once
/// per device, gated by persisted completion flags owned by
/// [TourPreferencesHelper], which this class deliberately does not touch).
class TourCoordinator {
  TourCoordinator._();

  /// App-wide coordinator instance.
  static final TourCoordinator instance = TourCoordinator._();

  String? _activeTourId;

  /// The tour id currently holding the coordinator, if any.
  String? get activeTourId => _activeTourId;

  /// Requests the right to start [tourId].
  ///
  /// Returns true (and holds the coordinator) when no tour is active, or when
  /// [tourId] is the tour already active (re-entry replay). Returns false —
  /// without side effects — when a different tour is active.
  bool requestStart(String tourId) {
    if (_activeTourId != null && _activeTourId != tourId) return false;
    _activeTourId = tourId;
    return true;
  }

  /// Releases the coordinator held by [tourId] (tour completed or skipped).
  ///
  /// No-op if a different tour currently holds the coordinator.
  void release(String tourId) {
    if (_activeTourId == tourId) _activeTourId = null;
  }

  /// Clears all coordinator state (app start, tests).
  void clear() => _activeTourId = null;
}
