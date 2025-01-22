import 'dart:convert';

import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:http/http.dart' as http;
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class PreviewApi extends AppApi {
  Future<PreviewSummary> getSummary(Timeline timeLine) async {
    // Utility.debugPrint(
    //     "|||||||Get sub event for timeline ${timeLine.toString()} |||||||");
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
          throw TilerError(message: 'Issues with authentication');
        }

        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult) &&
              jsonResult['Content'].containsKey('analyticSummary')) {
            return PreviewSummary.fromJson(
                jsonResult['Content']['analyticSummary']);
          }
        }
      }
    }
    throw TilerError(message: 'Failed to get preview summary');
  }
}
