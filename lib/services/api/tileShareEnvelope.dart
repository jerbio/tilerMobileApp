import 'dart:convert';

import 'package:tiler_app/services/tileShare/tileShareLog.dart';

/// Reads a TileShare read response.
///
/// The backend answers through `PostBackData`, so the payload is wrapped:
/// `{"Error": {"Code": 0, "Message": "SUCCESS"}, "Content": {...}}`. Returns
/// the `Content` map. A bare map (no envelope) is accepted as it is.
///
/// Anything else is an error that says what was wrong — a non-zero Tiler error
/// code, a body that is not an object, or a payload missing the list named by
/// [listKey] — and is logged under [tag]. Silently treating a missing list as
/// "nothing there" once made a broken response look like an empty inbox.
Map<String, dynamic> readTileShareContent(
  String body, {
  required String tag,
  required String what,
  required String listKey,
}) {
  Never fail(String message) {
    TileShareLog.d(tag, '$what: $message');
    throw StateError('$what: $message');
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(body);
  } on FormatException {
    fail('the response was not JSON');
  }
  if (decoded is! Map<String, dynamic>) fail('the response was not an object');

  Map<String, dynamic> content = decoded;
  if (decoded.containsKey('Content') || decoded.containsKey('Error')) {
    final Object? error = decoded['Error'];
    // The wire carries the code as a string ("0" is success); be lenient about
    // a number too.
    final Object? code = error is Map ? error['Code'] : null;
    if (code != null && num.tryParse('$code') != 0) {
      fail('server error $code (${(error as Map)['Message']})');
    }
    final Object? inner = decoded['Content'];
    if (inner is! Map<String, dynamic>) fail('the response had no Content');
    content = inner;
  }

  if (content[listKey] is! List) {
    fail('the response had no "$listKey" list '
        '(found: ${content.keys.join(', ')})');
  }
  return content;
}
