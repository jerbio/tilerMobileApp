import 'dart:convert';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/bloc/schedule/schedule_revision_cubit.dart';

enum ScheduleChangeKind {
  revise,
  shuffle,
  add,
  edit,
  complete,
  delete,
  defer,
  startNow,
  pause,
  resume,
  settings,
  accept,
}

/// HTTP writes are classified here so every entry point shares the same lock.
/// Reads and previews can continue while a schedule mutation is running.
ScheduleChangeKind? scheduleMutationKind(String method, String path) {
  if (!['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase())) {
    return null;
  }
  final route = path.toLowerCase().replaceFirst(RegExp(r'^/+'), '');
  if (route == 'api/schedule/event') {
    return method.toUpperCase() == 'DELETE'
        ? ScheduleChangeKind.delete
        : ScheduleChangeKind.add;
  }
  if (route == 'api/calendarevent' && method.toUpperCase() == 'DELETE') {
    return ScheduleChangeKind.delete;
  }
  const routes = {
    'api/schedule/revise': ScheduleChangeKind.revise,
    'api/schedule/buzz': ScheduleChangeKind.revise,
    'api/schedule/shuffle': ScheduleChangeKind.shuffle,
    'api/schedule/procrastinateall': ScheduleChangeKind.defer,
    'api/schedule/event/procrastinate': ScheduleChangeKind.defer,
    'api/schedule/event/complete': ScheduleChangeKind.complete,
    'api/schedule/events/complete': ScheduleChangeKind.complete,
    'api/calendarevent/complete': ScheduleChangeKind.complete,
    'api/schedule/event/now': ScheduleChangeKind.startNow,
    'api/calendarevent/now': ScheduleChangeKind.startNow,
    'api/schedule/event/pause': ScheduleChangeKind.pause,
    'api/schedule/event/resume': ScheduleChangeKind.resume,
    'api/subcalendarevent/update': ScheduleChangeKind.edit,
    'api/calendarevent/update': ScheduleChangeKind.edit,
    'api/vibe/request/execute': ScheduleChangeKind.edit,
    'manage/restrictionprofile': ScheduleChangeKind.settings,
    'manage/updatestartofday': ScheduleChangeKind.settings,
    'api/user/settings': ScheduleChangeKind.settings,
    'api/user': ScheduleChangeKind.settings,
    'api/integrations/location': ScheduleChangeKind.settings,
    'api/designatedtile/status': ScheduleChangeKind.accept,
    'api/integrations/google/calendaritem': ScheduleChangeKind.settings,
  };
  if (route == 'api/integrations' && method.toUpperCase() == 'DELETE') {
    return ScheduleChangeKind.delete;
  }
  return routes[route];
}

enum ScheduleEvaluationPhase { pending, uncertain, failed }

/// Wall-clock bounds; neither refresh nor process restart extends a deadline.
class ScheduleEvaluationConfig {
  const ScheduleEvaluationConfig({
    this.operationTimeout = const Duration(
        seconds: int.fromEnvironment('TILER_SCHEDULE_OPERATION_TIMEOUT_SECONDS',
            defaultValue: 180)),
    this.initializationTimeout = const Duration(
        seconds: int.fromEnvironment(
            'TILER_SCHEDULE_INITIALIZATION_TIMEOUT_SECONDS',
            defaultValue: 30)),
    this.baselineMaxAge = const Duration(
        seconds: int.fromEnvironment('TILER_SCHEDULE_BASELINE_MAX_AGE_SECONDS',
            defaultValue: 30)),
    this.reconcileFastInterval = const Duration(seconds: 5),
    this.reconcileFastWindow = const Duration(seconds: 30),
    this.reconcileSlowInterval = const Duration(seconds: 15),
    this.maxUnresolved = 3,
    this.uncertaintyGrace = const Duration(seconds: 3),
  });
  final Duration operationTimeout;
  final Duration initializationTimeout;
  final Duration baselineMaxAge;

  /// While a write's outcome is unknown, the schedule status is re-read
  /// every [reconcileFastInterval] for the first [reconcileFastWindow],
  /// then every [reconcileSlowInterval] until its deadline. Reads only.
  final Duration reconcileFastInterval;
  final Duration reconcileFastWindow;
  final Duration reconcileSlowInterval;

  /// Unconfirmed writes still checked in the background; beyond this the
  /// oldest is let go.
  final int maxUnresolved;

  /// When a write's outcome becomes unknown, the schedule is read once,
  /// for at most this long, before the user is told anything.
  final Duration uncertaintyGrace;
}

/// How a write whose outcome was unknown turned out, for a notice.
enum ScheduleChangeOutcomeKind {
  /// The schedule changed after the write started; it may have applied.
  acknowledged,

  /// Its own late 2xx arrived.
  confirmed,

  /// Its own late refusal arrived.
  failed,

  /// Its deadline passed with no evidence either way.
  unconfirmed,
}

class ScheduleChangeOutcome {
  const ScheduleChangeOutcome(this.evaluation, this.kind);
  final ScheduleEvaluation evaluation;
  final ScheduleChangeOutcomeKind kind;
}

/// A request owned by ScheduleBloc; revisions only describe data freshness.
class ScheduleEvaluation extends Equatable {
  const ScheduleEvaluation(
      {required this.id,
      required this.kind,
      required this.account,
      required this.startedAt,
      required this.expiresAt,
      required this.baseline,
      required this.baselineObservedAt,
      this.phase = ScheduleEvaluationPhase.pending,
      this.eventName,
      this.affectedEventCount = 0,
      this.affectedTileIds = const []});
  final String id;
  final ScheduleChangeKind kind;
  final String account;
  final DateTime startedAt;
  final DateTime expiresAt;
  final ScheduleRevision baseline;
  final DateTime baselineObservedAt;
  final ScheduleEvaluationPhase phase;
  final List<String> affectedTileIds;

  /// Snapshot of the command's target, independent of subsequent calendar reads.
  final String? eventName;
  final int affectedEventCount;

  /// Only a write still in flight holds other writes back. One whose outcome
  /// is unknown informs the user but leaves them free to carry on.
  bool get blocksChanges => phase == ScheduleEvaluationPhase.pending;

  /// Still waiting to learn whether it applied (in flight or unknown).
  bool get awaitsOutcome => phase != ScheduleEvaluationPhase.failed;
  ScheduleEvaluation withPhase(ScheduleEvaluationPhase phase) =>
      ScheduleEvaluation(
          id: id,
          kind: kind,
          account: account,
          startedAt: startedAt,
          expiresAt: expiresAt,
          baseline: baseline,
          baselineObservedAt: baselineObservedAt,
          phase: phase,
          eventName: eventName,
          affectedEventCount: affectedEventCount,
          affectedTileIds: affectedTileIds);
  ScheduleEvaluation withAccount(String account) => ScheduleEvaluation(
      id: id,
      kind: kind,
      account: account,
      startedAt: startedAt,
      expiresAt: expiresAt,
      baseline: baseline,
      baselineObservedAt: baselineObservedAt,
      phase: phase,
      eventName: eventName,
      affectedEventCount: affectedEventCount,
      affectedTileIds: affectedTileIds);
  @override
  List<Object?> get props =>
      [id, kind, phase, affectedTileIds, eventName, affectedEventCount];

  ScheduleEvaluation withTarget({required List<String> ids, String? name}) =>
      ScheduleEvaluation(
          id: id,
          kind: kind,
          account: account,
          startedAt: startedAt,
          expiresAt: expiresAt,
          baseline: baseline,
          baselineObservedAt: baselineObservedAt,
          phase: phase,
          affectedTileIds: affectedTileIds.isEmpty
              ? List.unmodifiable(ids)
              : affectedTileIds,
          eventName: eventName ?? name,
          affectedEventCount: affectedEventCount > 0
              ? affectedEventCount
              : ids.isNotEmpty
                  ? ids.length
                  : name == null
                      ? 0
                      : 1);

  Map<String, dynamic> toRecord() => {
        'version': 2,
        'id': id,
        'kind': kind.name,
        'analysisId': baseline.analysisId,
        'evaluationId': baseline.evaluationId,
        'baselineObservedAt': baselineObservedAt.millisecondsSinceEpoch,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'eventName': eventName,
        'affectedEventCount': affectedEventCount,
      };

  static ScheduleEvaluation? fromRecord(Map<String, dynamic> record,
      {required String account,
      required DateTime now,
      required ScheduleEvaluationConfig config}) {
    try {
      if (record['version'] != 2 ||
          record['id'] is! String ||
          (record['id'] as String).isEmpty) return null;
      final baseline = ScheduleRevision(
          record['analysisId'] as String?, record['evaluationId'] as String?);
      if (!baseline.isKnown) return null;
      final started =
          DateTime.fromMillisecondsSinceEpoch(record['startedAt'] as int);
      final observed = DateTime.fromMillisecondsSinceEpoch(
          record['baselineObservedAt'] as int);
      final savedDeadline =
          DateTime.fromMillisecondsSinceEpoch(record['expiresAt'] as int);
      final configuredDeadline = started.add(config.operationTimeout);
      final deadline = savedDeadline.isBefore(configuredDeadline)
          ? savedDeadline
          : configuredDeadline;
      if (started.isAfter(now) ||
          observed.isAfter(started) ||
          started.difference(observed) > config.baselineMaxAge ||
          !deadline.isAfter(now) ||
          !deadline.isAfter(started)) return null;
      return ScheduleEvaluation(
          id: record['id'] as String,
          kind: ScheduleChangeKind.values
              .firstWhere((k) => k.name == record['kind']),
          account: account,
          startedAt: started,
          expiresAt: deadline,
          baseline: baseline,
          baselineObservedAt: observed,
          eventName: record['eventName'] is String &&
                  (record['eventName'] as String).trim().isNotEmpty
              ? (record['eventName'] as String).trim()
              : null,
          affectedEventCount: record['affectedEventCount'] is int &&
                  (record['affectedEventCount'] as int) > 0
              ? record['affectedEventCount'] as int
              : 0,
          phase: ScheduleEvaluationPhase.uncertain);
    } catch (_) {
      return null;
    }
  }
}

class ScheduleInitializationFailed extends TilerError {
  ScheduleInitializationFailed()
      : super(Message: 'Refresh the schedule before making a change.');
}

/// The user chose not to send a change again while an earlier, identical
/// one was still unconfirmed. Nothing was sent.
class ScheduleChangeDeclined extends TilerError {
  ScheduleChangeDeclined() : super(Message: 'The change was not sent again.');
}

class ScheduleChangeBlocked extends TilerError {
  ScheduleChangeBlocked()
      : super(
            Message:
                'Finish the current schedule change before starting another.');
}

/// Stores identity, target display details, baseline hashes and timing.
/// Credentials and mutation payloads are never stored or logged.
/// Writes are serialized so a late disk write cannot resurrect a finished task.
class ScheduleEvaluationStore {
  ScheduleEvaluationStore() : _preferences = null;
  ScheduleEvaluationStore._(this._preferences, this._records);
  final SharedPreferences? _preferences;
  Map<String, dynamic> _records = {};
  Future<void> _writes = Future<void>.value();
  static const _key = 'schedule_operations_v1';

  static Future<ScheduleEvaluationStore> load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    Map<String, dynamic> records;
    try {
      records = raw == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (error) {
      scheduleFlowLog('journal_load_invalid',
          error: error, fields: {'restoredAsUncertain': false});
      records = {};
    }
    scheduleFlowLog('journal_loaded', fields: {
      'present': raw != null,
      'recordCount': records.length,
      'wildcardRecord': records.containsKey('*'),
    });
    return ScheduleEvaluationStore._(preferences, records);
  }

  /// Unconfirmed writes checked in the background (superseded or dismissed)
  /// for [account], oldest first.
  List<Map<String, dynamic>> readBackground(String account) {
    final records = _records[_backgroundKey(account)];
    if (records is! List) return const [];
    return [
      for (final record in records)
        if (record is Map) Map<String, dynamic>.from(record)
    ];
  }

  Future<void> writeBackground(
          String account, List<Map<String, dynamic>> records) =>
      write(_backgroundKey(account), records.isEmpty ? null : records);

  static String _backgroundKey(String account) => '$account#background';

  Map<String, dynamic>? read(String account) {
    final record = _records[account];
    if (record == null) return null;
    if (record is! Map) {
      scheduleFlowLog('journal_record_invalid',
          fields: {'restoredAsUncertain': false});
      return null;
    }
    return Map<String, dynamic>.from(record);
  }

  Future<void> write(String account, Object? record) {
    if (record == null) {
      _records.remove(account);
    } else {
      _records[account] = record;
    }
    final snapshot = jsonEncode(_records);
    final next = _writes.then((_) async {
      try {
        final saved = await _preferences?.setString(_key, snapshot);
        if (saved == false) throw StateError('Operation could not be saved');
        scheduleFlowLog('journal_write_completed', fields: {
          'action': record == null ? 'clear' : 'save',
          'persistent': _preferences != null,
        });
      } catch (error) {
        scheduleFlowLog('journal_write_failed', error: error, fields: {
          'action': record == null ? 'clear' : 'save',
        });
        rethrow;
      }
    });
    _writes = next.catchError((Object _) {});
    return next;
  }
}
