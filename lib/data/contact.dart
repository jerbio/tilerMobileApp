import 'package:tiler_app/data/request/contactModel.dart';

class Contact {
  String? id;
  String? phoneNumber;
  String? email;
  String? firstName;
  String? lastName;

  ContactModel toContactModel() {
    var contactModel = ContactModel();
    contactModel.Email = this.email;
    contactModel.PhoneNumber = this.phoneNumber;
    contactModel.FirstName = this.firstName;
    contactModel.LastName = this.lastName;
    return contactModel;
  }
}
