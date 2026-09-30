// TileShare logging: every TileShare log line goes through one sink, tagged
// with where it came from, so tests can read it and the app can decide where it
// goes (by default the project's Utility.debugPrint, which prints in debug
// builds and for the developer account in production).
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

void main() {
  late void Function(String) originalSink;

  setUp(() => originalSink = TileShareLog.sink);
  tearDown(() => TileShareLog.sink = originalSink);

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
