// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tileShareClusterModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TileShareClusterModel _$TileShareClusterModelFromJson(
        Map<String, dynamic> json) =>
    TileShareClusterModel()
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
      ..IsMultiTilette = json['IsMultiTilette'] as bool?
      ..ClusterTemplateTileModels =
          (json['ClusterTemplateTileModels'] as List<dynamic>?)
              ?.map((e) =>
                  ClusterTemplateTileModel.fromJson(e as Map<String, dynamic>))
              .toList();

Map<String, dynamic> _$TileShareClusterModelToJson(
        TileShareClusterModel instance) =>
    <String, dynamic>{
      'Name': instance.Name,
      'StartTime': instance.StartTime,
      'EndTime': instance.EndTime,
      'DurationInMs': instance.DurationInMs,
      'AddressData': instance.AddressData?.toJson(),
      'Contacts': instance.Contacts?.map((e) => e.toJson()).toList(),
      'SchedulePattern': instance.SchedulePattern,
      'Notes': instance.Notes,
      'IsMultiTilette': instance.IsMultiTilette,
      'ClusterTemplateTileModels':
          instance.ClusterTemplateTileModels?.map((e) => e.toJson()).toList(),
    };
