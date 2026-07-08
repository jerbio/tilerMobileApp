import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/bloc/vibeChat/tileCastPreviewLoader.dart';
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewSummary.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

VibePreviewAction _pa(String entityId, {String? previewId}) => VibePreviewAction(
      action: VibeAction(id: 'action_$entityId', descriptions: 'desc $entityId'),
      entityId: entityId,
      vibePreviewId: previewId ?? 'preview_1',
    );

VibeRequestPreview _batch(
  PreviewState state, {
  List<VibePreviewAction>? actions,
  bool isStale = false,
  String? failureReason,
  String? invalidationReason,
}) =>
    VibeRequestPreview(
      id: 'preview_1',
      vibeRequestId: 'req_1',
      state: state,
      isStale: isStale,
      failureReason: failureReason,
      invalidationReason: invalidationReason,
      previewActions: actions,
    );

VibePreviewSummary _summary(List<String> tileIds) => VibePreviewSummary(
      previewId: 'preview_1',
      subCalendarEvents:
          tileIds.map((id) => SubCalendarEvent.fromJson({'id': id})).toList(),
    );

void main() {
  // Helper to build a loader whose request-preview fetch returns a scripted
  // sequence (one entry per poll), and whose delay is a no-op that counts calls.
  ({
    TileCastPreviewLoader loader,
    List<int> delayCalls,
    List<String> summaryCalls,
  }) buildLoader(
    List<List<VibeRequestPreview>> sequence, {
    VibePreviewSummary? summary,
  }) {
    var pollIndex = 0;
    final delayCalls = <int>[];
    final summaryCalls = <String>[];
    final loader = TileCastPreviewLoader(
      fetchRequestPreview: (requestId) async {
        final value = pollIndex < sequence.length
            ? sequence[pollIndex]
            : sequence.last;
        pollIndex++;
        return value;
      },
      fetchSummary: (previewId) async {
        summaryCalls.add(previewId);
        return summary;
      },
      pollInterval: const Duration(seconds: 10),
      timeout: const Duration(minutes: 1),
      delay: (d) async => delayCalls.add(d.inMilliseconds),
    );
    return (loader: loader, delayCalls: delayCalls, summaryCalls: summaryCalls);
  }

  group('TileCastPreviewLoader completion', () {
    test('returns ready with actions + tiles when first poll is Completed',
        () async {
      final actions = [_pa('e1'), _pa('e2')];
      final h = buildLoader(
        [
          [_batch(PreviewState.ready, actions: actions)],
        ],
        summary: _summary(['e1', 'e2']),
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.ready);
      expect(result.actions.length, 2);
      expect(result.tiles.length, 2);
      expect(result.focusIndex, 0);
      expect(h.delayCalls, isEmpty, reason: 'no polling delay when ready first');
    });

    test('focusIndex resolves from actionId', () async {
      final actions = [_pa('e1'), _pa('e2'), _pa('e3')];
      final h = buildLoader(
        [
          [_batch(PreviewState.ready, actions: actions)],
        ],
        summary: _summary(['e1']),
      );

      final result = await h.loader.load('req_1', actionId: 'action_e3');

      expect(result.focusIndex, 2);
    });

    test('focusIndex defaults to 0 when actionId not found', () async {
      final actions = [_pa('e1'), _pa('e2')];
      final h = buildLoader(
        [
          [_batch(PreviewState.ready, actions: actions)],
        ],
        summary: _summary(['e1']),
      );

      final result = await h.loader.load('req_1', actionId: 'nope');

      expect(result.focusIndex, 0);
    });

    test('carries isStale from the completed batch', () async {
      final h = buildLoader(
        [
          [
            _batch(PreviewState.ready,
                actions: [_pa('e1')], isStale: true)
          ],
        ],
        summary: _summary(['e1']),
      );

      final result = await h.loader.load('req_1');

      expect(result.batch?.isStale, isTrue);
    });
  });

  group('TileCastPreviewLoader polling', () {
    test('polls through Processing then resolves on Completed', () async {
      final actions = [_pa('e1')];
      final h = buildLoader(
        [
          [_batch(PreviewState.queued)],
          [_batch(PreviewState.processing)],
          [_batch(PreviewState.ready, actions: actions)],
        ],
        summary: _summary(['e1']),
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.ready);
      // Two delays between the three polls.
      expect(h.delayCalls.length, 2);
    });

    test('empty preview list is treated as not-ready and keeps polling',
        () async {
      final actions = [_pa('e1')];
      final h = buildLoader(
        [
          <VibeRequestPreview>[],
          [_batch(PreviewState.ready, actions: actions)],
        ],
        summary: _summary(['e1']),
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.ready);
      expect(h.delayCalls.length, 1);
    });

    test('times out after maxAttempts when never terminal', () async {
      final h = buildLoader(
        [
          [_batch(PreviewState.processing)],
        ],
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.timedOut);
      // 10s interval over 1min => 6 attempts => 5 delays.
      expect(h.delayCalls.length, 5);
      expect(h.summaryCalls, isEmpty);
    });
  });

  group('TileCastPreviewLoader failure states', () {
    test('Failed maps to failed outcome with reason, no summary fetch',
        () async {
      final h = buildLoader(
        [
          [_batch(PreviewState.failed, failureReason: 'Scheduler error')],
        ],
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.failed);
      expect(result.failureReason, 'Scheduler error');
      expect(h.summaryCalls, isEmpty);
    });

    test('Invalidated maps to invalidated outcome with reason', () async {
      final h = buildLoader(
        [
          [
            _batch(PreviewState.invalidated,
                invalidationReason: 'Schedule changed')
          ],
        ],
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.invalidated);
      expect(result.failureReason, 'Schedule changed');
    });

    test('Completed but null summary maps to summaryUnavailable', () async {
      final h = buildLoader(
        [
          [_batch(PreviewState.ready, actions: [_pa('e1')])],
        ],
        summary: null,
      );

      final result = await h.loader.load('req_1');

      expect(result.outcome, TileCastOutcome.summaryUnavailable);
    });
  });
}
