import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/util.dart';

class LocationSearchWidget extends SearchWidget {
  Location? selectedLocation;
  Function? onLocationSelection;
  LocationSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      renderBelowTextfield = true,
      resultBoxDecoration,
      this.onLocationSelection,
      Key? key})
      : super(
            onChanged: onChanged,
            textField: textField,
            onInputCompletion: onInputCompletion,
            renderBelowTextfield: renderBelowTextfield,
            resultBoxDecoration: resultBoxDecoration,
            key: key);

  Location? otherLocation;
  @override
  LocationSearchState createState() => LocationSearchState();
}

class LocationSearchState extends SearchWidgetState {
  Function? inheritedOnChange;
  Location? selectedLocation;
  LocationApi locationNameApi = new LocationApi();
  List<Widget> locationSearchResult = [];
  TextEditingController textController = TextEditingController();
  bool isRequestEnabled = true;

  @override
  void initState() {
    super.initState();
    inheritedOnChange = this.widget.onChanged;
  }

  Widget locationNameWidget(
      Location location, Function collapseResultContainer) {
    Container retValue = Container(
      child: Text('No location'),
    );

    if (location.isNotNullAndNotDefault != null) {
      print(location.description);
      List<Widget> addressChildren = [];
      if (location.description != null) {
        addressChildren.add(Text(
          location.description.toString(),
        ));
      }

      retValue = Container(
        child: GestureDetector(
          onTap: () {
            LocationSearchWidget locationSearchWidget =
                (this.widget as LocationSearchWidget);
            setState(() {
              selectedLocation = location;
              isRequestEnabled = false;
              locationSearchWidget.selectedLocation = location;
              collapseResultContainer(selectedLocation);
              if (selectedLocation != null &&
                  selectedLocation!.address != null) {
                textController.text = selectedLocation!.address!;
              }
            });
            if (locationSearchWidget.onLocationSelection != null) {
              locationSearchWidget.onLocationSelection!(location);
            }

            Timer(const Duration(seconds: 3), () {
              Timer timer = new Timer(new Duration(seconds: 5), () {
                setState(() {
                  isRequestEnabled = true;
                });
                debugPrint("re enabled location web requests");
              });
            });
          },
          child: Container(
            color: Colors.green,
            child: Row(
              children: addressChildren,
            ),
          ),
        ),
      );
    }

    return retValue;
  }

  Future<List<Widget>> _onInputFieldChange(
      String name, Function collapseResultContainer) async {
    if (isRequestEnabled) {
      List<Widget> retValue = this.locationSearchResult;

      if (inheritedOnChange != null) {
        inheritedOnChange!(name);
      }

      if (name.length > 3) {
        List<Location> locations =
            await locationNameApi.getLocationsByName(name);
        retValue = locations
            .map((location) =>
                locationNameWidget(location, collapseResultContainer))
            .toList();
        if (retValue.length == 0) {
          retValue = [
            Container(
              child: Text('No matching location was found'),
            )
          ];
        }
      }

      setState(() {
        locationSearchResult = retValue;
      });

      return retValue;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    String hintText = 'Address';
    this.widget.onChanged = this._onInputFieldChange;
    this.widget.textField = TextField(
      controller: textController,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.arrow_back),
        hintText: hintText,
      ),
    );
    return super.build(context);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
