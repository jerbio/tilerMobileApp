class EditTilerEvent {
  String? name;
  int? splitCount;
  DateTime? startTime;
  DateTime? endTime;

  bool get isValid {
    bool retValue = true;
    retValue &= (name!=null && name!.isNotEmpty);
    retValue &= (splitCount!=null && splitCount! > 0);
    retValue &= endTime!=null;

    return retValue;
  }
}