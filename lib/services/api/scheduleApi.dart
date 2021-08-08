import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class ScheduleApi extends AppApi {
  bool preserveSubEventList = true;
  List<SubCalendarEvent> adhocGeneratedSubEvents = <SubCalendarEvent>[];

  Future<List<SubCalendarEvent>> getSubEvents(Timeline timeLine) async {
    // return getAdHocSubEvents(timeLine);
    return await getSubEventsInScheduleRequest(timeLine);
  }

  Future<List<SubCalendarEvent>> getSubEventsInScheduleRequest(
      Timeline timeLine) async {
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      DateTime dateTime = DateTime.now();
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final queryParameters = {
          'UserName': username,
          'StartRange': timeLine.start!.toInt().toString(),
          'EndRange': timeLine.end!.toInt().toString(),
          'TimeZoneOffset': dateTime.timeZoneOffset.inHours.toString(),
          'MobileApp': true.toString()
        };
        Uri uri =
            Uri.https(url, 'api/Schedule/getScheduleAlexa', queryParameters);

        var header = this.getHeaders();

        if (header != null) {
          var response = await http.get(uri, headers: header);
          var jsonResult = jsonDecode(response.body);
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult) &&
                jsonResult['Content'].containsKey('subCalendarEvents')) {
              List subEvents = jsonResult['Content']['subCalendarEvents'];
              List<SubCalendarEvent> retValue = subEvents
                  .map((eachSubEventJson) =>
                      SubCalendarEvent.fromJson(eachSubEventJson))
                  .toList();
              return retValue;
            }
          }
        }
      }
    }
    return [];
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
