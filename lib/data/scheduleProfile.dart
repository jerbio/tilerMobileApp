
enum TravelMedium { bicycling, transit, driving, walking }



enum PinPreference { start, mid, end }


class ScheduleProfile {
  TravelMedium? travelMedium;
  PinPreference? pinPreference;
  num? sleepDuration;

  ScheduleProfile.fromJson(Map<String, dynamic> json) {
    travelMedium = null;
    for (var eachVal in TravelMedium.values) {
      if (json['travelMedium'] != null &&
          eachVal.name.toString() == json['travelMedium']) {
        travelMedium = eachVal;
        break;
      }
    }
    for (var eachVal in PinPreference.values) {
      if (json['pinPreference'] != null &&
          eachVal.name.toString() == json['pinPreference']) {
        pinPreference = eachVal;
        break;
      }
    }

    if (json['sleepDuration'] != null) {
      sleepDuration = json['sleepDuration'];
    }
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'TravelMedium': travelMedium?.name.toString().toLowerCase(),
      'PinPreference': pinPreference?.name.toString().toLowerCase(),
      'SleepDurationInMs': sleepDuration,
    };
  }
}
