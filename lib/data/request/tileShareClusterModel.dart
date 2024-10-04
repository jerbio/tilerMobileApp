import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/data/request/addressModel.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';

part 'tileShareClusterModel.g.dart';

@JsonSerializable(explicitToJson: true)
class TileShareClusterModel {
  TileShareClusterModel();
  String? Name;
  int? StartTime;
  int? EndTime;
  int? DurationInMs;
  AddressModel? AddressData;
  List<ContactModel>? Contacts;
  String? SchedulePattern;
  String? Notes;
  List<ClusterTemplateTileModel>? ClusterTemplateTileModels;

  factory TileShareClusterModel.fromJson(Map<String, dynamic> json) =>
      _$TileShareClusterModelFromJson(json);

  Map<String, dynamic> toJson() => _$TileShareClusterModelToJson(this);
}
