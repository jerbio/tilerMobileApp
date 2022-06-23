import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/NewTile.dart';
import 'dart:convert';

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import '../../constants.dart' as Constants;

class ScheduleApi extends AppApi {
  bool preserveSubEventList = true;
  List<SubCalendarEvent> adhocGeneratedSubEvents = <SubCalendarEvent>[];

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubEvents(
      Timeline timeLine) async {
    // return getAdHocSubEvents(timeLine);
    return await getSubEventsInScheduleRequest(timeLine);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>>
      getSubEventsInScheduleRequest(Timeline timeLine) async {
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      DateTime dateTime = DateTime.now();
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final queryParameters = {
          'UserName': username,
          'StartRange': timeLine.startInMs!.toInt().toString(),
          'EndRange': timeLine.endInMs!.toInt().toString(),
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
              List subEventJson = jsonResult['Content']['subCalendarEvents'];
              List sleepTimelinesJson = [];
              print("Got more data " + subEventJson.length.toString());
              // List sleepTimelinesJson = jsonResult['Content']['sleepTimeline'];

              List<Timeline> sleepTimelines = sleepTimelinesJson
                  .map((timelinesJson) => Timeline.fromJson(timelinesJson))
                  .toList();

              List<SubCalendarEvent> subEvents = subEventJson
                  .map((eachSubEventJson) =>
                      SubCalendarEvent.fromJson(eachSubEventJson))
                  .toList();
              Tuple2<List<Timeline>, List<SubCalendarEvent>> retValue =
                  new Tuple2(sleepTimelines, subEvents);
              return retValue;
            }
          }
        }
      }
    }
    var retValue = new Tuple2<List<Timeline>, List<SubCalendarEvent>>([], []);
    return retValue;
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getAdHocSubEvents(
      Timeline timeLine) {
    if (!this.preserveSubEventList) {
      adhocGeneratedSubEvents = <SubCalendarEvent>[];
    }
    int subEventCount = Random().nextInt(20);
    while (subEventCount < 1) {
      subEventCount = Random().nextInt(20);
    }

    List<Timeline> sleepTimeLines = [];
    List<SubCalendarEvent> refreshedSubEvents = [];
    int maxDuration = Duration.millisecondsPerHour * 3;
    for (int i = 0; i < subEventCount; i++) {
      int durationMs = Random().nextInt(maxDuration);
      while (durationMs < 1) {
        durationMs = Random().nextInt(maxDuration);
      }
      int startLimit = timeLine.startInMs!.toInt() -
          durationMs -
          Utility.oneMin.inMilliseconds;
      int endLimit = timeLine.endInMs!.toInt() +
          durationMs -
          Utility.oneMin.inMilliseconds;
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
            startDayTime.millisecondsSinceEpoch.toDouble(),
            startDayTime
                .add(Duration(hours: 6))
                .millisecondsSinceEpoch
                .toDouble());
        sleepTimeLines.add(timeLine);

        while (startDayTime!.millisecondsSinceEpoch <
            endDayTime.millisecondsSinceEpoch) {
          startDayTime = startDayTime.add(Utility.oneDay);
          timeLine = new Timeline(
              startDayTime.millisecondsSinceEpoch.toDouble(),
              startDayTime
                  .add(Duration(hours: 6))
                  .millisecondsSinceEpoch
                  .toDouble());
          sleepTimeLines.add(timeLine);
        }
      }
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
    List<SubCalendarEvent> subEvents = this.adhocGeneratedSubEvents.toList();
    Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> retFuture =
        new Future.delayed(
            const Duration(seconds: 0),
            () => new Tuple2<List<Timeline>, List<SubCalendarEvent>>(
                sleepTimeLines, subEvents));
    return retFuture;
  }

  Future<Tuple2<SubCalendarEvent?, TilerError?>> addNewTile(
      NewTile tile) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated = await this.authentication.isUserAuthenticated();
    if (userIsAuthenticated) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      DateTime dateTime = DateTime.now();
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final newTileParameters = tile.toJson();
        newTileParameters['UserName'] = username;
        newTileParameters['TimeZoneOffset'] =
            dateTime.timeZoneOffset.inHours.toString();
        newTileParameters['MobileApp'] = true.toString();

        Uri uri = Uri.https(url, 'api/Schedule/Event');
        var header = this.getHeaders();

        if (header != null) {
          var response = await http.post(uri,
              headers: header, body: jsonEncode(newTileParameters));
          var jsonResult = jsonDecode(response.body);
          error.Message = "Issues with reaching Tiler servers";
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult)) {
              var subEventJson = jsonResult['Content'];
              SubCalendarEvent subEvent =
                  SubCalendarEvent.fromJson(subEventJson);
              return new Tuple2(subEvent, null);
            } else {
              if (isTileRequestError(jsonResult)) {
                var errorJson = jsonResult['Error'];
                error = TilerError.fromJson(errorJson);
              } else {
                error.Message = "Issues with reaching TIler servers";
              }
            }
          }
        }
      }
    }
    var retValue = new Tuple2<SubCalendarEvent?, TilerError?>(null, error);
    return retValue;
  }
}
