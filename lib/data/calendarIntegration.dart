import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/tileObject.dart';

class CalendarIntegration extends TilerObj {
  String? email;
  String? userId;
  String? id;
  String? calendarType;
  Location? location;

  CalendarIntegration.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json.containsKey('email')) {
      email = json['email'];
    }
    if (json.containsKey('calendarType')) {
      calendarType = json['calendarType'];
    }
    if (json.containsKey('location') && json["location"] != null) {
      location = Location.fromJson(json["location"]);
    }
  }
}
