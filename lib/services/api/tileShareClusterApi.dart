import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class TileShareClusterApi extends AppApi {
  Future createCluster(TileShareClusterData tileCluster) async {
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
        Uri uri = Uri.https(url, 'api/TileShareCluster');
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

  Future<List<DesignatedTile>> getDesignatedTiles(
      {int index = 0, int pageSize = 50, String? clusterId}) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final queryParameters = {
          'UserName': username,
          'MobileApp': true.toString(),
          'PageSize': pageSize.toString(),
          'Index': index.toString()
        };
        if (clusterId.isNot_NullEmptyOrWhiteSpace()) {
          queryParameters["ClusterId"] = clusterId!;
        }
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

  Future<List<TileShareClusterData>> getTileShareClusters(
      {int index = 0,
      int pageSize = 50,
      String? clusterId,
      bool? isOutbox}) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        String? username = '';
        final queryParameters = {
          'UserName': username,
          'MobileApp': true.toString(),
          'PageSize': pageSize.toString(),
          'Index': index.toString()
        };
        if (clusterId.isNot_NullEmptyOrWhiteSpace()) {
          queryParameters["ClusterId"] = clusterId!;
        }

        if (isOutbox != null) {
          queryParameters["IsOutbox"] = isOutbox.toString();
        }
        Uri uri = Uri.https(url, 'api/TileShareCluster', queryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }

        Response response = await http.get(uri, headers: header);
        HandleHttpStatusFailure(response);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (clusterId.isNot_NullEmptyOrWhiteSpace()) {
              String clusterKey = 'cluster';
              if (jsonResult['Content'].containsKey(clusterKey)) {
                TileShareClusterData designatedTilesJson =
                    TileShareClusterData.fromJson(
                        jsonResult['Content'][clusterKey]);
                return <TileShareClusterData>[designatedTilesJson];
              }
            } else {
              String clusterKey = 'clusters';
              if (jsonResult['Content'].containsKey(clusterKey)) {
                List designatedTilesJson = jsonResult['Content'][clusterKey];
                List<TileShareClusterData> designatedTiles = designatedTilesJson
                    .where((element) => element != null)
                    .map<TileShareClusterData>(
                        (e) => TileShareClusterData.fromJson(e))
                    .toList();
                return designatedTiles;
              }
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

  Future<DesignatedTile?> statusUpdate(
      String designatedTileId, InvitationStatus invitationStatus) async {
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
        final updatedStatusCluster = {
          "Id": designatedTileId,
          "Status": invitationStatus.name.toString()
        };

        Utility.debugPrint(
            "Designated tile update" + updatedStatusCluster.toString());
        Map<String, dynamic> injectedParameters = await injectRequestParams(
            updatedStatusCluster,
            includeLocationParams: false);
        Utility.debugPrint("injectRequestParams Tilecluster api" +
            updatedStatusCluster.toString());
        Uri uri = Uri.https(url, 'api/DesignatedTile/status');
        var header = this.getHeaders();
        Utility.debugPrint(
            "headers Tilecluster api" + updatedStatusCluster.toString());
        if (header == null) {
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.post(uri,
            headers: header, body: jsonEncode(injectedParameters));

        var jsonResult = jsonDecode(response.body);
        error.message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            var designatedTileJson = jsonResult['Content']['designatedTile'];
            if (designatedTileJson != null) {
              DesignatedTile designatedTile =
                  DesignatedTile.fromJson(designatedTileJson);
              return designatedTile;
            }
            return null;
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
