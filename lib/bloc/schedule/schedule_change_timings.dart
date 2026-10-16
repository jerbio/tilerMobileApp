import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:tiler_app/bloc/schedule/schedule_diagnostics.dart';
import 'package:tiler_app/bloc/schedule/schedule_evaluation.dart';
import 'package:tiler_app/services/analyticsSignal.dart';

/// One schedule change, timed from the tap to the refreshed calendar.
///
/// Marks are milliseconds since the tap, recorded the first time each
/// happens: `reserved`, `cardShown`, `sent`, `responded`, `uncertain`,
/// `told`, `settled`, `readStarted`, `applied`, `readFinished`, `rendered`.
/// A schedule update that lands before the change settles (an earlier
/// change's result, loaded meanwhile) is `appliedWhilePending`: it is not
/// this change's refresh.
class ScheduleChangeTiming {
  ScheduleChangeTiming(this.kind, this.startedAt);
  final ScheduleChangeKind kind;
  final DateTime startedAt;
  String? requestId;

  final Map<String, int> _marks = <String, int>{};
  final Map<String, Object?> _fields = <String, Object?>{};
  String? _outcome;
  bool _awaitingRefresh = false;
  bool _reported = false;

  int? _at(String name) => _marks[name];

  int? _span(String from, String to) {
    final start = _at(from), end = _at(to);
    return start == null || end == null ? null : end - start;
  }
}

/// Where a schedule change's time goes, so a calendar that looks stuck or
/// messages that seem to contradict each other can be read off one line.
///
/// Each change is reported once, as `schedule_change_timing` in the
/// schedule log and as an analytics event:
/// - `prepareMs`: tap to admitted (includes reading the schedule first);
/// - `sendMs`: POST sent to its response;
/// - `waitForDataMs`: settled to the new schedule arriving, the time the
///   change looks done while the old schedule is still shown;
/// - `readMs`: the schedule read after the change;
/// - `renderMs`: the new schedule arriving to the first frame painted;
/// - `totalMs`: tap to the refreshed calendar (or to the last mark).
///
/// A failed change (or one never sent) reports at once. One still open
/// after [reportAfter] is reported as `incomplete` at the next timing
/// event; no timer is kept per change.
class ScheduleChangeTimings {
  ScheduleChangeTimings({
    DateTime Function()? now,
    void Function(VoidCallback callback)? onNextFrame,
    void Function(Map<String, Object?> fields)? report,
    this.reportAfter = const Duration(minutes: 4),
    bool? enabled,
  })  : enabled = enabled ??
            resolveEnabled(
                debugMode: kDebugMode,
                setting:
                    const String.fromEnvironment('TILER_SCHEDULE_TIMINGS')),
        _now = now ?? DateTime.now,
        _onNextFrame = onNextFrame ?? _afterNextFrame,
        _report = report ?? _log;

  final DateTime Function() _now;
  final void Function(VoidCallback callback) _onNextFrame;
  final void Function(Map<String, Object?> fields) _report;
  final Duration reportAfter;

  /// Whether changes are timed and reported. Off, nothing is recorded,
  /// logged or sent.
  final bool enabled;

  /// On in debug builds, off in release and profile builds. Override with
  /// `--dart-define=TILER_SCHEDULE_TIMINGS=true` (to troubleshoot a release
  /// build) or `=false`; any other value keeps the build default.
  static bool resolveEnabled(
      {required bool debugMode, required String setting}) {
    switch (setting.trim().toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return debugMode;
    }
  }

  final List<ScheduleChangeTiming> _open = <ScheduleChangeTiming>[];
  bool _frameRequested = false;
  bool _disposed = false;

  static void _afterNextFrame(VoidCallback callback) {
    SchedulerBinding.instance
      ..addPostFrameCallback((_) => callback())
      ..ensureVisualUpdate();
  }

  static void _log(Map<String, Object?> fields) {
    scheduleFlowLog('schedule_change_timing', fields: fields);
    unawaited(AnalysticsSignal.send('schedule_change_timing',
        additionalInfo: fields));
  }

  ScheduleChangeTiming start(ScheduleChangeKind kind) {
    final timing = ScheduleChangeTiming(kind, _now());
    if (!enabled || _disposed) return timing;
    _sweep();
    _open.add(timing);
    return timing;
  }

  void mark(ScheduleChangeTiming? timing, String name,
      {Map<String, Object?> fields = const {}}) {
    if (!enabled) return;
    _sweep();
    if (timing == null || timing._reported) return;
    timing._marks.putIfAbsent(name, () => _elapsed(timing));
    for (final entry in fields.entries) {
      timing._fields.putIfAbsent(entry.key, () => entry.value);
    }
  }

  /// The change has an outcome. With [awaitRefresh] the report waits for
  /// the refreshed schedule to be read and painted.
  void finish(ScheduleChangeTiming? timing, String outcome,
      {bool awaitRefresh = false}) {
    if (!enabled || timing == null || timing._reported) return;
    timing._outcome ??= outcome;
    mark(timing, 'settled');
    if (!awaitRefresh) {
      _reportNow(timing);
      return;
    }
    // Reported once the read that follows the answer has finished and the
    // next frame is painted.
    timing._awaitingRefresh = true;
  }

  void readStarted() {
    _sweep();
    for (final timing in _awaiting) {
      mark(timing, 'readStarted');
    }
  }

  void readFinished() {
    final awaiting = _awaiting.toList();
    if (awaiting.isEmpty) return;
    for (final timing in awaiting) {
      mark(timing, 'readFinished');
    }
    _afterFrame();
  }

  /// A new schedule revision was emitted to the views.
  void applied() {
    _sweep();
    for (final timing in List.of(_open)) {
      mark(timing, timing._awaitingRefresh ? 'applied' : 'appliedWhilePending');
    }
  }

  Iterable<ScheduleChangeTiming> get _awaiting =>
      _open.where((t) => t._awaitingRefresh && !t._reported);

  void _afterFrame() {
    if (_frameRequested || _disposed) return;
    _frameRequested = true;
    _onNextFrame(() {
      _frameRequested = false;
      if (_disposed) return;
      for (final timing in _awaiting.toList()) {
        if (timing._at('readFinished') == null) continue;
        mark(timing, 'rendered');
        _reportNow(timing);
      }
    });
  }

  /// Reports changes open longer than [reportAfter] as incomplete.
  void _sweep() {
    for (final timing in List.of(_open)) {
      if (_now().difference(timing.startedAt) <= reportAfter) continue;
      timing._outcome ??= 'incomplete';
      _reportNow(timing);
    }
  }

  int _elapsed(ScheduleChangeTiming timing) =>
      _now().difference(timing.startedAt).inMilliseconds;

  void _reportNow(ScheduleChangeTiming timing) {
    if (timing._reported) return;
    timing._reported = true;
    _open.remove(timing);
    final marks = timing._marks;
    final last = marks.values.isEmpty ? 0 : marks.values.reduce(_max);
    _report({
      'requestId': timing.requestId,
      'kind': timing.kind.name,
      'outcome': timing._outcome,
      ...timing._fields,
      'prepareMs': marks['reserved'],
      'sendMs': timing._span('sent', 'responded'),
      'waitForDataMs': timing._span('settled', 'applied'),
      'readMs': timing._span('readStarted', 'readFinished'),
      'renderMs': timing._span('applied', 'rendered'),
      'totalMs': marks['rendered'] ?? last,
      'marks': Map<String, int>.of(marks),
    });
  }

  static int _max(int a, int b) => a > b ? a : b;

  /// Stops timing (the bloc closed); unfinished changes are not reported.
  void dispose() {
    _disposed = true;
    _open.clear();
  }
}
