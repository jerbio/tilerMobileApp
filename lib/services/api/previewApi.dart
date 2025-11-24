import 'dart:convert';
import 'dart:io';

import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class PreviewApi extends AppApi {
  PreviewApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future<PreviewSummary> getSummary(Timeline timeLine) async {
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
        Uri uri = Uri.https(url, 'api/Analysis/Summary', queryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }

        var response = await http.get(uri, headers: header);
        if (response.statusCode == HttpStatus.ok) {
          var jsonResult = jsonDecode(response.body);
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult) &&
                jsonResult['Content'].containsKey('analyticSummary')) {
              return PreviewSummary.fromJson(
                  jsonResult['Content']['analyticSummary']);
            }
          }
        } else {
          print("Response code is " + response.statusCode.toString());
        }
      }
    }
    throw TilerError(Message: 'Failed to get preview summary');
  }
}
