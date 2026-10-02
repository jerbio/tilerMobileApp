import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tiler_app/data/tileSharePreview.dart';

/// An accept that was sent and whose outcome is not known yet.
///
/// The server's accept is idempotent: repeating the **same command** (operation
/// id, token, mode, session and interval) returns the stored outcome - or
/// resumes an interrupted acceptance - and never accepts twice. So that a
/// timeout, a lost connection or a closed app can be recovered, the command is
/// kept until its outcome is known.
class PendingAccept {
  final String operationId;
  final String assignmentId;
  final String previewToken;
  final TileShareAcceptanceMode mode;
  final String? sessionKey;
  final TileShareLockedTimeLine? lockedTimeLine;
  final int savedAtMs;

  const PendingAccept({
    required this.operationId,
    required this.assignmentId,
    required this.previewToken,
    required this.mode,
    this.sessionKey,
    this.lockedTimeLine,
    required this.savedAtMs,
  });

  Map<String, Object?> toJson() => <String, Object?>{
        'operationId': operationId,
        'assignmentId': assignmentId,
        'previewToken': previewToken,
        'mode': mode.wire,
        if (sessionKey != null) 'sessionKey': sessionKey,
        if (lockedTimeLine != null) 'lockedTimeLine': lockedTimeLine!.toJson(),
        'savedAtMs': savedAtMs,
      };

  /// `null` when [json] is not a command that could be repeated.
  static PendingAccept? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? operationId = json['operationId'];
    final Object? assignmentId = json['assignmentId'];
    final Object? previewToken = json['previewToken'];
    final Object? modeWire = json['mode'];
    final Object? savedAt = json['savedAtMs'];
    if (operationId is! String ||
        assignmentId is! String ||
        previewToken is! String ||
        modeWire is! String ||
        savedAt is! num) {
      return null;
    }
    TileShareAcceptanceMode? mode;
    for (final TileShareAcceptanceMode candidate
        in TileShareAcceptanceMode.values) {
      if (candidate.wire == modeWire) mode = candidate;
    }
    if (mode == null) return null;

    final Object? key = json['sessionKey'];
    final Object? line = json['lockedTimeLine'];
    TileShareLockedTimeLine? lockedTimeLine;
    if (line is Map &&
        line['StartTimeUnixMsUtc'] is num &&
        line['DurationInMs'] is num) {
      lockedTimeLine = TileShareLockedTimeLine(
          startMs: (line['StartTimeUnixMsUtc'] as num).toInt(),
          durationMs: (line['DurationInMs'] as num).toInt());
    }
    // A lock names its session and interval; without them it cannot be repeated.
    if (mode == TileShareAcceptanceMode.lockSession &&
        (key is! String || key.isEmpty || lockedTimeLine == null)) {
      return null;
    }
    return PendingAccept(
      operationId: operationId,
      assignmentId: assignmentId,
      previewToken: previewToken,
      mode: mode,
      sessionKey: key is String ? key : null,
      lockedTimeLine: lockedTimeLine,
      savedAtMs: savedAt.toInt(),
    );
  }
}

/// Where the unconfirmed accept is kept. An interface so the preview cubit can
/// be tested without the platform.
abstract class TileSharePendingAcceptStore {
  Future<PendingAccept?> read(String assignmentId);

  Future<void> save(PendingAccept pending);

  Future<void> clear(String assignmentId);
}

/// [SharedPreferences] storage, scoped to the signed-in account and the
/// assignment. Never throws on absent or corrupt values, and forgets a command
/// older than the server keeps operation outcomes (seven days).
class StoredTileSharePendingAcceptStore implements TileSharePendingAcceptStore {
  static const Duration maxAge = Duration(days: 7);

  final String accountKey;
  final DateTime Function() _clock;

  StoredTileSharePendingAcceptStore({
    required this.accountKey,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  String _key(String assignmentId) =>
      'tileSharePendingAccept:$accountKey:$assignmentId';

  @override
  Future<PendingAccept?> read(String assignmentId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(assignmentId));
    if (raw == null) return null;
    PendingAccept? pending;
    try {
      pending = PendingAccept.fromJson(jsonDecode(raw));
    } catch (_) {
      pending = null;
    }
    final bool expired = pending != null &&
        _clock().millisecondsSinceEpoch - pending.savedAtMs >
            maxAge.inMilliseconds;
    if (pending == null || expired) {
      await prefs.remove(_key(assignmentId));
      return null;
    }
    return pending;
  }

  @override
  Future<void> save(PendingAccept pending) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key(pending.assignmentId), jsonEncode(pending.toJson()));
  }

  @override
  Future<void> clear(String assignmentId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(assignmentId));
  }
}
