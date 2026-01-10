import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class SettingsApi extends AppApi {
  SettingsApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<Map<String, RestrictionProfile>> getUserRestrictionProfile() async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await this.authentication.reLoadCredentialsCache();
      Map<String, dynamic> restrictedUpdatedParams =
          await injectRequestParams({}, includeLocationParams: false);
      String tilerDomain = Constants.tilerDomain;
      Uri uri = Uri.https(tilerDomain, 'Manage/GetRestrictionProfile');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.authenticationIssues);
      }
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
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
    throw TilerError(
      Message: LocalizationService.instance.translations.reachingServerIssues,
    );
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
      throw TilerError(
          Message:
              LocalizationService.instance.translations.reachingServerIssues);
    });
  }

  Future<StartOfDay> getUserStartOfDay() async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      Uri uri = Uri.https(tilerDomain, 'Manage/GetStartOfDay');
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.authenticationIssues);
      }
      var response = await httpClient.get(uri, headers: header).timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );
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
      throw TilerError(
          Message:
              LocalizationService.instance.translations.reachingServerIssues);
    });
  }

  Future<UserSettings> getUserSettings() async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      var queryParameters = {
        'MobileApp': true.toString(),
      };
      Uri uri = Uri.https(tilerDomain, 'api/User/Settings', queryParameters);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.authenticationIssues);
      }
      var response = await httpClient
          .get(
        uri,
        headers: header,
      )
          .timeout(
        AppApi.requestTimeout,
        onTimeout: () {
          throw TilerError(
              Message:
                  LocalizationService.instance.translations.requestTimeout);
        },
      );

      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            Map<String, dynamic> jsonMap = jsonResult['Content']['settings'];
            UserSettings retValue = UserSettings.fromJson(jsonMap);
            return retValue;
          }
        }
      }
    }
    throw TilerError();
  }

  Future<UserSettings> updateUserSettings(UserSettings userSetting) async {
    Map<String, dynamic> userSettingMap = userSetting.toJsonForUpdate();
    Utility.debugPrint("SENT TO API: ${userSettingMap}");
    return sendPostRequest('api/User/Settings', userSettingMap, analyze: false)
        .then((response) {
      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            Map<String, dynamic> jsonMap = jsonResult['Content']['settings'];
            UserSettings retValue = UserSettings.fromJson(jsonMap);
            return retValue;
          }
        }
      }
      throw TilerError(
          Message:
              LocalizationService.instance.translations.reachingServerIssues);
    });
  }
}
