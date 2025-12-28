import 'package:tiler_app/data/RecurringTask.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tileSuggestion.dart';


class OnboardingContent {
  String? personalHoursStart;
  String? workHoursStart;

  Location? workLocation;
  String? userLongitude;
  String? userLatitude;
  int? timeZoneOffset;
  String? timeZone;
  List<String>? preferredDaySections;
  List<RecurringTask>? recurringTasks;
  List<TileSuggestion>? tileSuggestions;
  List<String>? usage;


  OnboardingContent({
    required this.personalHoursStart,
    required this.workHoursStart,
    required this.workLocation,
    required this.userLongitude,
    required this.userLatitude,
    required this.timeZone,
    required this.timeZoneOffset,
    required this.preferredDaySections,
    required this.recurringTasks,
    required this.tileSuggestions,
    required this.usage
  });


  factory OnboardingContent.fromJson(Map<String, dynamic> json) {
    return OnboardingContent(
      personalHoursStart: json['PersonalHoursStart'] ?? '',
      workHoursStart: json['WorkHoursStart'] ?? '',
      workLocation: json['WorkLocation'] != null
          ? Location.fromJson(json['WorkLocation'])
          : Location.fromDefault(),
      userLongitude: json['UserLongitude'] ?? '',
      userLatitude:  json['UserLatitude'] ?? '',
      timeZoneOffset: json['TimeZoneOffset']??0,
      timeZone: json['TimeZone']??'',
      preferredDaySections: json['PreferredDaySections'] != null
          ? List<String>.from(json['PreferredDaySections'])
          : [],
      recurringTasks: json['Repetitives'] != null
          ? (json['Repetitives'] as List)
          .map((e) => RecurringTask.fromJson(e))
          .toList()
          : [],
      usage: json['TilerUsage'] != null
          ? List<String>.from(json['TilerUsage'])
          : [],
      tileSuggestions: json['TileList'] != null
          ? (json['TileList'] as List).map((e) => TileSuggestion.fromJson(e)).toList()
          : [],

    );
  }
  Map<String, dynamic> toJson() {
    return {
      'PersonalHoursStart': personalHoursStart,
      'WorkHoursStart': workHoursStart,
      'UserLongitude':userLongitude,
      'UserLatitude':userLatitude,
      'TimeZoneOffset':timeZoneOffset,
      'timeZone':timeZone,
      'WorkLocation':workLocation!.toJson(),
      'PreferredDaySections': preferredDaySections,
      'Repetitives': recurringTasks?.map((e) => e.toJson()).toList(),
      'TilerUsage' : usage,
      'TileList':tileSuggestions?.map((e) => e.toJson()).toList(),

    };
  }
}
