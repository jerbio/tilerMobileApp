import 'package:tiler_app/data/contact.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/util.dart';

class DesignatedUser {
  String? id;
  String? displayedName;
  String? designatedTileTemplateId;
  InvitationStatus? rsvpStatus;
  UserProfile? userProfile;

  DesignatedUser.fromJson(Map<String, dynamic> json) {
    id = '';
    if (json.containsKey('id')) {
      id = json['id'];
    }

    if (json.containsKey('designatedTileTemplateId')) {
      designatedTileTemplateId = json['designatedTileTemplateId'];
    }

    if (json.containsKey('displayedIdentifier')) {
      displayedName = json['displayedIdentifier'];
    }

    if (json.containsKey('userProfile') && json['userProfile'] != null) {
      userProfile = UserProfile.fromJson(json['userProfile']);
    }

    if (json.containsKey('rsvpStatus') && json['rsvpStatus'] != null) {
      rsvpStatus = DesignatedTile.stringToInvitationStatus(json['rsvpStatus']);
    }
  }

  Contact? toContact() {
    if (userProfile != null || displayedName.isNot_NullEmptyOrWhiteSpace()) {
      if (userProfile != null) {
        Contact retValue = Contact();
        retValue.email = userProfile!.email;
        retValue.username = userProfile!.username;
        retValue.phoneNumber = userProfile!.phoneNumber;
        return retValue;
      }
      if (displayedName.isNot_NullEmptyOrWhiteSpace()) {
        Contact retValue = Contact();
        retValue.email = Utility.isEmail(displayedName) ? displayedName : null;
        retValue.username = !(Utility.isEmail(displayedName) ||
                Utility.isPhoneNumber(displayedName))
            ? displayedName
            : null;
        retValue.phoneNumber =
            Utility.isPhoneNumber(displayedName) ? displayedName : null;
        return retValue;
      }
    }

    return null;
  }
}
