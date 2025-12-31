import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/clusterTemplateTileModel.dart';
import 'package:tiler_app/data/request/tileShareClusterModel.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class TileShareClusterApi extends AppApi {
  TileShareClusterApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future createCluster(TileShareClusterData tileCluster) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final newCluster = tileCluster.toTemplateClusterModel().toJson();

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
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .post(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            return;
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }

  Future<DesignatedTile> createDesignatedTileTemplate(
      ClusterTemplateTileModel templateTileModel) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final newCluster = templateTileModel.toJson();

        Utility.debugPrint(
            "newCluster Tilecluster api" + newCluster.toString());
        Map<String, dynamic> injectedParameters =
            await injectRequestParams(newCluster, includeLocationParams: false);
        Utility.debugPrint(
            "injectRequestParams Tilecluster api" + newCluster.toString());
        Uri uri = Uri.https(url, 'api/DesignatedTile');
        var header = this.getHeaders();
        Utility.debugPrint("headers Tilecluster api" + newCluster.toString());
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .post(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (jsonResult['Content'].containsKey('tileTemplate')) {
              Map<String, dynamic> designatedTilesJson =
                  jsonResult['Content']['tileTemplate'];
              DesignatedTile designatedTiles =
                  DesignatedTile.fromJson(designatedTilesJson);
              return designatedTiles;
            }
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
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
          throw TilerError(Message: 'Issues with authentication');
        }

        var response = await http.get(uri, headers: header);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            Utility.debugPrint("We have a result");
            print(jsonResult);
            if (jsonResult['Content'].containsKey('designatedTiles')) {
              List designatedTilesJson =
                  jsonResult['Content']['designatedTiles'];
              List<DesignatedTile> designatedTiles = designatedTilesJson
                  .where((element) => element != null)
                  .map<DesignatedTile>((e) => DesignatedTile.fromJson(e))
                  .toList();
              print("jsonParseComplete");
              print(designatedTiles);

              return designatedTiles;
            }
          }
        }
        throw TilerError(
            Message: 'Tiler disagrees with you, please try again later');
      }
    }
    throw TilerError(
        Message: 'Tiler disagrees with you, please try again later');
  }

  Future<List<TileShareTemplate>> getTileShareTemplates(
      {String? tileShareTemplateId, String? clusterId, String? Format}) async {
    if ((await this.authentication.isUserAuthenticated()).item1) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final queryParameters = {
          'Id': tileShareTemplateId,
          'TileShareClusterId': clusterId,
          'Format': Format
        };

        Uri uri = Uri.https(url, 'api/TileshareTemplate', queryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }

        var response = await httpClient.get(uri, headers: header).timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (jsonResult['Content'].containsKey('tileShareTemplates')) {
              List designatedTilesJson =
                  jsonResult['Content']['tileShareTemplates'];
              List<TileShareTemplate> designatedTiles = designatedTilesJson
                  .where((element) => element != null)
                  .map<TileShareTemplate>((e) => TileShareTemplate.fromJson(e))
                  .toList();
              return designatedTiles;
            }

            if (jsonResult['Content'].containsKey('tileShareTemplate')) {
              return [
                TileShareTemplate.fromJson(
                    jsonResult['Content']['tileShareTemplate'])
              ];
            }
          }
        }
        throw TilerError(
            Message: 'Tiler disagrees with you, please try again later');
      }
    }
    throw TilerError(
        Message: 'Tiler disagrees with you, please try again later');
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
          throw TilerError(Message: 'Issues with authentication');
        }

        Response response = await httpClient.get(uri, headers: header).timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );
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
            Message: 'Tiler disagrees with you, please try again later');
      }
    }
    throw TilerError(
        Message: 'Tiler disagrees with you, please try again later');
  }

  Future<TileShareClusterData> updateTileShareCluster(
      TileShareClusterModel tileShareClusterModel) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final newCluster = tileShareClusterModel.toJson();

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
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .put(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            String clusterKey = 'cluster';
            if (jsonResult['Content'].containsKey(clusterKey)) {
              Map<String, dynamic> tileShareClusterJson =
                  jsonResult['Content'][clusterKey];
              return TileShareClusterData.fromJson(tileShareClusterJson);
            }
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }

  Future<DesignatedTile?> statusUpdate(
      String designatedTileId, InvitationStatus invitationStatus) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
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
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .post(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
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
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }

  Future<TileShareTemplate> updateTileShareTemplate(
      ClusterTemplateTileModel templateTileModel) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final newCluster = templateTileModel.toJson();

        Utility.debugPrint(
            "Stringified TileShareTemplate api" + newCluster.toString());
        Map<String, dynamic> injectedParameters =
            await injectRequestParams(newCluster, includeLocationParams: false);
        Utility.debugPrint("injectRequestParams TileShareTemplate api" +
            newCluster.toString());
        Uri uri = Uri.https(url, 'api/TileShareTemplate');
        var header = this.getHeaders();
        Utility.debugPrint(
            "headers TileShareTemplate api" + newCluster.toString());
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .put(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (jsonResult['Content'].containsKey('tileShareTemplate')) {
              Map<String, dynamic> designatedTilesJson =
                  jsonResult['Content']['tileShareTemplate'];
              return TileShareTemplate.fromJson(designatedTilesJson);
            }
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }

  Future deleteCluster(String clusterId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final deleteclusterUpdate = {'ClusterId': clusterId};

        Map<String, dynamic> injectedParameters = await injectRequestParams(
            deleteclusterUpdate,
            includeLocationParams: false);

        Uri uri = Uri.https(url, 'api/TileShareCluster');
        var header = this.getHeaders();

        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .delete(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          return;
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }

  Future deleteTileShareTemplate(String tileShareTemplateId) async {
    TilerError error = new TilerError();
    error.Message = "Did not send request";
    bool userIsAuthenticated = true;
    userIsAuthenticated =
        (await this.authentication.isUserAuthenticated()).item1;
    if (userIsAuthenticated) {
      await checkAndReplaceCredentialCache();
      String tilerDomain = Constants.tilerDomain;
      String url = tilerDomain;
      if (this.authentication.cachedCredentials != null) {
        final contactUpdate = {'Id': tileShareTemplateId};
        Map<String, dynamic> injectedParameters = await injectRequestParams(
            contactUpdate,
            includeLocationParams: false);
        Uri uri = Uri.https(url, 'api/TileshareTemplate');
        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await httpClient
            .delete(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            return;
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      }
    }
    throw error;
  }
}
