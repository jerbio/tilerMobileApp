class UserProfile {
  String? id;
  String? username;
  int? timezoneDiff;
  String? timezone;
  String? email;
  String? endOfDay;
  String? fullName;
  String? lastName;
  String? firstName;
  String? phoneNumber;
  String? dateOfBirth;
  String? countryCode;

  UserProfile();

  UserProfile.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('firstName')) {
      firstName = json['firstName'];
    }

    if (json.containsKey('lastName')) {
      lastName = json['lastName'];
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
    if (json.containsKey('dateOfBirth') && json['dateOfBirth'] != null) {
      dateOfBirth = json['dateOfBirth'];
    }
    if (json.containsKey('countryCode') && json['countryCode'] != null) {
      countryCode = json['countryCode'];
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
      'phoneNumber': this.phoneNumber,
      'dateOfBirth': this.dateOfBirth,
    };
  }

  Map<String, dynamic> toJsonRequest() {
    int? dateOfBirthEpoch;
    try {
      if (this.dateOfBirth != null) {
        dateOfBirthEpoch =
            DateTime.parse(this.dateOfBirth!.replaceAll(r'/', '-'))
                .millisecondsSinceEpoch;
      }
    } catch (e) {
      dateOfBirthEpoch = null;
    }

    return <String, dynamic>{
      'UpdatedUserName': this.username,
      'CountryCode': this.timezone,
      'EndOfDay': this.endOfDay,
      'LastName': this.lastName,
      'FirstName': this.firstName,
      'PhoneNumber': this.phoneNumber,
      'DateOfBirthUtcEpoch': dateOfBirthEpoch,
    };
  }
}
