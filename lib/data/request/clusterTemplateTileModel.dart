import 'package:tiler_app/data/request/addressModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clusterTemplateTileModel.g.dart';

@JsonSerializable(explicitToJson: true)
class ClusterTemplateTileModel {
  ClusterTemplateTileModel();
  String? Id;
  String? Name;
  String? ClusterId;
  int? StartTime;
  int? EndTime;
  int? OrderedIndex;
  int? DurationInMs;
  AddressModel? AddressData;
  String? NoteMiscData;

  List<ContactModel>? Contacts;

  factory ClusterTemplateTileModel.fromJson(Map<String, dynamic> json) =>
      _$ClusterTemplateTileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClusterTemplateTileModelToJson(this);
}
