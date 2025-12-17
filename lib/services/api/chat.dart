import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/VibeChat/VibeAction.dart';
import 'package:tiler_app/data/VibeChat/VibeMessage.dart';
import 'package:tiler_app/data/VibeChat/VibeRequest.dart';
import 'package:tiler_app/data/VibeChat/VibeResponse.dart';
import 'package:tiler_app/data/VibeChat/VibeSession.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/services/localizationService.dart';
import 'dart:developer' as developer;

class ChatApi extends AppApi {
  ChatApi({Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  Future<List<VibeSession>> getVibeSessions() async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();

        String tilerDomain = Constants.tilerDomain;
        Map<String, String> queryParams = {'mobileApp': 'true'};
        Uri uri = Uri.https(tilerDomain, 'api/Vibe/Session', queryParams);

        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          var jsonResult = jsonDecode(response.body);
          if (jsonResult['Content'] != null && jsonResult['Content']['vibeSessions'] != null) {
            return (jsonResult['Content']['vibeSessions'] as List)
                .map((session) => VibeSession.fromJson(session))
                .toList();
          }
          return [];
        } else {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.responseHandlingError);
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<List<VibeMessage>> getMessages({required String sessionId,int batchSize = 5, int index = 0}) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        String tilerDomain = Constants.tilerDomain;
        Map<String, String> queryParams = {
          'SessionId': sessionId,
          'batchSize': batchSize.toString(),
          'index': index.toString(),
        };
        Uri uri = Uri.https(tilerDomain, 'api/Vibe/Chat', queryParams);

        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.get(uri, headers: headers);
        if (response.statusCode == 200) {
          var jsonResult = jsonDecode(response.body);
          if (jsonResult['Content'] != null && jsonResult['Content']['chats'] != null) {
            return (jsonResult['Content']['chats'] as List)
                .map((message) => VibeMessage.fromJson(message))
                .toList();
          }
          return [];
        } else {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.responseHandlingError);
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<List<VibeAction>> getActions(List<String> actionIds) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        final queryParams = <String, dynamic>{};

        if (actionIds.length == 1) {
          queryParams['ActionId'] = actionIds[0];
        } else {
          queryParams['ActionIds'] = actionIds;
        }
        Uri uri = Uri.https(Constants.tilerDomain, 'api/Vibe/Action', queryParams);
        var headers = this.getHeaders();

        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          var jsonResult = jsonDecode(response.body);
          final content = jsonResult['Content'];

          if (content['vibeActions'] != null) {
            return (content['vibeActions'] as List)
                .map((action) => VibeAction.fromJson(action))
                .toList();
          } else if (content['vibeAction'] != null) {
            return [VibeAction.fromJson(content['vibeAction'])];
          }
          return [];
        } else {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.responseHandlingError);
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<VibeRequest?> getVibeRequest(String requestId) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();

        String tilerDomain = Constants.tilerDomain;
        Map<String, String> queryParams = {
          'RequestId': requestId,
        };
        Uri uri = Uri.https(tilerDomain, 'api/Vibe/VibeRequest', queryParams);

        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.get(uri, headers: headers);

        if (response.statusCode == 200) {
          var jsonResult = jsonDecode(response.body);
          if (jsonResult['Content'] != null &&
              jsonResult['Content']['vibeRequest'] != null) {
            return VibeRequest.fromJson(jsonResult['Content']['vibeRequest']);
          }
          return null;
        } else {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.responseHandlingError);
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<VibeResponse?> sendChatMessage(String message, String? sessionId) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();

        Map<String, dynamic> requestBody = {
          'ChatMessage': message,
          'SessionId': sessionId??'',
          'MobileApp': true,
        };

        Uri uri = Uri.https(Constants.tilerDomain, 'api/Vibe/Chat');
        var headers = this.getHeaders();

        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200 || response.statusCode==60000001) {
          var jsonResult = jsonDecode(response.body);
          if (jsonResult['Content'] != null && jsonResult['Content']['vibeResponse'] != null) {
            return VibeResponse.fromJson(jsonResult['Content']['vibeResponse']);
          }
          return null;
        } else {

          throw TilerError(
              Message: LocalizationService
                  .instance.translations.responseHandlingError);
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<VibeRequest?> executeVibeRequest({ required String requestId, String? userLongitude, String? userLatitude, String? userLocationVerified}) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();

        Map<String, dynamic> requestBody = {
          'requestId': requestId,
          'MobileApp': true,
        };

        if (userLongitude != null) requestBody['userLongitude'] = userLongitude;
        if (userLatitude != null) requestBody['userLatitude'] = userLatitude;
        if (userLocationVerified != null) requestBody['userLocationVerified'] = userLocationVerified;

        Uri uri = Uri.https(Constants.tilerDomain, 'api/Vibe/Request/Execute');
        var headers = this.getHeaders();

        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }

        http.Response response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(requestBody),
        );


        if (response.statusCode == 200) {
          var jsonResult = jsonDecode(response.body);
          if (jsonResult['Content'] != null && jsonResult['Content']['vibeRequest'] != null) {
            return VibeRequest.fromJson(jsonResult['Content']['vibeRequest']);
          }
          return null;
        } else {
          throw TilerError(Message: 'Server returned ${response.statusCode}');
        }
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }
}

