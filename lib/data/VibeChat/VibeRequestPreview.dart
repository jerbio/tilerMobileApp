import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';

enum SimulationState {
  queued,
  processing,
  ready,
  failed,
  invalidated,
}

SimulationState? parseSimulationState(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'queued':
      return SimulationState.queued;
    case 'processing':
      return SimulationState.processing;
    case 'ready':
      return SimulationState.ready;
    case 'failed':
      return SimulationState.failed;
    case 'invalidated':
      return SimulationState.invalidated;
    default:
      return null;
  }
}

class VibeRequestPreview {
  final String? id;
  final String? vibeRequestId;
  final String? tilerUserId;
  final int? creationTimeInMs;
  final List<VibePreviewAction>? previewActions;
  final SimulationState? state;

  VibeRequestPreview({
    this.id,
    this.vibeRequestId,
    this.tilerUserId,
    this.creationTimeInMs,
    this.previewActions,
    this.state,
  });

  factory VibeRequestPreview.fromJson(Map<String, dynamic> json) {
    return VibeRequestPreview(
      id: json['id'] as String?,
      vibeRequestId: json['vibeRequestId'] as String?,
      tilerUserId: json['tilerUserId'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      state: parseSimulationState(json['state'] as String?),
      previewActions: json['previewActions'] != null &&
              (json['previewActions'] as List).isNotEmpty
          ? (json['previewActions'] as List)
              .map(
                  (e) => VibePreviewAction.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vibeRequestId': vibeRequestId,
      'tilerUserId': tilerUserId,
      'creationTimeInMs': creationTimeInMs,
      'state': state?.name,
      'previewActions': previewActions?.map((e) => e.toJson()).toList(),
    };
  }

  VibeRequestPreview copyWith({
    String? id,
    String? vibeRequestId,
    String? tilerUserId,
    int? creationTimeInMs,
    List<VibePreviewAction>? previewActions,
    SimulationState? state,
  }) {
    return VibeRequestPreview(
      id: id ?? this.id,
      vibeRequestId: vibeRequestId ?? this.vibeRequestId,
      tilerUserId: tilerUserId ?? this.tilerUserId,
      creationTimeInMs: creationTimeInMs ?? this.creationTimeInMs,
      previewActions: previewActions ?? this.previewActions,
      state: state ?? this.state,
    );
  }
}