class SubCalendarEvent {
  String name;
  String address;
  String addressDescription;
  String thirdpartyType;
  double travelTimeBefore;
  double travelTimeAfter;
  double start;
  double end;
  double rangeStart;
  double rangeEnd;
  bool isRecurring;

  SubCalendarEvent.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        address = json['address'];
}
