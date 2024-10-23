class UserProfile {
  String? id;
  String? username;
  int? timezoneDiff;
  String? timezone;
  String? email;
  String? endOfDay;
  String? fullName;

  UserProfile.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('username')) {
      username = json['username'];
    }

    if (json.containsKey('timeZone') && json['timeZone'] != null) {
      timezone = json['timeZone'];
    }

    if (json.containsKey('timeZoneDifference') &&
        json['timeZoneDifference'] != null) {
      timezoneDiff = json['timeZoneDifference'].round();
    }

    if (json.containsKey('email') && json['email'] != null) {
      email = json['email'];
    }

    if (json.containsKey('endOfDay') && json['endOfDay'] != null) {
      endOfDay = json['endOfDay'];
    }

    if (json.containsKey('fullName') && json['fullName'] != null) {
      fullName = json['fullName'];
    }
  }
}
