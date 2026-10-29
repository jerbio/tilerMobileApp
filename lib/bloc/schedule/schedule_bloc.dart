import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';
export 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_feed.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_timings.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart';
import 'package:tiler_app/bloc/schedule/schedule_recovery_monitor.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tuple/tuple.dart';

import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/previewApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

import '../../services/api/subCalendarEventApi.dart';

// Callers building `EvaluateSchedule` or calling `beginChange` need the
// origin types without a second import.
export 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart'
    show ScheduleChangeOrigin, ScheduleChangeAttribution, ScheduleRevisionGate;
export 'package:tiler_app/bloc/schedule/schedule_change_timings.dart'
    show ScheduleChangeTimings, ScheduleChangeTiming;
export 'package:tiler_app/bloc/schedule/schedule_change_feed.dart'
    show ScheduleChange, ScheduleChangeFeed;

part 'schedule_event.dart';
part 'schedule_state.dart';
part 'schedule_read_state.dart';

enum AuthorizedRouteTileListPage { Daily, Weekly, Monthly }

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  // Read failures outlive individual views and remain available while the
  // calendar's main state is presenting an add/edit/complete evaluation.
  final ScheduleReadCubit reads = ScheduleReadCubit();
  final Duration readTimeout;
  final ScheduleRecoveryMonitor Function(VoidCallback, VoidCallback)?
      recoveryMonitorFactory;
  _ScheduleReadAttempt? _activeRead;
  bool _readsForeground = true;
  DateTime? _lastAutomaticRead;
  bool get canAutomaticallyRetryScheduleReads => _readsForeground && !_closing;

  /// Completes for the actual request, including failure or supersession.
  Future<ScheduleReadOutcome> refreshSchedule({
    Timeline? timeline,
    String? eventId,
    bool automatic = false,
  }) {
    if (isClosed || _closing) {
      return Future.value(ScheduleReadOutcome.skipped);
    }
    final completion = Completer<ScheduleReadOutcome>();
    add(GetScheduleEvent(
        scheduleTimeline: timeline,
        eventId: eventId,
        forceRefresh: true,
        automatic: automatic,
        completion: completion));
    return completion.future;
  }

  Future<ScheduleReadOutcome> retryRead(ScheduleReadFailure failure) =>
      refreshSchedule(timeline: failure.timeline, eventId: failure.eventId);

  /// A gesture refreshes the visible day, even after an edge request failed.
  /// The failure's Retry button separately retains its exact request range.
  Timeline readTimelineFor(DateTime? date) {
    final read = reads.state;
    if (date != null) {
      if (read.hasDataFor(date)) return read.coverage!;
      if (read.requested != null && _includesDate(read.requested!, date)) {
        return read.requested!;
      }
      return Timeline.fromDateTime(DateTime(date.year, date.month, date.day),
          DateTime(date.year, date.month, date.day + 1));
    }
    return read.requested ??
        ScheduleState.generatePriorScheduleState(state).previousLookupTimeline;
  }

  void recoverScheduleReads() {
    if (!_readsForeground ||
        isClosed ||
        tutorialMode ||
        state is ScheduleLoggedOutState ||
        state is ScheduleInitialState) return;
    // Recover the latest requested scope. An older failure on another day
    // must not pull the calendar back to that day's range on reconnection.
    final range = reads.state.requested ?? reads.state.coverage;
    ScheduleReadFailure? failure;
    for (final candidate in reads.state.failures.reversed) {
      if (range != null && candidate.timeline.isEquivalent(range)) {
        failure = candidate;
        break;
      }
    }
    // Reconnection cannot repair missing credentials; the UI offers Sign In.
    if (failure?.error is ScheduleAuthenticationRequired) return;
    unawaited(refreshSchedule(
        timeline: range, eventId: failure?.eventId, automatic: true));
  }

  static final Object _requestZoneKey = Object();
  static final Object _ownerZoneKey = Object();

  /// The bloc running the schedule change the caller is part of, if any.
  /// Lets an API call made for a change reach its bloc even after the
  /// screen that started it has closed.
  static ScheduleBloc? get ofCurrentChange =>
      Zone.current[_ownerZoneKey] as ScheduleBloc?;
  final ScheduleEvaluationStore evaluationStore;

  /// Times each schedule change from the tap to the refreshed calendar.
  final ScheduleChangeTimings timings;
  final ScheduleEvaluationConfig evaluationConfig;
  final DateTime Function() _now;
  ScheduleEvaluation? _evaluation;
  ScheduleEvaluation? _restoredEvaluation;
  Timer? _evaluationTimer;
  Completer<bool>? _evaluationDeadline;
  Timer? _presentationTimer;
  Future<ScheduleRevision>? _baselineFetch;
  bool _initializingChange = false;
  String? _unconfirmedRequestId;
  String _account = 'session';
  int _sessionGeneration = 0;
  int _readGeneration = 0;
  int _sequence = 0;
  int _readsInFlight = 0;
  bool _sent = false;
  bool _fetching = false;
  final Expando<bool> _managedRequests = Expando<bool>();

  /// Unconfirmed writes no longer on the card (a newer write took it, or
  /// the user dismissed it), still checked until they resolve.
  final List<ScheduleEvaluation> _background = <ScheduleEvaluation>[];
  final StreamController<ScheduleChangeOutcome> _outcomes =
      StreamController<ScheduleChangeOutcome>.broadcast();
  ScheduleChangeOutcome? _lastOutcome;
  ScheduleEvaluation? _lastDeclined;
  Timer? _reconcileTimer;
  DateTime? _reconcileSince;
  bool _reconcilePaused = false;
  bool _reconcileInFlight = false;
  int _reconcileAttempt = 0;

  /// Set as soon as [close] starts, so a re-check finishing during close
  /// cannot schedule another.
  bool _closing = false;

  /// Timers bounding status reads made while an outcome is in doubt;
  /// cancelled with the bloc.
  final Set<Timer> _readTimeouts = <Timer>{};

  /// Writes whose outcome just became unknown, checked once against the
  /// schedule before anyone is told; each completes with the verdict.
  final Map<String, Completer<void>> _verdicts = <String, Completer<void>>{};

  /// The most recently admitted write, and the outcomes screens have told.
  String? _lastAdmittedId;

  /// The timing of each admitted write, by evaluation id (bounded).
  final Map<String, ScheduleChangeTiming> _timings =
      <String, ScheduleChangeTiming>{};

  ScheduleChangeTiming? _timingFor(String? evaluationId) =>
      evaluationId == null ? null : _timings[evaluationId];

  /// A change the server confirmed, shown as "Updating your schedule…"
  /// until the schedule read after it is on screen. Holds nothing back.
  ScheduleEvaluation? _refreshing;

  /// What the card shows: the write in progress, else the refresh.
  ScheduleEvaluation? get _shown => _evaluation ?? _refreshing;

  /// Completes when the app is back in the foreground; null while it is.
  Completer<void>? _foreground;
  final Set<String> _toldOutcomes = <String>{};
  StreamSubscription<ScheduleRevision?>? _revisionSubscription;

  ScheduleEvaluation? get activeEvaluation => _evaluation;

  /// Unconfirmed writes being checked in the background (superseded by a
  /// newer write, or dismissed), oldest first.
  List<ScheduleEvaluation> get unresolvedChanges =>
      List.unmodifiable(_background);

  /// How each unconfirmed write turned out.
  Stream<ScheduleChangeOutcome> get outcomes => _outcomes.stream;

  /// The most recent outcome, for messages shown after the fact.
  ScheduleChangeOutcome? get lastOutcome => _lastOutcome;

  /// How the most recently admitted write turned out, once known after its
  /// outcome was in doubt.
  ScheduleChangeOutcome? get latestOutcome {
    final outcome = _lastOutcome;
    return outcome != null && outcome.evaluation.id == _lastAdmittedId
        ? outcome
        : null;
  }

  /// A screen told the user how [evaluationId] turned out; the calendar's
  /// notice for it is then skipped.
  void markOutcomeTold(String evaluationId) {
    _toldOutcomes.add(evaluationId);
    while (_toldOutcomes.length > 16) {
      _toldOutcomes.remove(_toldOutcomes.first);
    }
  }

  bool outcomeTold(String evaluationId) => _toldOutcomes.contains(evaluationId);

  /// The earlier change the user chose not to send again, until the next
  /// admission.
  ScheduleEvaluation? get lastDeclinedChange => _lastDeclined;

  /// Asked before sending a change identical to one still unconfirmed (same
  /// kind and tile). Resolves true to send it again. Unset: no question.
  Future<bool> Function(ScheduleEvaluation unconfirmed)? confirmReattempt;

  /// Hides the uncertainty card; the write keeps being checked.
  void dismissUncertainty() {
    final evaluation = _evaluation;
    if (evaluation == null ||
        evaluation.phase != ScheduleEvaluationPhase.uncertain) return;
    _trace('uncertain_dismissed', request: evaluation);
    _moveToBackground(evaluation);
    _publishEvaluation();
    if (_reconcileTimer == null && !_reconcileInFlight) _scheduleReconcile();
  }

  /// The app went to the background or lost its connection: stop
  /// re-checking until it is back.
  void pauseReconciliation() {
    if (_reconcilePaused) return;
    _reconcilePaused = true;
    _foreground ??= Completer<void>();
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    if (_hasUnresolved) _trace('reconcile_paused');
  }

  /// Back in the foreground or online: check again straight away.
  void resumeReconciliation() {
    if (!_reconcilePaused) return;
    _reconcilePaused = false;
    final foreground = _foreground;
    _foreground = null;
    if (foreground != null && !foreground.isCompleted) foreground.complete();
    if (_hasUnresolved) unawaited(_reconcileTick());
  }

  bool get _hasUnresolved =>
      _evaluation?.phase == ScheduleEvaluationPhase.uncertain ||
      _background.isNotEmpty;

  List<ScheduleEvaluation> get _unresolved => [
        if (_evaluation?.phase == ScheduleEvaluationPhase.uncertain)
          _evaluation!,
        ..._background,
      ];

  /// A write's outcome became unknown: re-read the status now, then on the
  /// cadence, until every unconfirmed write resolves. Reads only; the write
  /// itself is never sent again.
  void _startReconciling({bool immediately = true}) {
    if (isClosed || _closing) return;
    _reconcileSince = _now();
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    if (immediately) {
      unawaited(_reconcileTick());
    } else {
      _scheduleReconcile();
    }
  }

  /// Reads the schedule status within [timeout], on a timer the bloc can
  /// cancel when it closes.
  Future<ScheduleStatus> _readStatus(Duration timeout) {
    final read = Completer<ScheduleStatus>();
    late final Timer timer;
    timer = Timer(timeout, () {
      _readTimeouts.remove(timer);
      if (!read.isCompleted) {
        read.completeError(TimeoutException('Schedule status unavailable'));
      }
    });
    _readTimeouts.add(timer);
    Future.sync(() => scheduleApi.getScheduleStatus()).then((status) {
      if (!read.isCompleted) read.complete(status);
    }, onError: (Object error, StackTrace stack) {
      if (!read.isCompleted) read.completeError(error, stack);
    }).whenComplete(() {
      timer.cancel();
      _readTimeouts.remove(timer);
    });
    return read.future;
  }

  bool _changedSince(ScheduleEvaluation evaluation) =>
      _baselineIsFresh &&
      !revisions.observedAt!.isBefore(evaluation.startedAt) &&
      revisions.state != evaluation.baseline;

  /// The write's outcome just became unknown. Before telling anyone, read
  /// the schedule once (bounded by [ScheduleEvaluationConfig
  /// .uncertaintyGrace]): if it already changed, the write is only
  /// acknowledged; otherwise the card says it is unconfirmed and re-checks
  /// continue. Until then it stays on the card as in progress, and the
  /// screen that sent it waits for the verdict, so the user hears once.
  void _confirmUncertainty(ScheduleEvaluation evaluation, String reason,
      {Object? error, Map<String, Object?> fields = const {}}) {
    final current = _evaluation;
    if (current == null ||
        current.id != evaluation.id ||
        current.phase != ScheduleEvaluationPhase.pending ||
        _verdicts.containsKey(evaluation.id)) return;
    final verdict = Completer<void>();
    _verdicts[evaluation.id] = verdict;
    _trace('mutation_confirming',
        request: current, fields: {'reason': reason, ...fields}, error: error);
    unawaited(_settleUnknownOutcome(current, reason, verdict,
        error: error, fields: fields));
  }

  Future<void> _settleUnknownOutcome(
      ScheduleEvaluation evaluation, String reason, Completer<void> verdict,
      {Object? error, Map<String, Object?> fields = const {}}) async {
    final generation = _sessionGeneration;
    try {
      // Cut off while the app is away (the system drops its connections):
      // nothing can be read until it returns, so decide then, not now.
      await _untilForeground(evaluation);
      if (isClosed || _closing || generation != _sessionGeneration) return;
      if (!_changedSince(evaluation)) {
        try {
          final status = await _readStatus(evaluationConfig.uncertaintyGrace);
          if (isClosed || _closing || generation != _sessionGeneration) {
            return;
          }
          revisions.observe(status);
        } catch (readError) {
          _trace('mutation_confirm_read_failed',
              request: evaluation, error: readError);
        }
      }
      if (isClosed || _closing || generation != _sessionGeneration) return;
      final current = _evaluation;
      // Settled while checking (a late answer): nothing more to decide.
      if (current == null ||
          current.id != evaluation.id ||
          current.phase != ScheduleEvaluationPhase.pending) return;
      _evaluation = current.withPhase(ScheduleEvaluationPhase.uncertain);
      timings.mark(_timingFor(current.id), 'uncertain');
      _trace('mutation_uncertain',
          fields: {'reason': reason, ...fields}, error: error);
      if (_changedSince(current)) {
        _releaseUnconfirmedEvaluation(_evaluation!, 'revision_changed');
        return;
      }
      _publishEvaluation();
      _startReconciling(immediately: false);
    } finally {
      _verdicts.remove(evaluation.id);
      if (!verdict.isCompleted) verdict.complete();
    }
  }

  /// Waits while the app is in the background, at most until
  /// [evaluation]'s deadline, on a timer the bloc cancels when it closes.
  Future<void> _untilForeground(ScheduleEvaluation evaluation) async {
    final foreground = _foreground;
    if (foreground == null) return;
    _trace('mutation_confirm_waiting_foreground', request: evaluation);
    final remaining = evaluation.expiresAt.difference(_now());
    if (remaining <= Duration.zero) return;
    final waited = Completer<void>();
    late final Timer timer;
    timer = Timer(remaining, () {
      _readTimeouts.remove(timer);
      if (!waited.isCompleted) waited.complete();
    });
    _readTimeouts.add(timer);
    unawaited(foreground.future.then((_) {
      if (!waited.isCompleted) waited.complete();
    }));
    await waited.future;
    timer.cancel();
    _readTimeouts.remove(timer);
  }

  /// A change could not start because the schedule could not be read
  /// first. Nothing reached the server; the user is told once, and trying
  /// again is safe.
  void _tellNotSent(
      ScheduleChangeKind kind, String? name, List<String> ids, Object error) {
    final now = _now();
    final unsent = ScheduleEvaluation(
        id: 'unsent_${now.microsecondsSinceEpoch}_${++_sequence}',
        kind: kind,
        account: _account,
        startedAt: now,
        expiresAt: now,
        baseline: revisions.state ?? const ScheduleRevision(null, null),
        baselineObservedAt: now,
        phase: ScheduleEvaluationPhase.failed,
        eventName: name,
        affectedEventCount: ids.isNotEmpty
            ? ids.length
            : name == null
                ? 0
                : 1,
        affectedTileIds: List.unmodifiable(ids));
    _trace('mutation_not_sent', request: unsent, error: error);
    _lastAdmittedId = unsent.id;
    _emitOutcome(unsent, ScheduleChangeOutcomeKind.notSent);
  }

  /// Lets a caller wait for [evaluationId]'s verdict before hearing about it.
  Future<void> _verdictFor(String evaluationId) =>
      _verdicts[evaluationId]?.future ?? Future<void>.value();

  void _scheduleReconcile() {
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    if (isClosed || _closing || _reconcilePaused || !_hasUnresolved) return;
    final since = _now().difference(_reconcileSince ?? _now());
    var delay = since < evaluationConfig.reconcileFastWindow
        ? evaluationConfig.reconcileFastInterval
        : evaluationConfig.reconcileSlowInterval;
    for (final evaluation in _unresolved) {
      final left = evaluation.expiresAt.difference(_now());
      if (left < delay) delay = left.isNegative ? Duration.zero : left;
    }
    _trace('reconcile_scheduled', fields: {
      'delayMs': delay.inMilliseconds,
      'unresolved': _unresolved.length,
    });
    _reconcileTimer = Timer(delay, () => unawaited(_reconcileTick()));
  }

  Future<void> _reconcileTick() async {
    _reconcileTimer = null;
    if (isClosed || _closing) return;
    _reconcileRevision();
    if (!_hasUnresolved) {
      _trace('reconcile_stopped');
      return;
    }
    if (_reconcilePaused || _reconcileInFlight) return;
    _reconcileInFlight = true;
    final generation = _sessionGeneration;
    final attempt = ++_reconcileAttempt;
    _trace('reconcile_attempt', fields: {
      'attempt': attempt,
      'unresolved': _unresolved.length,
      'canConfirmMutation': false,
    });
    try {
      final status = await _readStatus(evaluationConfig.reconcileReadTimeout);
      if (isClosed || generation != _sessionGeneration) return;
      revisions.observe(status);
    } catch (error) {
      _trace('reconcile_failed', error: error, fields: {'attempt': attempt});
    } finally {
      _reconcileInFlight = false;
    }
    if (isClosed || generation != _sessionGeneration) return;
    _reconcileRevision();
    _scheduleReconcile();
  }

  /// Takes [evaluation] off the card and keeps checking it in the
  /// background, journalled so a restart keeps it there.
  void _moveToBackground(ScheduleEvaluation evaluation) {
    if (_evaluation?.id == evaluation.id) {
      _evaluationTimer?.cancel();
      _evaluation = null;
    }
    _changeTokens.remove(evaluation.id);
    if (!_background.any((e) => e.id == evaluation.id)) {
      _background.add(evaluation);
    }
    _clearJournal(evaluation.account, evaluation.id);
    _persistBackground(evaluation.account);
    while (_background.length > evaluationConfig.maxUnresolved) {
      _releaseBackground(_background.first, 'unresolved_limit');
    }
  }

  void _persistBackground(String account) {
    final records = [
      for (final evaluation in _background)
        if (evaluation.account == account) evaluation.toRecord()
    ];
    unawaited(evaluationStore
        .writeBackground(account, records)
        .catchError((Object error) {
      _trace('mutation_background_journal_failed', error: error);
    }));
  }

  void _releaseBackground(ScheduleEvaluation evaluation, String reason) {
    if (!_background.any((e) => e.id == evaluation.id)) return;
    _background.removeWhere((e) => e.id == evaluation.id);
    _persistBackground(evaluation.account);
    _trace('mutation_released_unconfirmed', request: evaluation, fields: {
      'reason': reason,
      'background': true,
      'canConfirmMutation': false,
    });
    _emitOutcome(
        evaluation,
        reason == 'revision_changed'
            ? ScheduleChangeOutcomeKind.acknowledged
            : ScheduleChangeOutcomeKind.unconfirmed);
  }

  void _emitOutcome(
      ScheduleEvaluation evaluation, ScheduleChangeOutcomeKind kind) {
    final outcome = ScheduleChangeOutcome(evaluation, kind);
    _lastOutcome = outcome;
    if (kind == ScheduleChangeOutcomeKind.acknowledged ||
        kind == ScheduleChangeOutcomeKind.confirmed) {
      _trace('mutation_acknowledged', request: evaluation, fields: {
        'reason': kind == ScheduleChangeOutcomeKind.acknowledged
            ? 'revision_changed'
            : 'late_response',
      });
    }
    final timing = _timingFor(evaluation.id);
    timings.mark(timing, 'told', fields: {'told': kind.name});
    switch (kind) {
      case ScheduleChangeOutcomeKind.acknowledged:
      case ScheduleChangeOutcomeKind.confirmed:
        timings.finish(timing, kind.name, awaitRefresh: true);
      case ScheduleChangeOutcomeKind.failed:
      case ScheduleChangeOutcomeKind.unconfirmed:
        timings.finish(timing, kind.name);
      case ScheduleChangeOutcomeKind.notSent:
        break;
    }
    if (!_outcomes.isClosed) _outcomes.add(outcome);
  }

  /// An unconfirmed write the new one would repeat: same kind, same tile.
  ScheduleEvaluation? _repeatOf(ScheduleChangeKind kind, List<String> ids) {
    if (ids.isEmpty) return null;
    for (final evaluation in _unresolved.reversed) {
      if (evaluation.kind == kind &&
          evaluation.affectedTileIds.any(ids.contains)) {
        return evaluation;
      }
    }
    return null;
  }

  bool get lastChangeUnconfirmed => _unconfirmedRequestId != null;
  bool get scheduleChangesBlocked =>
      _evaluation?.blocksChanges == true &&
      _now().isBefore(_evaluation!.expiresAt);
  bool get ownsCurrentEvaluation =>
      _evaluation != null && Zone.current[_requestZoneKey] == _evaluation!.id;

  /// Records a refusal at a UI guard before an API request is attempted.
  void reportBlockedChange(ScheduleChangeKind? requestedKind) =>
      _trace('mutation_blocked', fields: {
        'requestedKind': requestedKind?.name,
        'reason': 'active_evaluation',
      });

  void _trace(String event,
      {ScheduleEvaluation? request,
      Map<String, Object?> fields = const {},
      Object? error}) {
    final evaluation = request ?? _evaluation;
    scheduleFlowLog(event, error: error, fields: {
      'requestId': evaluation?.id,
      'kind': evaluation?.kind.name,
      'phase': evaluation?.phase.name,
      'activeRequestId': _evaluation?.id,
      'activePhase': _evaluation?.phase.name,
      'ageMs': evaluation == null
          ? null
          : _now().difference(evaluation.startedAt).inMilliseconds,
      'remainingMs': evaluation?.expiresAt.difference(_now()).inMilliseconds,
      'baselineKnown': evaluation?.baseline.isKnown,
      'revisionKnown': revisions.state?.isKnown ?? false,
      'observationAgeMs': revisions.observedAt == null
          ? null
          : _now().difference(revisions.observedAt!).inMilliseconds,
      'baselineChanged': evaluation == null || revisions.state == null
          ? null
          : revisions.state != evaluation.baseline,
      'observedAfterStart': evaluation == null || revisions.observedAt == null
          ? null
          : !revisions.observedAt!.isBefore(evaluation.startedAt),
      'initializing': _initializingChange,
      'sent': _sent,
      'blocked': scheduleChangesBlocked,
      'session': _sessionGeneration,
      'read': _readGeneration,
      'readsInFlight': _readsInFlight,
      'state': state.runtimeType.toString(),
      'view': state.currentView.name,
      ...fields,
    });
  }

  /// Refresh can reconcile an interrupted request against its baseline.
  void refreshEvaluationSchedule() {
    _trace('ui_refresh_requested', fields: {
      'canConfirmMutation': false,
      'reason': _evaluation?.phase == ScheduleEvaluationPhase.uncertain
          ? 'check_revision_against_baseline'
          : 'calendar_read_only',
    });
    add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
  }

  void bindEvaluationAccount(String account) {
    if (_account == account || isClosed) return;
    _trace('account_bind', fields: {
      'previousScope': _account == 'session' ? 'session' : 'authenticated',
      'savedRecordPresent': evaluationStore.read(account) != null,
      'sessionRecordPresent': evaluationStore.read('session') != null,
    });
    final outstanding = _evaluation?.awaitsOutcome == true &&
        _now().isBefore(_evaluation!.expiresAt);
    if (outstanding && (_account != 'session' || _sent)) return;
    if (_account != 'session') revisions.reset();
    _account = account;
    if (_evaluation != null) _evaluation = _evaluation!.withAccount(account);
    _restoreBackground(account);
    final scope = evaluationStore.read(account) != null ? account : 'session';
    final saved = evaluationStore.read(scope);
    if (saved != null) {
      _restoredEvaluation = ScheduleEvaluation.fromRecord(saved,
          account: scope, now: _now(), config: evaluationConfig);
      if (_restoredEvaluation == null) {
        _trace('mutation_restore_discarded', fields: {
          'reason': 'missing_baseline_invalid_or_expired_timing',
        });
        _clearJournal(scope, saved['id']);
      } else {
        _trace('mutation_restore_staged', request: _restoredEvaluation);
        _reconcileRevision();
        if (_restoredEvaluation != null) {
          unawaited(_ensureBaseline(force: true).then<void>((_) {
            _reconcileRevision();
          }, onError: (Object error, StackTrace _) {
            _trace('mutation_restore_initialization_failed', error: error);
          }));
        }
      }
    }
  }

  void _restoreBackground(String account) {
    final scope = evaluationStore.readBackground(account).isNotEmpty
        ? account
        : 'session';
    var restored = 0;
    for (final record in evaluationStore.readBackground(scope)) {
      final evaluation = ScheduleEvaluation.fromRecord(record,
          account: scope, now: _now(), config: evaluationConfig);
      if (evaluation == null || _background.any((e) => e.id == evaluation.id))
        continue;
      _background.add(evaluation);
      restored++;
    }
    if (restored == 0) return;
    _trace('mutation_restore_background', fields: {'restored': restored});
    _startReconciling();
  }

  bool get _baselineIsFresh {
    final observed = revisions.observedAt;
    if (revisions.state?.isKnown != true || observed == null) return false;
    final age = _now().difference(observed);
    return !age.isNegative && age <= evaluationConfig.baselineMaxAge;
  }

  Future<ScheduleRevision> _ensureBaseline({bool force = false}) {
    if (!force && _baselineIsFresh) return Future.value(revisions.state!);
    return _baselineFetch ??= _fetchBaseline();
  }

  Future<ScheduleRevision> _fetchBaseline() async {
    final generation = _sessionGeneration;
    _trace('mutation_initialization_started', fields: {
      'initializationTimeoutMs':
          evaluationConfig.initializationTimeout.inMilliseconds,
      'baselineMaxAgeMs': evaluationConfig.baselineMaxAge.inMilliseconds,
    });
    try {
      final status =
          await Future<ScheduleStatus>(() => scheduleApi.getScheduleStatus())
              .timeout(evaluationConfig.initializationTimeout);
      if (isClosed || generation != _sessionGeneration)
        throw ScheduleChangeBlocked();
      if (!ScheduleRevision.fromStatus(status).isKnown)
        throw ScheduleInitializationFailed();
      revisions.observe(status);
      _trace('mutation_initialization_ready');
      return revisions.state!;
    } catch (error) {
      _trace('mutation_initialization_failed', error: error);
      if (!isClosed && generation == _sessionGeneration) _publishEvaluation();
      rethrow;
    } finally {
      if (generation == _sessionGeneration) _baselineFetch = null;
    }
  }

  void _clearJournal(String account, Object? id) {
    if (evaluationStore.read(account)?['id'] != id) return;
    unawaited(evaluationStore.write(account, null).then<void>((_) {
      _trace('mutation_journal_cleared', fields: {'clearedRequestId': id});
    }, onError: (Object error, StackTrace _) {
      _trace('mutation_journal_clear_failed', error: error);
    }));
  }

  void _armEvaluationDeadline() {
    _evaluationTimer?.cancel();
    final evaluation = _evaluation;
    if (evaluation == null || !evaluation.awaitsOutcome) return;
    final remaining = evaluation.expiresAt.difference(_now());
    if (remaining <= Duration.zero) {
      _expireEvaluation();
    } else {
      _evaluationTimer = Timer(remaining, _expireEvaluation);
    }
  }

  void _expireEvaluation() {
    final evaluation = _evaluation;
    if (evaluation == null || !evaluation.awaitsOutcome) return;
    if (_now().isBefore(evaluation.expiresAt)) {
      _armEvaluationDeadline();
      return;
    }
    _releaseUnconfirmedEvaluation(evaluation, 'deadline_expired');
  }

  void _releaseUnconfirmedEvaluation(
      ScheduleEvaluation evaluation, String reason) {
    _trace('mutation_released_unconfirmed',
        request: evaluation,
        fields: {'reason': reason, 'canConfirmMutation': false});
    _emitOutcome(
        evaluation,
        reason == 'revision_changed'
            ? ScheduleChangeOutcomeKind.acknowledged
            : ScheduleChangeOutcomeKind.unconfirmed);
    _clearJournal(evaluation.account, evaluation.id);
    if (reason == 'deadline_expired') _withdrawEvaluation(evaluation);
    if (_evaluation?.id == evaluation.id) {
      _evaluationTimer?.cancel();
      if (_evaluationDeadline?.isCompleted == false) {
        _evaluationDeadline!.complete(reason == 'deadline_expired');
      }
      _evaluation = null;
      _unconfirmedRequestId = evaluation.id;
      _sent = false;
      // Require a new status read before another explicit user write.
      if (reason == 'deadline_expired') revisions.invalidateObservation();
      _publishEvaluation(released: evaluation, releaseReason: reason);
    }
  }

  void _reconcileRevision() {
    _expireEvaluation();
    final restored = _restoredEvaluation;
    if (restored != null) {
      if (!_now().isBefore(restored.expiresAt)) {
        _restoredEvaluation = null;
        _clearJournal(restored.account, restored.id);
        _trace('mutation_restore_discarded',
            request: restored, fields: {'reason': 'deadline_expired'});
      } else if (_baselineIsFresh &&
          !revisions.observedAt!.isBefore(restored.startedAt)) {
        _restoredEvaluation = null;
        if (revisions.state != restored.baseline) {
          _releaseUnconfirmedEvaluation(restored, 'revision_changed');
        } else if (_evaluation?.awaitsOutcome == true) {
          _trace('mutation_restored_uncertain', request: restored, fields: {
            'liveResponseAttached': false,
            'background': true,
          });
          _moveToBackground(restored);
          _startReconciling();
        } else {
          _evaluation = restored;
          _sent = false;
          _armEvaluationDeadline();
          _trace('mutation_restored_uncertain',
              fields: {'liveResponseAttached': false});
          _publishEvaluation();
          _startReconciling();
        }
      }
    }
    final evaluation = _evaluation;
    if (evaluation?.phase == ScheduleEvaluationPhase.uncertain &&
        _baselineIsFresh &&
        !revisions.observedAt!.isBefore(evaluation!.startedAt) &&
        revisions.state != evaluation.baseline) {
      _releaseUnconfirmedEvaluation(evaluation, 'revision_changed');
    }
    for (final background in List.of(_background)) {
      if (!_now().isBefore(background.expiresAt)) {
        _releaseBackground(background, 'deadline_expired');
      } else if (_baselineIsFresh &&
          !revisions.observedAt!.isBefore(background.startedAt) &&
          revisions.state != background.baseline) {
        _releaseBackground(background, 'revision_changed');
      }
    }
  }

  void _publishEvaluation(
      {ScheduleEvaluation? released, String? releaseReason}) {
    if (!isClosed && !_closing)
      add(_EvaluationChangedEvent(_sessionGeneration,
          released: released, releaseReason: releaseReason));
  }

  /// Initialize a known baseline before reservation. Preparation is serialized;
  /// nested API calls inherit ownership, while independent writes reject.
  Future<T> runScheduleChange<T>(Future<T> Function() request,
      {ScheduleChangeKind kind = ScheduleChangeKind.edit,
      String? eventName,
      List<String> affectedTileIds = const []}) {
    final future = _runScheduleChange(request,
        kind: kind, eventName: eventName, affectedTileIds: affectedTileIds);
    _managedRequests[future] = true;
    // EvaluateSchedule may attach after a fast failure. Observe it immediately
    // while preserving the original typed future and its error for callers.
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace __) {}));
    return future;
  }

  Future<T> _runScheduleChange<T>(Future<T> Function() request,
      {ScheduleChangeKind kind = ScheduleChangeKind.edit,
      String? eventName,
      List<String> affectedTileIds = const []}) async {
    final ids = affectedTileIds
        .expand((id) => id.split(','))
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    String? name = eventName?.trim();
    if (name == null || name.isEmpty) {
      name = null;
      if (ids.length == 1) {
        final tiles = ScheduleState.generatePriorScheduleState(state).subEvents;
        for (final tile in tiles) {
          if (tile.id == ids.single ||
              tile.uniqueId == ids.single ||
              tile.calendarEvent?.id == ids.single) {
            final candidate = tile.name?.trim();
            if (candidate != null && candidate.isNotEmpty) {
              name = candidate;
              break;
            }
          }
        }
      }
    }
    _reconcileRevision();
    if (ownsCurrentEvaluation &&
        _evaluation?.phase == ScheduleEvaluationPhase.pending) {
      _trace('mutation_joined', fields: {'requestedKind': kind.name});
      final enriched = _evaluation!.withTarget(ids: ids, name: name);
      if (enriched != _evaluation) {
        _evaluation = enriched;
        _attachEvaluationSubject(enriched);
        _publishEvaluation();
      }
      return request();
    }
    if (scheduleChangesBlocked ||
        _initializingChange ||
        isClosed ||
        Zone.current[_requestZoneKey] != null) {
      _trace('mutation_blocked', fields: {
        'requestedKind': kind.name,
        'reason': isClosed ? 'bloc_closed' : 'active_evaluation'
      });
      throw ScheduleChangeBlocked();
    }
    _lastDeclined = null;
    final timing = timings.start(kind);
    final generation = _sessionGeneration;
    // While an earlier write is unconfirmed, read the schedule first: a
    // change there acknowledges it before this one starts.
    final unresolved = _hasUnresolved;
    if (!_baselineIsFresh || _restoredEvaluation != null || unresolved) {
      _initializingChange = true;
      try {
        await _ensureBaseline(force: _restoredEvaluation != null || unresolved);
        _reconcileRevision();
        if (isClosed ||
            generation != _sessionGeneration ||
            scheduleChangesBlocked) {
          throw ScheduleChangeBlocked();
        }
        final repeat = _repeatOf(kind, ids);
        final confirm = confirmReattempt;
        if (repeat != null && confirm != null) {
          _trace('mutation_reattempt_asked', request: repeat);
          final again = await confirm(repeat);
          if (isClosed ||
              generation != _sessionGeneration ||
              scheduleChangesBlocked) {
            throw ScheduleChangeBlocked();
          }
          if (!again) {
            _lastDeclined = repeat;
            _trace('mutation_reattempt_declined', request: repeat);
            throw ScheduleChangeDeclined();
          }
        }
      } on ScheduleChangeBlocked {
        timings.finish(timing, 'blocked');
        rethrow;
      } on ScheduleChangeDeclined {
        timings.finish(timing, 'declined');
        rethrow;
      } catch (error) {
        // The schedule could not be read first, so nothing was sent.
        if (!isClosed && generation == _sessionGeneration) {
          _tellNotSent(kind, name, ids, error);
        }
        timings.mark(timing, 'told', fields: {'told': 'notSent'});
        timings.finish(timing, 'not_sent');
        rethrow;
      } finally {
        if (generation == _sessionGeneration) _initializingChange = false;
      }
    }
    final superseded = _evaluation;
    if (superseded != null &&
        superseded.phase == ScheduleEvaluationPhase.uncertain) {
      _trace('mutation_superseded',
          request: superseded, fields: {'requestedKind': kind.name});
      _moveToBackground(superseded);
    }
    final startedAt = _now();
    final evaluation = ScheduleEvaluation(
        id: '${startedAt.microsecondsSinceEpoch}_${++_sequence}',
        kind: kind,
        account: _account,
        startedAt: startedAt,
        expiresAt: startedAt.add(evaluationConfig.operationTimeout),
        baseline: revisions.state!,
        baselineObservedAt: revisions.observedAt!,
        eventName: name,
        affectedEventCount: ids.isNotEmpty
            ? ids.length
            : name == null
                ? 0
                : 1,
        affectedTileIds: List.unmodifiable(ids));
    _evaluation = evaluation;
    _lastAdmittedId = evaluation.id;
    timing.requestId = evaluation.id;
    _timings[evaluation.id] = timing;
    while (_timings.length > 16) {
      _timings.remove(_timings.keys.first);
    }
    timings.mark(timing, 'reserved');
    _attributeEvaluation(evaluation);
    _unconfirmedRequestId = null;
    final deadline = Completer<bool>();
    _evaluationDeadline = deadline;
    _presentationTimer?.cancel();
    _sent = false;
    _armEvaluationDeadline();
    _trace('mutation_reserved', fields: {
      'affectedTileCount': affectedTileIds.length,
      'baselineKnown': evaluation.baseline.isKnown,
    });
    _publishEvaluation();
    try {
      final callback = runZoned(request, zoneValues: {
        _requestZoneKey: evaluation.id,
        _ownerZoneKey: this,
      });
      final expiry = deadline.future.then<T>((expired) {
        if (expired) {
          throw TimeoutException(
              'Schedule change deadline expired; outcome unconfirmed');
        }
        return callback;
      });
      final result = await Future.any<T>([callback, expiry]);
      // Fakes/legacy callbacks may not go through HTTP. Their awaited result
      // still settles this evaluation. HTTP itself settles at the 2xx boundary.
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id &&
          _evaluation?.phase == ScheduleEvaluationPhase.pending) {
        await _finishEvaluation(_evaluation!,
            success: result != false &&
                !(result is Tuple2 && result.item2 is TilerError));
      }
      _trace('mutation_callback_completed', request: evaluation, fields: {
        'requestStillActive': _evaluation?.id == evaluation.id,
        'resultType': result.runtimeType.toString(),
      });
      return result;
    } catch (error) {
      _trace('mutation_callback_error', request: evaluation, error: error);
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id &&
          _evaluation?.phase == ScheduleEvaluationPhase.pending &&
          !_verdicts.containsKey(evaluation.id)) {
        final cause = error is TilerError ? error.cause ?? error : error;
        if (_sent &&
            (cause is SocketException ||
                cause is TimeoutException ||
                cause is http.ClientException)) {
          _confirmUncertainty(_evaluation!, 'callback_transport_error',
              error: error);
        } else {
          await _finishEvaluation(_evaluation!, success: false);
        }
      }
      // Tell the caller only once the outcome is as clear as it will get,
      // so the user hears about this change once.
      await _verdictFor(evaluation.id);
      rethrow;
    }
  }

  /// Observe the original transport future so an eventual response can resolve
  /// uncertainty after timeout. Never replay schedule mutations.
  Future<http.StreamedResponse> observeScheduleResponse(
      Future<http.StreamedResponse> Function() send,
      {required ScheduleChangeKind kind,
      Duration timeout = const Duration(seconds: 180)}) async {
    if (!ownsCurrentEvaluation ||
        _evaluation?.phase != ScheduleEvaluationPhase.pending) {
      return runScheduleChange(
          () => observeScheduleResponse(send, kind: kind, timeout: timeout),
          kind: kind);
    }
    if (_restoredEvaluation != null) {
      await _ensureBaseline(force: true);
      _reconcileRevision();
      if (!ownsCurrentEvaluation ||
          _evaluation?.phase != ScheduleEvaluationPhase.pending) {
        throw ScheduleChangeBlocked();
      }
    }
    final evaluation = _evaluation!;
    final generation = _sessionGeneration;
    _trace('mutation_persist_started', request: evaluation);
    await evaluationStore.write(evaluation.account, evaluation.toRecord());
    _trace('mutation_persist_completed', request: evaluation);
    if (isClosed ||
        generation != _sessionGeneration ||
        _evaluation?.id != evaluation.id ||
        !_now().isBefore(evaluation.expiresAt)) {
      _trace('mutation_send_abandoned',
          request: evaluation,
          fields: {'reason': 'ownership_changed_before_send'});
      throw ScheduleChangeBlocked();
    }
    _sent = true;
    timings.mark(_timingFor(evaluation.id), 'sent');
    _trace('mutation_sent',
        request: evaluation,
        fields: {'responseTimeoutMs': timeout.inMilliseconds});
    var timedOut = false;
    final original = Future.sync(send).then((response) async {
      timings.mark(_timingFor(evaluation.id), 'responded',
          fields: {'status': response.statusCode});
      _trace('mutation_response', request: evaluation, fields: {
        'status': response.statusCode,
        'late': timedOut,
        'sameSession': generation == _sessionGeneration,
        'sameRequest': _evaluation?.id == evaluation.id,
      });
      final success = response.statusCode >= 200 && response.statusCode < 300;
      final uncertain =
          response.statusCode == 408 || response.statusCode >= 500;
      if (uncertain) {
        if (generation == _sessionGeneration &&
            _evaluation?.id == evaluation.id) {
          _confirmUncertainty(evaluation, 'http_response_unconfirmed',
              fields: {'status': response.statusCode});
        }
      } else {
        await _finishEvaluation(evaluation, success: success);
      }
      if (!success || timedOut) {
        unawaited(response.stream.drain<void>().catchError((Object _) {}));
      }
      if (!success) {
        await _verdictFor(evaluation.id);
        throw http.ClientException('Schedule change was not confirmed');
      }
      return response;
    }, onError: (Object error, StackTrace stack) async {
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id) {
        _confirmUncertainty(evaluation, 'transport_error', error: error);
      }
      await _verdictFor(evaluation.id);
      Error.throwWithStackTrace(error, stack);
    });
    final remaining = evaluation.expiresAt.difference(_now());
    final responseTimeout = timeout < remaining ? timeout : remaining;
    return original.timeout(responseTimeout, onTimeout: () async {
      timedOut = true;
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id) {
        _confirmUncertainty(evaluation, 'response_timeout', fields: {
          'responseTimeoutMs': timeout.inMilliseconds,
          'liveResponseAttached': true,
        });
      }
      await _verdictFor(evaluation.id);
      throw TimeoutException('Schedule change confirmation unavailable');
    });
  }

  Future<void> _finishEvaluation(ScheduleEvaluation evaluation,
      {required bool success}) async {
    final background = _background.indexWhere((e) => e.id == evaluation.id);
    if (background >= 0) {
      final unconfirmed = _background.removeAt(background);
      _persistBackground(unconfirmed.account);
      _trace('mutation_finished',
          request: unconfirmed,
          fields: {'success': success, 'background': true});
      _emitOutcome(
          unconfirmed,
          success
              ? ScheduleChangeOutcomeKind.confirmed
              : ScheduleChangeOutcomeKind.failed);
      if (success) {
        add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
      }
      return;
    }
    final wasUnconfirmed = _evaluation?.id == evaluation.id &&
        (_evaluation!.phase == ScheduleEvaluationPhase.uncertain ||
            _verdicts.containsKey(evaluation.id));
    if (success && _unconfirmedRequestId == evaluation.id)
      _unconfirmedRequestId = null;
    final saved = evaluationStore.read(evaluation.account);
    _trace('mutation_finish_started', request: evaluation, fields: {
      'success': success,
      'journalPresent': saved != null,
      'journalMatchesRequest': saved == null || saved['id'] == evaluation.id,
    });
    if (saved == null || saved['id'] == evaluation.id) {
      // Journal cleanup cannot delay a confirmed server response or UI release.
      _clearJournal(evaluation.account, saved?['id']);
    }
    if (isClosed || _evaluation?.id != evaluation.id) {
      _trace('mutation_finish_ignored', request: evaluation, fields: {
        'reason': isClosed ? 'bloc_closed' : 'request_no_longer_active'
      });
      return;
    }
    _evaluationTimer?.cancel();
    if (_evaluationDeadline?.isCompleted == false)
      _evaluationDeadline!.complete(false);
    _evaluation =
        success ? null : evaluation.withPhase(ScheduleEvaluationPhase.failed);
    if (success) {
      _changeTokens.remove(evaluation.id);
    } else {
      _withdrawEvaluation(evaluation);
    }
    _trace('mutation_finished',
        request: evaluation, fields: {'success': success});
    if (success && wasUnconfirmed) {
      _emitOutcome(evaluation, ScheduleChangeOutcomeKind.confirmed);
    } else {
      timings.finish(_timingFor(evaluation.id), success ? 'success' : 'failed',
          awaitRefresh: success);
    }
    if (success) _startRefreshing(evaluation);
    _publishEvaluation();
    if (success) {
      revisions.checkAfterChange(baseline: evaluation.baseline);
      add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
    }
  }

  void _startRefreshing(ScheduleEvaluation evaluation) {
    final refreshing = evaluation.withPhase(ScheduleEvaluationPhase.refreshing);
    _refreshing = refreshing;
    _trace('refresh_card_shown', request: refreshing);
  }

  /// The read after the answer ends the "Updating your schedule…" card for
  /// [evaluationId]: with the new schedule, or however else it ends.
  void _endRefreshing(String evaluationId, String reason,
      {bool publish = false}) {
    final refreshing = _refreshing;
    if (refreshing == null || refreshing.id != evaluationId) return;
    _refreshing = null;
    timings.mark(_timingFor(evaluationId), 'cardCleared');
    _trace('refresh_card_cleared',
        request: refreshing, fields: {'reason': reason});
    if (publish) _publishEvaluation();
  }

  void dismissEvaluationFailure() {
    if (_evaluation?.phase == ScheduleEvaluationPhase.failed) {
      _evaluation = null;
      _publishEvaluation();
    }
  }

  /// Every calendar emission consults current evaluation, rather than a request
  /// snapshot captured before another handler started/finished a mutation.
  void _emitCalendar(ScheduleState next, Emitter<ScheduleState> emit) {
    if (emit.isDone) return;
    final shown = _shown;
    if (shown == null) {
      emit(next);
      return;
    }
    final snapshot = ScheduleState.generatePriorScheduleState(next);
    timings.mark(_timingFor(shown.id), 'cardShown');
    _trace('calendar_preserved_evaluation', fields: {
      'readState': next.runtimeType.toString(),
      'tileCount': snapshot.subEvents.length,
      'fetching': _fetching,
      'canConfirmMutation': false,
    });
    emit(ScheduleEvaluationState(
        subEvents: snapshot.subEvents,
        timelines: snapshot.timelines,
        lookupTimeline: snapshot.previousLookupTimeline,
        scheduleStatus: snapshot.scheduleStatus,
        currentView: next.currentView,
        evaluationTime: shown.startedAt,
        evaluation: shown,
        isFetching: _fetching));
  }

  void _onEvaluationChanged(
      _EvaluationChangedEvent event, Emitter<ScheduleState> emit) {
    if (event.generation != _sessionGeneration ||
        state is ScheduleLoggedOutState) return;
    final snapshot = ScheduleState.generatePriorScheduleState(state);
    if (event.released != null &&
        _evaluation == null &&
        _unconfirmedRequestId == event.released!.id) {
      emit(ScheduleEvaluationReleasedState(
          requestId: event.released!.id,
          reason: event.releaseReason!,
          subEvents: snapshot.subEvents,
          timelines: snapshot.timelines,
          lookupTimeline: snapshot.previousLookupTimeline,
          previousLookupTimeline: snapshot.previousLookupTimeline,
          scheduleStatus: snapshot.scheduleStatus,
          currentView: state.currentView));
      return;
    }
    _emitCalendar(
        ScheduleLoadedState(
            subEvents: snapshot.subEvents,
            timelines: snapshot.timelines,
            lookupTimeline: snapshot.previousLookupTimeline,
            previousLookupTimeline: snapshot.previousLookupTimeline,
            scheduleStatus: snapshot.scheduleStatus,
            currentView: state.currentView),
        emit);
  }

  /// When true, `GetScheduleEvent` is a no-op so the tutorial's dummy tiles
  /// are not overwritten by real API data.
  bool tutorialMode = false;

  /// Real schedule data fetched in the background during tutorial mode.
  /// Used to immediately restore the schedule when the tutorial ends,
  /// avoiding the empty-day flash.
  Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>?
      _cachedRealSchedule;

  /// Fetches the real schedule in the background while the tutorial is active.
  /// The result is stored in [_cachedRealSchedule] so it can be emitted
  /// instantly when [restoreCachedSchedule] is called.
  void prefetchRealSchedule() {
    final timeline = Utility.initialScheduleTimeline;
    getSubTiles(timeline).then((value) {
      _cachedRealSchedule = value;
      revisions.observe(value.item3);
      _reconcileRevision();
    }).catchError((_) {
      // Silently ignore — the normal GetScheduleEvent path will retry.
    });
  }

  /// Emits the pre-fetched schedule immediately. Returns `true` if cached data
  /// was available, `false` otherwise (caller should fall back to a normal
  /// GetScheduleEvent).
  bool restoreCachedSchedule() {
    final cached = _cachedRealSchedule;
    _cachedRealSchedule = null;
    if (cached != null) {
      add(ReloadLocalScheduleEvent(
        subEvents: cached.item2,
        timelines: cached.item1,
        lookupTimeline: Utility.initialScheduleTimeline,
        previousLookupTimeline: Utility.initialScheduleTimeline,
        scheduleStatus: cached.item3,
      ));
      return true;
    }
    return false;
  }

  late ScheduleRevisionCubit revisions;
  ScheduleRecoveryMonitor? _recoveryMonitor;

  /// Attributes each new server revision to the change that caused it, or
  /// to a background refresh. Every schedule write the bloc admits records
  /// itself here (see [_attributeEvaluation]), so no flow has to.
  final ScheduleChangeTracker changeTracker = ScheduleChangeTracker();
  StreamSubscription<ScheduleRevision?>? _revisionAttribution;

  /// The tracker record for each admitted evaluation, by evaluation id.
  final Map<String, int> _changeTokens = <String, int>{};

  /// One [ScheduleChange] per new revision, shared by every view and
  /// subscriber that reacts to schedule changes.
  final ScheduleChangeFeed changeFeed = ScheduleChangeFeed();

  @override
  void onChange(Change<ScheduleState> change) {
    super.onChange(change);
    // Before any listener or widget sees the state, so the change and its
    // tiles always arrive together.
    if (changeFeed.observe(change.nextState,
            attribute: changeTracker.resolve) !=
        null) {
      timings.applied();
    }
  }

  /// What a write of [kind] is, as a cause of schedule changes.
  static ScheduleChangeOrigin originOf(ScheduleChangeKind kind) {
    switch (kind) {
      case ScheduleChangeKind.revise:
      case ScheduleChangeKind.shuffle:
      case ScheduleChangeKind.setup:
        return ScheduleChangeOrigin.tilerRevise;
      case ScheduleChangeKind.add:
        return ScheduleChangeOrigin.userAdd;
      case ScheduleChangeKind.complete:
        return ScheduleChangeOrigin.userComplete;
      case ScheduleChangeKind.edit:
      case ScheduleChangeKind.delete:
      case ScheduleChangeKind.defer:
      case ScheduleChangeKind.startNow:
      case ScheduleChangeKind.pause:
      case ScheduleChangeKind.resume:
      case ScheduleChangeKind.settings:
      case ScheduleChangeKind.accept:
        return ScheduleChangeOrigin.userEdit;
    }
  }

  /// Records an admitted write as the cause of the next new revision. The
  /// subject is the one tile it acts on, when it names exactly one.
  void _attributeEvaluation(ScheduleEvaluation evaluation) {
    final ids = evaluation.affectedTileIds;
    _changeTokens[evaluation.id] = changeTracker.begin(
        originOf(evaluation.kind),
        baseline: evaluation.baseline,
        subjectId: ids.length == 1 ? ids.single : null);
  }

  /// A nested call named the tile after the write was admitted.
  void _attachEvaluationSubject(ScheduleEvaluation evaluation) {
    final token = _changeTokens[evaluation.id];
    final ids = evaluation.affectedTileIds;
    if (token != null && ids.length == 1) {
      changeTracker.attachSubject(token, ids.single);
    }
  }

  /// The write did not change the schedule (confirmed failure, or its hold
  /// ended unconfirmed): it must not claim a later, unrelated revision.
  void _withdrawEvaluation(ScheduleEvaluation evaluation) {
    final token = _changeTokens.remove(evaluation.id);
    if (token != null) changeTracker.abandon(token);
  }

  void startRecoveryMonitoring() {
    if (_recoveryMonitor != null) return;
    void recover() {
      _readsForeground = true;
      // Rotate stale sockets after resume; leased requests keep their client.
      scheduleApi.refreshHttpClient();
      _trace('recovery_requested', fields: {'canConfirmMutation': false});
      if (!isClosed && !tutorialMode && state is! ScheduleLoggedOutState) {
        _reconcileRevision();
        revisions.recover();
        resumeReconciliation();
        recoverScheduleReads();
      }
    }

    void suspend() {
      _readsForeground = false;
      _trace('recovery_suspended');
      revisions.suspend();
      pauseReconciliation();
    }

    _recoveryMonitor = (recoveryMonitorFactory?.call(recover, suspend) ??
        ScheduleRecoveryMonitor(onRecover: recover, onSuspend: suspend))
      ..start();
  }

  @override
  Future<void> close() async {
    _closing = true;
    _activeRead?.finish(ScheduleReadOutcome.skipped);
    timings.dispose();
    _evaluationTimer?.cancel();
    _reconcileTimer?.cancel();
    for (final timer in List.of(_readTimeouts)) {
      timer.cancel();
    }
    _readTimeouts.clear();
    await _outcomes.close();
    _presentationTimer?.cancel();
    await _revisionSubscription?.cancel();
    _recoveryMonitor?.close();
    await _revisionAttribution?.cancel();
    await changeFeed.close();
    await revisions.close();
    await reads.close();
    await super.close();
  }

  late ScheduleApi scheduleApi;
  late SubCalendarEventApi subCalendarEventApi;
  Function getContextCallBack;
  late PreviewApi previewApi;
  ScheduleBloc(
      {required Function this.getContextCallBack,
      this.readTimeout = const Duration(seconds: 25),
      this.recoveryMonitorFactory,
      ScheduleEvaluationStore? evaluationStore,
      this.evaluationConfig = const ScheduleEvaluationConfig(),
      DateTime Function()? now,
      ScheduleChangeTimings? timings})
      : evaluationStore = evaluationStore ?? ScheduleEvaluationStore(),
        timings = timings ?? ScheduleChangeTimings(now: now),
        _now = now ?? DateTime.now,
        super(ScheduleInitialState(
            currentView: AuthorizedRouteTileListPage.Daily)) {
    if (evaluationConfig.operationTimeout <= Duration.zero ||
        readTimeout <= Duration.zero ||
        evaluationConfig.initializationTimeout <= Duration.zero ||
        evaluationConfig.baselineMaxAge < Duration.zero) {
      throw ArgumentError('Schedule evaluation timing must be positive');
    }
    // Admission below coalesces equivalent reads before they can cancel one
    // another; different ranges retain the existing latest-request semantics.
    on<GetScheduleEvent>(_onGetSchedule, transformer: concurrent());
    on<LogInScheduleEvent>(_onInitialLogInScheduleEvent);
    on<LogOutScheduleEvent>(_onLoggedOutScheduleEvent);
    on<ReloadLocalScheduleEvent>(_onLocalScheduleEvent);
    on<ReviseScheduleEvent>(_onReviseSchedule);
    on<ShuffleScheduleEvent>(_onShuffleSchedule);
    on<EvaluateSchedule>(_onEvaluateSchedule);
    on<_EvaluationChangedEvent>(_onEvaluationChanged);
    on<ChangeViewEvent>(_onChangeView, transformer: restartable());
    ;
    on<CompleteTaskEvent>(_onCompleteTask);
    scheduleApi = ScheduleApi(getContextCallBack: getContextCallBack);
    revisions = ScheduleRevisionCubit(
        now: _now, fetchStatus: () => scheduleApi.getScheduleStatus());
    // Resolve every new revision as it is observed, so a pending change is
    // claimed by the first revision after it even when no view asks.
    _revisionAttribution = revisions.stream.listen(changeTracker.resolve);
    subCalendarEventApi =
        SubCalendarEventApi(getContextCallBack: getContextCallBack);
    previewApi = PreviewApi(getContextCallBack: getContextCallBack);
    _revisionSubscription = revisions.stream.listen((revision) {
      _reconcileRevision();
      _trace('revision_observed', fields: {
        'known': revision?.isKnown ?? false,
        'canConfirmMutation': false,
      });
      if (revision == null ||
          isClosed ||
          tutorialMode ||
          _readsInFlight > 0 ||
          state is ScheduleInitialState ||
          state is ScheduleLoggedOutState) return;
      final rendered =
          ScheduleState.generatePriorScheduleState(state).scheduleStatus;
      if (ScheduleRevision.fromStatus(rendered) != revision) {
        _trace('revision_requested_read');
        add(GetScheduleEvent(
            forceRefresh: true, emitOnlyLoadedStated: true, automatic: true));
      }
    });
  }

  Future<Tuple3<List<Timeline>, List<SubCalendarEvent>, ScheduleStatus>>
      getSubTiles(Timeline timeLine) async {
    DateTime nextDay = Utility.currentTime().add(Duration(days: 1));
    DateTime endTime =
        DateTime(nextDay.year, nextDay.month, nextDay.day, 0, 0, 0);
    // var resultSummary = await previewApi
    //     .getSummary(Timeline.fromDateTime(Utility.currentTime(), endTime));
    return scheduleApi.getSubEvents(timeLine);
  }

  Future<bool> shouldGetRefreshedListOfTiles(ScheduleStatus currentStatus,
      {bool Function()? isCurrent}) {
    return scheduleApi.getScheduleStatus().then((value) {
      if (isCurrent != null && !isCurrent()) return false;
      revisions.observe(value);
      _reconcileRevision();
      bool isAnalyisTheSame = false;
      bool isEvaluationTheSame = false;
      if (value.analysisId == currentStatus.analysisId) {
        isAnalyisTheSame = true;
        if (currentStatus.analysisId == null ||
            currentStatus.analysisId!.isEmpty) {
          isAnalyisTheSame = false;
        }
      }
      if (value.evaluationId == currentStatus.evaluationId) {
        isEvaluationTheSame = true;
        if (currentStatus.evaluationId == null ||
            currentStatus.evaluationId!.isEmpty) {
          isEvaluationTheSame = false;
        }
      }

      bool retValue = !isAnalyisTheSame || !isEvaluationTheSame;
      print("THere is a change to schedule: " + retValue.toString());
      return retValue;
    });
  }

  void _onLocalScheduleEvent(
      ReloadLocalScheduleEvent event, Emitter<ScheduleState> emit) {
    reads.retain(event.lookupTimeline);
    revisions.observe(event.scheduleStatus);
    _reconcileRevision();
    LocalScheduleLoadedState put = LocalScheduleLoadedState(
        subEvents: event.subEvents,
        timelines: event.timelines,
        scheduleStatus: event.scheduleStatus,
        lookupTimeline: event.lookupTimeline,
        eventId: null,
        previousLookupTimeline: event.previousLookupTimeline,
        currentView: state.currentView);

    _emitCalendar(put, emit);
  }

  void _onLoggedOutScheduleEvent(
      LogOutScheduleEvent event, Emitter<ScheduleState> emit) async {
    _trace('session_logout');
    _activeRead?.finish(ScheduleReadOutcome.skipped);
    _activeRead = null;
    reads.reset();
    _lastAutomaticRead = null;
    ++_sessionGeneration;
    ++_readGeneration;
    _evaluation = null;
    _unconfirmedRequestId = null;
    _restoredEvaluation = null;
    _background.clear();
    _refreshing = null;
    _lastOutcome = null;
    _lastAdmittedId = null;
    _toldOutcomes.clear();
    _lastDeclined = null;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    _evaluationTimer?.cancel();
    _presentationTimer?.cancel();
    _baselineFetch = null;
    _initializingChange = false;
    _account = 'session';
    scheduleApi = ScheduleApi(getContextCallBack: () {
      return event.getContextCallBack();
    });
    revisions.reset();
    changeTracker.reset();
    _changeTokens.clear();
    changeFeed.reset();
    emit(ScheduleLoggedOutState());
  }

  void _onInitialLogInScheduleEvent(
      LogInScheduleEvent event, Emitter<ScheduleState> emit) async {
    _trace('session_login_reset');
    _activeRead?.finish(ScheduleReadOutcome.skipped);
    _activeRead = null;
    reads.reset();
    _lastAutomaticRead = null;
    ++_sessionGeneration;
    ++_readGeneration;
    _evaluation = null;
    _unconfirmedRequestId = null;
    _restoredEvaluation = null;
    _background.clear();
    _refreshing = null;
    _lastOutcome = null;
    _lastAdmittedId = null;
    _toldOutcomes.clear();
    _lastDeclined = null;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    _evaluationTimer?.cancel();
    _presentationTimer?.cancel();
    _baselineFetch = null;
    _initializingChange = false;
    _account = 'session';
    revisions.reset();
    emit(ScheduleInitialState(currentView: state.currentView));
  }

  Future<void> _onCompleteTask(
      CompleteTaskEvent event, Emitter<ScheduleState> emit) async {
    try {
      await runScheduleChange(
          () => subCalendarEventApi.complete(event.subEvent),
          kind: ScheduleChangeKind.complete,
          eventName: event.subEvent.name,
          affectedTileIds: [event.subEvent.id ?? '']);
    } catch (_) {
      // Evaluation retains the request's failure/uncertainty for the UI.
    }
  }

  Future<void> _onGetSchedule(
      GetScheduleEvent event, Emitter<ScheduleState> emit) async {
    _reconcileRevision();
    final endsRefresh = _refreshing?.id;
    if (tutorialMode || state is ScheduleLoggedOutState) {
      event.completion?.complete(ScheduleReadOutcome.skipped);
      _trace('read_skipped', fields: {
        'reason': tutorialMode ? 'tutorial' : 'logged_out',
      });
      if (endsRefresh != null) {
        _endRefreshing(endsRefresh, 'read_skipped', publish: true);
      }
      return;
    }
    final snapshot = ScheduleState.generatePriorScheduleState(state);
    final updateTimeline =
        event.scheduleTimeline ?? snapshot.previousLookupTimeline;
    final active = _activeRead;
    // Automatic hints join any active request so they cannot displace a user
    // action. Explicit requests share work only when range, edge identity,
    // freshness requirement, and post-change refresh ownership agree.
    if (active != null &&
        !active.completion.isCompleted &&
        (event.automatic ||
            (active.timeline.isEquivalent(updateTimeline) &&
                active.event.eventId == event.eventId &&
                (!event.forceRefresh || active.event.forceRefresh) &&
                active.refreshId == endsRefresh))) {
      if (event.completion != null) {
        event.completion!.complete(await active.completion.future);
      }
      return;
    }
    // Resume and connectivity callbacks can arrive just after a fast read has
    // finished. Debounce those hints; explicit Retry remains immediately usable.
    if (event.automatic &&
        (!_readsForeground ||
            (_lastAutomaticRead != null &&
                _now().difference(_lastAutomaticRead!) <
                    const Duration(seconds: 2)))) {
      event.completion?.complete(ScheduleReadOutcome.skipped);
      return;
    }
    if (event.automatic) _lastAutomaticRead = _now();
    // Release the old gesture immediately. Its eventual HTTP response is
    // rejected by the request/session checks below rather than shown as failure.
    active?.finish(ScheduleReadOutcome.superseded);
    final attempt = _ScheduleReadAttempt(updateTimeline, event, endsRefresh);
    _activeRead = attempt;
    if (event.completion != null) {
      unawaited(attempt.completion.future.then((outcome) {
        if (!event.completion!.isCompleted) event.completion!.complete(outcome);
      }));
    }
    // Status lookup and event retrieval share one budget, so a slow first
    // stage cannot leave the user waiting for a second full timeout period.
    final elapsed = Stopwatch()..start();
    Duration remaining() {
      final left = readTimeout - elapsed.elapsed;
      if (left <= Duration.zero)
        throw TimeoutException('Schedule read timed out');
      return left;
    }

    final generation = _sessionGeneration;
    final read = ++_readGeneration;
    // Guard both identities: navigation may supersede a read, and logout/login
    // may replace the account while an old response is still in flight.
    bool isCurrentRead() =>
        !isClosed &&
        !_closing &&
        generation == _sessionGeneration &&
        read == _readGeneration &&
        !attempt.completion.isCompleted;
    // Stop waiting on timeout or supersession and always consume late errors.
    // This releases our timer and waiter; it does not cancel the underlying I/O.
    Future<T> bounded<T>(Future<T> work) {
      final result = Completer<T>();
      final timer = Timer(remaining(), () {
        if (!result.isCompleted) {
          result.completeError(TimeoutException('Schedule read timed out'));
        }
      });
      _readTimeouts.add(timer);
      work.then((value) {
        if (!result.isCompleted) result.complete(value);
      }, onError: (Object error, StackTrace stack) {
        if (!result.isCompleted) result.completeError(error, stack);
      });
      unawaited(attempt.completion.future.then((_) {
        if (!result.isCompleted)
          result.completeError(_ScheduleReadSuperseded());
      }));
      return result.future.whenComplete(() {
        timer.cancel();
        _readTimeouts.remove(timer);
      });
    }

    var outcome = ScheduleReadOutcome.superseded;
    // Event count cannot establish readiness: a verified empty range is loaded.
    final wasLoaded = reads.state.coverage != null;
    reads.begin(updateTimeline, read);
    _fetching = true;
    _readsInFlight++;
    timings.readStarted();
    _trace('read_started', fields: {
      'forceRefresh': event.forceRefresh,
      'quietRefresh': event.emitOnlyLoadedStated,
      'requestedWindowProvided': event.scheduleTimeline != null,
      'tileCount': snapshot.subEvents.length,
      'canConfirmMutation': false,
    });
    if (!event.emitOnlyLoadedStated) {
      _emitCalendar(
          ScheduleLoadingState(
              subEvents: snapshot.subEvents,
              timelines: snapshot.timelines,
              previousLookupTimeline: snapshot.previousLookupTimeline,
              isAlreadyLoaded: wasLoaded,
              scheduleStatus: snapshot.scheduleStatus,
              loadingTime: Utility.currentTime(),
              currentView: state.currentView,
              connectionState: ConnectionState.waiting,
              eventId: event.eventId),
          emit);
    }
    try {
      final fetch = event.forceRefresh ||
          !wasLoaded ||
          event.scheduleTimeline == null ||
          !snapshot.previousLookupTimeline.isStartAndEndEqual(updateTimeline) ||
          await bounded(shouldGetRefreshedListOfTiles(snapshot.scheduleStatus,
              isCurrent: isCurrentRead));
      _trace('read_decision',
          fields: {'fetchTiles': fetch, 'readAttempt': read});
      if (emit.isDone ||
          generation != _sessionGeneration ||
          read != _readGeneration ||
          tutorialMode) {
        _trace('read_ignored', fields: {
          'stage': 'status',
          'readAttempt': read,
          'emitterDone': emit.isDone,
          'sameSession': generation == _sessionGeneration
        });
        return;
      }
      if (fetch) {
        final data = await bounded(getSubTiles(updateTimeline));
        if (emit.isDone ||
            generation != _sessionGeneration ||
            read != _readGeneration ||
            tutorialMode) {
          _trace('read_ignored', fields: {
            'stage': 'tiles',
            'readAttempt': read,
            'emitterDone': emit.isDone,
            'sameSession': generation == _sessionGeneration
          });
          return;
        }
        _trace('read_succeeded', fields: {
          'readAttempt': read,
          'elapsedMs': elapsed.elapsedMilliseconds,
          'tileCount': data.item2.length,
          'analysisChanged':
              data.item3.analysisId != snapshot.scheduleStatus.analysisId,
          'evaluationChanged':
              data.item3.evaluationId != snapshot.scheduleStatus.evaluationId,
          'canConfirmMutation': false,
        });
        revisions.observe(data.item3);
        _reconcileRevision();
        _fetching = false;
        reads.succeed(updateTimeline, _now(), read);
        outcome = ScheduleReadOutcome.succeeded;
        // The card leaves in the same update that shows the new schedule.
        if (endsRefresh != null) _endRefreshing(endsRefresh, 'read_applied');
        _emitCalendar(
            ScheduleLoadedState(
                subEvents: data.item2,
                timelines: data.item1,
                scheduleStatus: data.item3,
                lookupTimeline: updateTimeline,
                previousLookupTimeline: event.previousTimeline,
                currentView: state.currentView,
                eventId: event.eventId),
            emit);
      } else {
        _trace('read_reused_snapshot', fields: {
          'readAttempt': read,
          'elapsedMs': elapsed.elapsedMilliseconds
        });
        _fetching = false;
        reads.succeed(snapshot.previousLookupTimeline, _now(), read);
        outcome = ScheduleReadOutcome.succeeded;
        if (endsRefresh != null) _endRefreshing(endsRefresh, 'read_reused');
        _emitCalendar(
            LocalScheduleLoadedState(
                subEvents: snapshot.subEvents,
                timelines: snapshot.timelines,
                scheduleStatus: snapshot.scheduleStatus,
                lookupTimeline: snapshot.previousLookupTimeline,
                previousLookupTimeline: snapshot.previousLookupTimeline,
                currentView: state.currentView,
                eventId: event.eventId),
            emit);
      }
    } catch (error) {
      if (error is _ScheduleReadSuperseded || !isCurrentRead()) return;
      _trace('read_failed', error: error, fields: {
        'readAttempt': read,
        'elapsedMs': elapsed.elapsedMilliseconds,
        'sameSession': generation == _sessionGeneration,
        'emitterDone': emit.isDone,
        'canConfirmMutation': false,
      });
      if (emit.isDone ||
          generation != _sessionGeneration ||
          read != _readGeneration) return;
      _fetching = false;
      reads.fail(ScheduleReadFailure(updateTimeline, read, error,
          eventId: event.eventId));
      outcome = ScheduleReadOutcome.failed;
      if (endsRefresh != null) _endRefreshing(endsRefresh, 'read_failed');
      // Failure of a read cannot settle a mutation or remove its feedback.
      final current = ScheduleState.generatePriorScheduleState(state);
      _emitCalendar(
          FailedScheduleLoadedState(
              evaluationTime: Utility.currentTime(),
              subEvents: current.subEvents,
              timelines: current.timelines,
              scheduleStatus: current.scheduleStatus,
              lookupTimeline: current.previousLookupTimeline,
              previousLookupTimeline: current.previousLookupTimeline,
              currentView: state.currentView,
              eventId: event.eventId),
          emit);
    } finally {
      attempt.finish(outcome);
      if (identical(_activeRead, attempt)) _activeRead = null;
      _readsInFlight--;
      if (read == _readGeneration) _fetching = false;
      if (endsRefresh != null && read == _readGeneration) {
        _endRefreshing(endsRefresh, 'read_finished', publish: true);
      }
      timings.readFinished();
      _trace('read_finished', fields: {
        'readAttempt': read,
        'elapsedMs': elapsed.elapsedMilliseconds,
        'stillUncertain':
            _evaluation?.phase == ScheduleEvaluationPhase.uncertain,
      });
    }
  }

  static Tuple6<
      List<SubCalendarEvent>?,
      List<Timeline>?,
      Timeline?,
      String?,
      ScheduleStatus,
      AuthorizedRouteTileListPage> preserveState(ScheduleState state) {
    List<SubCalendarEvent>? subEvents;
    List<Timeline>? timelines;
    Timeline? lookupTimeline;
    String? message;
    ScheduleStatus scheduleStatus = ScheduleStatus();

    if (state is ScheduleLoadedState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      lookupTimeline = state.lookupTimeline;
      scheduleStatus = state.scheduleStatus;
    }

    if (state is ScheduleEvaluationState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      lookupTimeline = state.lookupTimeline;
    }

    if (state is ScheduleLoadingState) {
      subEvents = state.subEvents;
      timelines = state.timelines;
      scheduleStatus = state.scheduleStatus;
      lookupTimeline = state.previousLookupTimeline;
    }

    if (state is ScheduleInitialState) {
      subEvents = [];
      timelines = [];
      lookupTimeline = Utility.initialScheduleTimeline;
      scheduleStatus = ScheduleStatus();
    }

    return Tuple6<List<SubCalendarEvent>?, List<Timeline>?, Timeline?, String?,
            ScheduleStatus, AuthorizedRouteTileListPage>(subEvents, timelines,
        lookupTimeline, message, scheduleStatus, state.currentView);
  }

  Future<void> _onReviseSchedule(
      ReviseScheduleEvent event, Emitter<ScheduleState> emit) async {
    try {
      await runScheduleChange(scheduleApi.reviseSchedule,
          kind: ScheduleChangeKind.revise);
    } catch (_) {}
  }

  Future<void> _onEvaluateSchedule(
      EvaluateSchedule event, Emitter<ScheduleState> emit) async {
    if (event.request != null) {
      try {
        await runScheduleChange(event.request!,
            kind: event.kind,
            eventName: event.eventName,
            affectedTileIds: event.affectedTileIds);
      } catch (_) {}
      return;
    }
    if (event.callBack != null) {
      // Compatibility for callers handing over an already-started future.
      // API-owned requests have already reserved evaluation synchronously.
      if (_evaluation != null || _managedRequests[event.callBack!] == true) {
        try {
          await event.callBack;
        } catch (_) {}
      } else {
        try {
          await runScheduleChange(() async => await event.callBack,
              kind: event.kind,
              eventName: event.eventName,
              affectedTileIds: event.affectedTileIds);
        } catch (_) {}
      }
      return;
    }
    // Legacy editor beginEvaluation is presentation only. The API call owns
    // admission/outcome, so a manual begin cannot admit a conflicting write.
    if (_evaluation != null) return;
    _presentationTimer?.cancel();
    _presentationTimer = Timer(evaluationConfig.initializationTimeout, () {
      if (_evaluation == null) _publishEvaluation();
    });
    emit(ScheduleEvaluationState(
        subEvents: event.renderedSubEvents,
        timelines: event.renderedTimelines,
        lookupTimeline: event.renderedScheduleTimeline,
        evaluationTime: Utility.currentTime(),
        scheduleStatus: event.scheduleStatus,
        currentView: state.currentView,
        message: event.message));
  }

  Future<void> _onShuffleSchedule(
      ShuffleScheduleEvent event, Emitter<ScheduleState> emit) async {
    try {
      await runScheduleChange(scheduleApi.shuffleSchedule,
          kind: ScheduleChangeKind.shuffle);
    } catch (_) {}
  }

  void _onChangeView(ChangeViewEvent event, Emitter<ScheduleState> emit) {
    // Preserve the connection and snapshot while changing only the view.
    final snapshot = ScheduleState.generatePriorScheduleState(state);
    _emitCalendar(
        ScheduleLoadedState(
            subEvents: snapshot.subEvents,
            timelines: snapshot.timelines,
            lookupTimeline: snapshot.previousLookupTimeline,
            previousLookupTimeline: snapshot.previousLookupTimeline,
            scheduleStatus: snapshot.scheduleStatus,
            currentView: event.newView),
        emit);
    // The newly mounted view loads its selected range through TileList.
  }
}
