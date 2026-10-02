// TileShare redesign Step 9.11 (T21-T26): the accept-preview cubit. One
// assignment: its forecast, other arrangements (each already carrying its own
// preview, so choosing one needs no request), the session a lock would fix, and
// Accept / Accept and lock - one `status` request that runs the whole acceptance
// and answers with the outcome (no polling) - plus decline and recovery from an
// accept whose outcome was never seen.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_state.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/services/api/tileSharePreviewApi.dart';
import 'package:tiler_app/services/tileShare/tileSharePendingAccept.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';

import 'helpers/tileshare_fakes.dart';
import 'helpers/tileshare_fixtures.dart';
import 'helpers/tileshare_preview_fixtures.dart';

/// Just after the fixtures were generated, so their 15-minute tokens are fresh.
final DateTime _now = DateTime.fromMillisecondsSinceEpoch(1789500000000 + 60000);

TileSharePreview _viable() =>
    TileSharePreview.fromJson(previewFixture('preview_viable'));

/// A source whose alternatives (and revisions) can be held and released one at
/// a time, so a response can arrive late.
class _SlowSource extends FakeTileSharePreviewSource {
  Completer<PreviewOptionsPage>? optionsGate;
  Completer<TileSharePreview>? reviseGate;

  _SlowSource(super.previewResult, {super.optionPages, super.revisions});

  @override
  Future<PreviewOptionsPage> options({
    required String assignmentId,
    required String previewToken,
    required String sessionKey,
    int offset = 0,
  }) {
    final gate = optionsGate;
    if (gate == null) {
      return super.options(
          assignmentId: assignmentId,
          previewToken: previewToken,
          sessionKey: sessionKey,
          offset: offset);
    }
    calls.add('options($assignmentId, offset: $offset)');
    return gate.future;
  }

  @override
  Future<TileSharePreview> revise({
    required String assignmentId,
    required String previewToken,
    String? optionId,
    String? sessionKey,
    bool? fixed,
  }) {
    final gate = reviseGate;
    if (gate == null) {
      return super.revise(
          assignmentId: assignmentId,
          previewToken: previewToken,
          optionId: optionId,
          sessionKey: sessionKey,
          fixed: fixed);
    }
    calls.add('revise($assignmentId, option: $optionId, fixed: $fixed)');
    return gate.future;
  }
}

class _Rig {
  final FakeTileSharePreviewSource source;
  final FakeTileShareAssignmentsSource assignments;
  final FakePendingAcceptStore store;
  final List<TileSharePreviewState> states = [];
  late final TileSharePreviewCubit cubit;
  late final StreamSubscription<TileSharePreviewState> _sub;
  DateTime now = _now;

  _Rig({
    FakeTileSharePreviewSource? source,
    FakePendingAcceptStore? store,
    TileSharePreview? preview,
  })  : source = source ??
            FakeTileSharePreviewSource(preview ?? _viable(), optionPages: [
              PreviewOptionsPage.fromJson(previewFixture('options_page')),
              PreviewOptionsPage.fromJson(previewFixture('options_last_page')),
            ]),
        store = store ?? FakePendingAcceptStore(),
        assignments = FakeTileShareAssignmentsSource(
            [tsDesignatedTile(kPreviewAssignmentId)]) {
    cubit = TileSharePreviewCubit(
      source: this.source,
      assignments: assignments,
      assignmentId: kPreviewAssignmentId,
      pendingStore: this.store,
      clock: () => now,
    );
    _sub = cubit.stream.listen(states.add);
  }

  TileSharePreviewState get state => cubit.state;
  List<PreviewPhase> get phases => states.map((s) => s.phase).toList();
  List<String> callsStarting(String prefix) =>
      source.calls.where((c) => c.startsWith(prefix)).toList();

  Future<void> close() async {
    await _sub.cancel();
    await cubit.close();
  }
}

TileSharePreviewFailure _conflict(String reason) => TileSharePreviewFailure(
    PreviewFailureKind.conflict,
    statusCode: 409,
    reason: reason);

void main() {
  late List<String> logs;
  late void Function(String) originalSink;

  setUp(() {
    logs = <String>[];
    originalSink = TileShareLog.sink;
    TileShareLog.sink = logs.add;
  });
  tearDown(() => TileShareLog.sink = originalSink);

  // ------------------------------------------------------------------ loading
  group('loading the preview', () {
    test('idle, then loading, then ready with the forecast and a session to '
        'lock highlighted', () async {
      final rig = _Rig();
      expect(rig.state.phase, PreviewPhase.idle);
      await rig.cubit.load();
      expect(rig.phases.first, PreviewPhase.loading);
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.preview!.previewToken, kPreviewToken);
      expect(rig.state.original, same(rig.state.preview));
      expect(rig.state.highlightedSessionKey, '0');
      expect(rig.state.lockTarget!.sessionKey, '0');
      expect(rig.state.canAccept, isTrue);
      expect(rig.state.canAcceptAndLock, isTrue);
      expect(rig.callsStarting('preview('), ['preview($kPreviewAssignmentId)']);
      await rig.close();
    });

    test('an unsupported assignment says why and offers no accept', () async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson(
              previewFixture('preview_unsupported_constraints')));
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.unsupported);
      expect(rig.state.preview!.unsupportedReason,
          PreviewUnsupportedReason.unsupportedConstraints);
      expect(rig.state.canAccept, isFalse);
      await rig.close();
    });

    test('a preview that does not work out is shown, with nothing to accept '
        'and no session to lock', () async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson(previewFixture('preview_not_viable')));
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.preview!.isViable, isFalse);
      expect(rig.state.canAccept, isFalse);
      expect(rig.state.canAcceptAndLock, isFalse);
      expect(rig.state.lockTarget, isNull);
      await rig.close();
    });

    test('each failure is told apart', () async {
      Future<TileSharePreviewState> failWith(Object error) async {
        final rig = _Rig();
        rig.source.failNextOn('preview', error);
        await rig.cubit.load();
        final state = rig.state;
        await rig.close();
        return state;
      }

      final gone = await failWith(
          const TileSharePreviewFailure(PreviewFailureKind.notFound, statusCode: 404));
      expect(gone.phase, PreviewPhase.unavailable);
      expect(gone.problem, PreviewProblem.gone);

      final off = await failWith(const TileSharePreviewFailure(
          PreviewFailureKind.unavailable, statusCode: 503));
      expect(off.phase, PreviewPhase.unavailable);
      expect(off.problem, PreviewProblem.switchedOff);

      final auth = await failWith(const TileSharePreviewFailure(
          PreviewFailureKind.unauthorized, statusCode: 401));
      expect(auth.phase, PreviewPhase.error);
      expect(auth.problem, PreviewProblem.signInAgain);

      for (final other in <Object>[
        const TileSharePreviewFailure(PreviewFailureKind.server, statusCode: 500),
        StateError('malformed'),
      ]) {
        final s = await failWith(other);
        expect(s.phase, PreviewPhase.error);
        expect(s.problem, PreviewProblem.loadFailed);
      }
    });

    test('a failed load is logged with its cause', () async {
      final rig = _Rig();
      rig.source.failNextOn('preview', StateError('forecast exploded'));
      await rig.cubit.load();
      expect(
          logs.any((l) => l.contains('TileSharePreview') && l.contains('forecast exploded')),
          isTrue,
          reason: '$logs');
      await rig.close();
    });

    test('loading again after an error starts over', () async {
      final rig = _Rig();
      rig.source.failNextOn('preview', StateError('x'));
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.error);
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.problem, isNull);
      await rig.close();
    });
  });

  // ------------------------------------------------------------- regenerating
  group('generating a new preview', () {
    test('keeps the current preview on screen, then swaps it in whole and '
        'starts over', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      await rig.cubit.selectOption(rig.state.options.first.optionId);
      final fresh = TileSharePreview.fromJson(previewFixture('revise_moved'));
      rig.source.previewResult = fresh;
      rig.source.hold();
      final regenerating = rig.cubit.regenerate();
      await pumpEventQueue();
      expect(rig.state.isRefreshing, isTrue);
      expect(rig.state.preview!.previewToken, isNot(fresh.previewToken),
          reason: 'the old preview is still what is shown');
      rig.source.release();
      await regenerating;
      expect(rig.state.isRefreshing, isFalse);
      expect(rig.state.preview!.previewToken, fresh.previewToken);
      expect(rig.state.original!.previewToken, fresh.previewToken);
      expect(rig.state.selectedOptionId, isNull);
      expect(rig.state.options, isEmpty);
      expect(rig.state.optionsStarted, isFalse);
      await rig.close();
    });

    test('a failure keeps the preview that was valid and says so', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.failNextOn('preview', StateError('down'));
      await rig.cubit.regenerate();
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.preview!.previewToken, kPreviewToken);
      expect(rig.state.problem, PreviewProblem.loadFailed);
      expect(rig.state.isRefreshing, isFalse);
      await rig.close();
    });

    test('clears a stale preview', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.now = DateTime.fromMillisecondsSinceEpoch(1789500000000 + 16 * 60000);
      await rig.cubit.accept();
      expect(rig.state.problem, PreviewProblem.stale);
      rig.now = _now;
      await rig.cubit.regenerate();
      expect(rig.state.problem, isNull);
      expect(rig.state.canAccept, isTrue);
      await rig.close();
    });

    test('is not allowed while an accept is going out', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.hold();
      final accepting = rig.cubit.accept();
      await pumpEventQueue();
      await rig.cubit.regenerate();
      expect(rig.callsStarting('preview('), hasLength(1));
      rig.source.release();
      await accepting;
      await rig.close();
    });
  });

  // ---------------------------------------------------------------- the lock
  group('the session a lock would fix', () {
    test('can be moved to another placed session, and only to one', () async {
      final two = TileSharePreview.fromJson({
        ...previewFixture('preview_viable'),
        'sessions': [
          ...previewFixture('preview_viable')['sessions'] as List,
          {
            'id': 'sub-new-2',
            'name': 'Content & Marketing Report',
            'start': 1789560000000 + 7200000,
            'end': 1789560000000 + 10800000,
            'isProposed': true,
            'viable': true,
            'isFixed': false,
            'duration': 3600000.0,
            'sessionKey': '1',
            'placement': 'Scheduled',
          },
          {
            'id': 'sub-new-3',
            'start': 1,
            'end': 2,
            'isProposed': true,
            'viable': false,
            'sessionKey': '2',
            'placement': 'Unscheduled',
          },
        ],
      });
      final rig = _Rig(preview: two);
      await rig.cubit.load();
      expect(rig.state.highlightedSessionKey, '0');
      rig.cubit.highlightSession('1');
      expect(rig.state.lockTarget!.sessionKey, '1');
      rig.cubit.highlightSession('2');
      expect(rig.state.highlightedSessionKey, '1', reason: 'not placed');
      rig.cubit.highlightSession('nope');
      expect(rig.state.highlightedSessionKey, '1', reason: 'unknown');
      await rig.close();
    });
  });

  // ------------------------------------------------------------ arrangements
  group('other arrangements', () {
    test('the first page is asked for from the original preview, for the '
        'session that would be locked', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      expect(rig.callsStarting('options('),
          ['options($kPreviewAssignmentId, offset: 0)']);
      expect(rig.state.options, hasLength(4));
      expect(rig.state.nextOffset, 4);
      expect(rig.state.optionsLoad, OptionsLoad.ready);
      expect(rig.state.optionsStarted, isTrue);
      expect(rig.state.hasMoreOptions, isTrue);
      await rig.close();
    });

    test('asking again goes on from where the last page ended, and stops '
        'when there is no more', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      await rig.cubit.findOtherTimes();
      expect(rig.callsStarting('options(').last,
          'options($kPreviewAssignmentId, offset: 4)');
      expect(rig.state.options, hasLength(5));
      expect(rig.state.hasMoreOptions, isFalse);
      final calls = rig.source.calls.length;
      await rig.cubit.findOtherTimes();
      expect(rig.source.calls.length, calls, reason: 'nothing left to ask for');
      await rig.close();
    });

    test('an arrangement already shown, or the same as the original, is not '
        'added again, and finding nothing new is said plainly', () async {
      final page = PreviewOptionsPage.fromJson(previewFixture('options_page'));
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(), optionPages: [
        page,
        PreviewOptionsPage(options: page.options.take(2).toList(), nextOffset: 8),
        const PreviewOptionsPage(options: [], nextOffset: null),
      ]));
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      expect(rig.state.options, hasLength(4));
      expect(rig.state.noDifferentFound, isFalse);
      await rig.cubit.findOtherTimes();
      expect(rig.state.options, hasLength(4), reason: 'both were repeats');
      expect(rig.state.noDifferentFound, isTrue);
      expect(rig.state.hasMoreOptions, isTrue);
      await rig.cubit.findOtherTimes();
      expect(rig.state.noDifferentFound, isTrue);
      expect(rig.state.hasMoreOptions, isFalse);
      await rig.close();
    });

    test('an option that places the task exactly where the original does is '
        'not an alternative', () async {
      final original = _viable();
      final same = PreviewOption(
          optionId: 'same' * 8,
          startMs: original.sessions.single.startMs,
          endMs: original.sessions.single.endMs,
          preview: TileSharePreview.fromJson({
            ...previewFixture('preview_viable'),
            'previewToken': 'same' * 8,
          }));
      final rig = _Rig(
          source: FakeTileSharePreviewSource(original, optionPages: [
        PreviewOptionsPage(options: [same], nextOffset: null),
      ]));
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      expect(rig.state.options, isEmpty);
      expect(rig.state.noDifferentFound, isTrue);
      await rig.close();
    });

    test('overlapping requests make one request', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.hold();
      final a = rig.cubit.findOtherTimes();
      final b = rig.cubit.findOtherTimes();
      await pumpEventQueue();
      expect(rig.state.optionsLoad, OptionsLoad.loading);
      rig.source.release();
      await Future.wait([a, b]);
      expect(rig.callsStarting('options('), hasLength(1));
      await rig.close();
    });

    test('a failure keeps what is there and can be tried again', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      rig.source.failNextOn('options', StateError('slow forecast'));
      await rig.cubit.findOtherTimes();
      expect(rig.state.optionsLoad, OptionsLoad.error);
      expect(rig.state.options, hasLength(4));
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.canAccept, isTrue, reason: 'the choice stands');
      await rig.cubit.findOtherTimes();
      expect(rig.state.optionsLoad, OptionsLoad.ready);
      expect(rig.state.options, hasLength(5));
      await rig.close();
    });

    test('an expired preview found while asking is stale, with the choice '
        'kept', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.failNextOn('options', _conflict('previewExpired'));
      await rig.cubit.findOtherTimes();
      expect(rig.state.problem, PreviewProblem.stale);
      expect(rig.state.reason, 'previewExpired');
      expect(rig.state.preview, isNotNull);
      expect(rig.state.canAccept, isFalse);
      await rig.close();
    });

    test('is not asked for when the server did not allow it', () async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson({
        ...previewFixture('preview_viable'),
        'capabilities': {
          'alternatives': false,
          'fixedSessions': true,
          'reviewedAcceptance': true
        },
      }));
      await rig.cubit.load();
      expect(rig.state.canFindOtherTimes, isFalse);
      await rig.cubit.findOtherTimes();
      expect(rig.callsStarting('options('), isEmpty);
      await rig.close();
    });

    test('a response that arrives after a new preview was generated is '
        'ignored', () async {
      final source = _SlowSource(_viable(), optionPages: [
        PreviewOptionsPage.fromJson(previewFixture('options_page')),
      ]);
      final rig = _Rig(source: source);
      await rig.cubit.load();
      source.optionsGate = Completer<PreviewOptionsPage>();
      final asking = rig.cubit.findOtherTimes();
      await pumpEventQueue();
      await rig.cubit.regenerate();
      source.optionsGate!
          .complete(PreviewOptionsPage.fromJson(previewFixture('options_page')));
      await asking;
      expect(rig.state.options, isEmpty);
      expect(rig.state.optionsStarted, isFalse);
      await rig.close();
    });
  });

  // --------------------------------------------------------------- selecting
  group('choosing an arrangement', () {
    test('swaps the whole arrangement at once, with no request', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      final option = rig.state.options.first;
      final calls = rig.source.calls.length;
      await rig.cubit.selectOption(option.optionId);
      expect(rig.source.calls.length, calls);
      expect(rig.state.preview, same(option.preview));
      expect(rig.state.selectedOptionId, option.optionId);
      expect(rig.state.original!.previewToken, kPreviewToken,
          reason: 'the original is kept to go back to');
      expect(rig.state.canAccept, isTrue);
      await rig.close();
    });

    test('keeps the session to lock when the new arrangement has it, else '
        'takes the first placed one', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      await rig.cubit.selectOption(rig.state.options.first.optionId);
      expect(rig.state.highlightedSessionKey, '0');

      final lost = PreviewOption(
          optionId: 'lost' * 8,
          startMs: 1,
          endMs: 2,
          preview: TileSharePreview.fromJson({
            ...previewFixture('preview_viable'),
            'previewToken': 'lost' * 8,
            'sessions': [
              {
                'id': 's9',
                'start': 5,
                'end': 6,
                'isProposed': true,
                'viable': true,
                'sessionKey': '7',
                'placement': 'Scheduled'
              }
            ],
          }));
      final rig2 = _Rig(
          source: FakeTileSharePreviewSource(_viable(), optionPages: [
        PreviewOptionsPage(options: [lost], nextOffset: null),
      ]));
      await rig2.cubit.load();
      await rig2.cubit.findOtherTimes();
      await rig2.cubit.selectOption(lost.optionId);
      expect(rig2.state.highlightedSessionKey, '7');
      await rig.close();
      await rig2.close();
    });

    test('going back to the original restores it', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      await rig.cubit.selectOption(rig.state.options.first.optionId);
      rig.cubit.selectOriginal();
      expect(rig.state.preview, same(rig.state.original));
      expect(rig.state.selectedOptionId, isNull);
      await rig.close();
    });

    test('an unknown option does nothing', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.selectOption('nope');
      expect(rig.state.selectedOptionId, isNull);
      await rig.close();
    });

    test('an option that arrived without its preview is revised to, and '
        'only then shown', () async {
      final bare = PreviewOption.fromJson(previewFixture('options_bare')
          ['options'][0] as Map<String, dynamic>);
      final moved = TileSharePreview.fromJson(previewFixture('revise_moved'));
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(), optionPages: [
        PreviewOptionsPage(options: [bare], nextOffset: null),
      ], revisions: {
        bare.optionId: moved
      }));
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      await rig.cubit.selectOption(bare.optionId);
      expect(rig.callsStarting('revise('), hasLength(1));
      expect(rig.state.preview!.previewToken, moved.previewToken);
      expect(rig.state.isSelecting, isFalse);
      await rig.close();
    });

    test('a revise that fails keeps the choice that was valid', () async {
      final bare = PreviewOption.fromJson(previewFixture('options_bare')
          ['options'][0] as Map<String, dynamic>);
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(), optionPages: [
        PreviewOptionsPage(options: [bare], nextOffset: null),
      ]));
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      rig.source.failNextOn('revise', StateError('no'));
      await rig.cubit.selectOption(bare.optionId);
      expect(rig.state.preview!.previewToken, kPreviewToken);
      expect(rig.state.selectedOptionId, isNull);
      expect(rig.state.selectionFailed, isTrue);
      await rig.close();
    });

    test('a late revise never replaces a newer choice', () async {
      final bare = PreviewOption.fromJson(previewFixture('options_bare')
          ['options'][0] as Map<String, dynamic>);
      final page = PreviewOptionsPage.fromJson(previewFixture('options_page'));
      final slow = _SlowSource(_viable(), optionPages: [
        PreviewOptionsPage(options: [bare, ...page.options], nextOffset: null),
      ], revisions: {
        bare.optionId: TileSharePreview.fromJson(previewFixture('revise_moved'))
      });
      final rig = _Rig(source: slow);
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      slow.reviseGate = Completer<TileSharePreview>();
      final reviseing = rig.cubit.selectOption(bare.optionId);
      await pumpEventQueue();
      final newer = page.options.first;
      await rig.cubit.selectOption(newer.optionId);
      slow.reviseGate!
          .complete(TileSharePreview.fromJson(previewFixture('revise_moved')));
      await reviseing;
      expect(rig.state.selectedOptionId, newer.optionId);
      expect(rig.state.preview, same(newer.preview));
      await rig.close();
    });
  });

  // ------------------------------------------------------------------ accept
  group('accepting', () {
    test('Accept sends the shown preview\'s token and a flexible mode, saves '
        'the command first, and ends completed', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.accept();
      final sent = rig.source.accepted.single;
      expect(sent.mode, TileShareAcceptanceMode.flexible);
      expect(sent.previewToken, kPreviewToken);
      expect(sent.sessionKey, isNull);
      expect(sent.lockedTimeLine, isNull);
      expect(sent.operationId, matches(RegExp(r'^[0-9a-f]{32}$')));
      expect(rig.phases, contains(PreviewPhase.submitting));
      expect(rig.state.phase, PreviewPhase.completed);
      expect(rig.state.operation!.calendarId, isNotNull);
      expect(rig.store.log,
          ['read($kPreviewAssignmentId)', 'save(${sent.operationId})', 'clear($kPreviewAssignmentId)'],
          reason: 'saved before it was sent, cleared when the outcome is known');
      await rig.close();
    });

    test('Accept and lock sends the highlighted session and its interval',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.acceptAndLock();
      final sent = rig.source.accepted.single;
      final session = rig.state.preview!.sessions.single;
      expect(sent.mode, TileShareAcceptanceMode.lockSession);
      expect(sent.sessionKey, '0');
      expect(sent.lockedTimeLine,
          TileShareLockedTimeLine(
              startMs: session.startMs, durationMs: session.endMs - session.startMs));
      await rig.close();
    });

    test('after choosing another arrangement, that arrangement is what is '
        'accepted', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.findOtherTimes();
      final option = rig.state.options[1];
      await rig.cubit.selectOption(option.optionId);
      await rig.cubit.acceptAndLock();
      final sent = rig.source.accepted.single;
      expect(sent.previewToken, option.optionId);
      expect(sent.lockedTimeLine!.startMs, option.startMs);
      await rig.close();
    });

    test('needs review is its own outcome, with its reason', () async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.needsReview,
              acceptReason: 'fixedTimeChanged'));
      await rig.cubit.load();
      await rig.cubit.accept();
      expect(rig.state.phase, PreviewPhase.needsReview);
      expect(rig.state.operation!.reason, 'fixedTimeChanged');
      expect(rig.store[kPreviewAssignmentId], isNull);
      await rig.close();
    });

    test('rejected is its own outcome, with its reason, and the preview can '
        'be reviewed again', () async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.rejected,
              acceptReason: 'scheduleChanged'));
      await rig.cubit.load();
      await rig.cubit.accept();
      expect(rig.state.phase, PreviewPhase.rejected);
      expect(rig.state.operation!.reason, 'scheduleChanged');
      expect(rig.store[kPreviewAssignmentId], isNull);
      rig.source.acceptState = OperationState.completed;
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.ready);
      await rig.close();
    });

    test('is refused when there is nothing valid to accept', () async {
      final rig = _Rig(
          preview: TileSharePreview.fromJson(previewFixture('preview_not_viable')));
      await rig.cubit.load();
      await rig.cubit.accept();
      await rig.cubit.acceptAndLock();
      expect(rig.callsStarting('accept('), isEmpty);
      expect(rig.state.phase, PreviewPhase.ready);
      await rig.close();
    });

    test('a double tap sends once', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.hold();
      final a = rig.cubit.accept();
      final b = rig.cubit.accept();
      final c = rig.cubit.acceptAndLock();
      await pumpEventQueue();
      rig.source.release();
      await Future.wait([a, b, c]);
      expect(rig.source.accepted, hasLength(1));
      await rig.close();
    });

    test('an expired preview is stale and is not sent', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.now = DateTime.fromMillisecondsSinceEpoch(1789500000000 + 15 * 60000);
      await rig.cubit.accept();
      expect(rig.callsStarting('accept('), isEmpty);
      expect(rig.state.problem, PreviewProblem.stale);
      expect(rig.state.reason, 'previewExpired');
      expect(rig.state.preview, isNotNull, reason: 'the choice stays visible');
      await rig.close();
    });

    test('a non-final answer is "still adding", is kept for a check, and one '
        'check settles it (no loop)', () async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.queued,
              operationScript: [OperationState.completed]));
      await rig.cubit.load();
      await rig.cubit.accept();
      expect(rig.state.phase, PreviewPhase.adding);
      expect(rig.store[kPreviewAssignmentId], isNotNull);
      await pumpEventQueue();
      expect(rig.callsStarting('operation('), isEmpty, reason: 'no polling');
      await rig.cubit.checkStatus();
      expect(rig.callsStarting('operation('), hasLength(1));
      expect(rig.state.phase, PreviewPhase.completed);
      expect(rig.store[kPreviewAssignmentId], isNull);
      await rig.close();
    });

    test('a check that is still not final leaves it as it was', () async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.queued,
              operationScript: [OperationState.applied]));
      await rig.cubit.load();
      await rig.cubit.accept();
      await rig.cubit.checkStatus();
      expect(rig.state.phase, PreviewPhase.adding);
      await rig.close();
    });
  });

  // -------------------------------------------- failures before it was queued
  group('an accept the server refuses (HTTP 409 and others)', () {
    Future<TileSharePreviewState> refused(Object error) async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.failNextOn('accept', error);
      await rig.cubit.accept();
      final state = rig.state;
      expect(rig.store[kPreviewAssignmentId], isNull,
          reason: 'it never queued, so there is nothing to repeat');
      await rig.close();
      return state;
    }

    test('a preview that moved on is stale, with its reason and the choice '
        'kept', () async {
      for (final reason in ['previewExpired', 'invalidProposal', 'scheduleChanged']) {
        final s = await refused(_conflict(reason));
        expect(s.phase, PreviewPhase.ready, reason: reason);
        expect(s.problem, PreviewProblem.stale, reason: reason);
        expect(s.reason, reason);
        expect(s.preview, isNotNull);
        expect(s.canAccept, isFalse);
      }
    });

    test('a session that is no longer valid says so, and flexible acceptance '
        'is still possible', () async {
      final s = await refused(_conflict('invalidSession'));
      expect(s.problem, PreviewProblem.sessionInvalid);
      expect(s.canAcceptAndLock, isFalse);
      expect(s.canAccept, isTrue);
    });

    test('already answered elsewhere is a rejected outcome', () async {
      final s = await refused(_conflict('assignmentChanged'));
      expect(s.phase, PreviewPhase.rejected);
      expect(s.reason, 'assignmentChanged');
    });

    test('another response in progress is "adding", read with the exact '
        'assignment', () async {
      final s = await refused(_conflict('responseInProgress'));
      expect(s.phase, PreviewPhase.adding);
      expect(s.problem, PreviewProblem.responseInProgress);
    });

    test('a mismatched repeat is an error, not a guess', () async {
      final s = await refused(_conflict('operationMismatch'));
      expect(s.phase, PreviewPhase.error);
      expect(s.problem, PreviewProblem.invalidRequest);
    });

    test('gone, switched off, invalid and signed out', () async {
      final gone = await refused(const TileSharePreviewFailure(
          PreviewFailureKind.notFound, statusCode: 404));
      expect(gone.phase, PreviewPhase.unavailable);
      expect(gone.problem, PreviewProblem.gone);
      final off = await refused(const TileSharePreviewFailure(
          PreviewFailureKind.unavailable, statusCode: 503));
      expect(off.problem, PreviewProblem.switchedOff);
      final invalid = await refused(const TileSharePreviewFailure(
          PreviewFailureKind.invalid, statusCode: 400));
      expect(invalid.phase, PreviewPhase.error);
      expect(invalid.problem, PreviewProblem.invalidRequest);
      final auth = await refused(const TileSharePreviewFailure(
          PreviewFailureKind.unauthorized, statusCode: 401));
      expect(auth.problem, PreviewProblem.signInAgain);
    });

    test('the answer is logged with the operation and the reason', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.failNextOn('accept', _conflict('scheduleChanged'));
      await rig.cubit.accept();
      expect(logs.any((l) => l.contains('accept') && l.contains('scheduleChanged')),
          isTrue,
          reason: '$logs');
      await rig.close();
    });
  });

  // ------------------------------------------------------- outcome unknown
  group('an accept whose outcome was never seen', () {
    test('a timeout is "couldn\'t confirm", keeps the command, and repeating '
        'it returns the stored outcome without accepting twice', () async {
      final rig = _Rig(source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await rig.cubit.load();
      await rig.cubit.acceptAndLock();
      expect(rig.state.phase, PreviewPhase.unconfirmed);
      expect(rig.store[kPreviewAssignmentId], isNotNull);
      expect(rig.state.preview, isNotNull);
      final operationId = rig.source.accepted.single.operationId;

      await rig.cubit.retryAccept();
      expect(rig.state.phase, PreviewPhase.completed);
      expect(rig.source.accepted, hasLength(1), reason: 'not accepted twice');
      expect(rig.callsStarting('accept(').every((c) => c.contains(operationId)), isTrue,
          reason: 'the same operation id was repeated');
      expect(rig.store[kPreviewAssignmentId], isNull);
      await rig.close();
    });

    test('the repeat carries the same mode, session and interval', () async {
      final rig = _Rig(source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await rig.cubit.load();
      await rig.cubit.acceptAndLock();
      final first = rig.source.accepted.single;
      rig.source.acceptState = OperationState.completed;
      await rig.cubit.retryAccept();
      // an idempotent repeat would be a 409 operationMismatch if anything differed
      expect(rig.state.phase, PreviewPhase.completed);
      expect(first.sessionKey, '0');
      await rig.close();
    });

    test('every kind of "we do not know" is the same state', () async {
      for (final error in <Object>[
        const TileSharePreviewFailure(PreviewFailureKind.server, reason: 'timed out'),
        const TileSharePreviewFailure(PreviewFailureKind.server, statusCode: 500),
        StateError('connection reset'),
      ]) {
        final rig = _Rig();
        await rig.cubit.load();
        rig.source.failNextOn('accept', error);
        await rig.cubit.accept();
        expect(rig.state.phase, PreviewPhase.unconfirmed, reason: '$error');
        expect(rig.store[kPreviewAssignmentId], isNotNull, reason: '$error');
        await rig.close();
      }
    });

    test('a new accept is not allowed until this one is settled', () async {
      final rig = _Rig(source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await rig.cubit.load();
      await rig.cubit.accept();
      expect(rig.state.phase, PreviewPhase.unconfirmed);
      await rig.cubit.accept();
      await rig.cubit.acceptAndLock();
      expect(rig.source.accepted, hasLength(1));
      await rig.close();
    });

    test('retrying when nothing is pending does nothing', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.retryAccept();
      expect(rig.callsStarting('accept('), isEmpty);
      await rig.close();
    });

    test('checking: a command the server never saw frees the user to accept '
        'again; one it did see reports its outcome', () async {
      final never = _Rig();
      await never.cubit.load();
      never.source.failNextOn('accept', StateError('never reached'));
      await never.cubit.accept();
      expect(never.state.phase, PreviewPhase.unconfirmed);
      await never.cubit.checkStatus();
      expect(never.state.phase, PreviewPhase.ready);
      expect(never.store[kPreviewAssignmentId], isNull);
      expect(never.state.canAccept, isTrue);
      await never.close();

      final saw = _Rig(source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await saw.cubit.load();
      await saw.cubit.accept();
      await saw.cubit.checkStatus();
      expect(saw.state.phase, PreviewPhase.completed);
      await saw.close();
    });

    test('a check that itself fails leaves it unconfirmed', () async {
      final rig = _Rig(source: FakeTileSharePreviewSource(_viable())..commitButLoseResponse = true);
      await rig.cubit.load();
      await rig.cubit.accept();
      rig.source.failNextOn('operation', StateError('offline'));
      await rig.cubit.checkStatus();
      expect(rig.state.phase, PreviewPhase.unconfirmed);
      await rig.close();
    });

    test('with another response in progress the exact assignment is read', () async {
      final source = FakeTileSharePreviewSource(_viable(),
          response: TileShareAssignmentResponse.fromJson(
              previewFixture('response_accepted')));
      final rig = _Rig(source: source);
      await rig.cubit.load();
      source.failNextOn('accept', _conflict('responseInProgress'));
      await rig.cubit.accept();
      expect(rig.state.phase, PreviewPhase.adding);
      await rig.cubit.checkStatus();
      expect(rig.callsStarting('response('), hasLength(1));
      expect(rig.state.phase, PreviewPhase.completed);
      await rig.close();
    });
  });

  // --------------------------------------------------- reopening the preview
  group('opening the preview again after an accept was left unconfirmed', () {
    PendingAccept pendingFlexible() => PendingAccept(
          operationId: 'ab' * 16,
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          mode: TileShareAcceptanceMode.flexible,
          savedAtMs: _now.millisecondsSinceEpoch,
        );

    test('repeats that command instead of making a new preview, and shows '
        'its outcome', () async {
      final source = FakeTileSharePreviewSource(_viable());
      // the server already holds this operation (the first request committed)
      await source.accept(
          assignmentId: kPreviewAssignmentId,
          previewToken: kPreviewToken,
          operationId: 'ab' * 16,
          mode: TileShareAcceptanceMode.flexible);
      final rig = _Rig(source: source, store: FakePendingAcceptStore(pendingFlexible()));
      await rig.cubit.load();
      expect(rig.callsStarting('preview('), isEmpty);
      expect(rig.state.phase, PreviewPhase.completed);
      expect(source.accepted, hasLength(1), reason: 'still only the first accept');
      expect(rig.store[kPreviewAssignmentId], isNull);
      await rig.close();
    });

    test('an interrupted accept is resumed by the repeat', () async {
      final source = FakeTileSharePreviewSource(_viable());
      final rig = _Rig(source: source, store: FakePendingAcceptStore(pendingFlexible()));
      await rig.cubit.load();
      expect(source.accepted.single.operationId, 'ab' * 16);
      expect(rig.state.phase, PreviewPhase.completed);
      await rig.close();
    });

    test('if it still cannot be confirmed it stays pending', () async {
      final source = FakeTileSharePreviewSource(_viable());
      source.failNextOn('accept', StateError('offline'));
      final rig = _Rig(source: source, store: FakePendingAcceptStore(pendingFlexible()));
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.unconfirmed);
      expect(rig.store[kPreviewAssignmentId], isNotNull);
      await rig.close();
    });

    test('a rejected outcome is shown, and the command is forgotten',
        () async {
      final rig = _Rig(
          source: FakeTileSharePreviewSource(_viable(),
              acceptState: OperationState.rejected, acceptReason: 'previewExpired'),
          store: FakePendingAcceptStore(pendingFlexible()));
      await rig.cubit.load();
      expect(rig.state.phase, PreviewPhase.rejected);
      expect(rig.store[kPreviewAssignmentId], isNull);
      await rig.close();
    });

    test('nothing pending means an ordinary preview', () async {
      final rig = _Rig();
      await rig.cubit.load();
      expect(rig.callsStarting('preview('), hasLength(1));
      await rig.close();
    });
  });

  // ----------------------------------------------------------------- decline
  group('declining', () {
    test('uses the ordinary response, with no preview token, and ends '
        'declined', () async {
      final rig = _Rig();
      await rig.cubit.load();
      await rig.cubit.decline();
      expect(rig.assignments.calls, contains('respond($kPreviewAssignmentId, declined)'));
      expect(rig.callsStarting('accept('), isEmpty);
      expect(rig.state.phase, PreviewPhase.declined);
      await rig.close();
    });

    test('a failure puts the preview back, says so, and can be tried again',
        () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.assignments.failNextOn('respond', StateError('offline'));
      await rig.cubit.decline();
      expect(rig.state.phase, PreviewPhase.ready);
      expect(rig.state.declineFailed, isTrue);
      await rig.cubit.decline();
      expect(rig.state.phase, PreviewPhase.declined);
      expect(rig.state.declineFailed, isFalse);
      await rig.close();
    });

    test('is possible from a stale preview and an unsupported one, not '
        'while an accept is going out', () async {
      final stale = _Rig();
      await stale.cubit.load();
      stale.now = DateTime.fromMillisecondsSinceEpoch(1789500000000 + 20 * 60000);
      await stale.cubit.accept();
      await stale.cubit.decline();
      expect(stale.state.phase, PreviewPhase.declined);
      await stale.close();

      final unsupported = _Rig(
          preview: TileSharePreview.fromJson(
              previewFixture('preview_unsupported_already_accepted')));
      await unsupported.cubit.load();
      await unsupported.cubit.decline();
      expect(unsupported.state.phase, PreviewPhase.declined);
      await unsupported.close();

      final busy = _Rig();
      await busy.cubit.load();
      busy.source.hold();
      final accepting = busy.cubit.accept();
      await pumpEventQueue();
      await busy.cubit.decline();
      expect(busy.assignments.calls.where((c) => c.startsWith('respond')), isEmpty);
      busy.source.release();
      await accepting;
      await busy.close();
    });

    test('a double tap declines once', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.assignments.hold();
      final a = rig.cubit.decline();
      final b = rig.cubit.decline();
      await pumpEventQueue();
      rig.assignments.release();
      await Future.wait([a, b]);
      expect(rig.assignments.calls.where((c) => c.startsWith('respond')), hasLength(1));
      await rig.close();
    });
  });

  // --------------------------------------------------------------- lifecycle
  group('closing', () {
    test('mid-flight never emits afterwards', () async {
      final rig = _Rig();
      await rig.cubit.load();
      rig.source.hold();
      final accepting = rig.cubit.accept();
      await pumpEventQueue();
      await rig.cubit.close();
      rig.source.release();
      await accepting;
      expect(rig.states.last.phase, PreviewPhase.submitting);
    });

    test('a load that finishes after closing is dropped', () async {
      final rig = _Rig();
      rig.source.hold();
      final loading = rig.cubit.load();
      await pumpEventQueue();
      await rig.cubit.close();
      rig.source.release();
      await loading;
      expect(rig.states.every((s) => s.phase != PreviewPhase.ready), isTrue);
    });
  });
}
