// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clusterTemplateTileModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClusterTemplateTileModel _$ClusterTemplateTileModelFromJson(
        Map<String, dynamic> json) =>
    ClusterTemplateTileModel()
      ..Name = json['Name'] as String?
      ..StartTime = (json['StartTime'] as num?)?.toInt()
      ..EndTime = (json['EndTime'] as num?)?.toInt()
      ..OrderedIndex = (json['OrderedIndex'] as num?)?.toInt()
      ..AddressData = json['AddressData'] == null
          ? null
          : AddressModel.fromJson(json['AddressData'] as Map<String, dynamic>)
      ..Contacts = (json['Contacts'] as List<dynamic>?)
          ?.map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$ClusterTemplateTileModelToJson(
        ClusterTemplateTileModel instance) =>
    <String, dynamic>{
      'Name': instance.Name,
      'StartTime': instance.StartTime,
      'EndTime': instance.EndTime,
      'OrderedIndex': instance.OrderedIndex,
      'AddressData': instance.AddressData?.toJson(),
      'Contacts': instance.Contacts?.map((e) => e.toJson()).toList(),
    };
