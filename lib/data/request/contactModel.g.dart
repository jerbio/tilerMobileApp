// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contactModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContactModel _$ContactModelFromJson(Map<String, dynamic> json) => ContactModel()
  ..FirstName = json['FirstName'] as String?
  ..LastName = json['LastName'] as String?
  ..PhoneNumber = json['PhoneNumber'] as String?
  ..Email = json['Email'] as String?;

Map<String, dynamic> _$ContactModelToJson(ContactModel instance) =>
    <String, dynamic>{
      'FirstName': instance.FirstName,
      'LastName': instance.LastName,
      'PhoneNumber': instance.PhoneNumber,
      'Email': instance.Email,
    };
