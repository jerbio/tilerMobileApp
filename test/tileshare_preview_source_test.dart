// TileShare redesign Step 9.10 (T9, T21): the preview seam. The live adapter is
// a thin 1:1 layer over the API; the in-memory fake behaves like the server
// (paged alternatives, a revision per option, an accept that answers with its
// outcome and is idempotent) and can be told to fail or stall, so the
// cubit and screen tests in later steps need no network.
import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/liveTileShareSources.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_preview_fixtures.dart';

class _RecordingApi extends TileSharePreviewApi {
  final List<String> log;
  Object? failWith;

  _RecordingApi(this.log) : super(getContextCallBack: () => null);

  Future<T> _run<T>(String call, T result) async {
    log.add(call);
    if (failWith != null) throw failWith!;
    return result;
  }

  @override
  Future<TileSharePreview> preview(String assignmentId) => _run(
      'preview($assignmentId)',
      TileSharePreview.fromJson(previewFixture('preview_viable')));

  @override
  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  }) =>
      _run('options($assignmentId, $previewToken, $sessionKey, $offset)',
          PreviewOptionsPage.fromJson(previewFixture('options_page')));

  @override
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  }) =>
      _run('revise($assignmentId, $previewToken, $optionId, $sessionKey, $fixed)',
          TileSharePreview.fromJson(previewFixture('revise_moved')));

  @override
  Future<TileShareOperation> accept({
    required String assignmentId,
    required String previewToken,
    required String operationId,
    required TileShareAcceptanceMode mode,
    String? sessionKey,
    TileShareLockedTimeLine? lockedTimeLine,
  }) =>
      _run('accept($assignmentId, $previewToken, $operationId, ${mode.name}, '
          '$sessionKey, ${lockedTimeLine?.startMs}/${lockedTimeLine?.durationMs})',
          TileShareOperation.fromJson(previewFixture('operation_queued')));

  @override
  Future<TileShareOperation> operation(String operationId) => _run(
      'operation($operationId)',
      TileShareOperation.fromJson(previewFixture('operation_completed')));

  @override
  Future<TileShareAssignmentResponse> response(String assignmentId) => _run(
      'response($assignmentId)',
      TileShareAssignmentResponse.fromJson(previewFixture('response_accepted')));
}

void main() {
  group('LiveTileSharePreviewSource delegates 1:1', () {
    late List<String> log;
    late _RecordingApi api;
    late LiveTileSharePreviewSource source;

    setUp(() {
      log = <String>[];
      api = _RecordingApi(log);
      source = LiveTileSharePreviewSource(api);
    });

    test('every call reaches the API with its arguments', () async {
      await source.preview('a1');
      await source.options(
          assignmentId: 'a1', previewToken: 't', sessionKey: '0', offset: 4);
      await source.revise(assignmentId: 'a1', previewToken: 't', optionId: 'o');
      await source.accept(
          assignmentId: 'a1',
          previewToken: 't',
          operationId: 'op',
          mode: TileShareAcceptanceMode.lockSession,
          sessionKey: '1',
          lockedTimeLine:
              const TileShareLockedTimeLine(startMs: 60000, durationMs: 120000));
      await source.operation('op');
      await source.response('a1');
      expect(log, [
        'preview(a1)',
        'options(a1, t, 0, 4)',
        'revise(a1, t, o, null, null)',
        'accept(a1, t, op, lockSession, 1, 60000/120000)',
        'operation(op)',
        'response(a1)',
      ]);
    });

    test('options start at zero unless told otherwise', () async {
      await source.options(assignmentId: 'a1', previewToken: 't', sessionKey: '0');
      expect(log.single, 'options(a1, t, 0, 0)');
    });

    test('a new operation id is the API\'s format', () {
      expect(source.newOperationId(), matches(RegExp(r'^[0-9a-f]{32}$')));
    });

    test('errors pass through unchanged', () async {
      final error = const TileSharePreviewFailure(PreviewFailureKind.conflict,
          statusCode: 409, reason: 'previewExpired');
      api.failWith = error;
      await expectLater(source.preview('a1'), throwsA(same(error)));
      await expectLater(source.operation('op'), throwsA(same(error)));
    });
  });

  group('FakeTileSharePreviewSource', () {
    TileSharePreview viable() =>
        TileSharePreview.fromJson(previewFixture('preview_viable'));

    test('answers the preview it was given', () async {
      final fake = FakeTileSharePreviewSource(viable());
      final p = await fake.preview(kPreviewAssignmentId);
      expect(p.previewToken, kPreviewToken);
      expect(fake.calls, ['preview($kPreviewAssignmentId)']);
    });

    test('pages alternatives by offset, and stops when there are no more',
        () async {
      final fake = FakeTileSharePreviewSource(viable(), optionPages: [
        PreviewOptionsPage.fromJson(previewFixture('options_page')),
        PreviewOptionsPage.fromJson(previewFixture('options_last_page')),
      ]);
      final first = await fake.options(
          assignmentId: 'a', previewToken: 't', sessionKey: '0');
      expect(first.options, hasLength(4));
      expect(first.nextOffset, 4);
      final second = await fake.options(
          assignmentId: 'a',
          previewToken: 't',
          sessionKey: '0',
          offset: first.nextOffset!);
      expect(second.options, hasLength(1));
      expect(second.hasMore, isFalse);
      final past = await fake.options(
          assignmentId: 'a', previewToken: 't', sessionKey: '0', offset: 99);
      expect(past.options, isEmpty);
    });

    test('revises to the preview scripted for an option', () async {
      final moved = TileSharePreview.fromJson(previewFixture('revise_moved'));
      final fake = FakeTileSharePreviewSource(viable(), revisions: {'opt-1': moved});
      final p = await fake.revise(
          assignmentId: 'a', previewToken: 't', optionId: 'opt-1');
      expect(p.previewToken, moved.previewToken);
      await expectLater(
          fake.revise(assignmentId: 'a', previewToken: 't', optionId: 'nope'),
          throwsA(isA<TileSharePreviewFailure>()));
    });

    test('an accept answers with the outcome, completed unless scripted '
        'otherwise (the server runs the acceptance inside the request)',
        () async {
      final fake = FakeTileSharePreviewSource(viable());
      final id = fake.newOperationId();
      final done = await fake.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: id,
          mode: TileShareAcceptanceMode.flexible);
      expect(done.state, OperationState.completed);
      expect(done.succeeded, isTrue);
      expect(done.calendarId, isNotNull);
      expect((await fake.operation(id)).state, OperationState.completed);

      final review = FakeTileSharePreviewSource(viable(),
          acceptState: OperationState.needsReview, acceptReason: 'fixedTimeChanged');
      final r = await review.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: review.newOperationId(),
          mode: TileShareAcceptanceMode.flexible);
      expect(r.state, OperationState.needsReview);
      expect(r.reason, 'fixedTimeChanged');
    });

    test('a repeated accept returns the stored outcome and accepts once',
        () async {
      final fake = FakeTileSharePreviewSource(viable());
      final id = fake.newOperationId();
      Future<TileShareOperation> send() => fake.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: id,
          mode: TileShareAcceptanceMode.lockSession,
          sessionKey: '0',
          lockedTimeLine:
              const TileShareLockedTimeLine(startMs: 60000, durationMs: 120000));
      final first = await send();
      final second = await send();
      expect(second.state, first.state);
      expect(second.operationId, first.operationId);
      expect(fake.accepted, hasLength(1));
    });

    test('the same operation id with a different command is a 409 '
        'operationMismatch', () async {
      final fake = FakeTileSharePreviewSource(viable());
      final id = fake.newOperationId();
      await fake.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: id,
          mode: TileShareAcceptanceMode.flexible);
      await expectLater(
          fake.accept(
              assignmentId: 'a',
              previewToken: 't',
              operationId: id,
              mode: TileShareAcceptanceMode.lockSession,
              sessionKey: '0',
              lockedTimeLine: const TileShareLockedTimeLine(
                  startMs: 60000, durationMs: 120000)),
          throwsA(predicate((e) =>
              e is TileSharePreviewFailure && e.reason == 'operationMismatch')));
    });

    test('a lost response: the accept committed, the call failed, and a repeat '
        'returns the stored outcome', () async {
      final fake = FakeTileSharePreviewSource(viable())
        ..commitButLoseResponse = true;
      final id = fake.newOperationId();
      Future<TileShareOperation> send() => fake.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: id,
          mode: TileShareAcceptanceMode.flexible);
      await expectLater(send(), throwsA(isA<TileSharePreviewFailure>()));
      expect(fake.accepted, hasLength(1), reason: 'it did commit');
      final again = await send();
      expect(again.state, OperationState.completed);
      expect(fake.accepted, hasLength(1), reason: 'and was not accepted twice');
    });

    test('reading an operation the server never saw is a 404', () async {
      final fake = FakeTileSharePreviewSource(viable());
      await expectLater(
          fake.operation('never'),
          throwsA(predicate((e) =>
              e is TileSharePreviewFailure &&
              e.kind == PreviewFailureKind.notFound)));
    });

    test('a non-final accept follows its script as it is read, then stays',
        () async {
      final fake = FakeTileSharePreviewSource(viable(),
          acceptState: OperationState.queued,
          operationScript: [OperationState.applied, OperationState.completed]);
      final id = fake.newOperationId();
      final queued = await fake.accept(
          assignmentId: 'a',
          previewToken: 't',
          operationId: id,
          mode: TileShareAcceptanceMode.flexible);
      expect(queued.state, OperationState.queued);
      expect((await fake.operation(id)).state, OperationState.applied);
      expect((await fake.operation(id)).state, OperationState.completed);
      expect((await fake.operation(id)).state, OperationState.completed);
    });

    test('operation ids are 32 hex characters and never repeat', () {
      final fake = FakeTileSharePreviewSource(viable());
      final a = fake.newOperationId();
      final b = fake.newOperationId();
      expect(a, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(a, isNot(b));
    });

    test('can be told to fail once, by call, and to stall', () async {
      final fake = FakeTileSharePreviewSource(viable());
      fake.failNextOn(
          'options',
          const TileSharePreviewFailure(PreviewFailureKind.unavailable,
              statusCode: 503));
      await expectLater(
          fake.options(assignmentId: 'a', previewToken: 't', sessionKey: '0'),
          throwsA(isA<TileSharePreviewFailure>()));
      expect(
          (await fake.options(
                  assignmentId: 'a', previewToken: 't', sessionKey: '0'))
              .options,
          isEmpty);

      fake.hold();
      var done = false;
      final pending = fake.preview('a').then((_) => done = true);
      await pumpEventQueue();
      expect(done, isFalse);
      fake.release();
      await pending;
      expect(done, isTrue);
    });

    test('recovers the response it was given', () async {
      final fake = FakeTileSharePreviewSource(viable(),
          response: TileShareAssignmentResponse.fromJson(
              previewFixture('response_accepted')));
      expect((await fake.response('a')).isAccepted, isTrue);
    });
  });
}
