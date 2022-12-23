import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            decoration: BoxDecoration(
                color: Color.fromRGBO(31, 31, 31, 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(
              Icons.location_on_rounded,
              color: Color.fromRGBO(0, 0, 0, 0.4),
              size: 20.0,
            ),
          ),
          Text(
            addressString!,
            style: TextStyle(
                fontSize: 15,
                fontFamily: 'Rubik',
                fontWeight: FontWeight.normal,
                color: Color.fromRGBO(31, 31, 31, 1)),
          )
        ],
      ),
    );
  }
}
