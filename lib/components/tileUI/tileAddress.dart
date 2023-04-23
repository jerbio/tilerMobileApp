import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:tiler_app/styles.dart';

class TileAddress extends StatefulWidget {
  SubCalendarEvent subEvent;
  TileAddress(this.subEvent) {
    assert(this.subEvent != null);
  }
  @override
  TileAddressState createState() => TileAddressState();
}

class TileAddressState extends State<TileAddress> {
  @override
  Widget build(BuildContext context) {
    String? addressString = widget.subEvent.searchdDescription != null
        ? widget.subEvent.searchdDescription
        : widget.subEvent.address;
    addressString = addressString == null || addressString.trim().isEmpty
        ? widget.subEvent.addressDescription
        : addressString;
    if (addressString != null && addressString.isNotEmpty) {
      addressString =
          addressString[0].toUpperCase() + addressString.substring(1);
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
              decoration: TileStyles.tileIconContainerBoxDecoration,
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: Icon(
                Icons.location_on_rounded,
                color: TileStyles.defaultTextColor,
                size: TileStyles.tileIconSize,
              ),
            ),
            addressString != null
                ? Flexible(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                      child: Text(
                        addressString,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 15,
                            fontFamily: 'Rubik',
                            fontWeight: FontWeight.normal,
                            color: Color.fromRGBO(31, 31, 31, 1)),
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
