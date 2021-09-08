import 'dart:collection';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:tiler_app/data/blobEvent.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:faker/faker.dart';
import 'data/tilerEvent.dart';
import 'data/timeRangeMix.dart';
import 'data/timeline.dart';

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
  static final Faker _faker = Faker();
  static final DateTime _beginningOfTime = DateTime(0, 1, 1);
  static final Random randomizer = Random.secure();
  static DateTime currentTime() {
    return DateTime.now();
  }

  static int getDayIndex(DateTime time) {
    var spanInMicroSecond = time.microsecondsSinceEpoch -
        Utility._beginningOfTime.microsecondsSinceEpoch;
    int retValue = spanInMicroSecond ~/ Duration.microsecondsPerDay;
    return retValue;
  }

  static DateTime getTimeFromIndex(int dayIndex) {
    Duration totalDuration = Duration(days: dayIndex);
    DateTime retValueShifted = Utility._beginningOfTime.add(totalDuration);
    DateTime retValue = DateTime(
        retValueShifted.year, retValueShifted.month, retValueShifted.day);
    return retValue;
  }

  static Timeline todayTimeline() {
    DateTime currentTime = DateTime.now();
    DateTime begin =
        new DateTime(currentTime.year, currentTime.month, currentTime.day);
    DateTime end = begin.add(Utility.oneDay);

    Timeline retValue = Timeline(begin.millisecondsSinceEpoch.toDouble(),
        end.millisecondsSinceEpoch.toDouble());
    return retValue;
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

  static get randomName {
    return _faker.person.name();
  }

  static Tuple2<List<BlobEvent>, HashSet<TilerEvent>> getConflictingEvents(
      Iterable<TilerEvent> AllSubEvents) {
    HashSet<TilerEvent> dedupedSubEvents = HashSet.from(AllSubEvents);
    HashSet<TilerEvent> nonConflict = HashSet.from(dedupedSubEvents);
    List<BlobEvent> conflictingBlob = [];

    List<TilerEvent> orderedByStart = dedupedSubEvents.toList();
    orderedByStart.sort((eachTileBatchA, eachTileBatchB) =>
        eachTileBatchA.start!.compareTo(eachTileBatchB.start!));
    List<TilerEvent> AllSubEvents_List = orderedByStart.toList();

    Map<TimeRange, List<TimeRange>> subEventToConflicting =
        new Map<TimeRange, List<TimeRange>>();

    for (int i = 0; i < AllSubEvents_List.length && i >= 0; i++) {
      TilerEvent refSubCalendarEvent = AllSubEvents_List[i];
      List<TilerEvent> possibleInterferring =
          AllSubEvents_List.where((obj) => obj != refSubCalendarEvent).toList();
      List<TilerEvent> interferringEvents = possibleInterferring
          .where((obj) => obj.isInterfering(refSubCalendarEvent))
          .toList();
      if (interferringEvents.length > 0) //this tries to select the rest of
      {
        bool conflictFound = false;
        do {
          conflictFound = false;
          AllSubEvents_List = AllSubEvents_List.where(
              (element) => !interferringEvents.contains(element)).toList();
          double? LatestEndTimeInMs;
          interferringEvents.forEach((timeRange) {
            if (LatestEndTimeInMs == null) {
              LatestEndTimeInMs = timeRange.end;
            } else {
              if (timeRange.start! > LatestEndTimeInMs!) {
                LatestEndTimeInMs = timeRange.end;
              }
            }
          });

          Timeline possibleInterferringTimeLine =
              new Timeline(refSubCalendarEvent.start, LatestEndTimeInMs);
          AllSubEvents_List.forEach((subEvent) {
            if (subEvent.isInterfering(possibleInterferringTimeLine)) {
              nonConflict.remove(subEvent);
              interferringEvents.add(subEvent);
              conflictFound = true;
            }
          });
        } while (conflictFound);
        --i;
      }
      if (interferringEvents.length > 0) {
        conflictingBlob.add(BlobEvent.fromTilerEvents(interferringEvents));
      }
    }

    Tuple2<List<BlobEvent>, HashSet<TilerEvent>> retValue =
        new Tuple2<List<BlobEvent>, HashSet<TilerEvent>>(
            conflictingBlob, nonConflict);
    return retValue;
    //Continue from here Jerome you need to write the function for detecting conflicting events and then creating the interferring list.
  }

  static Duration thirtyMin = new Duration(minutes: 30);
  static Duration fifteenMin = new Duration(minutes: 15);
  static Duration oneHour = new Duration(hours: 1);
  static Duration oneMin = new Duration(minutes: 1);
  static Duration oneDay = new Duration(days: 1);
  static Duration sevenDays = new Duration(days: 7);
  static var uuid = Uuid();
}

extension DurationHuman on Duration {
  String get toHuman {
    return Utility.toHuman(this, includeSeconds: false);
  }
}

extension ListEnhance on List {
  get randomEntry {
    if (this.length > 0) {
      int index = Utility.randomizer.nextInt(this.length - 1);
      return this[index];
    }
    throw new Exception('Cannot get a random entry from an empty list');
  }
}

extension DateTimeHuman on DateTime {
  bool get isToday {
    DateTime todaysDate = DateTime.now();
    DateTime begin =
        DateTime(todaysDate.year, todaysDate.month, todaysDate.day);
    Duration fullDay = Duration(days: 1);
    DateTime end = begin.add(fullDay);
    return this.microsecondsSinceEpoch >= begin.microsecondsSinceEpoch &&
        this.microsecondsSinceEpoch < end.microsecondsSinceEpoch;
  }

  bool get isTomorrow {
    DateTime todaysDate = DateTime.now();
    DateTime begin =
        DateTime(todaysDate.year, todaysDate.month, todaysDate.day);
    Duration fullDay = Duration(days: 1);
    begin = begin.add(fullDay);
    DateTime end = begin.add(fullDay);
    return this.microsecondsSinceEpoch >= begin.microsecondsSinceEpoch &&
        this.microsecondsSinceEpoch < end.microsecondsSinceEpoch;
  }

  bool get isYesterday {
    DateTime todaysDate = DateTime.now();
    DateTime begin =
        DateTime(todaysDate.year, todaysDate.month, todaysDate.day);
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
