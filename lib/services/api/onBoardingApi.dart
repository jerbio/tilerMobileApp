import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/data/onBoarding.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnBoardingApi extends AppApi {
  Future<OnboardingContent?> fetchOnboardingData(BuildContext context) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        String tilerDomain = Constants.tilerDomain;
        Uri uri = Uri.https(tilerDomain, 'api/User/Onboarding');

        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(message:AppLocalizations.of(context)!.authenticationIssues);
        }
        print('Request headers: $headers');
        var response = await http.get(uri, headers: headers);
        print('Response from fetchOnboardingData: ${response.body}');
        return handleResponse(response,context);
      } else {
        throw TilerError(message: AppLocalizations.of(context)!.userIsNotAuthenticated);
      }
    } catch (e) {
      print('Exception occurred in fetchOnboardingData: ${e is TilerError?e.message:"Unknown error"}');
      throw TilerError(message: e is TilerError?e.message:AppLocalizations.of(context)!.errorOccurred);
    }
  }

  Future<OnboardingContent?> sendOnboardingData(
      OnboardingContent content,BuildContext context) async {
    try {
      var isAuthenticated = await this.authentication.isUserAuthenticated();
      if (isAuthenticated.item1) {
        await checkAndReplaceCredentialCache();
        Map<String, dynamic> requestParams = content.toJson();
        Uri uri = Uri.https(Constants.tilerDomain, 'api/User/Onboarding');
        var headers = this.getHeaders();
        if (headers == null) {
          throw TilerError(message: AppLocalizations.of(context)!.authenticationIssues);
        }
        http.Response response = await http.post(uri,
            headers: headers, body: jsonEncode(requestParams));
        print('Response from sendOnboardingData: ${response.body}');
        return handleResponse(response,context);
      } else {
        throw TilerError(message: AppLocalizations.of(context)!.userIsNotAuthenticated);
      }
    } catch (e) {
      print('Exception occurred in sendOnboardingData: ${e is TilerError?e.message:"Unknown error"}');
      throw TilerError(message: e is TilerError?e.message:AppLocalizations.of(context)!.errorOccurred);
    }
  }

  OnboardingContent? handleResponse(http.Response response,BuildContext context) {
    if (response.statusCode == 200) {
      var jsonResult = jsonDecode(response.body);
      if (jsonResult.containsKey('Content')) {
        OnboardingContent onboardingContent =
        OnboardingContent.fromJson(jsonResult['Content']);
        return onboardingContent;
      } else {
        throw TilerError(message: AppLocalizations.of(context)!.responseContentError);
      }
    } else {
      throw TilerError(message: AppLocalizations.of(context)!.responseHandlingError);
    }
  }

  Future<bool> areRequiredFieldsValid(BuildContext context) async {
    OnboardingContent? onboardingContent = await fetchOnboardingData(context);
    if (onboardingContent == null) {
      return false;
    }
    return (onboardingContent.personalHoursStart?.isNotEmpty ?? false) &&
        (onboardingContent.workHoursStart?.isNotEmpty ?? false) &&
        (onboardingContent.preferredDaySections?.isNotEmpty ?? false) &&
        (onboardingContent.workLocation?.address?.isNotEmpty ?? false);
  }
}

