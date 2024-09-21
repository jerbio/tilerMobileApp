// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addressModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) => AddressModel()
  ..Description = json['Description'] as String?
  ..Address = json['Address'] as String?
  ..AddressIsVerified = json['AddressIsVerified'] as bool?;

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) =>
    <String, dynamic>{
      'Description': instance.Description,
      'Address': instance.Address,
      'AddressIsVerified': instance.AddressIsVerified,
    };
