// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permissionProfile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PermissionProfile _$PermissionProfileFromJson(Map<String, dynamic> json) =>
    PermissionProfile()
      ..lastCheck = json['lastCheck'] == null
          ? null
          : DateTime.parse(json['lastCheck'] as String)
      ..isGranted = json['isGranted'] as bool?;

Map<String, dynamic> _$PermissionProfileToJson(PermissionProfile instance) =>
    <String, dynamic>{
      'lastCheck': instance.lastCheck?.toIso8601String(),
      'isGranted': instance.isGranted,
    };
