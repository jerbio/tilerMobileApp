import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:http/http.dart' as http;

import '../../constants.dart' as Constants;

class SettingsApi extends AppApi {
  Future<Map<String, RestrictionProfile>> getUserRestrictionProfile() async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await this.authentication.reLoadCredentialsCache();
      Map<String, dynamic> restrictedUpdatedParams =
          await injectRequestParams({}, includeLocationParams: false);
      String tilerDomain = Constants.tilerDomain;
      Uri uri = Uri.https(tilerDomain, 'Manage/GetRestrictionProfile');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, RestrictionProfile> retValue = {};
          if (jsonResult['Content'] is Map) {
            for (var restrictionType in jsonResult['Content'].keys) {
              retValue[restrictionType] = RestrictionProfile.fromJson(
                  jsonResult['Content'][restrictionType]);
            }
          }
          return retValue;
        }
      }
    }
    throw TilerError(message: "Issues with reaching TIler servers");
  }

  Future<RestrictionProfile> updateRestrictionProfile(
      RestrictionProfile restrictionProfile,
      {String? restrictionProfileType}) async {
    Map restrictionProfileParams = {
      'Id': restrictionProfile.id,
      'RestrictiveWeek': restrictionProfile.toRestrictionWeekConfig()?.toJson(),
      'RestrictionProfileType': restrictionProfileType
    };
    return sendPostRequest(
            'Manage/RestrictionProfile', restrictionProfileParams,
            analyze: false)
        .then((response) {
      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            Map<String, dynamic> jsonMap = jsonResult['Content'];
            RestrictionProfile retValue = RestrictionProfile.fromJson(jsonMap);
            return retValue;
          }
        }
      }
      print('restriction profile update issue');
      throw TilerError(message: "Issues with reaching Tiler servers");
    });
  }

  Future<StartOfDay> getUserStartOfDay() async {
    Map timeOfDayParams = {};

    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      Map<String, dynamic> restrictedUpdatedParams =
          await injectRequestParams({}, includeLocationParams: false);
      String tilerDomain = Constants.tilerDomain;
      Uri uri = Uri.https(tilerDomain, 'Manage/GetStartOfDay');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }
      var response = await http.get(uri, headers: header);
      var jsonResult = jsonDecode(response.body);
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> jsonMap = jsonResult['Content'];
          StartOfDayConfig startOfDayConfig =
              StartOfDayConfig.fromJson(jsonMap);

          return startOfDayConfig.toStartOfDay();
        }
      }
    }
    throw TilerError();
  }

  Future<StartOfDay> updateStartOfDay(StartOfDay startOfDay) async {
    Map<String, dynamic> updateStartOfDayParams =
        startOfDay.generateStartOfDayConfig().toJson();
    updateStartOfDayParams.remove('TimeZoneOffSet');
    return sendPostRequest('Manage/UpdateStartOfDay', updateStartOfDayParams,
            analyze: false)
        .then((response) {
      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            Map<String, dynamic> jsonMap = jsonResult['Content'];
            StartOfDay retValue =
                StartOfDayConfig.fromJson(jsonMap).toStartOfDay();
            return retValue;
          }
        }
      }
      print('Update start of day issue');
      print(response.body);
      throw TilerError(message: "Issues with reaching TIler servers");
    });
  }
}
