import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'dart:convert';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/request/contactModel.dart';
import 'package:tiler_app/services/api/appApi.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class DesignatedTileApi extends AppApi {
  DesignatedTileApi({required Function getContextCallBack})
      : super(getContextCallBack: getContextCallBack);
  Future addContact(String designatedTileId, ContactModel contactModel) async {
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
        final contactUpdate = {
          'EntityId': designatedTileId,
          'Contact': contactModel.toJson()
        };

        Utility.debugPrint("contactUpdate Designated Tile Template api" +
            contactUpdate.toString());
        Map<String, dynamic> injectedParameters = await injectRequestParams(
            contactUpdate,
            includeLocationParams: false);
        Utility.debugPrint("injectRequestParams Designated Tile Template api" +
            contactUpdate.toString());
        Uri uri = Uri.https(url, 'api/TileshareTemplate/contact');
        var header = this.getHeaders();
        Utility.debugPrint(
            "headers Tilecluster api" + contactUpdate.toString());
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await http.put(uri,
            headers: header, body: jsonEncode(injectedParameters));

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

  Future deleteContact(
      String designatedTileId, ContactModel contactModel) async {
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
        final contactUpdate = {
          'EntityId': designatedTileId,
          'Email': contactModel.Email,
          'PhoneNumber': contactModel.PhoneNumber,
        };

        Utility.debugPrint("contactUpdate deleting Contact via api" +
            contactUpdate.toString());
        Map<String, dynamic> injectedParameters = await injectRequestParams(
            contactUpdate,
            includeLocationParams: false);
        Utility.debugPrint("injectRequestParams Designated Tile Template api" +
            contactUpdate.toString());
        Uri uri = Uri.https(url, 'api/DesignatedTile/contact');
        var header = this.getHeaders();
        Utility.debugPrint(
            "headers Tilecluster api" + contactUpdate.toString());
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }
        var response = await http.delete(uri,
            headers: header, body: jsonEncode(injectedParameters));

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

  Future<List<DesignatedTile>> getDesignatedTiles(
      {int index = 0,
      int pageSize = 50,
      String? designatedTileId,
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
        if (designatedTileId.isNot_NullEmptyOrWhiteSpace()) {
          queryParameters["DesignatedTileTemplateId"] = designatedTileId!;
        }

        if (isOutbox != null) {
          queryParameters["IsOutbox"] = isOutbox.toString();
        }
        Uri uri =
            Uri.https(url, 'api/DesignatedTile/designated', queryParameters);

        var header = this.getHeaders();
        if (header == null) {
          throw TilerError(Message: 'Issues with authentication');
        }

        Response response = await http.get(uri, headers: header);
        HandleHttpStatusFailure(response);
        var jsonResult = jsonDecode(response.body);
        if (isJsonResponseOk(jsonResult)) {
          if (isContentInResponse(jsonResult)) {
            if (designatedTileId.isNot_NullEmptyOrWhiteSpace()) {
              String designatedTileKey = 'designatedTile';
              if (jsonResult['Content'].containsKey(designatedTileKey)) {
                DesignatedTile designatedTilesJson = DesignatedTile.fromJson(
                    jsonResult['Content'][designatedTileKey]);
                return <DesignatedTile>[designatedTilesJson];
              }
            } else {
              String designatedTileKey = 'designatedTiles';
              if (jsonResult['Content'].containsKey(designatedTileKey)) {
                List designatedTilesJson =
                    jsonResult['Content'][designatedTileKey];
                List<DesignatedTile> designatedTiles = designatedTilesJson
                    .where((element) => element != null)
                    .map<DesignatedTile>((e) => DesignatedTile.fromJson(e))
                    .toList();
                return designatedTiles;
              }
            }
          }
        }
        throw TilerError(Message: 'Issues reaching Tiler Servers');
      }
    }
    throw TilerError(Message: 'Issues reaching Tiler Servers');
  }
}
