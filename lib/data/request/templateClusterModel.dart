import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/data/request/addressModel.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';

part 'templateClusterModel.g.dart';

@JsonSerializable(explicitToJson: true)
class TemplateClusterModel {
  TemplateClusterModel();
  String? Name;
  int? StartTime;
  int? EndTime;
  int? DurationInMs;
  AddressModel? AddressData;
  List<ContactModel>? Contacts;
  String? SchedulePattern;
  String? Notes;
  List<ClusterTemplateTileModel>? ClusterTemplateTileModels;

  factory TemplateClusterModel.fromJson(Map<String, dynamic> json) =>
      _$TemplateClusterModelFromJson(json);

  Map<String, dynamic> toJson() => _$TemplateClusterModelToJson(this);
}
