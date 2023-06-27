import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'dart:convert';

import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../constants.dart' as Constants;

class TileNameApi extends AppApi {
  Future<List<TilerEvent>>? chainPending;

  var nextRequestParams = [];

  List<TilerEvent> processTileEventList(http.Response response) {
    var jsonResult = jsonDecode(response.body);
    if (isJsonResponseOk(jsonResult)) {
      if (isContentInResponse(jsonResult)) {
        List calEventJson = jsonResult['Content'];
        List sleepTimelinesJson = [];
        print("Got more data " + calEventJson.length.toString());
        List<Timeline> sleepTimelines = sleepTimelinesJson
            .map((timelinesJson) => Timeline.fromJson(timelinesJson))
            .toList();

        List<TilerEvent> calEvents = calEventJson
            .map((eachSubEventJson) => TilerEvent.fromJson(eachSubEventJson))
            .toList();
        List<TilerEvent> retValue = calEvents;
        return retValue;
      }
    }
    throw TilerError();
  }

  Future<List<TilerEvent>> _createEventFuture(Uri uri, var header) async {
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
    return processTileEventList(response);
  }

  Future<List<TilerEvent>> getTilesByName(String name) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;

    if ((await this.authentication.isUserAuthenticated()).item1) {
      await this.authentication.reLoadCredentialsCache();

      final queryParameters = {
        'Data': name,
        'TimeZoneOffset': DateTime.now().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString()
      };

      Uri uri = Uri.https(url, 'api/CalendarEvent/Name', queryParameters);
      var header = this.getHeaders();

      if (header != null) {
        if (chainPending != null) {
          var param = {
            'header': header,
            'uri': uri,
          };
          this.nextRequestParams.add(param);
          List<TilerEvent>? events = await chainPending;
          if (events != null) {
            return events;
          }
          throw TilerError();
        }

        chainPending = this._createEventFuture(uri, header);
        List<TilerEvent> retValue = await chainPending!;
        chainPending = null;
        return retValue;
      }
    }
    throw TilerError();
  }
}
