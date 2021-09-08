import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/util.dart';

class SubCalendarEvent extends TilerEvent {
  double? travelTimeBefore;
  double? travelTimeAfter;
  double? rangeStart;
  double? rangeEnd;

  bool isLocationInfoAvailable() {
    bool retValue = (this.address != null && this.address!.isNotEmpty) ||
        (this.addressDescription != null &&
            this.addressDescription!.isNotEmpty) ||
        (this.searchdDescription != null &&
            this.searchdDescription!.isNotEmpty);
    return retValue;
  }

  SubCalendarEvent(
      {double? start,
      double? end,
      String? name,
      String? address,
      String? addressDescription,
      String? id,
      String? userId})
      : super(
          start: start,
          end: end,
          name: name,
          address: address,
          addressDescription: addressDescription,
          id: id,
          userId: userId,
        );

  get isCurrent {
    int currentTimeInMs = Utility.msCurrentTime;
    if (this.start != null && this.end != null) {
      return this.start! <= currentTimeInMs && this.end! > currentTimeInMs;
    }

    return false;
  }

  get isBeforeNow {
    return Utility.msCurrentTime < this.start;
  }

  get hasElapsed {
    return Utility.msCurrentTime >= this.end;
  }

  static T? cast<T>(x) => x is T ? x : null;

  SubCalendarEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    travelTimeBefore = double.parse(json['travelTimeBefore'].toString());
    travelTimeAfter = double.parse(json['travelTimeAfter'].toString());
    rangeStart = cast<int>(json['rangeStart'])!.toDouble();
    rangeEnd = cast<int>(json['rangeEnd'])!.toDouble();
  }
}
