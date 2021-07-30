import 'dart:math';

import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class ScheduleApi {
  bool preserveSubEventList = true;
  List<SubCalendarEvent> adhocGeneratedSubEvents = <SubCalendarEvent>[];

  Future<List<SubCalendarEvent>> getSubEvents(Timeline timeLine) {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain + 'api/Schedule';

    return getAdHocSubEvents(timeLine);
  }

  Future<List<SubCalendarEvent>> getSubEventsInScheduleRequest(
      Timeline timeLine) {
    String tilerDomain = Constants.tilerDomain;
    DateTime dateTime = DateTime.now();
    String url = tilerDomain + 'api/Schedule';
    // var PostData = {
    //   UserName: UserCredentials.UserName,
    //   UserID: UserCredentials.ID,
    //   StartRange: RangeData.Start.getTime(),
    //   EndRange: RangeData.End.getTime(),
    //   TimeZoneOffset: TimeZone
    // };
    final queryParameters = {
      'UserName': 'one',
      'UserID': 'two',
      'StartRange': timeLine.start,
      'EndRange': timeLine.end,
      'TimeZoneOffset': dateTime.timeZoneOffset,
      'MobileApp': true
    };
  }

  Future<List<SubCalendarEvent>> getAdHocSubEvents(Timeline timeLine) {
    if (!this.preserveSubEventList) {
      adhocGeneratedSubEvents = <SubCalendarEvent>[];
    }
    int subEventCount = Random().nextInt(20);
    while (subEventCount < 1) {
      subEventCount = Random().nextInt(20);
    }

    List<SubCalendarEvent> refreshedSubEvents = [];
    int maxDuration = Duration.millisecondsPerHour * 3;
    for (int i = 0; i < subEventCount; i++) {
      int durationMs = Random().nextInt(maxDuration);
      while (durationMs < 1) {
        durationMs = Random().nextInt(maxDuration);
      }
      Duration timeSpan = Duration(milliseconds: durationMs);
      int startLimit =
          timeLine.start!.toInt() - durationMs - Utility.oneMin.inMilliseconds;
      int endLimit =
          timeLine.end!.toInt() + durationMs - Utility.oneMin.inMilliseconds;
      int durationLimit = endLimit - startLimit;
      int durationInSec = durationLimit ~/
          1000; // we need to use seconds because of the random.nextInt of requiring an integer
      int start = startLimit + ((Random().nextInt(durationInSec)) * 1000);
      int end = start + durationMs;

      SubCalendarEvent subEvent = new SubCalendarEvent(
          name: Utility.randomName,
          start: start.toDouble(),
          end: end.toDouble(),
          address: Utility.randomName,
          addressDescription: Utility.randomName);
      subEvent.colorBlue = Random().nextInt(255);
      subEvent.colorGreen = Random().nextInt(255);
      subEvent.colorRed = Random().nextInt(255);
      subEvent.id = Utility.getUuid;
      refreshedSubEvents.add(subEvent);
    }
    this.adhocGeneratedSubEvents.addAll(refreshedSubEvents);
    List<SubCalendarEvent> retValue = this.adhocGeneratedSubEvents.toList();
    Future<List<SubCalendarEvent>> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
    return retFuture;
  }
}
