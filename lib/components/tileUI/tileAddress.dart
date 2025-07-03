import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';

class TileAddress extends StatefulWidget {
  SubCalendarEvent subEvent;
  bool isMonthlyView;
  TileAddress(this.subEvent, {this.isMonthlyView = false}) {
    assert(this.subEvent != null);
  }
  @override
  TileAddressState createState() => TileAddressState();
}

class TileAddressState extends State<TileAddress> {
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Tuple2<bool, String> isStringUrl(String url) {
    try {
      bool retValue = Uri.parse(url).isAbsolute;
      return Tuple2(retValue, url);
    } catch (err) {
      List<String> eachUrlComponent = url.split(" ");
      if (eachUrlComponent.isNotEmpty) {
        for (var element in eachUrlComponent) {
          Tuple2<bool, String> isStringUrlTuple = isStringUrl(element);
          if (isStringUrlTuple.item1) {
            return isStringUrlTuple;
          }
        }
      }
    }
    return Tuple2(false, url);
  }

  @override
  Widget build(BuildContext context) {
    final theme= Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    bool isAddressTexturl = false;
    String? addressString = widget.subEvent.addressDescription != null
        ? widget.subEvent.addressDescription
        : widget.subEvent.address;
    addressString = addressString == null || addressString.trim().isEmpty
        ? widget.subEvent.addressDescription
        : addressString;
    if (addressString != null && addressString.isNotEmpty) {
      addressString.split(" ");
      var isStringUrlResult = isStringUrl(addressString);
      isAddressTexturl = isStringUrlResult.item1;
      if (!isAddressTexturl) {
        addressString =
            addressString[0].toUpperCase() + addressString.substring(1);
      }
    }

    return GestureDetector(
      onTap: () async {
        String? addressLookup = this.widget.subEvent.address;
        if (addressLookup == null) {
          addressLookup = this.widget.subEvent.addressDescription;
        }
        if (addressLookup == null) {
          addressLookup = this.widget.subEvent.searchdDescription;
        }
        if (addressLookup != null) {
          var isStringUrlResult = isStringUrl(addressLookup);
          isAddressTexturl = isStringUrlResult.item1;
          if (isAddressTexturl) {
            final Uri url = Uri.parse(isStringUrlResult.item2);
            await _launchUrl(url);
            return;
          }
          MapsLauncher.launchQuery(addressLookup);
        }
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: widget.isMonthlyView
                  ? TileDecorations.tileIconContainerBoxDecorationMonthly(colorScheme.onSurface)
                  : TileDecorations.tileIconContainerBoxDecoration(colorScheme.onSurface),
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: Icon(
                !isAddressTexturl
                    ? Icons.location_on_rounded
                    : Icons.link_outlined,
                color: widget.isMonthlyView
                    ? tileThemeExtension.onSurfaceVariantHighest
                    : colorScheme.onSurface,
                size: TileDimensions.tileIconSize,
              ),
            ),
            addressString != null
                ? Flexible(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                      child: Text(
                        addressString,
                        overflow: TextOverflow.ellipsis,
                        style:  TextStyle(
                            fontFamily: TileTextStyles.rubikFontName,
                            fontSize: 15
                        ),
                      ),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }
}
