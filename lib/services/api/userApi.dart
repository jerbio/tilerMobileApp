import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/notificationData.dart';
import '../../constants.dart' as Constants;
import 'package:tiler_app/services/api/appApi.dart';

class UserApi extends AppApi {
  Future<NotificationData?> getNotificationChannel(String platform) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain;
    if ((await this.authentication.isUserAuthenticated()).item1) {
      final queryParameters = await injectRequestParams({'platform': platform});

      // Uri uri = Uri.https(url, 'api/User/Notification');
      // var header = this.getHeaders();
      // if (header == null) {
      //   throw TilerError(message: 'Issues with authentication');
      // }

      Map<String, dynamic> updatedParams = await injectRequestParams(
          queryParameters,
          includeLocationParams: false);
      Uri uri = Uri.https(url, 'api/User/Notification', updatedParams);
      var header = this.getHeaders();
      if (header == null) {
        throw TilerError(message: 'Issues with authentication');
      }

      var response = await http.get(uri, headers: header);
      NotificationData retValue = NotificationData.noCredentials();

      if (response.statusCode == 200) {
        var jsonResult = jsonDecode(response.body);
        try {
          if (isJsonResponseOk(jsonResult)) {
            if (isContentInResponse(jsonResult)) {
              Map<String, dynamic> notificationResponse = jsonResult['Content'];
              return await NotificationData.initializedWithRestData(
                  notificationResponse['id'],
                  notificationResponse['channelType'],
                  notificationResponse['thirdPartyId'],
                  notificationResponse['expiryTIme']);
            }
          }
        } catch (e) {
          return retValue;
        }
      } else {
        var jsonResult = jsonDecode(response.body);
        if (jsonResult.containsKey('error') &&
            jsonResult.containsKey('error_description') &&
            jsonResult.containsKey('error_description') != null &&
            jsonResult.containsKey('error_description').isNotEmpty) {
          throw TilerError(message: jsonResult['error_description']);
        }
        return retValue;
      }
      return retValue;
    }
  }
}
