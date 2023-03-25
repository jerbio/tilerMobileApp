// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TilerError.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TilerError _$TilerErrorFromJson(Map<String, dynamic> json) => TilerError(
      message: json['message'] as String?,
    )..Code = json['Code'] as String?;

Map<String, dynamic> _$TilerErrorToJson(TilerError instance) =>
    <String, dynamic>{
      'message': instance.message,
      'Code': instance.Code,
    };
