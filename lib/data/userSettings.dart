import 'package:tiler_app/data/scheduleProfile.dart';

class UserPreference {
  final bool? notificationEnabled;
  final int? notificationEnabledMs;
  final bool? emailNotificationEnabled;
  final bool? textNotificationEnabled;

  UserPreference({
    required this.notificationEnabled,
    required this.notificationEnabledMs,
    required this.emailNotificationEnabled,
    required this.textNotificationEnabled,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    try {
      return UserPreference(
        notificationEnabled: json['notiifcationEnabled'] ?? false,
        notificationEnabledMs: json['notiifcationEnabledMs'] ?? 0,
        emailNotificationEnabled: json['emailNotificationEnabled'] ?? false,
        textNotificationEnabled: json['textNotificationEnabled'] ?? false,
      );
    } catch (e) {
      throw FormatException('Error parsing UserPreference: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'notiifcationEnabled': notificationEnabled,
      'notiifcationEnabledMs': notificationEnabledMs,
      'emailNotificationEnabled': emailNotificationEnabled,
      'textNotificationEnabled': textNotificationEnabled,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'NotificationEnabled': notificationEnabled,
      'NotificationEnabledMs': notificationEnabledMs,
      'EmailNotificationEnabled': emailNotificationEnabled,
      'TextNotificationEnabled': textNotificationEnabled,
    };
  }
}

class MarketingPreference {
  final bool? disableAll;
  final bool? disableEmail;
  final bool? disableTextMsg;

  MarketingPreference({
    required this.disableAll,
    required this.disableEmail,
    required this.disableTextMsg,
  });

  factory MarketingPreference.fromJson(Map<String, dynamic> json) {
    try {
      return MarketingPreference(
        disableAll: json['disableAll'] ?? false,
        disableEmail: json['disableEmail'] ?? false,
        disableTextMsg: json['disableTextMsg'] ?? false,
      );
    } catch (e) {
      throw FormatException('Error parsing MarketingPreference: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'disableAll': disableAll,
      'disableEmail': disableEmail,
      'disableTextMsg': disableTextMsg,
    };
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'DisableAll': disableAll,
      'DisableEmail': disableEmail,
      'DisableTextMsg': disableTextMsg,
    };
  }
}

class UserSettings {
  final UserPreference? userPreference;
  final MarketingPreference? marketingPreference;
  final ScheduleProfile? scheduleProfile;

  UserSettings({
    required this.userPreference,
    required this.marketingPreference,
    required this.scheduleProfile,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    try {
      return UserSettings(
        userPreference: UserPreference.fromJson(json['userPreference'] ??
            {}), // Default empty map for error resilience
        marketingPreference: MarketingPreference.fromJson(
            json['marketingPreference'] ??
                {}), // Default empty map for error resilience
        scheduleProfile: ScheduleProfile.fromJson(json['scheduleProfile'] ??
            {}), // Default empty map for error resilience
      );
    } catch (e) {
      throw FormatException('Error parsing Settings: $e');
    }
  }

  Map<String, dynamic> toJsonForUpdate() {
    // this uses pascal casing for the json response
    // this is used for the update settings
    return {
      'UserPreference': userPreference?.toJsonForUpdate(),
      'MarketingPreference': marketingPreference?.toJsonForUpdate(),
      'ScheduleProfile': scheduleProfile?.toJsonForUpdate(),
    };
  }
}
