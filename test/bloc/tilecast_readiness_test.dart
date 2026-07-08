import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewSummary.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/services/api/chatApi.dart';

/// Scriptable ChatApi that returns a preset sequence of request-preview
/// responses (one per poll) and records how many times it was called.
class _FakeChatApi extends ChatApi {
  _FakeChatApi(this.sequence);

  final List<List<VibeRequestPreview>> sequence;
  int calls = 0;
  bool throwOnCall = false;

  @override
  Future<List<VibeRequestPreview>> getVibeRequestPreviews(
      String vibeRequestId) async {
    calls++;
    if (throwOnCall) throw Exception('boom');
    final value =
        calls - 1 < sequence.length ? sequence[calls - 1] : sequence.last;
    return value;
  }

  @override
  Future<VibePreviewSummary?> getVibePreviewSummary(String previewId) async =>
      VibePreviewSummary(previewId: previewId, subCalendarEvents: const []);
}

VibeRequestPreview _preview(PreviewState state) => VibeRequestPreview(
      id: 'preview_1',
      vibeRequestId: 'req_1',
      state: state,
    );

VibeChatBloc _bloc(_FakeChatApi api) {
  final bloc = VibeChatBloc(
    scheduleBloc: ScheduleBloc(getContextCallBack: () => null),
    scheduleSummaryBloc: ScheduleSummaryBloc(getContextCallBack: () => null),
    getContextCallBack: () => null,
  );
  bloc.chatApi = api;
  bloc.tileCastReadinessDelayOverride = (_) async {};
  bloc.tileCastReadinessPollInterval = const Duration(milliseconds: 1);
  bloc.tileCastReadinessMaxAttempts = 10;
  return bloc;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VibeChatState TileCast readiness helpers', () {
    test('defaults to unknown for an untracked request', () {
      const state = VibeChatState();
      expect(state.tileCastStateFor('req_x'), PreviewState.unknown);
      expect(state.isTileCastReadyFor('req_x'), isFalse);
      expect(state.tileCastStatusFor('req_x'), isNull);
    });

    test('reflects a tracked request state', () {
      final state = VibeChatState(
        tileCastStatusByRequest: {'req_1': _preview(PreviewState.ready)},
      );
      expect(state.tileCastStateFor('req_1'), PreviewState.ready);
      expect(state.isTileCastReadyFor('req_1'), isTrue);
    });

    test('null request id is unknown / not ready', () {
      const state = VibeChatState();
      expect(state.tileCastStateFor(null), PreviewState.unknown);
      expect(state.isTileCastReadyFor(null), isFalse);
    });
  });

  group('TrackTileCastReadinessEvent polling', () {
    test('polls until ready, updates the map, then stops', () async {
      final api = _FakeChatApi([
        [_preview(PreviewState.processing)],
        [_preview(PreviewState.ready)],
      ]);
      final bloc = _bloc(api);

      bloc.add(TrackTileCastReadinessEvent('req_1'));
      final ready = await bloc.stream.firstWhere(
        (s) => s.tileCastStateFor('req_1') == PreviewState.ready,
      );

      expect(ready.tileCastStateFor('req_1'), PreviewState.ready);
      // Stops immediately once terminal — no extra poll beyond the ready one.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(api.calls, 2);
      await bloc.close();
    });

    test('keeps polling while the preview object is absent', () async {
      final api = _FakeChatApi([
        <VibeRequestPreview>[],
        <VibeRequestPreview>[],
        [_preview(PreviewState.ready)],
      ]);
      final bloc = _bloc(api);

      bloc.add(TrackTileCastReadinessEvent('req_1'));
      await bloc.stream.firstWhere(
        (s) => s.tileCastStateFor('req_1') == PreviewState.ready,
      );

      expect(api.calls, 3);
      await bloc.close();
    });

    test('ignores a request that is already terminal', () async {
      final api = _FakeChatApi([
        [_preview(PreviewState.ready)],
      ]);
      final bloc = _bloc(api);
      // Seed a terminal status so tracking should short-circuit.
      bloc.emit(bloc.state.copyWith(
        tileCastStatusByRequest: {'req_1': _preview(PreviewState.ready)},
      ));

      bloc.add(TrackTileCastReadinessEvent('req_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(api.calls, 0);
      await bloc.close();
    });

    test('stops gracefully when the fetch throws', () async {
      final api = _FakeChatApi([
        [_preview(PreviewState.processing)],
      ])
        ..throwOnCall = true;
      final bloc = _bloc(api);

      bloc.add(TrackTileCastReadinessEvent('req_1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // One attempt, caught, and no state update.
      expect(api.calls, 1);
      expect(bloc.state.tileCastStateFor('req_1'), PreviewState.unknown);
      await bloc.close();
    });

    test('empty request id is a no-op', () async {
      final api = _FakeChatApi([
        [_preview(PreviewState.ready)],
      ]);
      final bloc = _bloc(api);

      bloc.add(TrackTileCastReadinessEvent(''));
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(api.calls, 0);
      await bloc.close();
    });
  });
}
