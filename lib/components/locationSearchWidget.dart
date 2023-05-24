import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  Function? onChange;
  Location? selectedLocation;
  LocationApi locationNameApi = new LocationApi();
  List<Widget> locationSearchResult = [];
  TextEditingController textController = TextEditingController();
  bool isRequestEnabled = true;

  @override
  void initState() {
    super.initState();
    onChange = this.widget.onChanged;
  }

  Widget locationNameWidget(
      Location location, Function collapseResultContainer) {
    Widget retValue = Container(
      child: Text(AppLocalizations.of(context)!.noLocation),
    );

    if (location.isNotNullAndNotDefault != null) {
      print(location.description);
      List<Widget> addressChildren = [];
      if (location.description != null) {
        List<Widget> locationText = [
          FractionallySizedBox(
              alignment: FractionalOffset.center,
              widthFactor: TileStyles.inputWidthFactor,
              child: Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 10),
                  padding: EdgeInsets.fromLTRB(0, 0, 10, 0),
                  alignment: Alignment.topLeft,
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                            child: Text(
                          location.address.toString(),
                          maxLines: 1,
                          style: TextStyle(
                              fontSize: 15,
                              fontFamily: 'Rubik',
                              color: Color.fromRGBO(31, 31, 31, 1)),
                          overflow: TextOverflow.ellipsis,
                        ))
                      ])))
        ];
        if (location.address != location.description) {
          locationText.add(FractionallySizedBox(
              widthFactor: TileStyles.inputWidthFactor,
              child: Container(
                  margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                  padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                  alignment: Alignment.topLeft,
                  child: Row(children: [
                    Expanded(
                        child: Text(location.description.toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                fontSize: 15,
                                fontFamily: 'Rubik',
                                fontWeight: FontWeight.w700,
                                color: Color.fromRGBO(31, 31, 31, 1))))
                  ]))));
        }

        addressChildren.add(Stack(
          children: [
            Positioned(
                child: Icon(
                  location.source == null ||
                          location.source!.isEmpty ||
                          location.source! == 'none'
                      ? Icons.save_outlined
                      : Icons.cloud_outlined,
                  color: TileStyles.activeColor,
                ),
                top: 45,
                right: 0),
            Container(
              width: (MediaQuery.of(context).size.width *
                      TileStyles.inputWidthFactor *
                      TileStyles.inputWidthFactor) -
                  60,
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(35, 20, 0, 0),
              child: Column(
                children: locationText,
              ),
            )
          ],
        ));
      }

      retValue = FractionallySizedBox(
          widthFactor: TileStyles.inputWidthFactor,
          child: Container(
              margin: EdgeInsets.fromLTRB(5, 10, 5, 10),
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
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: Radius.circular(10),
                        bottomRight: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white70.withOpacity(0.2),
                        spreadRadius: 5,
                        blurRadius: 5,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: addressChildren,
                  ),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 5,
                    offset: Offset(0, 1),
                  ),
                ],
              )));
    }

    return retValue;
  }

  Future<List<Widget>> _onInputFieldChange(
      String name, Function collapseResultContainer) async {
    if (isRequestEnabled) {
      List<Widget> retValue = this.locationSearchResult;

      if (onChange != null) {
        onChange!(name);
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
    Color hslLightColor =
        TileStyles.primaryColorLightHSL.toColor().withLightness(0.9);
    var hslDarkColor =
        TileStyles.primaryColorDarkHSL.toColor().withLightness(0.9);
    String hintText = AppLocalizations.of(context)!.address;
    this.widget.onChanged = this._onInputFieldChange;
    if (this.widget.textField == null) {
      this.widget.textField = TextField(
        controller: textController,
        decoration: InputDecoration(
          hintText: hintText,
        ),
      );
    }
    this.widget.resultBoxDecoration = BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
          hslLightColor,
          hslLightColor,
          hslLightColor,
          hslDarkColor,
          hslDarkColor,
        ]));
    this.widget.resultMargin = EdgeInsets.fromLTRB(0, 60, 0, 20);
    return super.build(context);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
