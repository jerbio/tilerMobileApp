import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileSuggestion.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/onBoarding.dart';
import 'package:tiler_app/services/localizationService.dart';

class OnBoardingApi extends AppApi {
  OnBoardingApi() : super(getContextCallBack: () => null);
  Future<OnboardingContent?> fetchOnboardingData() async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        String tilerDomain = Constants.tilerDomain;
        Uri uri = Uri.https(tilerDomain, 'api/User/Onboarding');

        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }
        print('Request headers: $headers');
        var response = await http.get(uri, headers: headers);
        print('Response from fetchOnboardingData: ${response.body}');
        return handleResponse(response);
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      print(
          'Exception occurred in fetchOnboardingData: ${e is TilerError ? e.Message : "Unknown error"}');
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  Future<OnboardingContent?> sendOnboardingData(
      OnboardingContent content) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        Map<String, dynamic> requestParams = content.toJson();
        Uri uri = Uri.https(Constants.tilerDomain, 'api/User/Onboarding');
        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(
              Message: LocalizationService
                  .instance.translations.authenticationIssues);
        }
        http.Response response = await http.post(uri,
            headers: headers, body: jsonEncode(requestParams));
        print('Response from sendOnboardingData: ${response.body}');
        return handleResponse(response);
      } else {
        throw TilerError(
            Message: LocalizationService
                .instance.translations.userIsNotAuthenticated);
      }
    } catch (e) {
      print(
          'Exception occurred in sendOnboardingData: ${e is TilerError ? e.Message : "Unknown error"}');
      throw TilerError(
          Message: e is TilerError
              ? e.Message
              : LocalizationService.instance.translations.errorOccurred);
    }
  }

  OnboardingContent? handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (jsonResult.containsKey('Content')) {
        OnboardingContent onboardingContent =
            OnboardingContent.fromJson(jsonResult['Content']);
        return onboardingContent;
      } else {
        throw TilerError(
            Message:
                LocalizationService.instance.translations.responseContentError);
      }
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw TilerError(
          Message:
              LocalizationService.instance.translations.responseHandlingError);
    }
  }

  Future<bool> areRequiredFieldsValid() async {
    OnboardingContent? onboardingContent = await fetchOnboardingData();
    if (onboardingContent == null) {
      return false;
    }
    return (onboardingContent.personalHoursStart?.isNotEmpty ?? false) &&
        (onboardingContent.workHoursStart?.isNotEmpty ?? false) &&
        (onboardingContent.preferredDaySections?.isNotEmpty ?? false) &&
        (onboardingContent.workLocation?.address?.isNotEmpty ?? false);
  }

  Future<List<TileSuggestion>> generateSuggestionTiles(
      {
        required String profession,
        String description = ""
      }
      ) async {
        try {
          var isAuthenticated = await this.authentication.isUserAuthenticated();
          if (isAuthenticated.item1) {
            await checkAndReplaceCredentialCache();

            Uri uri = Uri.https(Constants.tilerDomain, 'api/Persona/GenerateTiles');
            var headers = this.getHeaders();

            if (headers == null) {
              throw TilerError(
                  Message: LocalizationService.instance.translations.authenticationIssues);
            }

            Map<String, dynamic> requestBody = {
              'PersonaName': profession,
              'Description': description,
            };

            http.Response response = await http.post(
                uri,
                headers: headers,
                body: jsonEncode(requestBody)
            ).timeout(
              Duration(seconds: 30),
              onTimeout: () {
                throw TilerError(Message: 'Request timed out');
              },
            );


            print('Response from generateTiles: ${response.body}');

            if (response.statusCode == 200) {
              var jsonResult = jsonDecode(response.body);
              if (jsonResult.containsKey('Content') &&
                  jsonResult['Content']['result'] != null &&
                  jsonResult['Content']['result']['persona'] != null) {
                List<
                    dynamic> tilePrefs = jsonResult['Content']['result']['persona']['TilePreferences'];
                return tilePrefs.map((e) => TileSuggestion.fromJson(e)).toList();
              }
              return [];
            } else {
              throw TilerError(
                  Message: LocalizationService.instance.translations.responseHandlingError);
            }
          } else {
            throw TilerError(
                Message: LocalizationService.instance.translations.userIsNotAuthenticated);
          }
        } catch (e) {
          print('Exception in generateTiles: ${e is TilerError ? e.Message : "Unknown error"}');
          throw TilerError(
              Message: e is TilerError
                  ? e.Message
                  : LocalizationService.instance.translations.errorOccurred);
        }
  }
}
