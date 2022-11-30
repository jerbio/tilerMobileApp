import 'dart:convert';

import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'dart:convert';

import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/services/api/appApi.dart';

import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class LocationApi extends AppApi {
  Future<List<Location>>? chainPending;
  var nextRequestParams = [];

  List<Location> processLocationList(http.Response response) {
    var jsonResult = jsonDecode(response.body);
    if (isJsonResponseOk(jsonResult)) {
      if (isContentInResponse(jsonResult)) {
        List locationJson = jsonResult['Content'];
        // List sleepTimelinesJson = [];
        print("Got more data " + locationJson.length.toString());
        // List<Timeline> sleepTimelines = sleepTimelinesJson
        //     .map((timelinesJson) => Timeline.fromJson(timelinesJson))
        //     .toList();

        List<Location> locations = locationJson
            .map((eachLocationJson) => Location.fromJson(eachLocationJson))
            .toList();
        List<Location> retValue = locations;
        return retValue;
      }
    }
    throw NullThrownError();
  }

  Future<List<Location>> _createLocationFuture(Uri uri, var header) async {
    var pendingRequest = http.get(uri, headers: header);
    http.Response response = await pendingRequest;
    while (nextRequestParams.length > 0) {
      var params = nextRequestParams.last;
      nextRequestParams = [];
      header = params['header'];
      uri = params['uri'];
      response = await http.get(uri, headers: header);
    }
    this.chainPending = null;
    return processLocationList(response);
  }

  Future<List<Location>> getLocationsByName(String name) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;

    if (await this.authentication.isUserAuthenticated()) {
      await this.authentication.reLoadCredentialsCache();

      final queryParameters = {
        'Data': name,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };

      Uri uri = Uri.https(url, 'api/Location/Name', queryParameters);
      var header = this.getHeaders();

      if (header != null) {
        if (chainPending != null) {
          var param = {
            'header': header,
            'uri': uri,
          };
          this.nextRequestParams.add(param);
          List<Location>? events = await chainPending;
          if (events != null) {
            return events;
          }
          throw NullThrownError();
        }

        chainPending = this._createLocationFuture(uri, header);
        List<Location> retValue = await chainPending!;
        chainPending = null;
        return retValue;
      }
    }

    List<Location> locations = [];
    return locations;
  }
}