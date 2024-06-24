import 'package:tiler_app/data/location.dart';

class OnboardingContent {
  String? personalHoursStart;
  String? workHoursStart;
  Location? workLocation;
  List<String>? preferredDaySections;


  OnboardingContent({
    required this.personalHoursStart,
    required this.workHoursStart,
    required this.workLocation,
    required this.preferredDaySections,

  });


  factory OnboardingContent.fromJson(Map<String, dynamic> json) {
    return OnboardingContent(
      personalHoursStart: json['PersonalHoursStart'] ?? '',
      workHoursStart: json['WorkHoursStart'] ?? '',
      workLocation: json['WorkLocation'] != null
          ? Location.fromJson(json['WorkLocation'])
          : Location.fromDefault(),
      preferredDaySections: json['PreferredDaySections'] != null
          ? List<String>.from(json['PreferredDaySections'])
          : [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'PersonalHoursStart': personalHoursStart,
      'WorkHoursStart': workHoursStart,
      'WorkLocation':workLocation!.toJson(),
      'PreferredDaySections': preferredDaySections,

    };
  }
}
