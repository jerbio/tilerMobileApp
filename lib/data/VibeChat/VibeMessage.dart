import 'package:tiler_app/data/VibeChat/VibeAction.dart';

enum MessageOrigin {
  user,
  tiler,
  model;

  static MessageOrigin fromString(String origin) {
    switch (origin.toLowerCase()) {
      case 'user':
        return MessageOrigin.user;
      case 'tiler':
        return MessageOrigin.tiler;
      case 'model':
        return MessageOrigin.model;
      default:
        return MessageOrigin.tiler;
    }
  }

  String toJson() => name;
}

class VibeMessage {
  final String? id;
  final MessageOrigin? origin;
  final String? content;
  final String? requestId;
  final String? sessionId;
  final List<String>? actionIds;
  final List<VibeAction>? actions;

  VibeMessage({
    this.id,
    this.origin,
    this.content,
    this.requestId,
    this.sessionId,
    this.actionIds,
    this.actions,
  });

  factory VibeMessage.fromJson(Map<String, dynamic> json) {
    return VibeMessage(
      id: json['id'] as String?,
      origin: json['origin'] != null
          ? MessageOrigin.fromString(json['origin'] as String)
          : null,
      content: json['content'] as String?,
      requestId: json['requestId'] as String?,
      sessionId: json['sessionId'] as String?,
      actionIds: json['actionIds'] != null
          ? List<String>.from(json['actionIds'] as List)
          : null,
      actions: json['actions'] != null && (json['actions'] as List).isNotEmpty
          ? (json['actions'] as List)
          .map((action) => VibeAction.fromJson(action))
          .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin?.toJson(),
      'content': content,
      'requestId': requestId,
      'sessionId': sessionId,
      'actionIds': actionIds,
      'actions': actions?.map((action) => action.toJson()).toList(),
    };
  }

  VibeMessage copyWith({
    String? id,
    MessageOrigin? origin,
    String? content,
    String? requestId,
    String? sessionId,
    List<String>? actionIds,
    List<VibeAction>? actions,
  }) {
    return VibeMessage(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      content: content ?? this.content,
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      actionIds: actionIds ?? this.actionIds,
      actions: actions ?? this.actions,
    );
  }
}