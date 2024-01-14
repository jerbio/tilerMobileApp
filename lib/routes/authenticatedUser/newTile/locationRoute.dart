import 'package:flutter/material.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';

import '../../../styles.dart';

class LocationRoute extends StatefulWidget {
  Location? pushedLocation;
  Map? _locationParams;
  @override
  LocationRouteState createState() => LocationRouteState();
}

class LocationRouteState extends State<LocationRoute> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = TileStyles.primaryColorLightHSL.toColor();
  Location? selectedLocation;
  TextEditingController? locationNickNameController;
  TextEditingController? locationAddressController;
  bool isLocationVerified = false;
  String? addressText;
  String? lookupNickNameText;

  onAutoSuggestedLocationTap({Location? location, bool onlyAddress = false}) {
    setState(() {
      if (location != null) {
        String nickNameDescription = location.description ?? '';
        if (onlyAddress) {
          location.description = locationNickNameController!.value.text;
          nickNameDescription = locationNickNameController!.value.text;
        }
        locationNickNameController!.value = TextEditingValue(
          text: nickNameDescription,
          selection: TextSelection.fromPosition(
            TextPosition(offset: (nickNameDescription).length),
          ),
        );

        selectedLocation = location;
        if (addressText != location.address) {
          addressText = location.address;
        }
        locationAddressController!.value = TextEditingValue(
          text: location.address ?? '',
        );
        isLocationVerified = location.isVerified ?? false;
        if (!(location.source == null ||
            location.source!.isEmpty ||
            location.source! == 'none')) {
          isLocationVerified = true;
        }
      }
    });
  }

  onNickNameTextChange(TextEditingController textController) {
    return () {
      if (textController.text != lookupNickNameText) {
        setState(() {
          lookupNickNameText = textController.text;
          selectedLocation = null;
        });
      }
    };
  }

  onAddressTextChange(TextEditingController textController) {
    return () {
      if (textController.text != addressText) {
        setState(() {
          addressText = textController.text;
          selectedLocation = null;
          isLocationVerified = false;
        });
      }
    };
  }

  Widget renderNickNameDefaultButton(Location location,
      {IconData? iconData, bool isEnabled = true, bool isSelected = false}) {
    String locationText = location.description!.capitalize();
    Icon defaultLocationIcon = Icon(
      iconData ?? Icons.location_pin,
      color: isEnabled ? (isSelected ? Colors.white : null) : Colors.white,
    );

    Widget retValue = ElevatedButton.icon(
      onPressed: () {
        if (!isEnabled) {
          return;
        }

        TextEditingController locationNickNameControllerUpdate =
            TextEditingController(text: location.description ?? '');
        TextEditingController locationAddressControllerUpdate =
            TextEditingController(text: location.address ?? '');
        locationNickNameControllerUpdate.addListener(
            onNickNameTextChange(locationNickNameControllerUpdate));
        locationAddressControllerUpdate
            .addListener(onAddressTextChange(locationAddressControllerUpdate));
        setState(() {
          selectedLocation = location;
          locationAddressController = locationAddressControllerUpdate;
          locationNickNameController = locationNickNameControllerUpdate;
        });
      },
      style: isEnabled
          ? (isSelected
              ? TileStyles.selectedButtonStyle
              : TileStyles.enabledButtonStyle)
          : TileStyles.disabledButtonStyle,
      icon: defaultLocationIcon,
      label: Text(locationText),
    );

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    Map? locationParams = ModalRoute.of(context)?.settings.arguments as Map?;
    if (locationParams != null && this.widget._locationParams == null) {
      this.widget._locationParams = locationParams;
    }

    if (this.widget._locationParams != null &&
        this.widget._locationParams!.containsKey('location') &&
        this.widget.pushedLocation == null) {
      this.widget.pushedLocation = this.widget._locationParams!['location'];
      locationAddressController = new TextEditingController(
          text: this.widget.pushedLocation!.address ?? '');
      locationNickNameController = new TextEditingController(
          text: this.widget.pushedLocation!.description ?? '');
      selectedLocation = this.widget.pushedLocation;
      locationNickNameController!
          .addListener(onNickNameTextChange(locationNickNameController!));
      locationAddressController!
          .addListener(onAddressTextChange(locationAddressController!));
    }

    if (locationNickNameController == null) {
      locationNickNameController = TextEditingController();
      locationNickNameController!
          .addListener(onNickNameTextChange(locationNickNameController!));
    }
    if (locationAddressController == null) {
      locationAddressController = TextEditingController();
      locationAddressController!
          .addListener(onAddressTextChange(locationAddressController!));
    }

    TextField addressTextField = TextField(
      style: TileStyles.fullScreenTextFieldStyle,
      decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.address,
          filled: true,
          isDense: true,
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          fillColor: Colors.transparent,
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent),
          ),
          focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textBorderColor, width: 1)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: textBorderColor.withLightness(0.8), width: 1))),
      controller: locationAddressController,
    );

    Widget locationSearchWidget = FractionallySizedBox(
        alignment: FractionalOffset.center,
        widthFactor: TileStyles.inputWidthFactor,
        child: LocationSearchWidget(
            onChanged: (address) {
              onAddressTextChange(locationAddressController!);
            },
            textField: addressTextField,
            onLocationSelection: onAutoSuggestedLocationTap));
    List<Widget> routeStackWidgets = <Widget>[
      Align(
          alignment: Alignment.center,
          child: FractionallySizedBox(
              widthFactor: TileStyles.inputWidthFactor,
              child: Container(
                alignment: Alignment.topCenter,
                margin: EdgeInsets.fromLTRB(0, 90, 0, 0),
                child: TextField(
                  controller: locationNickNameController,
                  style: TileStyles.fullScreenTextFieldStyle,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.nickName,
                    filled: true,
                    isDense: true,
                    contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
                    fillColor: Colors.transparent,
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide:
                            BorderSide(color: textBorderColor, width: 1)),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: textBorderColor.withLightness(0.8),
                            width: 1)),
                  ),
                ),
              ))),
      Container(
        alignment: Alignment.topCenter,
        child: locationSearchWidget,
      ),
    ];

    Location? homeLocation = Location.fromDefault();
    homeLocation.description = AppLocalizations.of(context)!.home;
    homeLocation.address = '';
    Location? workLocation = Location.fromDefault();
    workLocation.description = AppLocalizations.of(context)!.work;
    workLocation.address = '';
    List<Widget> defaultLocationFields = <Widget>[];
    if (this.widget._locationParams != null &&
        this.widget._locationParams!.containsKey('defaults') &&
        this.widget._locationParams!['defaults'] != null &&
        this.widget._locationParams!['defaults'].isNotEmpty) {
      for (Location eachLocation in this.widget._locationParams!['defaults']) {
        if (eachLocation.description!.toLowerCase() ==
            Location.homeLocationNickName.toLowerCase()) {
          homeLocation = eachLocation;
          continue;
        }
        if (eachLocation.description!.toLowerCase() ==
            Location.workLocationNickName.toLowerCase()) {
          workLocation = eachLocation;
          continue;
        }
        defaultLocationFields.add(renderNickNameDefaultButton(eachLocation));
      }
    }
    if (workLocation != null) {
      defaultLocationFields.add(renderNickNameDefaultButton(workLocation,
          iconData: Icons.work,
          isEnabled: workLocation.isNotNullAndNotDefault,
          isSelected: workLocation.description == null
              ? false
              : workLocation.description!.toLowerCase() ==
                  (locationNickNameController!.text).toLowerCase()));
    }
    if (homeLocation != null) {
      defaultLocationFields.insert(
          0,
          renderNickNameDefaultButton(homeLocation,
              iconData: Icons.home,
              isEnabled: homeLocation.isNotNullAndNotDefault,
              isSelected: homeLocation.description == null
                  ? false
                  : homeLocation.description!.toLowerCase() ==
                      (locationNickNameController!.text).toLowerCase()));
    }
    Widget rowOfDefaults = Container(
      margin: EdgeInsets.fromLTRB(0, 180, 0, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: defaultLocationFields,
      ),
    );
    // This needs to be inserted before the address field.
    // This is so the auto complete result from the address search will have
    // the default  Z-index positioning
    routeStackWidgets.insert(0, rowOfDefaults);

    Widget columnOfItems = Stack(
      children: routeStackWidgets,
    );
    return CancelAndProceedTemplateWidget(
      child: Container(
        child: columnOfItems,
      ),
      onProceed: () {
        String locationNickNameText = "";
        if (locationNickNameController!.text.isNotEmpty) {
          locationNickNameText = locationNickNameController!.text;
        }

        String? addressText = this.lookupNickNameText;
        if (locationAddressController!.text.isNotEmpty) {
          addressText = locationAddressController!.text;
        }

        if (selectedLocation == null) {
          selectedLocation = Location.fromDefault();

          if (addressText == null) {
            addressText = '';
          }

          selectedLocation!.description = locationNickNameText;
          selectedLocation!.address = addressText;
          if (addressText.isNotEmpty || locationNickNameText.isNotEmpty) {
            selectedLocation!.isDefault = false;
            selectedLocation!.isNull = false;
          }
          selectedLocation!.isVerified = this.isLocationVerified;
        }

        if (selectedLocation!.description != locationNickNameText) {
          selectedLocation!.id = '';
        }

        if (this.widget._locationParams != null &&
            this.widget._locationParams!.containsKey('location')) {
          this.widget._locationParams!['location'] = selectedLocation;
        }
      },
    );
  }
}
