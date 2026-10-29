import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Filter the console by [LocationFlow]. No coordinates or request payloads.
/// Silent by default in all builds. Opt in for diagnostic runs with
/// --dart-define=TILER_LOCATION_LOGS=true.
void locationFlowLog(String event,
    {Map<String, Object?> fields = const {}, Object? error}) {
  if (!const bool.fromEnvironment('TILER_LOCATION_LOGS')) return;
  try {
    debugPrint('[LocationFlow] ${jsonEncode({
          'time': DateTime.now().toUtc().toIso8601String(),
          'event': event,
          ...fields,
          if (error != null) 'errorType': error.runtimeType.toString(),
          if (error is TimeoutException)
            'timeoutMs': error.duration?.inMilliseconds,
        })}');
  } catch (_) {
    // Diagnostics must not interrupt location or request handling.
  }
}
