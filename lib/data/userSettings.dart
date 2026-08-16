import 'package:tiler_app/data/appThemeMode.dart';
import 'package:tiler_app/data/scheduleProfile.dart';
import 'package:tiler_app/services/themerHelper.dart';

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
        notificationEnabled: json['notifcationEnabled'] ?? false,
        notificationEnabledMs: json['notifcationEnabledMs'] ?? 0,
        emailNotificationEnabled: json['emailNotificationEnabled'] ?? false,
        textNotificationEnabled: json['textNotificationEnabled'] ?? false,
      );
    } catch (e) {
      throw FormatException('Error parsing UserPreference: $e');
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'notifcationEnabled': notificationEnabled,
      'notifcationEnabledMs': notificationEnabledMs,
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
  final UiScheme? mobileUiScheme;
  final UiScheme? desktopUiScheme;

  UserSettings({
    required this.userPreference,
    required this.marketingPreference,
    required this.scheduleProfile,
    this.mobileUiScheme,
    this.desktopUiScheme,
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
        mobileUiScheme: json['mobileUiScheme'] != null
            ? UiScheme.fromJson(json['mobileUiScheme'])
            : null,
        desktopUiScheme: json['desktopUiScheme'] != null
            ? UiScheme.fromJson(json['desktopUiScheme'])
            : null,
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
      'MobileUiScheme': mobileUiScheme?.toJsonForUpdate(),
      'DesktopUiScheme': desktopUiScheme?.toJsonForUpdate(),
    };
  }
}

class UiScheme {
  final String? id;
  final String? scheduleProfileId;
  final String? name;
  final String? mainColor;
  final String? accentColor;
  final String? fontFamily;
  final num? fontSize;
  final String? fontWeight;
  final bool? isDefault;
  final AppThemeMode? themeMode;

  UiScheme({
    this.id,
    this.scheduleProfileId,
    this.name,
    this.mainColor,
    this.accentColor,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.isDefault,
    this.themeMode,
  });

  factory UiScheme.fromJson(Map<String, dynamic> json) {
    return UiScheme(
      id: json['id'],
      scheduleProfileId: json['scheduleProfileId'],
      name: json['name'],
      mainColor: json['mainColor'],
      accentColor: json['accentColor'],
      fontFamily: json['fontFamily'],
      fontSize: json['fontSize'],
      fontWeight: json['fontWeight'],
      isDefault: json['isDefault'],
      themeMode: json['themeMode'] != null
          ? ThemeManager.fromString(json['themeMode'])
          : null,
    );
  }

  Map<String, dynamic> toJsonForUpdate() {
    return {
      'id': id,
      'scheduleProfileId': scheduleProfileId,
      'name': name,
      'mainColor': mainColor,
      'accentColor': accentColor,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'fontWeight': fontWeight,
      'isDefault': isDefault,
      'themeMode': themeMode?.name,
    };
  }

  UiScheme copyWith({AppThemeMode? themeMode}) {
    return UiScheme(
      id: id,
      scheduleProfileId: scheduleProfileId,
      name: name,
      mainColor: mainColor,
      accentColor: accentColor,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      isDefault: isDefault,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
