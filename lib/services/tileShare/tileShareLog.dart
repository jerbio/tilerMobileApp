import 'package:flutter/foundation.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/util.dart';

/// The one place TileShare writes diagnostic lines, so they are tagged with
/// where they came from (`TileShareAttention: …`, `TileShareInvitationsApi: …`)
/// and easy to filter in the console.
///
/// Flutter debug builds log regardless of which backend they connect to.
/// Profile/release builds can opt in with
/// `--dart-define=TILESHARE_DIAGNOSTICS=true`; otherwise they keep the project's
/// [Utility.debugPrint] policy. Tests replace [sink] to read what was logged.
abstract final class TileShareLog {
  static const bool _diagnosticsEnabled =
      bool.fromEnvironment('TILESHARE_DIAGNOSTICS');

  static void Function(String message) sink = _defaultSink;

  static void _defaultSink(String message) {
    if (kDebugMode || _diagnosticsEnabled) {
      debugPrint(message);
      return;
    }
    Utility.debugPrint(message);
  }

  /// Logs "[tag]: [message]". A logger that fails must never break the code
  /// that is logging.
  static void d(String tag, String message) {
    try {
      sink('$tag: $message');
    } catch (_) {}
  }

  /// [error] as a log line can read it: a [TilerError] by its code and the
  /// server's message (its own `toString` says only "Instance of ...").
  static String describe(Object error) => error is TilerError
      ? 'TilerError(${error.Code ?? '-'}): ${error.Message ?? ''}'
      : '$error';
}
