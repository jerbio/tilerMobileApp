enum ActionStatus {
  parsed,
  clarification,
  none,
  pending,
  executed,
  failed,
  exited,
  disposed;

  static ActionStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'parsed':
        return ActionStatus.parsed;
      case 'clarification':
        return ActionStatus.clarification;
      case 'none':
        return ActionStatus.none;
      case 'pending':
        return ActionStatus.pending;
      case 'executed':
        return ActionStatus.executed;
      case 'failed':
        return ActionStatus.failed;
      case 'exited':
        return ActionStatus.exited;
      case 'disposed':
        return ActionStatus.disposed;
      default:
        return ActionStatus.none;
    }
  }

  String toJson() => name;
}

class VibeAction {
  final String? id;
  final String? descriptions;
  final String? type;
  final int? creationTimeInMs;
  final ActionStatus? status;
  final String? beforeScheduleId;
  final String? afterScheduleId;

  VibeAction({
    this.id,
    this.descriptions,
    this.type,
    this.creationTimeInMs,
    this.status,
    this.beforeScheduleId,
    this.afterScheduleId,
  });

  factory VibeAction.fromJson(Map<String, dynamic> json) {
    return VibeAction(
      id: json['id'] as String?,
      descriptions: json['descriptions'] as String?,
      type: json['type'] as String?,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      status: json['status'] != null
          ? ActionStatus.fromString(json['status'] as String)
          : null,
      beforeScheduleId: json['beforeScheduleId'] as String?,
      afterScheduleId: json['afterScheduleId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'descriptions': descriptions,
      'type': type,
      'creationTimeInMs': creationTimeInMs,
      'status': status?.toJson(),
      'beforeScheduleId': beforeScheduleId,
      'afterScheduleId': afterScheduleId,
    };
  }
}