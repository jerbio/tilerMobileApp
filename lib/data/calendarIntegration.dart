import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/tileObject.dart';

class CalendarItem {
  String? id;
  String? name;
  bool? isEnabled;
  bool? isSelected;
  String? description;
  String? authenticationId;
  String? userIdentifier;

  CalendarItem({
    this.id,
    this.name,
    this.isEnabled,
    this.isSelected,
    this.description,
    this.authenticationId,
    this.userIdentifier,
  });

  CalendarItem.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    isEnabled = json['isEnabled'];
    isSelected = json['isSelected'];
    description = json['description'];
    authenticationId = json['authenticationId'];
    userIdentifier = json['userIdentifier'];
  }
}

class CalendarIntegration extends TilerObj {
  String? email;
  String? userId;
  String? id;
  String? calendarType;
  Location? location;
  List<CalendarItem>? calendarItems;

  CalendarIntegration.fromJson(Map<String, dynamic> json)
      : super.fromJson(json) {
    if (json.containsKey('email')) {
      email = json['email'];
    }
    if (json.containsKey('userId')) {
      userId = json['userId'];
    }
    if (json.containsKey('id')) {
      id = json['id'];
    }
    if (json.containsKey('provider')) {
      calendarType = json['provider'];
    }
    if (json.containsKey('location') && json["location"] != null) {
      location = Location.fromJson(json["location"]);
    }
    if (json.containsKey('calendarItems') && json['calendarItems'] != null) {
      calendarItems = <CalendarItem>[];
      json['calendarItems'].forEach((v) {
        calendarItems!.add(CalendarItem.fromJson(v));
      });
    }
  }
}
