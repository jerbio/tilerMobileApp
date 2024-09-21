// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'templateClusterModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TemplateClusterModel _$TemplateClusterModelFromJson(
        Map<String, dynamic> json) =>
    TemplateClusterModel()
      ..Name = json['Name'] as String?
      ..StartTime = (json['StartTime'] as num?)?.toInt()
      ..EndTime = (json['EndTime'] as num?)?.toInt()
      ..DurationInMs = (json['DurationInMs'] as num?)?.toInt()
      ..AddressData = json['AddressData'] == null
          ? null
          : AddressModel.fromJson(json['AddressData'] as Map<String, dynamic>)
      ..Contacts = (json['Contacts'] as List<dynamic>?)
          ?.map((e) => ContactModel.fromJson(e as Map<String, dynamic>))
          .toList()
      ..SchedulePattern = json['SchedulePattern'] as String?
      ..Notes = json['Notes'] as String?
      ..ClusterTemplateTileModels =
          (json['ClusterTemplateTileModels'] as List<dynamic>?)
              ?.map((e) =>
                  ClusterTemplateTileModel.fromJson(e as Map<String, dynamic>))
              .toList();

Map<String, dynamic> _$TemplateClusterModelToJson(
        TemplateClusterModel instance) =>
    <String, dynamic>{
      'Name': instance.Name,
      'StartTime': instance.StartTime,
      'EndTime': instance.EndTime,
      'DurationInMs': instance.DurationInMs,
      'AddressData': instance.AddressData?.toJson(),
      'Contacts': instance.Contacts?.map((e) => e.toJson()).toList(),
      'SchedulePattern': instance.SchedulePattern,
      'Notes': instance.Notes,
      'ClusterTemplateTileModels':
          instance.ClusterTemplateTileModels?.map((e) => e.toJson()).toList(),
    };
