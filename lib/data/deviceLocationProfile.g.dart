// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deviceLocationProfile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceLocationProfile _$DeviceLocationProfileFromJson(
        Map<String, dynamic> json) =>
    DeviceLocationProfile()
      ..isLoaded = json['isLoaded'] as bool?
      ..location = json['location'] == null
          ? null
          : Location.fromJson(json['location'] as Map<String, dynamic>)
      ..lastTimeLoaded = json['lastTimeLoaded'] == null
          ? null
          : DateTime.parse(json['lastTimeLoaded'] as String)
      ..permission = json['permission'] == null
          ? null
          : PermissionProfile.fromJson(
              json['permission'] as Map<String, dynamic>);

Map<String, dynamic> _$DeviceLocationProfileToJson(
        DeviceLocationProfile instance) =>
    <String, dynamic>{
      'isLoaded': instance.isLoaded,
      'location': instance.location?.toJson(),
      'lastTimeLoaded': instance.lastTimeLoaded?.toIso8601String(),
      'permission': instance.permission?.toJson(),
    };
