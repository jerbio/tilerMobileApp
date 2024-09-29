import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/data/contact.dart';

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

  Contact toContact() {
    var contact = Contact();
    contact.email = this.Email;
    contact.phoneNumber = this.PhoneNumber;
    contact.firstName = this.FirstName;
    contact.lastName = this.LastName;
    return contact;
  }
}
