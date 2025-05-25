import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/searchComponent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../constants.dart' as Constants;

class LocationSearchWidget extends SearchWidget {
  Location? selectedLocation;
  Function? onLocationSelection;
  final bool? includeDeviceLocation;
  LocationSearchWidget(
      {onChanged,
      textField,
      onInputCompletion,
      listView,
      this.includeDeviceLocation = true,
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
  late LocationApi locationNameApi;
  List<Widget> locationSearchResult = [];
  TextEditingController textController = TextEditingController();
  bool isRequestEnabled = true;

  @override
  void initState() {
    super.initState();
    print("new location search widget state created");
    locationNameApi = LocationApi(getContextCallBack: () => this.context);
    onChange = this.widget.onChanged;
  }

  onLocationTap(collapseResultContainer,
      {Location? location, bool onlyAddress = false}) {
    return () {
      LocationSearchWidget locationSearchWidget =
          (this.widget as LocationSearchWidget);
      setState(() {
        selectedLocation = location;
        isRequestEnabled = false;
        locationSearchWidget.selectedLocation = location;
        collapseResultContainer(selectedLocation);
        if (selectedLocation != null && selectedLocation!.address != null) {
          textController.text = selectedLocation!.address!;
        }
      });
      if (locationSearchWidget.onLocationSelection != null) {
        locationSearchWidget.onLocationSelection!(
            location: location, onlyAddress: onlyAddress);
      }

      Timer(const Duration(seconds: 1), () {
        Timer timer = new Timer(new Duration(seconds: 2), () {
          if (!mounted) return;
          setState(() {
            isRequestEnabled = true;
          });
          debugPrint("re enabled location web requests");
        });
      });
    };
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
                              fontFamily: TileTextStyles.rubikFontName,
                              color: Color.fromRGBO(31, 31, 31, 1)),
                          overflow: TextOverflow.ellipsis,
                        ))
                      ])))
        ];
        if (location.address != location.description) {
          locationText.add(FractionallySizedBox(
              widthFactor: TileStyles.inputWidthFactor * 0.75,
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
            Container(
              width: (MediaQuery.of(context).size.width *
                      TileStyles.inputWidthFactor) -
                  95,
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.fromLTRB(20, 20, 0, 0),
              child: Column(
                children: locationText,
              ),
            ),
            Positioned(
              top: 36,
              right: 0,
              child: Row(
                children: [
                  Icon(
                    location.source == null ||
                            location.source!.isEmpty ||
                            location.source! == 'none'
                        ? Icons.save_outlined
                        : Icons.cloud_outlined,
                    color: TileColors.activeColor,
                  ),
                  IconButton(
                      onPressed: onLocationTap(collapseResultContainer,
                          location: location, onlyAddress: true),
                      icon: Icon(
                        Icons.business,
                        color: TileColors.activeColor,
                      ))
                ],
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
                onTap:
                    onLocationTap(collapseResultContainer, location: location),
                child: Container(
                  height: 100,
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
      List<Widget> retValue = [
        Container(
          padding: EdgeInsets.all(10),
          child: Text(
              AppLocalizations.of(this.context)!.atLeastThreeLettersForLookup),
          alignment: Alignment.center,
        )
      ];

      if (onChange != null) {
        onChange!(name);
      }

      if (name.length > Constants.autoCompleteMinCharLength) {
        bool includeLocationParams = false;
        if (this.widget is LocationSearchWidget) {
          includeLocationParams =
              (this.widget as LocationSearchWidget).includeDeviceLocation!;
        }
        List<Location> locations = await locationNameApi.getLocationsByName(
            name,
            includeLocationParams: includeLocationParams);
        retValue = locations
            .map((location) =>
                locationNameWidget(location, collapseResultContainer))
            .toList();
        if (retValue.length == 0) {
          retValue = [
            Container(
              padding: EdgeInsets.all(10),
              child: Text(
                  AppLocalizations.of(this.context)!.noLocationMatchWasFound),
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
    TileColors.primaryColorLightHSL.toColor(); //.withLightness(0.9);
    var hslDarkColor =
    TileColors.primaryColorDarkHSL.toColor().withLightness(0.9);
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
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10)),
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
    this.widget.resultMargin = EdgeInsets.fromLTRB(0, 75, 0, 20);
    return super.build(context);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
