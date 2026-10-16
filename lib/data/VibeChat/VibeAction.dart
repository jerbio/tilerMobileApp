enum ActionType {
  addNewAppointment,
  addNewTask,
  updateExistingTask,
  removeExistingTask,
  procrastinateAllTasks,
  exitPrompting,
  addNewProject,
  decideIfTaskOrProject,
  markTaskAsDone,
  whatIfAddANewAppointment,
  whatIfAddedNewTask,
  whatIfEditUpdateTask,
  whatIfProcrastinateTask,
  whatIfRemovedTask,
  whatIfMarkedTaskAsDone,
  whatIfProcrastinateAll,
  conversationalAndNotSupported,
  tileShareSearchProjects,
  tileShareGetProject,
  tileShareGetTilette,
  tileShareListRecipients,
  tileShareRenameProject,
  tileShareRenameTilette,
  tileShareSetTiletteNotes,
  tileShareUpdateTilette,
  tileShareUpdateProject,
  tileShareUpdatePlan,
  tileShareUpdateRecipients,
  tileShareUpdateAccess,
  tileShareDeleteTilette,
  none;

  static ActionType? fromString(String type) {
    switch (type.toLowerCase()) {
      case 'add_new_appointment':
        return ActionType.addNewAppointment;
      case 'add_new_task':
        return ActionType.addNewTask;
      case 'update_existing_task':
        return ActionType.updateExistingTask;
      case 'remove_existing_task':
        return ActionType.removeExistingTask;
      case 'procrastinate_all_tasks':
        return ActionType.procrastinateAllTasks;
      case 'exit_prompting':
        return ActionType.exitPrompting;
      case 'add_new_project':
        return ActionType.addNewProject;
      case 'decide_if_task_or_project':
        return ActionType.decideIfTaskOrProject;
      case 'mark_task_as_done':
        return ActionType.markTaskAsDone;
      case 'whatif_addanewappointment':
        return ActionType.whatIfAddANewAppointment;
      case 'whatif_addednewtask':
        return ActionType.whatIfAddedNewTask;
      case 'whatif_editupdatetask':
        return ActionType.whatIfEditUpdateTask;
      case 'whatif_procrastinatetask':
        return ActionType.whatIfProcrastinateTask;
      case 'whatif_removedtask':
        return ActionType.whatIfRemovedTask;
      case 'whatif_markedtaskasdone':
        return ActionType.whatIfMarkedTaskAsDone;
      case 'whatif_procrastinateall':
        return ActionType.whatIfProcrastinateAll;
      case 'tileshare_delete_tilette':
        return ActionType.tileShareDeleteTilette;
      case 'tileshare_update_recipients':
        return ActionType.tileShareUpdateRecipients;
      case 'tileshare_update_access':
        return ActionType.tileShareUpdateAccess;
      case 'tileshare_update_project':
        return ActionType.tileShareUpdateProject;
      case 'tileshare_update_plan':
        return ActionType.tileShareUpdatePlan;
      case 'tileshare_update_tilette':
        return ActionType.tileShareUpdateTilette;
      case 'tileshare_set_tilette_notes':
        return ActionType.tileShareSetTiletteNotes;
      case 'tileshare_rename_tilette':
        return ActionType.tileShareRenameTilette;
      case 'tileshare_rename_project':
        return ActionType.tileShareRenameProject;
      case 'tileshare_list_recipients':
        return ActionType.tileShareListRecipients;
      case 'tileshare_get_tilette':
        return ActionType.tileShareGetTilette;
      case 'tileshare_get_project':
        return ActionType.tileShareGetProject;
      case 'tileshare_search_projects':
        return ActionType.tileShareSearchProjects;
      case 'conversational_and_not_supported':
        return ActionType.conversationalAndNotSupported;
      case 'none':
        return ActionType.none;
      default:
        return null;
    }
  }

  String toJson() => name;
}

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
  final Map<String, dynamic>? tileShareResult;
  final String? id;
  final String? descriptions;
  final ActionType? type;
  final int? creationTimeInMs;
  final ActionStatus? status;
  final String? beforeScheduleId;
  final String? afterScheduleId;
  final String? entityId;
  final String? entityType;

  VibeAction({
    this.id,
    this.tileShareResult,
    this.descriptions,
    this.type,
    this.creationTimeInMs,
    this.status,
    this.beforeScheduleId,
    this.afterScheduleId,
    this.entityId,
    this.entityType,
  });

  factory VibeAction.fromJson(Map<String, dynamic> json) {
    return VibeAction(
      id: json['id'] as String?,
      tileShareResult: json['tileShareResult'] == null
          ? null
          : Map<String, dynamic>.from(json['tileShareResult']),
      descriptions: json['descriptions'] as String?,
      type: json['type'] != null
          ? ActionType.fromString(json['type'] as String)
          : null,
      creationTimeInMs: json['creationTimeInMs'] as int?,
      status: json['status'] != null
          ? ActionStatus.fromString(json['status'] as String)
          : null,
      beforeScheduleId: json['beforeScheduleId'] as String?,
      afterScheduleId: json['afterScheduleId'] as String?,
      entityId: json['entityId'] as String?,
      entityType: json['entityType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tileShareResult': tileShareResult,
      'descriptions': descriptions,
      'type': type?.toJson(),
      'creationTimeInMs': creationTimeInMs,
      'status': status?.toJson(),
      'beforeScheduleId': beforeScheduleId,
      'afterScheduleId': afterScheduleId,
      'entityId': entityId,
      'entityType': entityType,
    };
  }

  VibeAction copyWith({
    String? id,
    Map<String, dynamic>? tileShareResult,
    String? descriptions,
    ActionType? type,
    int? creationTimeInMs,
    ActionStatus? status,
    String? beforeScheduleId,
    String? afterScheduleId,
    String? entityId,
    String? entityType,
  }) {
    return VibeAction(
      id: id ?? this.id,
      tileShareResult: tileShareResult ?? this.tileShareResult,
      descriptions: descriptions ?? this.descriptions,
      type: type ?? this.type,
      creationTimeInMs: creationTimeInMs ?? this.creationTimeInMs,
      status: status ?? this.status,
      beforeScheduleId: beforeScheduleId ?? this.beforeScheduleId,
      afterScheduleId: afterScheduleId ?? this.afterScheduleId,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
    );
  }
}
