import 'dart:math';

import 'package:tiler_app/components/tileUI/timeScrub.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class ScheduleApi {
  Future<List<SubCalendarEvent>> getSubEvents(Timeline? timeLine) {
    if(timeLine == null) {
      timeLine = Utility.todayTimeline();
    }
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain + 'api/Schedule';

    return getAdHocSubEvents(timeLine);
  }

  Future<List<SubCalendarEvent>> getAdHocSubEvents(Timeline timeLine) {
    int subEventCount = Random().nextInt(20);
    while(subEventCount < 1) {
      subEventCount  = Random().nextInt(20);
    }

    List<SubCalendarEvent> retValue = [];
 

    for(int i = 0 ; i < subEventCount; i++) {
      int durationMs = Random().nextInt(Duration.millisecondsPerDay);
      while(durationMs < 1) {
        durationMs  = Random().nextInt(Duration.millisecondsPerDay);
      }
      Duration timeSpan = Duration(milliseconds: durationMs);
      int startLimit = timeLine.start! - durationMs - Utility.oneMin.inMilliseconds;
      int endLimit = timeLine.end! + durationMs - Utility.oneMin.inMilliseconds;
      int durationLimit = endLimit - startLimit;
      int start = startLimit + Random().nextInt(durationLimit);
      int end = durationMs;


      SubCalendarEvent subEvent = new SubCalendarEvent(name: Utility.randomName, start: start.toDouble(), end: end.toDouble(), address: Utility.randomName, addressDescription: Utility.randomName);
      retValue.add(subEvent);
    }
    
    Future<List<SubCalendarEvent>> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
      return retFuture;
    
  }
}