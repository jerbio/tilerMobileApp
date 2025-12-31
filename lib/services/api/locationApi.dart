import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';

import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/util.dart';
import '../../constants.dart' as Constants;

class LocationApi extends AppApi {
  LocationApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<List<Location>>? chainPending;
  var nextRequestParams = [];

  List<Location> processLocationList(http.Response response) {
    var jsonResult = jsonDecode(response.body);
    if (isJsonResponseOk(jsonResult)) {
      if (isContentInResponse(jsonResult)) {
        List locationJson = jsonResult['Content'];
        print("Got more data " + locationJson.length.toString());

        List<Location> locations = locationJson
            .map((eachLocationJson) => Location.fromJson(eachLocationJson))
            .toList();
        List<Location> retValue = locations;
        return retValue;
      }
    }
    throw TilerError();
  }

  Future<List<Location>> _createLocationFuture(Uri uri, var header) async {
    var pendingRequest = httpClient.get(uri, headers: header).timeout(
      AppApi.requestTimeout,
      onTimeout: () {
        throw TilerError(
            Message: LocalizationService.instance.translations.requestTimeout);
      },
    );
    http.Response response = await pendingRequest;
    while (nextRequestParams.length > 0) {
      var params = nextRequestParams.last;
      nextRequestParams = [];
      header = params['header'];
      uri = params['uri'];
      response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
    }
    this.chainPending = null;
    return processLocationList(response);
  }

  Future<List<Location>> getLocationsByName(String name,
      {includeMapSearch = true, includeLocationParams = true}) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;

    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();

      final queryParameters = {
        'Data': name,
        'TimeZoneOffset':
            Utility.currentTime().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString(),
        'IncludeMapSearch': includeMapSearch.toString()
      };

      Map<String, dynamic> injectedLocationParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: includeLocationParams);
      Uri uri = Uri.https(url, 'api/Location/Name', injectedLocationParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(Message: 'Issues with authentication');
      }
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
        throw TilerError();
      }

      chainPending = this._createLocationFuture(uri, header);
      List<Location> retValue = await chainPending!;
      chainPending = null;
      return retValue;
    }

    List<Location> locations = [];
    return locations;
  }

  Future<Location?> getSpecificLocationByNickName(String name) async {
    List<Location>? locations = await getLocationsByName(name,
        includeMapSearch: false, includeLocationParams: false);

    List<Location> foundEvents = locations
        .where((location) =>
            location.description != null &&
            location.description!.toLowerCase() == name.toLowerCase())
        .toList();
    if (foundEvents.isNotEmpty) {
      return foundEvents.first;
    }
    return null;
  }

  Future<Location?> getLocationById(
      {String? id, String? calendarId, String? subEventId}) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;

    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();

      final queryParameters = {
        'Id': id,
        'SubEventId': subEventId,
        'CalendarEventId': calendarId,
        'TimeZoneOffset':
            Utility.currentTime().timeZoneOffset.inHours.toString(),
        'MobileApp': true.toString(),
      };

      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/Location', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(Message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          return Location.fromJson(jsonResult['Content']);
        }
      }

      throw TilerError();
    }
  }
}
