import 'package:tiler_app/data/request/contactModel.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/util.dart';

class Contact {
  String? id;
  String? phoneNumber;
  String? email;
  String? firstName;
  String? lastName;
  String? username;
  Contact();

  Contact.fromUserProfile(UserProfile userProfile) {
    this.email = userProfile.email;
    this.phoneNumber = userProfile.phoneNumber;
    this.id = userProfile.id;
    this.email = userProfile.email;
    this.username = userProfile.username;
    if (userProfile.fullName != null &&
        userProfile.fullName.isNot_NullEmptyOrWhiteSpace()) {
      List<String> names = userProfile.fullName!
          .split(" ")
          .map((e) => e.trim())
          .where((element) => element.isNot_NullEmptyOrWhiteSpace())
          .toList();
      firstName = names.firstOrNull;
      if (names.length > 1) {
        lastName = names.last;
      }
    }
  }

  String? get displayedIdentifier {
    return this.firstName.isNot_NullEmptyOrWhiteSpace()
        ? this.firstName
        : this.lastName.isNot_NullEmptyOrWhiteSpace()
            ? this.lastName
            : this.email.isNot_NullEmptyOrWhiteSpace()
                ? this.email
                : this.phoneNumber.isNot_NullEmptyOrWhiteSpace()
                    ? this.phoneNumber
                    : this.username.isNot_NullEmptyOrWhiteSpace()
                        ? this.username
                        : null;
  }

  @override
  String toString() {
    return "{id:$id, phoneNumber:$phoneNumber, email:$email, firstName:$firstName, lastName:$lastName}";
  }

  ContactModel toContactModel() {
    var contactModel = ContactModel();
    contactModel.Email = this.email;
    contactModel.PhoneNumber = this.phoneNumber;
    contactModel.FirstName = this.firstName;
    contactModel.LastName = this.lastName;
    return contactModel;
  }
}
