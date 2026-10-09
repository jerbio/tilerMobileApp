import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/scheduleDelta.dart';

/// What the "Plan updated" chip and its "See changes" sheet report for one
/// day, built from a [ScheduleDelta] and what caused it.
class ScheduleChangeSummary {
  final ScheduleDelta delta;
  final ScheduleChangeAttribution attribution;

  /// The day's tiles before and after the change, in time order (all-day
  /// tiles left out), for the side-by-side view. When not given, only the
  /// changed tiles are known.
  final List<SubCalendarEvent> beforeDay;
  final List<SubCalendarEvent> afterDay;

  ScheduleChangeSummary._(this.delta, this.attribution,
      {List<SubCalendarEvent>? before, List<SubCalendarEvent>? after})
      : beforeDay = _onDay(
            before ?? [for (final c in delta.changes) c.before].nonNulls,
            delta),
        afterDay = _onDay(
            after ?? [for (final c in delta.changes) c.after].nonNulls, delta);

  /// [tiles] that start on [delta]'s day, in time order.
  static List<SubCalendarEvent> _onDay(
      Iterable<SubCalendarEvent> tiles, ScheduleDelta delta) {
    final day = delta.day;
    return [
      for (final t in tiles)
        if (t.start != null &&
            t.end != null &&
            t.uniqueId.isNotEmpty &&
            !t.isAllDay &&
            t.start! >= day.start! &&
            t.start! < day.end!)
          t,
    ]..sort((a, b) => a.start!.compareTo(b.start!));
  }

  /// The summary worth showing for [delta], or null when there is nothing
  /// to tell the user:
  /// - background refreshes never get a chip;
  /// - a re-optimize gets one whenever the day changed;
  /// - a user's own change (drag, edit, complete) gets one only when it
  ///   moved other Tiles too. The user already knows what they did to the
  ///   Tile they touched.
  ///
  /// [before] / [after] are the loaded tiles on each side of the change,
  /// for the side-by-side view.
  static ScheduleChangeSummary? from(
      ScheduleDelta delta, ScheduleChangeAttribution attribution,
      {List<SubCalendarEvent>? before, List<SubCalendarEvent>? after}) {
    if (attribution.isRefresh || delta.isEmpty) return null;
    if (attribution.origin != ScheduleChangeOrigin.tilerRevise) {
      final subject = attribution.subjectId;
      final knockOn = delta.changes.any((c) => c.id != subject) ||
          delta.travelChanges.any((t) => t.id != subject);
      if (!knockOn) return null;
    }
    return ScheduleChangeSummary._(delta, attribution,
        before: before, after: after);
  }

  bool get isDayCleared => delta.tier == ScheduleDeltaTier.dayEmptied;

  /// Tiles that now sit somewhere else on this day, including ones that
  /// arrived from another day.
  int get movedCount => _count(const {
        TileChangeKind.moved,
        TileChangeKind.resized,
        TileChangeKind.movedAndResized,
        TileChangeKind.movedFromOtherDay,
      });

  int get movedToOtherDaysCount =>
      _count(const {TileChangeKind.movedToOtherDay});

  int get addedCount => _count(const {TileChangeKind.added});

  int get removedCount => _count(const {TileChangeKind.removed});

  int get travelUpdatedCount => delta.travelChanges.length;

  /// Free minutes gained on the day; 0 when free time shrank or held.
  int get freeMinutesGained =>
      delta.freeMinutesDelta > 0 ? delta.freeMinutesDelta : 0;

  /// The changed Tiles in day order (by where they are now, or were, for
  /// Tiles that left the day).
  List<TileChange> get orderedChanges {
    int at(TileChange c) {
      final after = c.after;
      final onDay = after != null &&
          after.start! >= delta.day.start! &&
          after.start! < delta.day.end!;
      return (onDay ? after : (c.before ?? after))!.start!;
    }

    return [...delta.changes]..sort((a, b) => at(a).compareTo(at(b)));
  }

  int _count(Set<TileChangeKind> kinds) =>
      delta.changes.where((c) => kinds.contains(c.kind)).length;
}

/// Turns the stream of schedule states into summaries for the day on
/// screen.
///
/// Keeps the last snapshot it saw (Tiles + loaded window) and only diffs
/// when a known, new server revision arrives, so loading more days, cache
/// replays and failed loads never produce a summary.
class ScheduleChangeWatcher {
  final ScheduleRevisionGate _gate = ScheduleRevisionGate();
  List<SubCalendarEvent>? _subEvents;
  Timeline? _window;

  /// Feeds [state] in. Returns a summary for [day] when this state is a new
  /// revision worth reporting.
  ScheduleChangeSummary? observe(
    ScheduleState state, {
    required Timeline day,
    required ScheduleChangeAttribution Function(ScheduleStatus status)
        attribute,
  }) {
    if (state is! ScheduleLoadedState || state is FailedScheduleLoadedState) {
      return null;
    }
    final revision = ScheduleRevision.fromStatus(state.scheduleStatus);
    // An unknown revision carries no trustworthy snapshot: keep the last one.
    if (!revision.isKnown) return null;

    final before = _subEvents;
    final beforeWindow = _window;
    final isNew = _gate.admit(revision);
    _subEvents = state.subEvents;
    _window = state.lookupTimeline;
    if (!isNew || before == null) return null;

    final delta = ScheduleDelta.compute(
      before: before,
      after: state.subEvents,
      day: day,
      beforeWindow: beforeWindow,
      afterWindow: state.lookupTimeline,
    );
    return ScheduleChangeSummary.from(delta, attribute(state.scheduleStatus),
        before: before, after: state.subEvents);
  }
}
