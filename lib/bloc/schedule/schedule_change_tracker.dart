import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';

/// What caused a schedule revision.
enum ScheduleChangeOrigin {
  /// Re-optimize / shuffle.
  tilerRevise,

  /// A Tile dropped on the day grid.
  userDrag,

  /// Any other user mutation that re-evaluates the schedule.
  userEdit,

  /// Marking a Tile complete.
  userComplete,

  /// No pending change claimed the revision: a poll, app resume, or an
  /// edit made on another device.
  refresh,
}

class ScheduleChangeAttribution {
  final ScheduleChangeOrigin origin;

  /// The Tile the user acted on (`uniqueId`), when there is one.
  final String? subjectId;

  const ScheduleChangeAttribution(this.origin, {this.subjectId});

  static const ScheduleChangeAttribution refresh =
      ScheduleChangeAttribution(ScheduleChangeOrigin.refresh);

  bool get isRefresh => origin == ScheduleChangeOrigin.refresh;
}

/// Attributes server revisions to the change that caused them.
///
/// A mutation calls [begin] with the revision it started from. The first
/// known revision that differs from that baseline is claimed by it; any
/// revision nobody claims is a [ScheduleChangeOrigin.refresh]. Attribution
/// is remembered per revision, so asking twice gives the same answer.
///
/// Only one change is pending at a time: a newer [begin] replaces the
/// older one, so two quick mutations folded into one revision are
/// attributed to the latest.
class ScheduleChangeTracker {
  ScheduleChangeTracker({
    DateTime Function()? clock,
    this.maxPendingAge = const Duration(minutes: 2),
    this.historyLimit = 16,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  /// A pending change older than this no longer claims revisions, so a
  /// request that never settled cannot mislabel a later, unrelated change.
  final Duration maxPendingAge;
  final int historyLimit;

  _PendingChange? _pending;
  int _nextToken = 0;
  final Map<ScheduleRevision, ScheduleChangeAttribution> _history = {};

  /// Records a change about to be sent. Returns a token for [abandon].
  int begin(
    ScheduleChangeOrigin origin, {
    required ScheduleRevision? baseline,
    String? subjectId,
  }) {
    final token = ++_nextToken;
    _pending = _PendingChange(
      token: token,
      baseline: baseline,
      attribution: ScheduleChangeAttribution(origin, subjectId: subjectId),
      startedAt: _clock(),
    );
    return token;
  }

  /// Drops the pending change if it is still [token] (the request failed).
  void abandon(int token) {
    if (_pending?.token == token) _pending = null;
  }

  /// The attribution for [revision], claiming the pending change when this
  /// is the first new revision since it began.
  ScheduleChangeAttribution resolve(ScheduleRevision? revision) {
    if (revision == null || !revision.isKnown) {
      return ScheduleChangeAttribution.refresh;
    }
    final known = _history[revision];
    if (known != null) return known;

    var attribution = ScheduleChangeAttribution.refresh;
    final pending = _pending;
    if (pending != null) {
      if (_clock().difference(pending.startedAt) > maxPendingAge) {
        _pending = null;
      } else if (revision != pending.baseline) {
        attribution = pending.attribution;
        _pending = null;
      }
    }
    _history[revision] = attribution;
    while (_history.length > historyLimit) {
      _history.remove(_history.keys.first);
    }
    return attribution;
  }

  void reset() {
    _pending = null;
    _history.clear();
  }
}

class _PendingChange {
  final int token;
  final ScheduleRevision? baseline;
  final ScheduleChangeAttribution attribution;
  final DateTime startedAt;

  const _PendingChange({
    required this.token,
    required this.baseline,
    required this.attribution,
    required this.startedAt,
  });
}

/// Per-view gate: decides whether a newly rendered schedule state should be
/// diffed and animated.
///
/// Only a known revision that differs from the last one this view rendered
/// passes. The first known revision, unknown revisions (failed loads,
/// tutorial), and repeats of the same revision (more days loaded, cache
/// replays, rebuilds) never animate.
class ScheduleRevisionGate {
  ScheduleRevision? _lastRendered;

  ScheduleRevision? get lastRendered => _lastRendered;

  /// Returns true when [next] should be diffed against the last rendered
  /// snapshot. Records [next] as rendered whenever it is known.
  bool admit(ScheduleRevision? next) {
    if (next == null || !next.isKnown) return false;
    final previous = _lastRendered;
    _lastRendered = next;
    return previous != null && previous != next;
  }

  void reset() => _lastRendered = null;
}
