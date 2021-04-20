import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Utility {
  static DateTime currentTime() {
    return DateTime.now();
  }

  static get msCurrentTime {
    return currentTime().millisecondsSinceEpoch;
  }

  static String toHuman(Duration duration,
      {bool all = false, bool includeSeconds = false}) {
    Duration durationLeft = duration;
    var stringArr = [];
    int days = durationLeft.inDays;
    if (days > 0) {
      Duration dayDuration = Duration(days: days);
      durationLeft = durationLeft - dayDuration;
      String dayString = 'days';
      if (days == 1) {
        dayString = 'day';
      }
      stringArr.add('$days $dayString');
    }

    int hours = durationLeft.inHours;
    if (hours > 0) {
      Duration hourDuration = Duration(hours: hours);
      durationLeft = durationLeft - hourDuration;

      String hourString = 'hours';
      if (hours == 1) {
        hourString = 'hour';
      }
      stringArr.add('$hours $hourString');
    }

    int minute = durationLeft.inMinutes;
    if (minute > 0) {
      Duration minDuration = Duration(minutes: minute);
      durationLeft = durationLeft - minDuration;

      String minuteString = 'minutes';
      if (minute == 1) {
        minuteString = 'minute';
      }
      stringArr.add('$minute $minuteString');
    }

    if (includeSeconds) {
      int seconds = durationLeft.inSeconds;
      if (seconds > 0) {
        Duration secondDuration = Duration(minutes: seconds);
        durationLeft = durationLeft - secondDuration;

        String secondString = 'seconds';
        if (seconds == 1) {
          secondString = 'second';
        }
        stringArr.add('$seconds $secondString');
      }
    }

    String retValue = '';
    if (stringArr.length > 1) {
      if (all) {
        var subAllStrings = stringArr.sublist(0, stringArr.length - 1);
        retValue = subAllStrings.join(', ');
        retValue += " and ";
      } else {
        stringArr = [stringArr[0]];
      }
    } else if (stringArr.length == 0) {
      stringArr = ["0 Minutes"];
    }
    String lastString = stringArr.last;
    retValue += "$lastString";
    return retValue;
  }

  static void noop() {
    return;
  }

  static get getUuid {
    return uuid.v4();
  }

  static String returnMonth(DateTime date) {
    return new DateFormat.MMMM().format(date);
  }

  static Duration thirtyMin = new Duration(minutes: 30);
  static Duration fifteenMin = new Duration(minutes: 15);
  static Duration oneHour = new Duration(hours: 1);
  static Duration oneMin = new Duration(minutes: 1);
  static var uuid = Uuid();
}
