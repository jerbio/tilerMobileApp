import 'package:tiler_app/services/tileShareActivityChanges.dart';
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
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class TileShareClusterApi extends AppApi {
  static const String _tag = 'TileShareClusterApi';

  TileShareClusterApi({required Function? getContextCallBack})
      : super(getContextCallBack: getContextCallBack);

  /// Report the response shape without dumping profiles, notes or credentials.
  void _logAssignmentResponse(String request, http.Response response) {
    TileShareLog.d(_tag,
        '$request -> HTTP ${response.statusCode} (${response.body.length} chars)');
    try {
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) {
        TileShareLog.d(_tag, '$request response type=${decoded.runtimeType}');
        return;
      }
      final dynamic error = decoded['Error'];
      final dynamic content = decoded['Content'];
      TileShareLog.d(
          _tag,
          '$request response keys=${decoded.keys.toList()} '
          'errorCode=${error is Map ? error['Code'] : '-'} '
          'errorMessage=${error is Map ? error['Message'] : '-'} '
          'content=${content is Map ? content.keys.toList() : content.runtimeType}');
      if (content is Map && content['designatedTiles'] is List) {
        final List rows = content['designatedTiles'];
        TileShareLog.d(_tag, '$request designatedTiles=${rows.length}');
        // Field names reveal missing/case-mismatched mobile payload fields.
        for (final row in rows.take(50)) {
          if (row is! Map) continue;
          final dynamic template = row['template'];
          final dynamic roster =
              template is Map ? template['designatedUsers'] : null;
          TileShareLog.d(
              _tag,
              '$request assignment=${row['id']} keys=${row.keys.toList()} '
              'templateKeys=${template is Map ? template.keys.toList() : template.runtimeType} '
              'rosterCount=${roster is List ? roster.length : '-'} '
              'rosterEntryKeys=${roster is List ? roster.whereType<Map>().take(1).map((u) => u.keys.toList()).toList() : []}');
        }
      }
    } catch (_) {
      TileShareLog.d(_tag, '$request response shape unavailable');
    }
  }

  /// Creates [tileCluster]; answers with the new share as the server sends
  /// it back (with its id).
  Future<TileShareClusterData> createCluster(
      TileShareClusterData tileCluster) async {
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

        final dynamic jsonResult;
        try {
          jsonResult = jsonDecode(response.body);
        } catch (_) {
          _dumpCreateFailure(response);
          rethrow;
        }
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          tileShareActivityChanges.value++;
          if (isContentInResponse(jsonResult) &&
              jsonResult['Content'] is Map<String, dynamic>) {
            return TileShareClusterData.fromJson(jsonResult['Content']);
          }
        }
        _dumpCreateFailure(response);
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          throw FormatException(error.Message!);
        } else if (jsonResult is Map && jsonResult['Message'] is String) {
          // A plain bad request ({"Message": ...}) says why: keep it.
          error.Message = jsonResult['Message'];
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
          tileShareActivityChanges.value++;
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
    final String request = 'GET api/DesignatedTile/designated '
        'cluster=$clusterId index=$index pageSize=$pageSize MobileApp=true';
    TileShareLog.d(_tag, '$request preparing');
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
          TileShareLog.d(_tag, '$request not sent: no headers');
          throw TilerError(Message: 'Issues with authentication');
        }

        TileShareLog.d(_tag, '$request sending');
        var response = await http.get(uri, headers: header);
        _logAssignmentResponse(request, response);
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
              TileShareLog.d(_tag,
                  '$request parsed assignments=${designatedTiles.length}');

              return designatedTiles;
            }
          }
        }
        TileShareLog.d(_tag,
            '$request failed: expected successful designatedTiles content');
        throw TilerError(
            Message: 'Tiler disagrees with you, please try again later');
      } else {
        TileShareLog.d(_tag, '$request not sent: no cached credentials');
      }
    } else {
      TileShareLog.d(_tag, '$request not sent: not authenticated');
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
          tileShareActivityChanges.value++;
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
    final String request = 'POST api/DesignatedTile/status '
        'id=$designatedTileId status=${invitationStatus.name}';
    TileShareLog.d(_tag, '$request preparing');
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

        Map<String, dynamic> injectedParameters = await injectRequestParams(
            updatedStatusCluster,
            includeLocationParams: false);
        Uri uri = Uri.https(url, 'api/DesignatedTile/status');
        var header = this.getHeaders();
        if (header == null) {
          TileShareLog.d(_tag, '$request not sent: no headers');
          throw TilerError(Message: 'Issues with authentication');
        }
        TileShareLog.d(_tag, '$request sending');
        var response = await httpClient
            .post(uri, headers: header, body: jsonEncode(injectedParameters))
            .timeout(
          AppApi.requestTimeout,
          onTimeout: () {
            TileShareLog.d(_tag, '$request timed out');
            throw TilerError(
                Message:
                    LocalizationService.instance.translations.requestTimeout);
          },
        );

        _logAssignmentResponse(request, response);
        var jsonResult = jsonDecode(response.body);
        error.Message = "Issues with reaching Tiler servers";
        if (isJsonResponseOk(jsonResult)) {
          tileShareActivityChanges.value++;
          if (isContentInResponse(jsonResult)) {
            var designatedTileJson = jsonResult['Content']['designatedTile'];
            if (designatedTileJson != null) {
              DesignatedTile designatedTile =
                  DesignatedTile.fromJson(designatedTileJson);
              TileShareLog.d(_tag,
                  '$request parsed id=${designatedTile.id} status=${designatedTile.invitationStatus}');
              return designatedTile;
            }
            TileShareLog.d(
                _tag, '$request succeeded without a designatedTile in content');
            return null;
          }
        }
        if (isTilerRequestError(jsonResult)) {
          var errorJson = jsonResult['Error'];
          error = TilerError.fromJson(errorJson);
          TileShareLog.d(
              _tag, '$request failed: ${TileShareLog.describe(error)}');
          throw FormatException(error.Message!);
        } else {
          error.Message = "Issues with reaching Tiler servers";
        }
      } else {
        TileShareLog.d(_tag, '$request not sent: no cached credentials');
      }
    } else {
      TileShareLog.d(_tag, '$request not sent: not authenticated');
    }
    TileShareLog.d(_tag, '$request failed: ${TileShareLog.describe(error)}');
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
          tileShareActivityChanges.value++;
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
          tileShareActivityChanges.value++;
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
        // The server confirms with code 0 and no content
        // ({"Error":{"Code":"0","Message":"Tilette deleted"},"Content":null}).
        if (isJsonResponseOk(jsonResult)) {
          tileShareActivityChanges.value++;
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

  /// A create the server did not accept, as it answered - status, headers
  /// and the whole body (an exception's details when the server sends them)
  /// - to troubleshoot from the device log (O30).
  void _dumpCreateFailure(Response response) {
    final String headers =
        response.headers.entries.map((e) => '${e.key}: ${e.value}').join('; ');
    TileShareLog.d(
        'TileShareClusterApi',
        'create failed: HTTP ${response.statusCode}\n'
            'headers: $headers\n'
            'body: ${response.body}');
  }
}
