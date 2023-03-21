// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'startOfDay.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartOfDayConfig _$StartOfDayConfigFromJson(Map<String, dynamic> json) =>
    StartOfDayConfig()
      ..TimeOfDay = json['TimeOfDay'] as String?
      ..TimeZoneOffSet = json['TimeZoneOffSet'] as String?
      ..TimeZone = json['TimeZone'] as String?;

Map<String, dynamic> _$StartOfDayConfigToJson(StartOfDayConfig instance) =>
    <String, dynamic>{
      'TimeOfDay': instance.TimeOfDay,
      'TimeZoneOffSet': instance.TimeZoneOffSet,
      'TimeZone': instance.TimeZone,
    };
