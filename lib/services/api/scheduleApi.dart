import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tuple/tuple.dart';

import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class ScheduleApi extends AppApi {
  bool preserveSubEventList = true;
  List<SubCalendarEvent> adhocGeneratedSubEvents = <SubCalendarEvent>[];

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getSubEvents(
      Timeline timeLine) async {
    // return await getAdHocSubEvents(timeLine);
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
              List subEventJson = jsonResult['Content']['subCalendarEvents'];
              List sleepTimelinesJson = [];
              print("Got more data " + subEventJson.length.toString());

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

  Future<Tuple2<List<Duration>, List<Location>>> getAutoResult(
      String tileName) async {
    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      DateTime dateTime = DateTime.now();
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final queryParameters = {'UserName': username, 'Name': tileName};
        Map<String, String?> updatedQueryParameters =
            await this.injectRequestParams(queryParameters);
        Uri uri = Uri.https(
            url, 'api/Schedule/NewTilePrediction', updatedQueryParameters);

        var header = this.getHeaders();

        if (header != null) {
          var response = await http.get(uri, headers: header);
          var jsonResult = jsonDecode(response.body);
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult)) {
              List<Duration> durations = [];
              List<Location> locations = [];
              Tuple2<List<Duration>, List<Location>> retValue =
                  new Tuple2(durations, locations);
              if (jsonResult['Content'].containsKey('duration')) {
                List<double> durationInMs = [];
                for (var eachDuration in jsonResult['Content']['duration']) {
                  durationInMs.add(eachDuration);
                }
                durationInMs.sort((a, b) {
                  double diff = a - b;
                  if (diff > 0) {
                    return 1;
                  }
                  if (diff < 0) {
                    return -1;
                  }
                  return 0;
                });
                for (var durationInMs in durationInMs) {
                  durations.add(Duration(milliseconds: durationInMs.toInt()));
                }
              }
              if (jsonResult['Content'].containsKey('location')) {
                for (var eachLocation in jsonResult['Content']['location']) {
                  locations.add(Location.fromJson(eachLocation));
                }
              }

              return retValue;
            }
          }
        }
      }
    }
    return new Tuple2([], []);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getAdHocSubEvents(
      Timeline timeLine,
      {bool forceInterFerringWithNowTile = true}) {
    if (!this.preserveSubEventList) {
      adhocGeneratedSubEvents = <SubCalendarEvent>[];
    }
    int subEventCount = Random().nextInt(20);
    while (subEventCount < 1) {
      subEventCount = Random().nextInt(20);
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
          timeLine.start!.toInt() - durationMs - Utility.oneMin.inMilliseconds;
      int endLimit =
          timeLine.end!.toInt() + durationMs - Utility.oneMin.inMilliseconds;
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
    error.message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated = await this.authentication.isUserAuthenticated();
    if (userIsAuthenticated) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final newTileParameters = tile.toJson();
        newTileParameters['UserName'] = username;
        var restrictedWeekData;
        if (newTileParameters.containsKey('RestrictiveWeek')) {
          restrictedWeekData = newTileParameters['RestrictiveWeek'];
          newTileParameters.remove('RestrictiveWeek');
        }
        Map<String, dynamic> injectedParameters = await injectRequestParams(
            newTileParameters,
            includeLocationParams: true);
        if (restrictedWeekData != null) {
          Map<String, dynamic> injectedParametersCpy = injectedParameters;
          injectedParameters = {};
          for (String eachKey in injectedParametersCpy.keys) {
            injectedParameters[eachKey] = injectedParametersCpy[eachKey];
          }
          injectedParameters['RestrictiveWeek'] = restrictedWeekData;
        }
        Uri uri = Uri.https(url, 'api/Schedule/Event');
        var header = this.getHeaders();

        if (header != null) {
          var response = await http.post(uri,
              headers: header, body: jsonEncode(injectedParameters));
          var jsonResult = jsonDecode(response.body);
          error.message = "Issues with reaching Tiler servers";
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult)) {
              var subEventJson = jsonResult['Content'];
              SubCalendarEvent subEvent =
                  SubCalendarEvent.fromJson(subEventJson);
              return new Tuple2(subEvent, null);
            }
          }
          if (isTilerRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
            throw FormatException(error.message!);
          } else {
            error.message = "Issues with reaching TIler servers";
          }
        }
      }
    }
    throw error;
  }

  Future procrastinateAll(Duration duration) async {
    TilerError error = new TilerError();
    error.message = "Did not send procrastinate all request";
    bool userIsAuthenticated = true;
    userIsAuthenticated = await this.authentication.isUserAuthenticated();
    if (userIsAuthenticated) {
      await this.authentication.reLoadCredentialsCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = this.authentication.cachedCredentials!.username;
        final procrastinateParameters = {
          'UserName': username,
          'DurationInMs': duration.inMilliseconds.toString()
        };
        Map injectedParameters = await injectRequestParams(
            procrastinateParameters,
            includeLocationParams: true);
        Uri uri = Uri.https(url, 'api/Schedule/ProcrastinateAll');
        var header = this.getHeaders();

        if (header != null) {
          var response = await http.post(uri,
              headers: header, body: jsonEncode(injectedParameters));
          var jsonResult = jsonDecode(response.body);
          error.message = "Issues with reaching Tiler servers";
          if (isJsonResponseOk(jsonResult)) {
            return;
          }
          if (isTilerRequestError(jsonResult)) {
            var errorJson = jsonResult['Error'];
            error = TilerError.fromJson(errorJson);
            throw FormatException(error.message!);
          } else {
            error.message = "Issues with reaching TIler servers";
          }
        }
      }
    }
    throw error;
  }

  Future reviseSchedule() async {
    TilerError error = new TilerError();
    error.message = "Failed to revise schedule";

    return sendPostRequest('api/Schedule/Revise', {}).then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return;
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw error;
      } else {
        error.message = "Issues with reaching Tiler servers";
        throw error;
      }
    });
  }

  Future shuffleSchedule() async {
    TilerError error = new TilerError();
    error.message = "Failed to shuffle schedule";
    return sendPostRequest('api/Schedule/Shuffle', {}).then((response) {
      var jsonResult = jsonDecode(response.body);
      error.message = "Issues with reaching Tiler servers";
      if (isJsonResponseOk(jsonResult)) {
        return;
      }
      if (isTilerRequestError(jsonResult)) {
        var errorJson = jsonResult['Error'];
        error = TilerError.fromJson(errorJson);
        throw FormatException(error.message!);
      } else {
        error.message = "Issues with reaching Tiler servers";
      }
    });
  }
}
