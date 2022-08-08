import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/location.dart';

class LocationRoute extends StatefulWidget {
  Location? selectedLocation;
  Map? locationParams;
  @override
  LocationRouteState createState() => LocationRouteState();
}

class LocationRouteState extends State<LocationRoute> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = Colors.white;
  Location? selectedLocation;
  TextEditingController locationNickName = TextEditingController();

  @override
  Widget build(BuildContext context) {
    Map locationParams = ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.locationParams = locationParams;
    LocationSearchWidget locationSearchWidget = LocationSearchWidget(
      resultBoxDecoration: BoxDecoration(color: Colors.yellow),
      onChanged: (text) {
        if (this.widget.locationParams != null &&
            this.widget.locationParams!.containsKey('isFromLookup')) {
          this.widget.locationParams!['isFromLookup'] = false;
        }
      },
      onLocationSelection: (location) {
        setState(() {
          selectedLocation = location;
          this.widget.selectedLocation = location;
          if (location != null) {
            locationNickName.value = TextEditingValue(
              text: location?.description ?? '',
              selection: TextSelection.fromPosition(
                TextPosition(offset: (location?.description ?? '').length),
              ),
            );
          }
        });
      },
    );
    Widget columnOfItems = Stack(
      children: [
        Container(
          margin: EdgeInsets.fromLTRB(0, 70, 0, 0),
          child: TextField(
            controller: locationNickName,
            style: TextStyle(
                color: Color.fromRGBO(31, 31, 31, 1),
                fontSize: 20,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Location Nick Name',
              filled: true,
              isDense: true,
              contentPadding: EdgeInsets.fromLTRB(10, 15, 0, 15),
              fillColor: textBackgroundColor,
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(50.0),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
                borderSide: BorderSide(color: textBorderColor, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(
                  const Radius.circular(8.0),
                ),
                borderSide: BorderSide(
                  color: textBorderColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        Container(
          child: locationSearchWidget,
        ),
      ],
    );
    return CancelAndProceedTemplateWidget(
      child: Container(
        child: columnOfItems,
      ),
      onProceed: () {
        if (selectedLocation != null) {
          if (this.widget.locationParams != null &&
              this.widget.locationParams!.containsKey('location')) {
            this.widget.locationParams!['location'] = selectedLocation;
          }
        }
      },
    );
  }
}
