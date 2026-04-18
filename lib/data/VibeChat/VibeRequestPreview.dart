import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';

class VibeRequestPreview {
  final String? id;
  final String? vibeRequestId;
  final String? tilerUserId;
  final int? creationTimeInMs;
  final List<VibePreviewAction>? previewActions;

  VibeRequestPreview({
    this.id,
    this.vibeRequestId,
    this.tilerUserId,
    this.creationTimeInMs,
    this.previewActions,
  });

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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vibeRequestId': vibeRequestId,
      'tilerUserId': tilerUserId,
      'creationTimeInMs': creationTimeInMs,
      'previewActions': previewActions?.map((e) => e.toJson()).toList(),
    };
  }

  VibeRequestPreview copyWith({
    String? id,
    String? vibeRequestId,
    String? tilerUserId,
    int? creationTimeInMs,
    List<VibePreviewAction>? previewActions,
  }) {
    return VibeRequestPreview(
      id: id ?? this.id,
      vibeRequestId: vibeRequestId ?? this.vibeRequestId,
      tilerUserId: tilerUserId ?? this.tilerUserId,
      creationTimeInMs: creationTimeInMs ?? this.creationTimeInMs,
      previewActions: previewActions ?? this.previewActions,
    );
  }
}