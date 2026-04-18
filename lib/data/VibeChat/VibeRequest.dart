import 'package:tiler_app/data/VibeChat/VibeAction.dart';

class VibeRequest {
  final String? id;
  final int? creationTimeInMs;
  final VibeAction? activeAction;
  final bool? isClosed;
  final String? beforeScheduleId;
  final String? afterScheduleId;
  final List<VibeAction>? actions;

  VibeRequest({
    this.id,
    this.creationTimeInMs,
    this.activeAction,
    this.isClosed,
    this.beforeScheduleId,
    this.afterScheduleId,
    this.actions,
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
    );
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
    };
  }
}