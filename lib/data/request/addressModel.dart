import 'package:json_annotation/json_annotation.dart';

part 'addressModel.g.dart';

@JsonSerializable(explicitToJson: true)
class AddressModel {
  AddressModel();
  String? Description;
  String? Address;
  bool? AddressIsVerified;

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}
