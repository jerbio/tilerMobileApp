
class PeekDay {
  double? duration;
  double? durationRatio;
  int? dayIndex;
  double? sleepTime;

  PeekDay.fromJson(Map<String, dynamic> json) {
    if (json['duration'] != null) {
      duration = json['duration'];
    }
    if (json['durationRatio'] != null) {
      durationRatio = json['durationRatio'];
    }
    if (json['dayIndex'] != null) {
      dayIndex = json['dayIndex'];
    }
    if (json['sleepTime'] != null) {
      sleepTime = json['sleepTime'];
    }
  }
}
