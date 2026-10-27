part of 'schedule_bloc.dart';

/// Every read ends with an outcome so refresh gestures can stop waiting, even
/// when navigation replaces the request or logout prevents it from running.
enum ScheduleReadOutcome { succeeded, failed, superseded, skipped }

/// A failed read never implies that a schedule change failed.
class ScheduleReadFailure extends Equatable {
  const ScheduleReadFailure(this.timeline, this.attempt, this.error,
      {this.eventId});
  final Timeline timeline;
  final int attempt;
  final Object error;
  final String? eventId;

  bool includes(DateTime date) => _includesDate(timeline, date);

  @override
  List<Object?> get props =>
      [timeline.start, timeline.end, attempt, eventId, error];
}

// Ranges exclude their end: midnight belongs to the following day's request.
bool _includesDate(Timeline range, DateTime date) =>
    date.millisecondsSinceEpoch >= range.start! &&
    date.millisecondsSinceEpoch < range.end!;

/// Read state is independent of the calendar's mutation/evaluation state.
/// Coverage describes the retained snapshot, including a verified empty one.
class ScheduleReadState extends Equatable {
  const ScheduleReadState({
    this.coverage,
    this.lastSuccessfulAt,
    this.dataAttempt = 0,
    this.requested,
    this.attempt = 0,
    this.isLoading = false,
    this.failures = const [],
  });

  /// Null means no retained data has been established. A covered day with zero
  /// events is still usable data and can keep its empty state during a refresh.
  final Timeline? coverage;
  final DateTime? lastSuccessfulAt;

  /// Sequence of the retained data, used to compare it with earlier failures.
  final int dataAttempt;

  /// The requested range can differ from coverage during navigation or failure.
  final Timeline? requested;
  final int attempt;
  final bool isLoading;
  final List<ScheduleReadFailure> failures;

  bool hasDataFor(DateTime date) =>
      coverage != null && _includesDate(coverage!, date);

  bool loadingFor(DateTime date) =>
      isLoading && requested != null && _includesDate(requested!, date);

  ScheduleReadFailure? failureFor(DateTime date) {
    // A successful narrower request resolves the warning for its own days.
    // Keep the wider failure available for days that were not refreshed.
    for (final failure in failures.reversed) {
      if (failure.includes(date) &&
          !(hasDataFor(date) && dataAttempt > failure.attempt)) return failure;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        coverage?.start,
        coverage?.end,
        lastSuccessfulAt,
        dataAttempt,
        requested?.start,
        requested?.end,
        attempt,
        isLoading,
        failures,
      ];
}

class ScheduleReadCubit extends Cubit<ScheduleReadState> {
  ScheduleReadCubit() : super(const ScheduleReadState());

  /// Starting a retry keeps the warning and snapshot until success confirms
  /// that they can be replaced; tapping Retry alone does not resolve an error.
  void begin(Timeline timeline, int attempt) => emit(ScheduleReadState(
      coverage: state.coverage,
      lastSuccessfulAt: state.lastSuccessfulAt,
      dataAttempt: state.dataAttempt,
      requested: timeline,
      attempt: attempt,
      isLoading: true,
      failures: state.failures));

  void succeed(Timeline timeline, DateTime now, int attempt) =>
      emit(ScheduleReadState(
        coverage: timeline,
        lastSuccessfulAt: now,
        dataAttempt: attempt,
        requested: timeline,
        attempt: attempt,
        failures: List.unmodifiable(state.failures.where((f) =>
            !(timeline.start! <= f.timeline.start! &&
                timeline.end! >= f.timeline.end!))),
      ));

  /// Retain only the newest failure per range, capped to avoid accumulating
  /// error history indefinitely as the user browses different dates.
  void fail(ScheduleReadFailure failure) => emit(ScheduleReadState(
      coverage: state.coverage,
      lastSuccessfulAt: state.lastSuccessfulAt,
      dataAttempt: state.dataAttempt,
      requested: failure.timeline,
      attempt: failure.attempt,
      failures: List.unmodifiable([
        ...state.failures
            .where((f) => !f.timeline.isEquivalent(failure.timeline)),
        failure,
      ].reversed.take(16).toList().reversed)));

  /// Local merges change coverage, but cannot clear a read failure.
  void retain(Timeline timeline) => emit(ScheduleReadState(
      coverage: timeline,
      lastSuccessfulAt: state.lastSuccessfulAt,
      dataAttempt: state.dataAttempt,
      requested: state.requested,
      attempt: state.attempt,
      isLoading: state.isLoading,
      failures: state.failures));

  void reset() => emit(const ScheduleReadState());
}

class _ScheduleReadAttempt {
  _ScheduleReadAttempt(this.timeline, this.event, this.refreshId);
  final Timeline timeline;
  final GetScheduleEvent event;
  // A read started before a confirmed change cannot satisfy its later refresh.
  final String? refreshId;
  // Coalesced callers share this result instead of starting another HTTP read.
  final completion = Completer<ScheduleReadOutcome>();
  void finish(ScheduleReadOutcome outcome) {
    if (!completion.isCompleted) completion.complete(outcome);
  }
}

class _ScheduleReadSuperseded implements Exception {}
