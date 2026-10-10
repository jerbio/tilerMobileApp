import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/util.dart';

/// The one place TileShare writes diagnostic lines, so they are tagged with
/// where they came from (`TileShareAttention: …`, `TileShareInvitationsApi: …`)
/// and easy to filter in the console.
///
/// The default sink is the project's [Utility.debugPrint], which prints in
/// debug builds and for the developer account in production. Tests replace
/// [sink] to read what was logged.
abstract final class TileShareLog {
  static void Function(String message) sink = _defaultSink;

  static void _defaultSink(String message) {
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
