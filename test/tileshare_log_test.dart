// TileShare logging: every TileShare log line goes through one sink, tagged
// with where it came from, so tests can read it and the app can decide where it
// goes (Flutter debug builds log even when using the production backend).
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/constants.dart' as constants;
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

void main() {
  late void Function(String) originalSink;

  setUp(() => originalSink = TileShareLog.sink);
  tearDown(() => TileShareLog.sink = originalSink);

  test('debug logging does not depend on the backend or developer account', () {
    final lines = <String>[];
    final previousPrint = debugPrint;
    final previousUserId = constants.userId;
    final previousUserName = constants.userName;
    try {
      constants.userId = '';
      constants.userName = '';
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) lines.add(message);
      };
      TileShareLog.d('TileShareDetail', 'diagnostics visible');
      expect(lines, ['TileShareDetail: diagnostics visible']);
    } finally {
      debugPrint = previousPrint;
      constants.userId = previousUserId;
      constants.userName = previousUserName;
    }
  });

  test('a line is "tag: message"', () {
    final lines = <String>[];
    TileShareLog.sink = lines.add;
    TileShareLog.d('TileShareAttention', 'loaded invitations=2');
    expect(lines, ['TileShareAttention: loaded invitations=2']);
  });

  test('a sink that throws never breaks the caller', () {
    TileShareLog.sink = (_) => throw StateError('logger broke');
    expect(() => TileShareLog.d('Tag', 'message'), returnsNormally);
  });

  test('the default sink is replaceable and restorable', () {
    final before = TileShareLog.sink;
    TileShareLog.sink = (_) {};
    TileShareLog.sink = before;
    expect(identical(TileShareLog.sink, before), isTrue);
  });
}
