import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Local diagnostics only. Callers supply counts, phases, and local request
/// identities, never credentials, account identifiers, or request payloads.
/// Debug builds log by default; other builds can opt in with
/// --dart-define=TILER_SCHEDULE_LOGS=true.
void scheduleFlowLog(String event,
    {Map<String, Object?> fields = const {}, Object? error}) {
  if (!kDebugMode && !const bool.fromEnvironment('TILER_SCHEDULE_LOGS')) return;
  debugPrint('[ScheduleFlow] ${jsonEncode({
        'time': DateTime.now().toUtc().toIso8601String(),
        'event': event,
        ...fields,
        if (error != null) 'errorType': error.runtimeType.toString(),
        if (error is SocketException) 'socketCode': error.osError?.errorCode,
        if (error is TimeoutException)
          'timeoutMs': error.duration?.inMilliseconds,
      })}');
}
