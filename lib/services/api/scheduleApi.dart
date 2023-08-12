import 'package:http/http.dart' as http;
import 'package:tiler_app/data/analysis.dart';
import 'package:tiler_app/data/combination.dart';
import 'package:tiler_app/data/driveTime.dart';
import 'package:tiler_app/data/overview_item.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/timelineSummary.dart';
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
    // return await getAdHocSubEvents(Timeline.fromDateTimeAndDuration(
    //     Utility.todayTimeline().endTime.add(Utility.oneDay), Utility.oneDay));
    return await getSubEventsInScheduleRequest(timeLine);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>>
      getSubEventsInScheduleRequest(Timeline timeLine) async {
    print("|||||||Get sub event for timeline ${timeLine.toString()} |||||||");
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();

      String tilerDomain = Constants.tilerDomain;
      DateTime dateTime = Utility.currentTime();
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
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
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }

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
        throw TilerError(
            message: 'Tiler disagrees with you, please try again later');
      }
    }
    var retValue = new Tuple2<List<Timeline>, List<SubCalendarEvent>>([], []);
    return retValue;
  }

  Future<Map<int, TimelineSummary>> getDaySummary(Timeline timeline) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;

      DateTime dateTime = Utility.currentTime();
      final queryParameters = {
        'StartRange': timeline.start!.toInt().toString(),
        'EndRange': timeline.end!.toInt().toString(),
        'TimeZoneOffset': dateTime.timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/Schedule/daySummarys', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map jsDayIndexToTimelineSummary = jsonResult['Content'];
          Map<int, TimelineSummary> retValue = {};

          for (String jsDayIndexString in jsDayIndexToTimelineSummary.keys) {
            int jsDayIndex = int.parse(jsDayIndexString);
            DateTime dateOfFirst = Utility.getTimeFromIndexForJS(jsDayIndex);
            Map<String, dynamic> timelineSummaryJson =
                jsDayIndexToTimelineSummary[jsDayIndexString];
            TimelineSummary timelineSummary =
                TimelineSummary.subCalendarEventFromJson(timelineSummaryJson);
            timelineSummary.dayIndex = dateOfFirst.universalDayIndex;
            retValue[dateOfFirst.universalDayIndex] = timelineSummary;
          }

          return retValue;
        }
      }
      throw TilerError();
    }
    throw TilerError();
  }

  Future<
      Tuple4<List<Duration>, List<Location>, RestrictionProfile,
          List<String>>> getAutoResult(String tileName) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final queryParameters = {'UserName': username, 'Name': tileName};
        Map<String, dynamic> updatedQueryParameters =
            await this.injectRequestParams(queryParameters);
        Uri uri = Uri.https(
            url, 'api/Schedule/NewTilePrediction', updatedQueryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            List<Duration> durations = [];
            List<Location> locations = [];
            List<String> timeOfDaySections = [];
            RestrictionProfile restrictionProfile =
                RestrictionProfile.noRestriction();

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
            if (jsonResult['Content'].containsKey('restrictionProfile')) {
              if (jsonResult['Content']['restrictionProfile'] != null) {
                restrictionProfile = RestrictionProfile.fromJson(
                    jsonResult['Content']['restrictionProfile']);
              }
            }
            if (jsonResult['Content'].containsKey('timeOfDay')) {
              if (jsonResult['Content']['timeOfDay']['restrictionProfile'] !=
                  null) {
                restrictionProfile = RestrictionProfile.fromJson(
                    jsonResult['Content']['timeOfDay']['restrictionProfile']);
              }
              if (jsonResult['Content']['timeOfDay']
                  .containsKey('daySections')) {
                for (var eachDaySection in jsonResult['Content']['timeOfDay']
                    ['daySections']) {
                  if (eachDaySection != null &&
                      eachDaySection.toLowerCase() == 'anytime') {
                    restrictionProfile = RestrictionProfile.noRestriction();
                    timeOfDaySections = [];
                    break;
                  }
                  if (eachDaySection != null) {
                    timeOfDaySections.add(eachDaySection);
                  }
                }
              }
            }

            Tuple4<List<Duration>, List<Location>, RestrictionProfile,
                    List<String>> retValue =
                new Tuple4(durations, locations, restrictionProfile,
                    timeOfDaySections);
            return retValue;
          }
        }
      }
    }
    RestrictionProfile restrictionProfile = RestrictionProfile.noRestriction();
    return new Tuple4([], [], restrictionProfile, []);
  }

  Future<Tuple2<List<Timeline>, List<SubCalendarEvent>>> getAdHocSubEvents(
      Timeline timeLine,
      {bool forceInterFerringWithNowTile = true}) {
    Tuple2<List<Timeline>, List<SubCalendarEvent>> refreshedResults =
        Utility.generateAdhocSubEvents(timeLine,
            forceInterFerringWithNowTile: forceInterFerringWithNowTile);
    List<Timeline> sleepTimeLines = refreshedResults.item1;
    List<SubCalendarEvent> refreshedSubEvents = refreshedResults.item2;
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
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
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
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.post(uri,
            headers: header, body: jsonEncode(injectedParameters));

        var jsonResult = jsonDecode(response.body);
        error.message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            var subEventJson = jsonResult['Content'];
            SubCalendarEvent subEvent = SubCalendarEvent.fromJson(subEventJson);
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
    throw error;
  }

  Future procrastinateAll(Duration duration) async {
    TilerError error = new TilerError();
    error.message = "Did not send procrastinate all request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final procrastinateParameters = {
          'UserName': username,
          'DurationInMs': duration.inMilliseconds.toString()
        };
        Map injectedParameters = await injectRequestParams(
            procrastinateParameters,
            includeLocationParams: true);
        Uri uri = Uri.https(url, 'api/Schedule/ProcrastinateAll');
        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
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

  Future<TimelineSummary?> getTimelineSummary(Timeline timeline) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;

      DateTime dateTime = Utility.currentTime();
      final queryParameters = {
        'StartRange': timeline.start!.toInt().toString(),
        'EndRange': timeline.end!.toInt().toString(),
        'TimeZoneOffset': dateTime.timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };
      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/Schedule/timelineSummary', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          print(jsonResult);
          return TimelineSummary.subCalendarEventFromJson(
              jsonResult['Content']);
        }
      }
      throw TilerError();
    }
    throw TilerError();
  }

  Future<Analysis?> getAnalysis() async {
    try {
      if ((await this.authentication.isUserAuthenticated()).item1) {
        await checkAndReplaceCredentialCache();
        String tilerDomain = Constants.tilerDomain;
        String url = tilerDomain;
        if (this.authentication.cachedCredentials != null) {
          String? username = '';
          final queryParameters = {
            'UserName': username,
          };
          Map<String, dynamic> updatedQueryParameters =
              await this.injectRequestParams(queryParameters);
          Uri uri = Uri.https(url, 'api/Analysis', updatedQueryParameters);

          var header = this.getHeaders();
          if (header == null) {
            throw TilerError(message: 'Issues with authentication');
          }

          final response = await http.get(uri, headers: header);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final json = jsonDecode(response.body);

            final todayDate = DateTime.now();
            final newtodayDate =
                DateTime(todayDate.year, todayDate.month, todayDate.day);

            List<Timeline> sleepLines = [];
            final value1 = json['Content']['locationBreakdown'];

            List<String> keys = value1.keys.toList();

            List<OverViewItem> overview = [];
            if (keys.isNotEmpty) {
              int otherDuration = 0;
              keys.forEach((element) {
                int totalDuration = 0;
                final mm =
                    List.from(json['Content']['locationBreakdown'][element])
                        .map((e) => SubCalendarEvent.fromJson(e))
                        .toList();
                mm.forEach((element) {
                  Duration duration = DateTime.fromMillisecondsSinceEpoch(
                          element.end!)
                      .difference(
                          DateTime.fromMillisecondsSinceEpoch(element.start!));

                  totalDuration = totalDuration + duration.inMilliseconds;
                });
                OverViewItem? item;
                if (element.isNotEmpty) {
                  item = OverViewItem(name: element, duration: totalDuration);
                }

                if (overview.length < 5) {
                  if (item != null) overview.add(item);
                } else {
                  otherDuration = otherDuration + totalDuration;

                  if (overview.length >= 5) {
                    overview.removeLast();
                  }
                  final item =
                      OverViewItem(name: "Others", duration: otherDuration);
                  overview.add(item);
                }
              });
            }

            final locationCombination =
                List.from(json['Content']['travelTime']['locationCombination'])
                    .map((e) {
              final item = Combination.fromJson(e);

              double total = item.count! * item.duration!;
              item.totalDuration = total;
              return item;
            }).toList();

            List<DriveTime> allDriveTime = [];

            locationCombination.forEach((element) {
              String name =
                  "${element.first!.description!} - ${element.second!.description!}";

              DriveTime? item;

              if (name.isNotEmpty) {
                item = DriveTime(
                    name: name, duration: element.totalDuration!.toInt());
                allDriveTime.add(item);
              }
            });

            List<String> sleepLinesKey =
                json['Content']['sleep']['SleepTimeLines'].keys.toList();
            sleepLinesKey.forEach((element) {
              final value = Timeline.fromJson(json['Content']['sleep']
                  ['SleepTimeLines'][element]['SleepTimeline']);
              sleepLines.add(value);
            });

            final itemlast = Analysis(
                drivesTime: allDriveTime,
                overview: overview,
                sleep: sleepLines);

            return itemlast;
          }
        }
      }
    } catch (ex) {
      return null;
    }
  }
}
