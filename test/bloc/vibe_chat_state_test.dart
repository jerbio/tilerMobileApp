import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/vibeChat/vibe_chat_bloc.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';

VibePreviewAction _pa(String entityId) => VibePreviewAction(
      action: VibeAction(id: 'action_$entityId', descriptions: 'desc $entityId'),
      entityId: entityId,
      vibePreviewId: 'preview_1',
    );

void main() {
  group('VibeChatState TileCast carousel fields', () {
    test('defaults: empty previewActions, index 0, null batch', () {
      const state = VibeChatState();
      expect(state.previewActions, isEmpty);
      expect(state.currentPreviewIndex, 0);
      expect(state.previewBatch, isNull);
    });

    test('copyWith preserves new fields when not specified', () {
      final state = VibeChatState(
        previewActions: [_pa('e1'), _pa('e2')],
        currentPreviewIndex: 1,
        previewBatch: VibeRequestPreview(state: PreviewState.ready),
      );

      final copy = state.copyWith(step: VibeChatStep.loaded);

      expect(copy.previewActions.length, 2);
      expect(copy.currentPreviewIndex, 1);
      expect(copy.previewBatch?.state, PreviewState.ready);
    });

    test('copyWith updates new fields', () {
      const state = VibeChatState();
      final copy = state.copyWith(
        previewActions: [_pa('e1')],
        currentPreviewIndex: 3,
        previewBatch: VibeRequestPreview(
            state: PreviewState.processing, isStale: true),
      );

      expect(copy.previewActions.single.entityId, 'e1');
      expect(copy.currentPreviewIndex, 3);
      expect(copy.previewBatch?.isStale, isTrue);
    });
  });

  group('VibeChatState TileCast helpers', () {
    test('currentPreviewAction returns action at index', () {
      final state = VibeChatState(
        previewActions: [_pa('e1'), _pa('e2'), _pa('e3')],
        currentPreviewIndex: 2,
      );
      expect(state.currentPreviewAction?.entityId, 'e3');
    });

    test('currentPreviewAction is null when index out of range', () {
      final state = VibeChatState(
        previewActions: [_pa('e1')],
        currentPreviewIndex: 5,
      );
      expect(state.currentPreviewAction, isNull);
    });

    test('currentPreviewAction is null when list empty', () {
      const state = VibeChatState();
      expect(state.currentPreviewAction, isNull);
    });

    test('previewState reflects batch state, unknown when no batch', () {
      const noBatch = VibeChatState();
      expect(noBatch.previewState, PreviewState.unknown);

      final withBatch = VibeChatState(
        previewBatch: VibeRequestPreview(state: PreviewState.failed),
      );
      expect(withBatch.previewState, PreviewState.failed);
    });

    test('isPreviewStale reflects batch, false when no batch', () {
      const noBatch = VibeChatState();
      expect(noBatch.isPreviewStale, isFalse);

      final stale = VibeChatState(
        previewBatch: VibeRequestPreview(isStale: true),
      );
      expect(stale.isPreviewStale, isTrue);
    });
  });

  group('TileCast events', () {
    test('LoadTileCastEvent carries requestId and optional actionId', () {
      final e = LoadTileCastEvent('req_1', actionId: 'action_e2');
      expect(e.vibeRequestId, 'req_1');
      expect(e.actionId, 'action_e2');
    });

    test('LoadTileCastEvent actionId is optional', () {
      final e = LoadTileCastEvent('req_1');
      expect(e.vibeRequestId, 'req_1');
      expect(e.actionId, isNull);
    });

    test('NavigateTileCastEvent carries index', () {
      final e = NavigateTileCastEvent(4);
      expect(e.index, 4);
    });

    test('RetryTileCastEvent constructs', () {
      expect(RetryTileCastEvent('req_1').vibeRequestId, 'req_1');
    });
  });
}
