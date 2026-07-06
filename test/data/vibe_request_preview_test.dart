import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';

void main() {
  // Mirrors the real payload from GET /api/Vibe/Request/{id}/Preview
  Map<String, dynamic> processingJson() => <String, dynamic>{
        'id': 'vibepreview_user_01_1783315028219_ABC',
        'vibeRequestId': 'user_viberequest_1783315017003_XYZ',
        'tilerUserId': 'user_01',
        'creationTimeInMs': 1783315028219,
        'previewActions': <dynamic>[],
        'state': 'Processing',
        'previewJobId': 'anJob_user_01_JOB',
        'failureReason': null,
        'generatedAt': null,
        'invalidatedAt': null,
        'invalidationReason': null,
        'queuedAt': 1783315028219,
        'processingStartAt': 1783315029150,
        'processingEndAt': null,
        'isStale': true,
      };

  group('VibeRequestPreview.fromJson state parsing', () {
    test('parses Processing state', () {
      final preview = VibeRequestPreview.fromJson(processingJson());
      expect(preview.state, PreviewState.processing);
    });

    test('parses Queued state (case-insensitive)', () {
      final json = processingJson()..['state'] = 'queued';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.state, PreviewState.queued);
    });

    test('parses Completed state', () {
      final json = processingJson()..['state'] = 'Completed';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.state, PreviewState.completed);
    });

    test('parses Failed state', () {
      final json = processingJson()..['state'] = 'Failed';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.state, PreviewState.failed);
    });

    test('parses Invalidated state', () {
      final json = processingJson()..['state'] = 'Invalidated';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.state, PreviewState.invalidated);
    });

    test('maps unknown/absent state to PreviewState.unknown', () {
      final json = processingJson()..['state'] = 'SomethingNew';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.state, PreviewState.unknown);

      final missing = processingJson()..remove('state');
      expect(
          VibeRequestPreview.fromJson(missing).state, PreviewState.unknown);
    });
  });

  group('VibeRequestPreview.fromJson lifecycle fields', () {
    test('reads isStale', () {
      final preview = VibeRequestPreview.fromJson(processingJson());
      expect(preview.isStale, isTrue);
    });

    test('isStale defaults to false when absent', () {
      final json = processingJson()..remove('isStale');
      expect(VibeRequestPreview.fromJson(json).isStale, isFalse);
    });

    test('reads timestamps and job id', () {
      final preview = VibeRequestPreview.fromJson(processingJson());
      expect(preview.previewJobId, 'anJob_user_01_JOB');
      expect(preview.queuedAt, 1783315028219);
      expect(preview.processingStartAt, 1783315029150);
      expect(preview.processingEndAt, isNull);
      expect(preview.generatedAt, isNull);
    });

    test('reads failure and invalidation reasons when present', () {
      final json = processingJson()
        ..['state'] = 'Failed'
        ..['failureReason'] = 'Scheduler timed out'
        ..['invalidatedAt'] = 1783315099999
        ..['invalidationReason'] = 'Schedule changed';
      final preview = VibeRequestPreview.fromJson(json);
      expect(preview.failureReason, 'Scheduler timed out');
      expect(preview.invalidatedAt, 1783315099999);
      expect(preview.invalidationReason, 'Schedule changed');
    });
  });

  group('VibeRequestPreview state helpers', () {
    test('isTerminal is true for completed/failed/invalidated', () {
      expect(
          VibeRequestPreview.fromJson(processingJson()..['state'] = 'Completed')
              .isTerminal,
          isTrue);
      expect(
          VibeRequestPreview.fromJson(processingJson()..['state'] = 'Failed')
              .isTerminal,
          isTrue);
      expect(
          VibeRequestPreview.fromJson(
                  processingJson()..['state'] = 'Invalidated')
              .isTerminal,
          isTrue);
    });

    test('isTerminal is false while processing/queued', () {
      expect(VibeRequestPreview.fromJson(processingJson()).isTerminal, isFalse);
      expect(
          VibeRequestPreview.fromJson(processingJson()..['state'] = 'Queued')
              .isTerminal,
          isFalse);
    });
  });

  group('VibeRequestPreview backward compatibility', () {
    test('still parses existing id / vibeRequestId / previewActions', () {
      final preview = VibeRequestPreview.fromJson(processingJson());
      expect(preview.id, 'vibepreview_user_01_1783315028219_ABC');
      expect(preview.vibeRequestId, 'user_viberequest_1783315017003_XYZ');
      expect(preview.tilerUserId, 'user_01');
      expect(preview.creationTimeInMs, 1783315028219);
      // Empty list in JSON currently maps to null in the model.
      expect(preview.previewActions ?? const [], isEmpty);
    });
  });
}
