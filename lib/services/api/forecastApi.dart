import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/appApi.dart';

import '../../constants.dart' as Constants;
import '../../data/forecast.dart';

class SchedulePreviewApi extends AppApi {

  Future<Forecast> sendSchedulePreviewRequest(
      Map<String, dynamic> userInput) async {
    try {
      if ((await this.authentication.isUserAuthenticated()).item1) {
        await checkAndReplaceCredentialCache();
        Map<String, dynamic> finalRequest = await injectRequestParams(
          userInput,
          includeLocationParams: false,
        );
        finalRequest.forEach((key, value) {
          print("Field: $key, Type: ${value.runtimeType}");
        });
        print("finalRequest after injectRequestParams: $finalRequest");
        finalRequest =
            finalRequest.map((key, value) => MapEntry(key, value.toString()));
        print("Sending Schedule Preview Request with payload: $finalRequest");
        String tilerDomain = Constants.tilerDomain;
        Uri uri = Uri.https(tilerDomain, 'api/WhatIf/NewTile', finalRequest);
        var header = this.getHeaders();
        print("Headers: $header");
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        http.Response response = await http.post(
            uri, headers: header, body: jsonEncode(finalRequest));
        print("Received raw response: ${response.body}");
        return processSchedulePreviewResponse(response);
      }
      throw TilerError();
    } catch (e, stackTrace) {
      print("log Error during API call: $e");
      print("StackTrace: $stackTrace");
      rethrow;
    }
  }

  Forecast processSchedulePreviewResponse(http.Response response) {
    print("Received response status: ${response.statusCode}");
    var jsonResult = jsonDecode(response.body);
    print("Decoded JSON response: $jsonResult");

    if (response.statusCode == 200) {
      if (isJsonResponseOk(jsonResult)) {
        if (isContentInResponse(jsonResult)) {
          Map<String, dynamic> content = jsonResult['Content'];
          print("Processed content: $content");
          return Forecast.fromJson(content);
        } else {
          print("Response content is missing");
        }
      } else {
        print("JSON response is not OK");
      }
    } else {
      print("Error response with status code: ${response.statusCode}");
    }
    throw TilerError(message: "Invalid response format");
  }
}
