import 'dart:convert';

import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/api/tileShareEnvelope.dart';
import 'package:tiler_app/services/api/tileShareTransport.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// A recipient change that did not succeed, with enough to act on and to log.
class TileShareRecipientFailure implements Exception {
  final TileShareFailureKind kind;
  final int? statusCode;
  final String? reason;

  const TileShareRecipientFailure(this.kind, {this.statusCode, this.reason});

  @override
  String toString() => 'TileShareRecipientFailure(${kind.name}'
      '${statusCode == null ? '' : ', HTTP $statusCode'}'
      '${reason == null ? '' : ', $reason'})';
}

/// Adding and removing a tilette's recipients (redesign Step 9.13).
///
/// * [addRecipient] invites a contact to a tilette (a removed recipient is
///   restored) and answers with the tilette and its recipients, so a roster
///   refreshes from the answer instead of reloading.
/// * [removeRecipient] removes one recipient's assignment - the same route the
///   web uses.
///
/// A failure is a [TileShareRecipientFailure] (by HTTP status, with the
/// server's reason); a 200 that is not shaped as expected, or that carries a
/// Tiler error, is a `StateError`. Nothing that failed is ever reported done.
class TileShareRecipientsApi extends AppApi with TileShareTransport {
  static const String _tag = 'TileShareRecipientsApi';
  static const String _contactRoute = 'api/TileshareTemplate/contact';

  TileShareRecipientsApi({required super.getContextCallBack});

  @override
  String get transportTag => _tag;

  @override
  Exception transportFailure(TileShareFailureKind kind,
          {int? statusCode, String? reason}) =>
      TileShareRecipientFailure(kind, statusCode: statusCode, reason: reason);

  Future<TileShareTemplate> addRecipient(
      String tiletteId, Contact contact) async {
    final String body = await tileShareSend('PUT', _contactRoute, body: {
      'EntityId': tiletteId,
      'Contact': <String, Object?>{
        if ((contact.email ?? '').trim().isNotEmpty)
          'Email': contact.email!.trim(),
        if ((contact.phoneNumber ?? '').trim().isNotEmpty)
          'PhoneNumber': contact.phoneNumber!.trim(),
      },
    });
    final Map<String, dynamic> content = readTileShareContent(body,
        tag: _tag, what: 'Add recipient', requiredKey: 'tileTemplate');
    return TileShareTemplate.fromJson(
        Map<String, dynamic>.from(content['tileTemplate'] as Map));
  }

  Future<void> removeRecipient(String tiletteId, String assignmentId) async {
    final String body = await tileShareSend('DELETE', _contactRoute,
        body: {'TiletteId': tiletteId, 'AssignmentId': assignmentId});
    _expectSuccess(body, 'Remove recipient');
  }

  /// A 200 whose envelope carries a Tiler error is not success.
  static void _expectSuccess(String body, String what) {
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      return; // No envelope to contradict the 2xx.
    }
    if (decoded is Map) {
      final Object? error = decoded['Error'];
      final Object? code = error is Map ? error['Code'] : null;
      if (code != null && num.tryParse('$code') != 0) {
        final String message = '$what: server error $code '
            '(${(error as Map)['Message']})';
        TileShareLog.d(_tag, message);
        throw StateError(message);
      }
    }
  }
}
