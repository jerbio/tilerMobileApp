import 'package:http/http.dart' as http;
import 'package:tiler_app/data/designatedTille.dart';
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileClusterData.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';

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
        // String? username = '';
        final newCluster = tileCluster.toTemplateClusterModel().toJson();
        // newCluster['UserName'] = username;

        Utility.debugPrint(
            "newCluster Tilecluster api" + newCluster.toString());
        Map<String, dynamic> injectedParameters =
            await injectRequestParams(newCluster, includeLocationParams: false);
        Utility.debugPrint(
            "injectRequestParams Tilecluster api" + newCluster.toString());
        Uri uri = Uri.https(url, 'api/Cluster');
        var header = this.getHeaders();
        Utility.debugPrint("headers Tilecluster api" + newCluster.toString());
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

  Future<List<DesignatedTile>> getDesignatedTiles() async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final queryParameters = {
          'UserName': username,
          'MobileApp': true.toString()
        };
        Uri uri =
            Uri.https(url, 'api/DesignatedTile/designated', queryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }

        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (jsonResult['Content'].containsKey('designatedTiles')) {
              List designatedTilesJson =
                  jsonResult['Content']['designatedTiles'];
              List<DesignatedTile> designatedTiles = designatedTilesJson
                  .where((element) => element != null)
                  .map<DesignatedTile>((e) => DesignatedTile.fromJson(e))
                  .toList();
              return designatedTiles;
            }
          }
        }
        throw TilerError(
            message: 'Tiler disagrees with you, please try again later');
      }
    }
    throw TilerError(
        message: 'Tiler disagrees with you, please try again later');
  }

  Future updateDesignatedTile(DesignatedTile designatedTile) async {
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
        final newCluster = {};

        Utility.debugPrint(
            "newCluster Tilecluster api" + newCluster.toString());
        Map<String, dynamic> injectedParameters =
            await injectRequestParams(newCluster, includeLocationParams: false);
        Utility.debugPrint(
            "injectRequestParams Tilecluster api" + newCluster.toString());
        Uri uri = Uri.https(url, 'api/Cluster');
        var header = this.getHeaders();
        Utility.debugPrint("headers Tilecluster api" + newCluster.toString());
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
