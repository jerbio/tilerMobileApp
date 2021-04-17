import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/util.dart';

class SubCalendarEvent extends TilerEvent {
  double travelTimeBefore;
  double travelTimeAfter;
  double rangeStart;
  double rangeEnd;

  bool isLocationInfoAvailable() {
    bool retValue = (this.address != null && this.address.isNotEmpty) ||
        (this.addressDescription != null &&
            this.addressDescription.isNotEmpty) ||
        (this.searchdDescription != null && this.searchdDescription.isNotEmpty);
    return retValue;
  }

  get isCurrent {
    int currentTimeInMs = Utility.msCurrentTime;
    return this.start <= currentTimeInMs && this.end > currentTimeInMs;
  }

  get isBeforeNow {
    return Utility.msCurrentTime < this.start;
  }

  get hasElapsed {
    return Utility.msCurrentTime >= this.end;
  }

  static T cast<T>(x) => x is T ? x : null;

  SubCalendarEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    name = json['name'];
    address = json['address'];
    addressDescription = json['addressDescription'];
    thirdpartyType = json['thirdpartyType'];
    searchdDescription = json['searchdDescription'];
    travelTimeBefore = cast<int>(json['travelTimeBefore']).toDouble();
    travelTimeAfter = cast<int>(json['travelTimeAfter']).toDouble();
    start = cast<int>(json['start']).toDouble();
    end = cast<int>(json['end']).toDouble();
    rangeStart = cast<int>(json['rangeStart']).toDouble();
    rangeEnd = cast<int>(json['rangeEnd']).toDouble();
    colorOpacity = cast<double>(json['colorOpacity']);
    colorRed = cast<int>(json['colorRed']);
    colorGreen = cast<int>(json['colorGreen']);
    colorBlue = cast<int>(json['colorBlue']);
    isRecurring = json['isRecurring'];
  }
}
