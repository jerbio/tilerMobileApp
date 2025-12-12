class VibeAction {
  final String? id;
  final String? descriptions;
  final String? type;
  final int? creationTimeInMs;
  final String? status;
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
      status: json['status'] as String?,
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
      'status': status,
      'beforeScheduleId': beforeScheduleId,
      'afterScheduleId': afterScheduleId,
    };
  }
}