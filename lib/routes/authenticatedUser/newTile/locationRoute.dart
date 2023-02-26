import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../styles.dart';

class LocationRoute extends StatefulWidget {
  Location? pushedLocation;
  Map? _locationParams;
  @override
  LocationRouteState createState() => LocationRouteState();
}

class LocationRouteState extends State<LocationRoute> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = Colors.white;
  Location? selectedLocation;
  TextEditingController? locationNickNameController;
  TextEditingController? locationAddressController;
  bool isLocationVerified = false;
  String? addressText;
  String? lookupNickNameText;

  onAutoSuggestedLocationTap(Location? location) {
    setState(() {
      selectedLocation = location;
      if (location != null) {
        locationNickNameController!.value = TextEditingValue(
          text: location.description ?? '',
          selection: TextSelection.fromPosition(
            TextPosition(offset: (location.description ?? '').length),
          ),
        );
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
          )),
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
    Widget columnOfItems = Stack(
      children: [
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
                        borderSide:
                            BorderSide(color: textBorderColor, width: 2),
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
                ))),
        Container(
          alignment: Alignment.topCenter,
          child: locationSearchWidget,
        ),
      ],
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
