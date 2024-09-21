import 'package:json_annotation/json_annotation.dart';

part 'contactModel.g.dart';

@JsonSerializable(explicitToJson: true)
class ContactModel {
  ContactModel();
  String? FirstName;
  String? LastName;
  String? PhoneNumber;
  String? Email;

  factory ContactModel.fromJson(Map<String, dynamic> json) =>
      _$ContactModelFromJson(json);

  Map<String, dynamic> toJson() => _$ContactModelToJson(this);
}
