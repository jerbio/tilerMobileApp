import 'package:tiler_app/data/VibeChat/VibeAction.dart';

class VibePreviewAction {
  final VibeAction? action;
  final String? entityId;
  final String? entityType;
  final String? vibePreviewId;

  VibePreviewAction({
    this.action,
    this.entityId,
    this.entityType,
    this.vibePreviewId,
  });

  factory VibePreviewAction.fromJson(Map<String, dynamic> json) {
    return VibePreviewAction(
      action: json['action'] != null
          ? VibeAction.fromJson(json['action'] as Map<String, dynamic>)
          : null,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
      vibePreviewId: json['vibePreviewId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action?.toJson(),
      'entityId': entityId,
      'entityType': entityType,
      'vibePreviewId': vibePreviewId,
    };
  }

  VibePreviewAction copyWith({
    VibeAction? action,
    String? entityId,
    String? entityType,
    String? vibePreviewId,
  }) {
    return VibePreviewAction(
      action: action ?? this.action,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      vibePreviewId: vibePreviewId ?? this.vibePreviewId,
    );
  }
}