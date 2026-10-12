import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';

/// An immutable revision, available both as current state and a subscription.
class ScheduleRevision extends Equatable {
  const ScheduleRevision(this.analysisId, this.evaluationId);

  factory ScheduleRevision.fromStatus(ScheduleStatus status) =>
      ScheduleRevision(status.analysisId, status.evaluationId);

  final String? analysisId;
  final String? evaluationId;
  bool get isKnown =>
      (analysisId ?? '').isNotEmpty && (evaluationId ?? '').isNotEmpty;

  @override
  List<Object?> get props => [analysisId, evaluationId];
}

/// Shared status polling: consumers subscribe without starting their own polls.
class ScheduleRevisionCubit extends Cubit<ScheduleRevision?> {
  ScheduleRevisionCubit({
    required this.fetchStatus,
    DateTime Function()? now,
    this.retryDelays = const [
      Duration(milliseconds: 500),
      Duration(seconds: 1),
      Duration(seconds: 2),
    ],
  })  : _now = now ?? DateTime.now,
        super(null);

  final DateTime Function() _now;
  DateTime? observedAt;
  void invalidateObservation() => observedAt = null;

  final Future<ScheduleStatus> Function() fetchStatus;
  final List<Duration> retryDelays;
  Timer? _timer;
  int _generation = 0;
  final _recovery = StreamController<void>.broadcast();
  Stream<void> get recovery => _recovery.stream;
  ScheduleRevision? _pendingBaseline;

  /// Resume/reconnection also lets consumers retry failed reads at the same revision.
  void recover() {
    if (isClosed) return;
    scheduleFlowLog('revision_recover', fields: {
      'generation': _generation,
      'baselineKnown': _pendingBaseline?.isKnown ?? false
    });
    _recovery.add(null);
    checkAfterChange(baseline: _pendingBaseline, forceCheck: true);
  }

  void suspend() {
    scheduleFlowLog('revision_suspend', fields: {'generation': _generation});
    ++_generation;
    _timer?.cancel();
  }

  void observe(ScheduleStatus status) {
    final revision = ScheduleRevision.fromStatus(status);
    if (revision != state) {
      scheduleFlowLog('revision_changed', fields: {
        'known': revision.isKnown,
        'analysisChanged': revision.analysisId != state?.analysisId,
        'evaluationChanged': revision.evaluationId != state?.evaluationId,
        'canConfirmMutation': false,
      });
    }
    if (!isClosed && revision.isKnown) {
      observedAt = _now();
      emit(revision);
    }
  }

  /// Call after a mutation, with its pre-mutation revision when available.
  void checkAfterChange({ScheduleRevision? baseline, bool forceCheck = false}) {
    final previous = baseline ?? state;
    _pendingBaseline = previous;
    final generation = ++_generation;
    scheduleFlowLog('revision_check_started', fields: {
      'generation': generation,
      'forceCheck': forceCheck,
      'baselineKnown': previous?.isKnown ?? false,
    });
    _timer?.cancel();
    Future<void> check(int attempt) async {
      if (isClosed || generation != _generation) return;
      if (!(forceCheck && attempt == 0) &&
          previous != null &&
          state != null &&
          state != previous) {
        _pendingBaseline = null;
        return;
      }
      try {
        scheduleFlowLog('revision_check_attempt', fields: {
          'generation': generation,
          'attempt': attempt + 1,
        });
        final status = await fetchStatus();
        if (isClosed || generation != _generation) return;
        observe(status);
        scheduleFlowLog('revision_check_succeeded', fields: {
          'generation': generation,
          'attempt': attempt + 1,
          'changed': state != null && state != previous,
          'canConfirmMutation': false,
        });
        if (forceCheck) _recovery.add(null);
        if (state != null && state != previous) {
          _pendingBaseline = null;
          return;
        }
      } catch (error) {
        scheduleFlowLog('revision_check_failed', error: error, fields: {
          'generation': generation,
          'attempt': attempt + 1,
        });
        // Transient failures share the same bounded retry budget.
      }
      if (!isClosed &&
          generation == _generation &&
          attempt < retryDelays.length) {
        _timer = Timer(retryDelays[attempt], () => check(attempt + 1));
      } else if (!isClosed && generation == _generation) {
        scheduleFlowLog('revision_check_exhausted', fields: {
          'generation': generation,
          'attempts': attempt + 1,
        });
      }
    }

    unawaited(check(0));
  }

  void reset() {
    ++_generation;
    _timer?.cancel();
    _pendingBaseline = null;
    observedAt = null;
    emit(null);
  }

  @override
  Future<void> close() {
    ++_generation;
    _timer?.cancel();
    unawaited(_recovery.close());
    return super.close();
  }
}
