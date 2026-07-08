import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/VibeChat/VibePreviewSummary.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

/// Outcome of attempting to load a TileCast preview batch.
enum TileCastOutcome {
  /// Preview generated and its schedule downloaded successfully.
  ready,

  /// Backend reported the preview generation failed.
  failed,

  /// The preview was generated but has since been invalidated.
  invalidated,

  /// Polling exhausted its time budget while still processing.
  timedOut,

  /// Preview reported complete but the schedule summary could not be loaded.
  summaryUnavailable,
}

/// Immutable result describing how a TileCast preview load resolved.
class TileCastPreviewResult {
  final TileCastOutcome outcome;
  final VibeRequestPreview? batch;
  final List<VibePreviewAction> actions;
  final List<SubCalendarEvent> tiles;
  final int focusIndex;
  final String? failureReason;

  const TileCastPreviewResult({
    required this.outcome,
    this.batch,
    this.actions = const [],
    this.tiles = const [],
    this.focusIndex = 0,
    this.failureReason,
  });
}

/// Encapsulates the polling loop that turns an asynchronous, request-level
/// TileCast preview into a ready-to-render result.
///
/// Kept free of BLoC/network/timer dependencies so the polling behaviour can be
/// unit tested with injected fetchers and a controllable [delay].
class TileCastPreviewLoader {
  /// Fetches the request-level preview(s). Returns an empty list when the
  /// backend has not yet produced a preview object.
  final Future<List<VibeRequestPreview>> Function(String vibeRequestId)
      fetchRequestPreview;

  /// Fetches the full schedule for a completed preview.
  final Future<VibePreviewSummary?> Function(String previewId) fetchSummary;

  /// How long to wait between polls while the preview is still processing.
  final Duration pollInterval;

  /// Total time budget before giving up on a still-processing preview.
  final Duration timeout;

  /// Injection seam for waiting between polls (defaults to [Future.delayed]).
  final Future<void> Function(Duration duration) delay;

  TileCastPreviewLoader({
    required this.fetchRequestPreview,
    required this.fetchSummary,
    this.pollInterval = const Duration(seconds: 10),
    this.timeout = const Duration(minutes: 1),
    Future<void> Function(Duration duration)? delay,
  }) : delay = delay ?? Future.delayed;

  int get _maxAttempts {
    final interval = pollInterval.inMilliseconds;
    if (interval <= 0) return 1;
    final attempts = (timeout.inMilliseconds / interval).ceil();
    return attempts < 1 ? 1 : attempts;
  }

  Future<TileCastPreviewResult> load(String vibeRequestId,
      {String? actionId}) async {
    final maxAttempts = _maxAttempts;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final previews = await fetchRequestPreview(vibeRequestId);
      final batch = previews.isNotEmpty ? previews.first : null;

      if (batch != null && batch.isTerminal) {
        return _resolveTerminal(batch, actionId);
      }

      // Still queued/processing (or no preview object yet) — wait and retry
      // unless the time budget is exhausted.
      if (attempt < maxAttempts - 1) {
        await delay(pollInterval);
      }
    }

    return const TileCastPreviewResult(outcome: TileCastOutcome.timedOut);
  }

  Future<TileCastPreviewResult> _resolveTerminal(
      VibeRequestPreview batch, String? actionId) async {
    switch (batch.state) {
      case PreviewState.failed:
        return TileCastPreviewResult(
          outcome: TileCastOutcome.failed,
          batch: batch,
          failureReason: batch.failureReason,
        );
      case PreviewState.invalidated:
        return TileCastPreviewResult(
          outcome: TileCastOutcome.invalidated,
          batch: batch,
          failureReason: batch.invalidationReason ?? batch.failureReason,
        );
      case PreviewState.ready:
        return _resolveCompleted(batch, actionId);
      default:
        // Should not happen (isTerminal guarded), treat defensively as timeout.
        return const TileCastPreviewResult(outcome: TileCastOutcome.timedOut);
    }
  }

  Future<TileCastPreviewResult> _resolveCompleted(
      VibeRequestPreview batch, String? actionId) async {
    final actions = batch.previewActions ?? const <VibePreviewAction>[];

    // All actions share the same preview; prefer the focused action's preview
    // id, else the first action's, else the batch id.
    final focusIndex = _focusIndexFor(actions, actionId);
    final previewId = (focusIndex < actions.length
            ? actions[focusIndex].vibePreviewId
            : null) ??
        (actions.isNotEmpty ? actions.first.vibePreviewId : null) ??
        batch.id;

    if (previewId == null) {
      return TileCastPreviewResult(
        outcome: TileCastOutcome.summaryUnavailable,
        batch: batch,
        actions: actions,
        focusIndex: focusIndex,
      );
    }

    final summary = await fetchSummary(previewId);
    if (summary == null) {
      return TileCastPreviewResult(
        outcome: TileCastOutcome.summaryUnavailable,
        batch: batch,
        actions: actions,
        focusIndex: focusIndex,
      );
    }

    return TileCastPreviewResult(
      outcome: TileCastOutcome.ready,
      batch: batch,
      actions: actions,
      tiles: summary.subCalendarEvents ?? const [],
      focusIndex: focusIndex,
    );
  }

  int _focusIndexFor(List<VibePreviewAction> actions, String? actionId) {
    if (actionId == null) return 0;
    final idx =
        actions.indexWhere((a) => a.action?.id == actionId);
    return idx >= 0 ? idx : 0;
  }
}
