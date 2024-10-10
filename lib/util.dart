import 'dart:async';
import 'dart:collection';
import 'dart:math';
import '../../../constants.dart' as Constants;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/adHoc/autoData.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/blobEvent.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/editCalendarEvent.dart';
import 'package:tiler_app/data/editTileEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:tuple/tuple.dart';
import 'package:uuid/uuid.dart';
import 'package:faker/faker.dart';
import 'data/tilerEvent.dart';
import 'data/timeRangeMix.dart';
import 'data/timeline.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';

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
  static final DateTime _jsBeginningOfTime = DateTime(1970, 1, 1);
  static final Random randomizer = Random.secure();
  static final log = Logger();

  static DateTime currentTime({bool minuteLimitAccuracy = true}) {
    DateTime time = DateTime.now();
    if (minuteLimitAccuracy) {
      DateTime retValue =
          DateTime(time.year, time.month, time.day, time.hour, time.minute);
      time = retValue;
    }
    return time;
  }

  static final TimeOfDay defaultEndOfDay = TimeOfDay(hour: 22, minute: 00);

  static final Position _defaultPosition = new Position(
      headingAccuracy: 777,
      altitudeAccuracy: 0,
      longitude: 7777,
      latitude: 7777,
      timestamp: Utility.currentTime(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0);

  static int getTimeZoneOffset() {
    return (-currentTime().timeZoneOffset.inMinutes);
  }

  static T? cast<T>(x) => x is T ? x : null;
  static bool isEditTileEventEquivalentToTileEvent(
      EditTilerEvent editTilerEvent, TilerEvent tilerEvent) {
    bool retValue =
        editTilerEvent.startTime!.toLocal().millisecondsSinceEpoch ==
                tilerEvent.startTime.toLocal().millisecondsSinceEpoch &&
            editTilerEvent.endTime!.toLocal().millisecondsSinceEpoch ==
                tilerEvent.endTime.toLocal().millisecondsSinceEpoch &&
            editTilerEvent.name == tilerEvent.name &&
            editTilerEvent.splitCount == tilerEvent.split;
    if (editTilerEvent.note != null && tilerEvent.noteData != null) {
      retValue &= editTilerEvent.note == tilerEvent.noteData!.note;
    }

    retValue &= editTilerEvent.address == tilerEvent.address;
    retValue &=
        editTilerEvent.addressDescription == tilerEvent.addressDescription;
    return retValue;
  }

  static bool isEditTileEventEquivalentToSubCalendarEvent(
      EditTilerEvent editTilerEvent, SubCalendarEvent subCalendarEvent) {
    bool retValue =
        isEditTileEventEquivalentToTileEvent(editTilerEvent, subCalendarEvent);
    retValue &= editTilerEvent.calEndTime!.toLocal().millisecondsSinceEpoch ==
        subCalendarEvent.calendarEventEndTime!.toLocal().millisecondsSinceEpoch;
    retValue &= editTilerEvent.calStartTime!.toLocal().millisecondsSinceEpoch ==
        subCalendarEvent.calendarEventStartTime!
            .toLocal()
            .millisecondsSinceEpoch;
    return retValue;
  }

  static bool isEditTileEventEquivalentToCalendarEvent(
      EditCalendarEvent editCalendarEvent, CalendarEvent calendarEvent) {
    bool retValue = isEditTileEventEquivalentToTileEvent(
            editCalendarEvent, calendarEvent) &&
        calendarEvent.isAutoReviseDeadline ==
            editCalendarEvent.isAutoReviseDeadline;
    retValue &=
        calendarEvent.isAutoDeadline == editCalendarEvent.isAutoDeadline;
    if (calendarEvent.tileDuration != null &&
        editCalendarEvent.tileDuration != null) {
      retValue &= editCalendarEvent.tileDuration!.inMinutes ==
          calendarEvent.tileDuration!.inMinutes;
    }

    return retValue;
  }

  static int getDayIndex(DateTime time) {
    var spanInMicroSecond = time.dayDate.microsecondsSinceEpoch -
        Utility._beginningOfTime.dayDate.microsecondsSinceEpoch;
    int retValue =
        (spanInMicroSecond.toDouble() / Duration.microsecondsPerDay.toDouble())
            .round();
    return retValue;
  }

  static DateTime getTimeFromIndex(int dayIndex) {
    Duration totalDuration = Duration(days: dayIndex);
    DateTime retValueShifted =
        Utility._beginningOfTime.dayDate.add(totalDuration);
    DateTime retValue = DateTime(
        retValueShifted.year, retValueShifted.month, retValueShifted.day);
    return retValue;
  }

  static DateTime getTimeFromIndexForJS(int dayIndex) {
    Duration totalDuration = Duration(days: dayIndex);
    DateTime retValueShifted =
        Utility._jsBeginningOfTime.dayDate.add(totalDuration);
    DateTime retValue = DateTime(
        retValueShifted.year, retValueShifted.month, retValueShifted.day);
    return retValue;
  }

  static Timeline todayTimeline() {
    DateTime currentTime = Utility.currentTime();
    DateTime begin =
        new DateTime(currentTime.year, currentTime.month, currentTime.day);
    DateTime end = begin.add(Utility.oneDay);

    Timeline retValue =
        Timeline(begin.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
    return retValue;
  }

  static Duration durationDifference(DateTime a, DateTime b) {
    int durationInMs = utcEpochMillisecondsFromDateTime(a) -
        utcEpochMillisecondsFromDateTime(b);
    return Duration(milliseconds: durationInMs);
  }

  static Position getDefaultPosition() {
    return _defaultPosition;
  }

  static int get msCurrentTime {
    return currentTime().toUtc().millisecondsSinceEpoch;
  }

  static DateTime localDateTimeFromMs(int utcMillisecondsSinceEpoch) {
    return DateTime.fromMillisecondsSinceEpoch(utcMillisecondsSinceEpoch,
            isUtc: true)
        .toLocal();
  }

  static int utcEpochMillisecondsFromDateTime(DateTime dateTime) {
    return dateTime.toLocal().toUtc().millisecondsSinceEpoch;
  }

  static get initialScheduleTimeline {
    return Timeline.fromDateTimeAndDuration(
        Utility.currentTime().add(Duration(days: -3)), Duration(days: 7));
  }

  static final _emailRegex = RegExp(r"^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
  static final _phoneRegex = RegExp(r"^\+?[0-9]{7,15}$");
  static bool isEmail(String? emailString) {
    if (emailString != null) {
      return _emailRegex.hasMatch(emailString);
    }
    return false;
  }

  static bool isPhoneNumber(String? phoneNumber) {
    if (phoneNumber != null) {
      return _phoneRegex.hasMatch(phoneNumber);
    }
    return false;
  }

  static Tuple2<List<Timeline>, List<SubCalendarEvent>> generateAdhocSubEvents(
      Timeline timeLine,
      {bool forceInterFerringWithNowTile = true}) {
    int subEventCount = Random().nextInt(2);
    while (subEventCount < 1) {
      subEventCount = Random().nextInt(2);
    }

    List<Timeline> sleepTimeLines = [];
    List<SubCalendarEvent> refreshedSubEvents = [];
    if (forceInterFerringWithNowTile) {
      SubCalendarEvent adHocInterferringWithNowTile = new SubCalendarEvent(
          name: Utility.randomName,
          start: Utility.msCurrentTime.toInt() -
              Utility.oneMin.inMilliseconds.toInt(),
          end: Utility.msCurrentTime.toInt() +
              Utility.oneMin.inMilliseconds.toInt(),
          address: Utility.randomName,
          addressDescription: Utility.randomName);
      adHocInterferringWithNowTile.colorBlue = Random().nextInt(255);
      adHocInterferringWithNowTile.colorGreen = Random().nextInt(255);
      adHocInterferringWithNowTile.colorRed = Random().nextInt(255);
      adHocInterferringWithNowTile.id = Utility.getUuid;
      refreshedSubEvents.add(adHocInterferringWithNowTile);
    }

    int maxDuration = Duration.millisecondsPerHour * 3;
    for (int i = 0; i < subEventCount; i++) {
      int durationMs = Random().nextInt(maxDuration);
      while (durationMs < 1) {
        durationMs = Random().nextInt(maxDuration);
      }
      int startLimit =
          timeLine.start! - durationMs - Utility.oneMin.inMilliseconds;
      int endLimit = timeLine.end! + durationMs - Utility.oneMin.inMilliseconds;
      int durationLimit = endLimit - startLimit;
      int durationInSec = durationLimit ~/
          1000; // we need to use seconds because of the random.nextInt of requiring an integer
      int start = startLimit + ((Random().nextInt(durationInSec)) * 1000);
      int end = start + durationMs;
      int dayCount =
          (durationLimit / Utility.oneDay.inMilliseconds).toDouble().ceil();

      DateTime? startDayTime = timeLine.startTime;
      DateTime? endDayTime = timeLine.endTime;
      if (startDayTime != null && endDayTime != null) {
        startDayTime = new DateTime(
            startDayTime.year, startDayTime.month, startDayTime.day, 0, 0, 0);
        endDayTime = new DateTime(
            endDayTime.year, endDayTime.month, endDayTime.day, 0, 0, 0);

        Timeline timeLine = new Timeline(
            startDayTime.millisecondsSinceEpoch.toInt(),
            startDayTime
                .add(Duration(hours: 6))
                .millisecondsSinceEpoch
                .toInt());
        sleepTimeLines.add(timeLine);

        while (startDayTime!.millisecondsSinceEpoch <
            endDayTime.millisecondsSinceEpoch) {
          startDayTime = startDayTime.add(Utility.oneDay);
          timeLine = new Timeline(
              startDayTime.millisecondsSinceEpoch.toInt(),
              startDayTime
                  .add(Duration(hours: 6))
                  .millisecondsSinceEpoch
                  .toInt());
          sleepTimeLines.add(timeLine);
        }
      }
      SubCalendarEvent subEvent = new SubCalendarEvent(
          name: Utility.randomName,
          start: start.toInt(),
          end: end.toInt(),
          address: Utility.randomName,
          addressDescription: Utility.randomName);
      subEvent.colorBlue = Random().nextInt(255);
      subEvent.colorGreen = Random().nextInt(255);
      subEvent.colorRed = Random().nextInt(255);
      subEvent.id = Utility.getUuid;
      refreshedSubEvents.add(subEvent);
    }

    return new Tuple2<List<Timeline>, List<SubCalendarEvent>>(
        sleepTimeLines, refreshedSubEvents);
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

  static updateMapList(Map map, entry, key, initial) {
    var entries = initial;
    if (map.containsKey(key)) {
      entries = map[key];
    }
    map[key] = entries;
    entries.add(entry);
  }

  static void _initializeAutotile() {
    _adHocAutoTiles = {};
    _adHocAutoTilesByCategory = {};
    _adHocAutoTilesByDescription = {};
    _adHocAutoTilesByDuration = {};
    _lastCards = [];
    for (int i = 0; i < autoTileParams.length; i++) {
      var autoTileParam = autoTileParams[i];
      String categoryId = autoTileParam['id'];
      bool isLastCard = autoTileParam.containsKey('isLastCard')
          ? autoTileParam['isLastCard']
          : false;
      List<String> descriptions = autoTileParam['descriptions'];
      List<Duration> durations = autoTileParam['durations'];
      List<String> imageAsset = autoTileParam['assets'];

      for (int descriptionIndex = 0;
          descriptionIndex < descriptions.length;
          descriptionIndex++) {
        String description = descriptions[descriptionIndex];
        for (int imageAssetIndex = 0;
            imageAssetIndex < imageAsset.length;
            imageAssetIndex++) {
          String asset = imageAsset[imageAssetIndex];
          for (int durationIndex = 0;
              durationIndex < durations.length;
              durationIndex++) {
            Duration duration = durations[durationIndex];
            AutoTile autoTile = AutoTile(
                description: description,
                image: asset,
                duration: duration,
                categoryId: categoryId,
                isLastCard: isLastCard);

            _adHocAutoTiles![autoTile.id] = autoTile;

            if (!isLastCard) {
              updateMapList(_adHocAutoTilesByCategory!, autoTile, categoryId,
                  <AutoTile>[]);
              updateMapList(_adHocAutoTilesByDescription!, autoTile,
                  description, <AutoTile>[]);
              updateMapList(_adHocAutoTilesByDuration!, autoTile,
                  duration.inMilliseconds, <AutoTile>[]);
            } else {
              _lastCards!.add(autoTile);
            }
          }
        }
      }
    }
  }

  static Map<String, List<AutoTile>>? _adHocAutoTilesByCategory;
  static Map<String, List<AutoTile>>? _adHocAutoTilesByDescription;
  static Map<int, List<AutoTile>>? _adHocAutoTilesByDuration;
  static Map<String, AutoTile>? _adHocAutoTiles;
  static List<AutoTile>? _lastCards;

  static List<AutoTile> get autoTiles {
    if (_adHocAutoTiles == null) {
      _initializeAutotile();
    }
    return _adHocAutoTiles!.values.toList();
  }

  static List<AutoTile> get lastCards {
    if (_lastCards == null) {
      _initializeAutotile();
    }
    return _lastCards!.toList();
  }

  static Map<String, List<AutoTile>> get adHocAutoTilesByCategory {
    if (_adHocAutoTiles == null) {
      _initializeAutotile();
    }
    return _adHocAutoTilesByCategory!;
  }

  static Map<String, List<AutoTile>> get adHocAutoTilesByDescription {
    if (_adHocAutoTiles == null) {
      _initializeAutotile();
    }
    return _adHocAutoTilesByDescription!;
  }

  static Map<int, List<AutoTile>> get adHocAutoTilesByDuration {
    if (_adHocAutoTiles == null) {
      _initializeAutotile();
    }
    return _adHocAutoTilesByDuration!;
  }

  static List<TilerEvent> orderTiles(List<TilerEvent> tiles) {
    List<TilerEvent> retValue = tiles.toList();
    retValue.sort((tileA, tileB) {
      int retValue = tileA.start! - tileB.start!;
      if (retValue == 0) {
        retValue = tileA.end! - tileB.end!;
      }
      return retValue.toInt();
    });

    return retValue;
  }

  static TimeOfDay stringToTimeOfDay(String tod) {
    final format = DateFormat.jm(); //"6:00 AM"
    return TimeOfDay.fromDateTime(format.parse(tod));
  }

  static TimeOfDay timeOfDayFromTime(DateTime dateTime) {
    return TimeOfDay.fromDateTime(dateTime);
  }

  static DateTime dateTimeFromTimeOfDay(TimeOfDay timeOfDay) {
    return DateTime(2020, 1, 1, timeOfDay.hour, timeOfDay.minute);
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  static Future<Position> determineDevicePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  static Future<bool> checkOnboardingStatus() async {
    try {
      await Future.delayed(
          const Duration(milliseconds: Constants.onTextChangeDelayInMs));
      bool shouldSkipOnboarding =
          await OnBoardingSharedPreferencesHelper.getSkipOnboarding();
      bool isOnboardingvalid = await OnBoardingApi().areRequiredFieldsValid();
      return shouldSkipOnboarding || isOnboardingvalid;
    } catch (e) {
      print("Error checking onboarding status: $e");
      return true;
    }
  }

  static debugPrint(String val) {
    if (Constants.isDebug ||
        Constants.userId == "6bc6992f-3222-4fd8-9e2b-b94eba2fb717" ||
        Constants.userName == "jerbio") {
      print(val);
    }
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
          int? LatestEndTimeInMs;
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

  static List<Timeline> getListofDays(DateTime startDate) {
    List<Timeline> result = [];
    DateTime endDate = startDate.add(Duration(days: 7));
    do {
      final timeLine = new Timeline(startDate.millisecondsSinceEpoch.toInt(),
          startDate.add(Duration(hours: 6)).millisecondsSinceEpoch.toInt());
      result.add(timeLine);
      startDate = startDate.add(Utility.oneDay);
    } while (startDate.millisecondsSinceEpoch < endDate.millisecondsSinceEpoch);

    return result;
  }

  static int daysInAweek = 7;
  static Duration thirtySeconds = new Duration(seconds: 30);
  static Duration thirtyMin = new Duration(minutes: 30);
  static Duration fifteenMin = new Duration(minutes: 15);
  static Duration oneHour = new Duration(hours: 1);
  static Duration oneMin = new Duration(minutes: 1);
  static Duration oneDay = new Duration(days: 1);
  static Duration activeDayDuration = new Duration(hours: 16);
  static Duration sevenDays = new Duration(days: daysInAweek);
  static var uuid = Uuid();

  static Tuple2<Future, StreamSubscription?> setTimeOut(
      {required Duration duration, Function? callBack}) {
    var future = new Future.delayed(duration);

    // ignore: cancel_subscriptions
    StreamSubscription? streamSubScription;
    if (callBack != null) {
      // ignore: cancel_subscriptions
      streamSubScription = future.asStream().listen((event) async {
        if (callBack is Future) {
          await callBack();
        } else {
          callBack();
        }
      });
    }

    return new Tuple2(future, streamSubScription);
  }
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

  List getRandomize({int? seed}) {
    List retValue = [];
    List listCopy = this.toList();
    Random randomizer = Utility.randomizer;
    if (seed != null) {
      randomizer = Random(seed);
    }
    while (listCopy.length > 0) {
      int index = randomizer.nextInt(listCopy.length);
      retValue.add(listCopy[index]);
      listCopy.removeAt(index);
    }

    return retValue;
  }
}

extension StringEnhance on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

extension TilerDayOfWeek on DateTime {
  get tilerDayOfWeek {
    return this.weekday % Utility.daysInAweek;
  }
}

extension DurationInMS on TimeOfDay {
  get durationFromMidnight {
    int retValue = this.hour * Utility.oneHour.inMilliseconds +
        this.minute * Utility.oneMin.inMilliseconds;
    return retValue;
  }

  String get formatTimeOfDay {
    final now = Utility.currentTime();
    final dt = DateTime(now.year, now.month, now.day, this.hour, this.minute);
    final format = DateFormat.jm(); //"6:00 AM"
    return format.format(dt);
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

  String get dateDateWeek {
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
        dayString = DateFormat('d').format(this);
      } else {
        dayString = DateFormat('EEE, MMM d, ' 'yy').format(this);
      }
    }
    return dayString;
  }

  DateTime get dayDate {
    return DateTime(this.year, this.month, this.day);
  }

  int get universalDayIndex {
    return Utility.getDayIndex(this);
  }

  //Returns the date in the format 03/08/2023 22:42:00
  String get backEndFormat {
    String dayString =
        '${this.month}/${this.day}/${this.year} ${this.hour}:${this.minute}';
    return dayString;
  }

  DateTime get endOfDay {
    DateTime retValue = DateTime(this.year, this.month, this.day, 23, 59);
    return retValue;
  }

  DateTime get startOfDay {
    DateTime retValue = DateTime(this.year, this.month, this.day, 0, 0);
    return retValue;
  }

  DateTime get endOfTheWeek {
    int weekDay = this.weekday;
    int zeroThDayOfWeek = weekDay % 7;
    int daysTillSaturday = 6 - zeroThDayOfWeek;
    if (daysTillSaturday == 0) {
      daysTillSaturday += 7;
    }

    Duration durationTillSaturday = Duration(days: daysTillSaturday);
    DateTime retValue = DateTime(this.year, this.month, this.day, 23, 59);
    retValue.add(durationTillSaturday);
    return retValue;
  }
}

extension ColorExtension on Color {
  Color withLightness(double lightness) {
    HSLColor hslColor = HSLColor.fromColor(this);
    return hslColor.withLightness(lightness).toColor();
  }
}

extension StringExtension on String? {
  bool isNot_NullEmptyOrWhiteSpace({int minLength = 0}) {
    return this != null &&
        this!.isNotEmpty &&
        (minLength == 0 || this!.trim().length > minLength);
  }
}
