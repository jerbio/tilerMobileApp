import 'package:http/http.dart' as http;
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
    error.message = "Did not send request";
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
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.put(uri,
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

  Future deleteContact(
      String designatedTileId, ContactModel contactModel) async {
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
          throw TilerError(message: 'Issues with authentication');
        }
        var response = await http.delete(uri,
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
}
