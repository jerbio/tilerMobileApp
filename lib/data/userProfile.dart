class UserProfile {
  String? id;
  String? username;
  int? timezoneDiff;
  String? timezone;
  String? email;
  String? endOfDay;
  String? fullName;
  String? phoneNumber;

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

    if (json.containsKey('phoneNumber') && json['phoneNumber'] != null) {
      phoneNumber = json['phoneNumber'];
    }
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': this.id,
      'username': this.username,
      'timeZone': this.timezone,
      'timeZoneDifference': this.timezoneDiff,
      'email': this.email,
      'endOfDay': this.endOfDay,
      'fullName': this.fullName,
      'phoneNumber': this.phoneNumber
    };
  }
}
