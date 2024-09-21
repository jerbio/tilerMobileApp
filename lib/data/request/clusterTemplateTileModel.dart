import 'package:tiler_app/data/request/addressModel.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:json_annotation/json_annotation.dart';

part 'clusterTemplateTileModel.g.dart';

@JsonSerializable(explicitToJson: true)
class ClusterTemplateTileModel {
  ClusterTemplateTileModel();
  String? Name;
  int? StartTime;
  int? EndTime;
  int? OrderedIndex;
  AddressModel? AddressData;
  List<ContactModel>? Contacts;

  factory ClusterTemplateTileModel.fromJson(Map<String, dynamic> json) =>
      _$ClusterTemplateTileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClusterTemplateTileModelToJson(this);
}
