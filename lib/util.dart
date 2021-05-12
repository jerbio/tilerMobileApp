import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Utility {
  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  static DateTime currentTime() {
    return DateTime.now();
  }

  static get msCurrentTime {
    return currentTime().millisecondsSinceEpoch;
  }

  static String toHuman(Duration duration,
      {bool all = false, bool includeSeconds = false, abbreviations = false}) {
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
      if (abbreviations) {
        hourString = 'hrs';
      }
      if (hours == 1) {
        hourString = 'hour';
        if (abbreviations) {
          hourString = 'hr';
        }
      }
      stringArr.add('$hours $hourString');
    }

    int minute = durationLeft.inMinutes;
    if (minute > 0) {
      Duration minDuration = Duration(minutes: minute);
      durationLeft = durationLeft - minDuration;

      String minuteString = 'minutes';
      if (abbreviations) {
        minuteString = 'mins';
      }
      if (minute == 1) {
        minuteString = 'minute';
        if (abbreviations) {
          minuteString = 'min';
        }
      }
      stringArr.add('$minute $minuteString');
    }

    if (includeSeconds) {
      int seconds = durationLeft.inSeconds;
      if (seconds > 0) {
        Duration secondDuration = Duration(minutes: seconds);
        durationLeft = durationLeft - secondDuration;

        String secondString = 'seconds';
        if (abbreviations) {
          secondString = 's';
        }
        if (seconds == 1) {
          secondString = 'second';
          if (abbreviations) {
            secondString = 's';
          }
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

extension DurationHuman on Duration {
  String get toHuman {
    return Utility.toHuman(this, includeSeconds: false);
  }
}

extension DateTimeHuman on DateTime {
  bool get isToday {
    DateTime begin = DateTime(this.year, this.month, this.day);
    Duration fullDay = Duration(days: 1);
    DateTime end = begin.add(fullDay);
    return this.microsecondsSinceEpoch >= begin.microsecondsSinceEpoch &&
        this.microsecondsSinceEpoch < end.microsecondsSinceEpoch;
  }

  bool get isTomorrow {
    DateTime begin = DateTime(this.year, this.month, this.day);
    Duration fullDay = Duration(days: 1);
    begin = begin.add(fullDay);
    DateTime end = begin.add(fullDay);
    return this.microsecondsSinceEpoch >= begin.microsecondsSinceEpoch &&
        this.microsecondsSinceEpoch < end.microsecondsSinceEpoch;
  }

  bool get isYesterday {
    DateTime begin = DateTime(this.year, this.month, this.day);
    Duration fullDay = Duration(days: -1);
    begin = begin.add(fullDay);
    DateTime end = begin.add(fullDay);
    return this.microsecondsSinceEpoch >= begin.microsecondsSinceEpoch &&
        this.microsecondsSinceEpoch < end.microsecondsSinceEpoch;
  }

  String get humanDate {
    String dayString = '';
    if (this.isToday) {
      dayString = 'Today';
    } else if (this.isYesterday) {
      dayString = 'Yesterday';
    } else if (this.isTomorrow) {
      dayString = 'Tomorrow';
    } else {
      DateTime now = DateTime.now();
      bool isSameYear = now.year == this.year;
      if (isSameYear) {
        dayString = DateFormat('EEE, MMM d').format(this);
      } else {
        dayString = DateFormat('EEE, MMM d, ' 'yy').format(this);
      }
    }

    return dayString;
  }
}
