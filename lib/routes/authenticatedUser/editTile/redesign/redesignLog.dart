// Edit Tile / Tile Detail redesign — structured console logging.
//
// The plan's "Observe" vocabulary (`edit_tile_load_failed(code)`,
// `tile_detail_save_failed(code)`, …), written to the app logger. The
// analytics sink is a no-op app-wide (O1), so on a device round THESE are
// how a failure gets read: one line per event, the identity of the tile,
// the reason code, and the underlying error's message.
//
// Never written out: a provider user id, a session, a token — only whether
// a provider user id was present.
import 'package:flutter/foundation.dart';
import 'package:tiler_app/util.dart';

class RedesignLog {
  RedesignLog._();

  /// Test seam: when set, receives every event instead of the logger.
  static void Function(String event, Map<String, Object?> data)? sink;

  /// Records [event] with [data]. A failure carries the error's message
  /// under `error` and its type under `errorType`; the stack goes to the
  /// logger, not the line.
  static void event(String event, Map<String, Object?> data,
      {Object? error, StackTrace? stack}) {
    final Map<String, Object?> line = <String, Object?>{
      ...data,
      if (error != null) 'errorType': error.runtimeType.toString(),
      if (error != null) 'error': _message(error),
    };
    final void Function(String, Map<String, Object?>)? s = sink;
    if (s != null) {
      s(event, line);
      return;
    }
    final String text = '[redesign] $event '
        '${line.entries.map((e) => '${e.key}=${e.value}').join(' ')}';
    if (error != null) {
      Utility.log.e(text, error: error, stackTrace: stack);
    } else if (kDebugMode) {
      Utility.log.i(text);
    }
  }

  /// `TilerError` carries its text in `Message`; everything else in
  /// `toString()`.
  static String _message(Object error) {
    try {
      final dynamic e = error;
      final Object? message = e.Message;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // Not a TilerError.
    }
    return error.toString();
  }
}
