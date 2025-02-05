class TravelTimeAndDistance {
  DateTime? dayEndTime;
  double? distance;
  double? travelTimeInMs;
  TravelTimeAndDistance.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('travelTime') && json['travelTime'] != null) {
      travelTimeInMs = double.parse(json['travelTime'].toString());
    }
    if (json.containsKey('totalDistance') && json['totalDistance'] != null) {
      distance = double.parse(json['totalDistance'].toString());
    }
  }
}
