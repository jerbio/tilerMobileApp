// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'RestrictionWeekConfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RestrictionWeekConfig _$RestrictionWeekConfigFromJson(
        Map<String, dynamic> json) =>
    RestrictionWeekConfig()
      ..WeekDayOption = (json['WeekDayOption'] as List<dynamic>?)
          ?.map((e) =>
              RestrictionWeekDayConfig.fromJson(e as Map<String, dynamic>))
          .toList()
      ..isEnabled = json['isEnabled'] as String
      ..timeZone = json['timeZone'] as String;

Map<String, dynamic> _$RestrictionWeekConfigToJson(
        RestrictionWeekConfig instance) =>
    <String, dynamic>{
      'WeekDayOption': instance.WeekDayOption?.map((e) => e.toJson()).toList(),
      'isEnabled': instance.isEnabled,
      'timeZone': instance.timeZone,
    };

RestrictionWeekDayConfig _$RestrictionWeekDayConfigFromJson(
        Map<String, dynamic> json) =>
    RestrictionWeekDayConfig()
      ..Start = json['Start'] as String?
      ..Index = json['Index'] as String?
      ..End = json['End'] as String?;

Map<String, dynamic> _$RestrictionWeekDayConfigToJson(
        RestrictionWeekDayConfig instance) =>
    <String, dynamic>{
      'Start': instance.Start,
      'Index': instance.Index,
      'End': instance.End,
    };
