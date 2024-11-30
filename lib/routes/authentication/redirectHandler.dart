import 'package:flutter/material.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';

class RedirectHandler {
  static const String redirectPrefix = "rerouteapp";
  static const String paramDelimiter = "&";

  static routePage(BuildContext context, Uri? remoteUri) {
    if (remoteUri != null) {
      if (remoteUri.toString().isNotEmpty &&
          remoteUri.toString().contains(redirectPrefix)) {
        if (remoteUri.toString().toLowerCase().contains("tileshareid")) {
          _routeToTileShare(context, remoteUri.toString());
        }
      }
    }
  }

  static void _routeToTileShare(BuildContext context, String uriString) {
    var decodedString = Uri.decodeFull(uriString);
    debugPrint('decoded by id ' + decodedString);
    String uriString_lower = decodedString.toLowerCase();
    String tileShareByIdLookupString = "tileshareid=";
    if (uriString_lower.contains(tileShareByIdLookupString)) {
      int beginIndex = uriString_lower.indexOf(tileShareByIdLookupString);
      if (beginIndex > 0) {
        String paramsTileShareUri = decodedString.substring(beginIndex);
        int delimiterIndex = paramsTileShareUri.indexOf(paramDelimiter);
        if (delimiterIndex >= 0) {
          paramsTileShareUri = paramsTileShareUri.substring(delimiterIndex);
        }
        String tileShareId =
            paramsTileShareUri.substring(tileShareByIdLookupString.length);
        if (tileShareId.isNotEmpty) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      TileShareDetailWidget.byId(tileShareId: tileShareId)));
          return;
        }

        Navigator.pushNamed(context, '/TileShare');
      }
    }
  }
}
