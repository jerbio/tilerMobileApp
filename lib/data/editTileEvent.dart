import 'package:tiler_app/data/repetition.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/uiConfig.dart';

class EditTilerEvent {
  String? id;
  String? name;
  int? splitCount;
  DateTime? startTime;
  DateTime? endTime;
  DateTime? calStartTime;
  DateTime? calEndTime;
  String? thirdPartyType;
  String? thirdPartyId;
  String? thirdPartyUserId;
  String? note;
  String? addressDescription;
  String? address;
  bool? isAddressVerified;
  Repetition? repetition;
  UIConfig? uiConfig;
  RestrictionProfile? restrictionProfile;

  bool get isValid {
    bool retValue = true;
    retValue &= (name != null && name!.isNotEmpty);
    retValue &= (id != null && id!.isNotEmpty);
    retValue &= (splitCount != null && splitCount! > 0);
    retValue &= startTime != null;
    retValue &= endTime != null;
    retValue &= calStartTime != null;
    retValue &= calEndTime != null;
    retValue &= note != null;
    if (startTime != null && endTime != null) {
      retValue &=
          startTime!.millisecondsSinceEpoch < endTime!.millisecondsSinceEpoch;
    }

    return retValue;
  }
}
