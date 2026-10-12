import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';
export 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/bloc/schedule/schedule_change_feed.dart';
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
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

import '../../services/api/subCalendarEventApi.dart';

// Callers building `EvaluateSchedule` or calling `beginChange` need the
// origin types without a second import.
export 'package:tiler_app/bloc/schedule/schedule_change_tracker.dart'
    show
        ScheduleChangeOrigin,
        ScheduleChangeAttribution,
        ScheduleRevisionGate;
export 'package:tiler_app/bloc/schedule/schedule_change_feed.dart'
    show ScheduleChange, ScheduleChangeFeed;

part 'schedule_event.dart';
part 'schedule_state.dart';

enum AuthorizedRouteTileListPage { Daily, Weekly, Monthly }

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  static final Object _requestZoneKey = Object();
  static final Object _ownerZoneKey = Object();

  /// The bloc running the schedule change the caller is part of, if any.
  /// Lets an API call made for a change reach its bloc even after the
  /// screen that started it has closed.
  static ScheduleBloc? get ofCurrentChange =>
      Zone.current[_ownerZoneKey] as ScheduleBloc?;
  final ScheduleEvaluationStore evaluationStore;
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
  StreamSubscription<ScheduleRevision?>? _revisionSubscription;

  ScheduleEvaluation? get activeEvaluation => _evaluation;
  bool get lastChangeUnconfirmed => _unconfirmedRequestId != null;
  bool get scheduleChangesBlocked =>
      _evaluation?.blocksChanges == true &&
      _now().isBefore(_evaluation!.expiresAt);
  bool get ownsCurrentEvaluation =>
      _evaluation != null && Zone.current[_requestZoneKey] == _evaluation!.id;

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
    if (scheduleChangesBlocked && (_account != 'session' || _sent)) return;
    if (_account != 'session') revisions.reset();
    _account = account;
    if (_evaluation != null) _evaluation = _evaluation!.withAccount(account);
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
    if (evaluation == null || !evaluation.blocksChanges) return;
    final remaining = evaluation.expiresAt.difference(_now());
    if (remaining <= Duration.zero) {
      _expireEvaluation();
    } else {
      _evaluationTimer = Timer(remaining, _expireEvaluation);
    }
  }

  void _expireEvaluation() {
    final evaluation = _evaluation;
    if (evaluation == null || !evaluation.blocksChanges) return;
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
        } else {
          _evaluation = restored;
          _sent = false;
          _armEvaluationDeadline();
          _trace('mutation_restored_uncertain',
              fields: {'liveResponseAttached': false});
          _publishEvaluation();
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
  }

  void _publishEvaluation(
      {ScheduleEvaluation? released, String? releaseReason}) {
    if (!isClosed)
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
    final generation = _sessionGeneration;
    if (!_baselineIsFresh || _restoredEvaluation != null) {
      _initializingChange = true;
      try {
        await _ensureBaseline(force: _restoredEvaluation != null);
        _reconcileRevision();
        if (isClosed ||
            generation != _sessionGeneration ||
            scheduleChangesBlocked) {
          throw ScheduleChangeBlocked();
        }
      } finally {
        if (generation == _sessionGeneration) _initializingChange = false;
      }
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
          _evaluation?.phase == ScheduleEvaluationPhase.pending) {
        if (_sent &&
            (error is SocketException ||
                error is TimeoutException ||
                error is http.ClientException)) {
          _evaluation =
              _evaluation!.withPhase(ScheduleEvaluationPhase.uncertain);
          _trace('mutation_uncertain',
              fields: {'reason': 'callback_transport_error'}, error: error);
          _publishEvaluation();
          _reconcileRevision();
        } else {
          await _finishEvaluation(_evaluation!, success: false);
        }
      }
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
    _trace('mutation_sent',
        request: evaluation,
        fields: {'responseTimeoutMs': timeout.inMilliseconds});
    var timedOut = false;
    final original = Future.sync(send).then((response) async {
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
          _evaluation = evaluation.withPhase(ScheduleEvaluationPhase.uncertain);
          _trace('mutation_uncertain', fields: {
            'reason': 'http_response_unconfirmed',
            'status': response.statusCode,
          });
          _publishEvaluation();
          _reconcileRevision();
        }
      } else {
        await _finishEvaluation(evaluation, success: success);
      }
      if (!success || timedOut) {
        unawaited(response.stream.drain<void>().catchError((Object _) {}));
      }
      if (!success)
        throw http.ClientException('Schedule change was not confirmed');
      return response;
    }, onError: (Object error, StackTrace stack) {
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id) {
        _evaluation = evaluation.withPhase(ScheduleEvaluationPhase.uncertain);
        _trace('mutation_uncertain',
            fields: {'reason': 'transport_error'}, error: error);
        _publishEvaluation();
        _reconcileRevision();
      }
      Error.throwWithStackTrace(error, stack);
    });
    final remaining = evaluation.expiresAt.difference(_now());
    final responseTimeout = timeout < remaining ? timeout : remaining;
    return original.timeout(responseTimeout, onTimeout: () {
      timedOut = true;
      if (generation == _sessionGeneration &&
          _evaluation?.id == evaluation.id) {
        _evaluation = evaluation.withPhase(ScheduleEvaluationPhase.uncertain);
        _trace('mutation_uncertain', fields: {
          'reason': 'response_timeout',
          'responseTimeoutMs': timeout.inMilliseconds,
          'liveResponseAttached': true,
        });
        _publishEvaluation();
        _reconcileRevision();
      }
      throw TimeoutException('Schedule change confirmation unavailable');
    });
  }

  Future<void> _finishEvaluation(ScheduleEvaluation evaluation,
      {required bool success}) async {
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
    _publishEvaluation();
    if (success) {
      revisions.checkAfterChange(baseline: evaluation.baseline);
      add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
    }
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
    if (_evaluation == null) {
      emit(next);
      return;
    }
    final snapshot = ScheduleState.generatePriorScheduleState(next);
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
        evaluationTime: _evaluation!.startedAt,
        evaluation: _evaluation,
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
    changeFeed.observe(change.nextState, attribute: changeTracker.resolve);
  }

  /// What a write of [kind] is, as a cause of schedule changes.
  static ScheduleChangeOrigin originOf(ScheduleChangeKind kind) {
    switch (kind) {
      case ScheduleChangeKind.revise:
      case ScheduleChangeKind.shuffle:
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
    _recoveryMonitor = ScheduleRecoveryMonitor(
      onRecover: () {
        _trace('recovery_requested', fields: {'canConfirmMutation': false});
        if (!isClosed && !tutorialMode && state is! ScheduleLoggedOutState) {
          _reconcileRevision();
          revisions.recover();
        }
      },
      onSuspend: () {
        _trace('recovery_suspended');
        revisions.suspend();
      },
    )..start();
  }

  @override
  Future<void> close() async {
    _evaluationTimer?.cancel();
    _presentationTimer?.cancel();
    await _revisionSubscription?.cancel();
    _recoveryMonitor?.close();
    await _revisionAttribution?.cancel();
    await changeFeed.close();
    await revisions.close();
    await super.close();
  }

  late ScheduleApi scheduleApi;
  late SubCalendarEventApi subCalendarEventApi;
  Function getContextCallBack;
  late PreviewApi previewApi;
  ScheduleBloc(
      {required Function this.getContextCallBack,
      ScheduleEvaluationStore? evaluationStore,
      this.evaluationConfig = const ScheduleEvaluationConfig(),
      DateTime Function()? now})
      : evaluationStore = evaluationStore ?? ScheduleEvaluationStore(),
        _now = now ?? DateTime.now,
        super(ScheduleInitialState(
            currentView: AuthorizedRouteTileListPage.Daily)) {
    if (evaluationConfig.operationTimeout <= Duration.zero ||
        evaluationConfig.initializationTimeout <= Duration.zero ||
        evaluationConfig.baselineMaxAge < Duration.zero) {
      throw ArgumentError('Schedule evaluation timing must be positive');
    }
    on<GetScheduleEvent>(_onGetSchedule, transformer: restartable());
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
        add(GetScheduleEvent(forceRefresh: true, emitOnlyLoadedStated: true));
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

  Future<bool> shouldGetRefreshedListOfTiles(ScheduleStatus currentStatus) {
    return scheduleApi.getScheduleStatus().then((value) {
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
    ++_sessionGeneration;
    ++_readGeneration;
    _evaluation = null;
    _unconfirmedRequestId = null;
    _restoredEvaluation = null;
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
    ++_sessionGeneration;
    ++_readGeneration;
    _evaluation = null;
    _unconfirmedRequestId = null;
    _restoredEvaluation = null;
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
    if (tutorialMode || state is ScheduleLoggedOutState) {
      _trace('read_skipped', fields: {
        'reason': tutorialMode ? 'tutorial' : 'logged_out',
      });
      return;
    }
    final elapsed = Stopwatch()..start();
    final generation = _sessionGeneration;
    final read = ++_readGeneration;
    final snapshot = ScheduleState.generatePriorScheduleState(state);
    final updateTimeline =
        event.scheduleTimeline ?? snapshot.previousLookupTimeline;
    final wasLoaded = state is ScheduleLoadedState ||
        state is ScheduleEvaluationState ||
        (state is ScheduleLoadingState &&
            (state as ScheduleLoadingState).isAlreadyLoaded);
    _fetching = true;
    _readsInFlight++;
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
          await shouldGetRefreshedListOfTiles(snapshot.scheduleStatus);
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
        final data = await getSubTiles(updateTimeline);
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
      _readsInFlight--;
      if (read == _readGeneration) _fetching = false;
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
