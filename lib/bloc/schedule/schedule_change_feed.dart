import 'dart:async';

import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

/// One new schedule revision: what the schedule was, what it is now, and
/// what caused the change. Produced once by [ScheduleChangeFeed] and shared
/// by everything that reacts to schedule changes.
class ScheduleChange {
  /// Increases with every change, so consumers can tell a change apart from
  /// one they already handled.
  final int id;
  final ScheduleRevision revision;
  final ScheduleChangeAttribution attribution;

  /// Every loaded tile before and after, across all loaded days.
  final List<SubCalendarEvent> before;
  final List<SubCalendarEvent> after;

  /// The windows each side was loaded for.
  final Timeline? beforeWindow;
  final Timeline? afterWindow;

  final Map<int, ScheduleDelta> _byDay = <int, ScheduleDelta>{};

  ScheduleChange({
    required this.id,
    required this.revision,
    required this.attribution,
    required this.before,
    required this.after,
    this.beforeWindow,
    this.afterWindow,
  });

  /// What changed on [day], computed once per day.
  ScheduleDelta deltaFor(Timeline day) => _byDay.putIfAbsent(
      day.start!,
      () => ScheduleDelta.compute(
            before: before,
            after: after,
            day: day,
            beforeWindow: beforeWindow,
            afterWindow: afterWindow,
          ));

  /// The tiles before the change, by uniqueId.
  Map<String, SubCalendarEvent> get beforeById =>
      {for (final tile in before) tile.uniqueId: tile};
}

/// Turns the schedule states the bloc emits into one [ScheduleChange] per
/// new server revision.
///
/// It accepts every state that carries a known revision — a loaded state or
/// one still evaluating a change — so a read that lands before the change
/// settles still produces the change, and the later loaded state with the
/// same revision produces nothing. The "before" side is the last snapshot
/// the feed saw, never what a particular view happened to draw. Failed loads
/// and unknown revisions are ignored and keep the last snapshot.
class ScheduleChangeFeed {
  final StreamController<ScheduleChange> _changes =
      StreamController<ScheduleChange>.broadcast();
  _Snapshot? _snapshot;
  ScheduleChange? _latest;
  int _sequence = 0;

  /// Changes as they happen, for subscribers not tied to a frame.
  Stream<ScheduleChange> get changes => _changes.stream;

  /// The most recent change, for views reading it while they build.
  ScheduleChange? get latest => _latest;

  /// Feeds [state] in. Returns the change it produced, if it carried a new
  /// revision. [attribute] says what caused that revision.
  ScheduleChange? observe(
    ScheduleState state, {
    required ScheduleChangeAttribution Function(ScheduleRevision revision)
        attribute,
  }) {
    final List<SubCalendarEvent> tiles;
    final Timeline window;
    final ScheduleStatus status;
    if (state is ScheduleLoadedState && state is! FailedScheduleLoadedState) {
      tiles = state.subEvents;
      window = state.lookupTimeline;
      status = state.scheduleStatus;
    } else if (state is ScheduleEvaluationState) {
      tiles = state.subEvents;
      window = state.lookupTimeline;
      status = state.scheduleStatus;
    } else {
      return null;
    }
    final revision = ScheduleRevision.fromStatus(status);
    if (!revision.isKnown) return null;

    final previous = _snapshot;
    _snapshot = _Snapshot(revision, tiles, window);
    if (previous == null || previous.revision == revision) return null;

    final change = ScheduleChange(
      id: ++_sequence,
      revision: revision,
      attribution: attribute(revision),
      before: previous.tiles,
      after: tiles,
      beforeWindow: previous.window,
      afterWindow: window,
    );
    _latest = change;
    _changes.add(change);
    return change;
  }

  /// Forgets everything (logout): the next known revision only seeds.
  void reset() {
    _snapshot = null;
    _latest = null;
  }

  Future<void> close() => _changes.close();
}

class _Snapshot {
  final ScheduleRevision revision;
  final List<SubCalendarEvent> tiles;
  final Timeline window;

  const _Snapshot(this.revision, this.tiles, this.window);
}
