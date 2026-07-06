import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';

/// Lifecycle of a request-level TileCast preview as reported by
/// GET /api/Vibe/Request/{id}/Preview.
enum PreviewState {
  queued,
  processing,
  completed,
  failed,
  invalidated,
  unknown;

  static PreviewState fromString(String? state) {
    switch (state?.toLowerCase()) {
      case 'queued':
        return PreviewState.queued;
      case 'processing':
        return PreviewState.processing;
      case 'completed':
        return PreviewState.completed;
      case 'failed':
        return PreviewState.failed;
      case 'invalidated':
        return PreviewState.invalidated;
      default:
        return PreviewState.unknown;
    }
  }

  String toJson() => name;
}

class VibeRequestPreview {
  final String? id;
  final String? vibeRequestId;
  final String? tilerUserId;
  final int? creationTimeInMs;
  final List<VibePreviewAction>? previewActions;
  final PreviewState state;
  final bool isStale;
  final String? failureReason;
  final int? invalidatedAt;
  final String? invalidationReason;
  final int? generatedAt;
  final int? queuedAt;
  final int? processingStartAt;
  final int? processingEndAt;
  final String? previewJobId;

  VibeRequestPreview({
    this.id,
    this.vibeRequestId,
    this.tilerUserId,
    this.creationTimeInMs,
    this.previewActions,
    this.state = PreviewState.unknown,
    this.isStale = false,
    this.failureReason,
    this.invalidatedAt,
    this.invalidationReason,
    this.generatedAt,
    this.queuedAt,
    this.processingStartAt,
    this.processingEndAt,
    this.previewJobId,
  });

  /// True once the backend has reached a state that will not change on its own,
  /// i.e. polling can stop.
  bool get isTerminal =>
      state == PreviewState.completed ||
      state == PreviewState.failed ||
      state == PreviewState.invalidated;

  factory VibeRequestPreview.fromJson(Map<String, dynamic> json) {
    return VibeRequestPreview(
      id: json['id'] as String?,
      vibeRequestId: json['vibeRequestId'] as String?,
      tilerUserId: json['tilerUserId'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      previewActions: json['previewActions'] != null &&
          (json['previewActions'] as List).isNotEmpty
          ? (json['previewActions'] as List)
          .map((e) => VibePreviewAction.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      state: PreviewState.fromString(json['state'] as String?),
      isStale: json['isStale'] as bool? ?? false,
      failureReason: json['failureReason'] as String?,
      invalidatedAt: json['invalidatedAt'] as int?,
      invalidationReason: json['invalidationReason'] as String?,
      generatedAt: json['generatedAt'] as int?,
      queuedAt: json['queuedAt'] as int?,
      processingStartAt: json['processingStartAt'] as int?,
      processingEndAt: json['processingEndAt'] as int?,
      previewJobId: json['previewJobId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vibeRequestId': vibeRequestId,
      'tilerUserId': tilerUserId,
      'creationTimeInMs': creationTimeInMs,
      'previewActions': previewActions?.map((e) => e.toJson()).toList(),
      'state': state.toJson(),
      'isStale': isStale,
      'failureReason': failureReason,
      'invalidatedAt': invalidatedAt,
      'invalidationReason': invalidationReason,
      'generatedAt': generatedAt,
      'queuedAt': queuedAt,
      'processingStartAt': processingStartAt,
      'processingEndAt': processingEndAt,
      'previewJobId': previewJobId,
    };
  }

  VibeRequestPreview copyWith({
    String? id,
    String? vibeRequestId,
    String? tilerUserId,
    int? creationTimeInMs,
    List<VibePreviewAction>? previewActions,
    PreviewState? state,
    bool? isStale,
    String? failureReason,
    int? invalidatedAt,
    String? invalidationReason,
    int? generatedAt,
    int? queuedAt,
    int? processingStartAt,
    int? processingEndAt,
    String? previewJobId,
  }) {
    return VibeRequestPreview(
      id: id ?? this.id,
      vibeRequestId: vibeRequestId ?? this.vibeRequestId,
      tilerUserId: tilerUserId ?? this.tilerUserId,
      creationTimeInMs: creationTimeInMs ?? this.creationTimeInMs,
      previewActions: previewActions ?? this.previewActions,
      state: state ?? this.state,
      isStale: isStale ?? this.isStale,
      failureReason: failureReason ?? this.failureReason,
      invalidatedAt: invalidatedAt ?? this.invalidatedAt,
      invalidationReason: invalidationReason ?? this.invalidationReason,
      generatedAt: generatedAt ?? this.generatedAt,
      queuedAt: queuedAt ?? this.queuedAt,
      processingStartAt: processingStartAt ?? this.processingStartAt,
      processingEndAt: processingEndAt ?? this.processingEndAt,
      previewJobId: previewJobId ?? this.previewJobId,
    );
  }
}