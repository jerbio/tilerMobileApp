class ScheduleStatus {
  String? analysisId;
  String? evaluationId;
  ScheduleStatus();
  ScheduleStatus.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('analysisId')) {
      analysisId = json["analysisId"];
    }
    if (json.containsKey('evaluationId')) {
      evaluationId = json["evaluationId"];
    }
  }
}
