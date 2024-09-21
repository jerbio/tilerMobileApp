import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileClusterData.dart';
import 'package:tiler_app/services/api/appApi.dart';

import '../../constants.dart' as Constants;

class TileClusterApi extends AppApi {
  Future createCluster(TileClusterData tileCluster) async {
    TilerError error = new TilerError();
    error.message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final newCluster = {};
        //final newCluster = tileCluster.toJson();
        newCluster['UserName'] = username;
        Map<String, dynamic> injectedParameters =
            await injectRequestParams(newCluster, includeLocationParams: true);
        Uri uri = Uri.https(url, 'api/Cluster');
        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.post(uri,
            headers: header, body: jsonEncode(injectedParameters));

        var jsonResult = jsonDecode(response.body);
        error.message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            return;
            // var subEventJson = jsonResult['Content'];
            // SubCalendarEvent subEvent = SubCalendarEvent.fromJson(subEventJson);
            // return new Tuple2(subEvent, null);
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.message!);
        } else {
          error.message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }
}
