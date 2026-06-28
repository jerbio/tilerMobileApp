import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeRequestPreview.dart';

enum VibeRequestState {
  executed,
  superseded,
  failed,
}

VibeRequestState? parseVibeRequestState(String? raw) {
  switch (raw?.toLowerCase()) {
    case 'executed':
      return VibeRequestState.executed;
    case 'superseded':
      return VibeRequestState.superseded;
    case 'failed':
      return VibeRequestState.failed;
    default:
      return null;
  }
}

class VibeRequest {
  final String? id;
  final int? creationTimeInMs;
  final VibeAction? activeAction;
  final bool? isClosed;
  final String? beforeScheduleId;
  final String? afterScheduleId;
  final List<VibeAction>? actions;
  final VibeRequestPreview? preview;
  final List<VibeRequestPreview>? previews;
  final VibeRequestState? state;
  final String? supersededByRequestId;

  VibeRequest({
    this.id,
    this.creationTimeInMs,
    this.activeAction,
    this.isClosed,
    this.beforeScheduleId,
    this.afterScheduleId,
    this.actions,
    this.preview,
    this.previews,
    this.state,
    this.supersededByRequestId,
  });

  factory VibeRequest.fromJson(Map<String, dynamic> json) {
    return VibeRequest(
      id: json['id'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      activeAction: json['activeAction'] != null
          ? VibeAction.fromJson(json['activeAction'])
          : null,
      isClosed: json['isClosed'] as bool?,
      beforeScheduleId: json['beforeScheduleId'] as String?,
      afterScheduleId: json['afterScheduleId'] as String?,
      actions: json['actions'] != null && (json['actions'] as List).isNotEmpty
          ? (json['actions'] as List)
          .map((action) => VibeAction.fromJson(action))
          .toList()
          : null,
      preview: json['preview'] is Map<String, dynamic>
          ? VibeRequestPreview.fromJson(json['preview'] as Map<String, dynamic>)
          : null,
      previews: json['previews'] is List && (json['previews'] as List).isNotEmpty
          ? (json['previews'] as List)
              .whereType<Map<String, dynamic>>()
              .map((p) => VibeRequestPreview.fromJson(p))
              .toList()
          : null,
      state: parseVibeRequestState(json['state'] as String?),
      supersededByRequestId: json['supersededByRequestId'] as String?,
    );
  }

  VibeRequestPreview? get primedPreview {
    if (preview != null) return preview;
    final list = previews;
    if (list != null && list.isNotEmpty) {
      for (final p in list) {
        if (p.state != SimulationState.invalidated) return p;
      }
      return list.first;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'creationTimeInMs': creationTimeInMs,
      'activeAction': activeAction?.toJson(),
      'isClosed': isClosed,
      'beforeScheduleId': beforeScheduleId,
      'afterScheduleId': afterScheduleId,
      'actions': actions?.map((action) => action.toJson()).toList(),
      'preview': preview?.toJson(),
      'previews': previews?.map((p) => p.toJson()).toList(),
      'state': state?.name,
      'supersededByRequestId': supersededByRequestId,
    };
  }
}
