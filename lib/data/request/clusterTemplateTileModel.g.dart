// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clusterTemplateTileModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClusterTemplateTileModel _$ClusterTemplateTileModelFromJson(
        Map<String, dynamic> json) =>
    ClusterTemplateTileModel()
      ..Id = json['Id'] as String?
      ..Name = json['Name'] as String?
      ..ClusterId = json['ClusterId'] as String?
      ..StartTime = (json['StartTime'] as num?)?.toInt()
      ..EndTime = (json['EndTime'] as num?)?.toInt()
      ..OrderedIndex = (json['OrderedIndex'] as num?)?.toInt()
      ..DurationInMs = (json['DurationInMs'] as num?)?.toInt()
      ..AddressData = json['AddressData'] == null
          ? null
          : AddressModel.fromJson(json['AddressData'] as Map<String, dynamic>)
      ..NoteMiscData = json['NoteMiscData'] as String?
      ..Contacts = (json['Contacts'] as List<dynamic>?)
          ?.map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ClusterTemplateTileModelToJson(
        ClusterTemplateTileModel instance) =>
    <String, dynamic>{
      'Id': instance.Id,
      'Name': instance.Name,
      'ClusterId': instance.ClusterId,
      'StartTime': instance.StartTime,
      'EndTime': instance.EndTime,
      'OrderedIndex': instance.OrderedIndex,
      'DurationInMs': instance.DurationInMs,
      'AddressData': instance.AddressData?.toJson(),
      'NoteMiscData': instance.NoteMiscData,
      'Contacts': instance.Contacts?.map((e) => e.toJson()).toList(),
    };
