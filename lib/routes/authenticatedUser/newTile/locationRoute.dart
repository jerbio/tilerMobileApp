import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/locationSearchWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/location.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../styles.dart';

class LocationRoute extends StatefulWidget {
  Location? pushedLocation;
  Map? locationParams;
  @override
  LocationRouteState createState() => LocationRouteState();
}

class LocationRouteState extends State<LocationRoute> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = Colors.white;
  Location? selectedLocation;
  TextEditingController? locationNickNameController;
  TextEditingController? locationAddressController;
  String? lookupNickNameText;

  @override
  Widget build(BuildContext context) {
    Map locationParams = ModalRoute.of(context)?.settings.arguments as Map;
    this.widget.locationParams = locationParams;
    var onTextChange = (textController) {
      return () {
        if (this.widget.locationParams != null &&
            this.widget.locationParams!.containsKey('isFromLookup')) {
          this.widget.locationParams!['isFromLookup'] = false;
        }
        setState(() {
          lookupNickNameText = textController.text;
          selectedLocation = null;
        });
      };
    };
    if (this.widget.locationParams != null &&
        this.widget.locationParams!.containsKey('location') &&
        this.widget.pushedLocation == null) {
      this.widget.pushedLocation = this.widget.locationParams!['location'];
      locationAddressController = new TextEditingController(
          text: this.widget.pushedLocation!.address ?? '');
      locationNickNameController = new TextEditingController(
          text: this.widget.pushedLocation!.description ?? '');
      selectedLocation = this.widget.pushedLocation;
      locationNickNameController!
          .addListener(onTextChange(locationNickNameController));
      locationAddressController!
          .addListener(onTextChange(locationAddressController));
    }

    if (locationNickNameController == null) {
      locationNickNameController = TextEditingController();
      locationNickNameController!
          .addListener(onTextChange(locationNickNameController));
    }
    if (locationAddressController == null) {
      locationAddressController = TextEditingController();
      locationAddressController!
          .addListener(onTextChange(locationAddressController));
    }

    TextField addressTextField = TextField(
      style: TileStyles.fullScreenTextFieldStyle,
      decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.address,
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
          )),
      controller: locationAddressController,
    );

    Widget locationSearchWidget = FractionallySizedBox(
        alignment: FractionalOffset.center,
        widthFactor: TileStyles.inputWidthFactor,
        child: LocationSearchWidget(
          onChanged: onTextChange,
          textField: addressTextField,
          onLocationSelection: (location) {
            setState(() {
              selectedLocation = location;
              if (location != null) {
                locationNickNameController!.value = TextEditingValue(
                  text: location?.description ?? '',
                  selection: TextSelection.fromPosition(
                    TextPosition(offset: (location?.description ?? '').length),
                  ),
                );
                locationAddressController!.value = TextEditingValue(
                  text: location?.address ?? '',
                );
              }
            });
          },
        ));
    Widget columnOfItems = Stack(
      children: [
        Align(
            alignment: Alignment.center,
            child: FractionallySizedBox(
                widthFactor: TileStyles.inputWidthFactor,
                child: Container(
                  alignment: Alignment.topCenter,
                  margin: EdgeInsets.fromLTRB(0, 80, 0, 0),
                  child: TextField(
                    controller: locationNickNameController,
                    style: TileStyles.fullScreenTextFieldStyle,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.locationNickName,
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
        }

        if (selectedLocation!.description != locationNickNameText) {
          selectedLocation!.id = '';
        }

        if (this.widget.locationParams != null &&
            this.widget.locationParams!.containsKey('location')) {
          this.widget.locationParams!['location'] = selectedLocation;
        }
      },
    );
  }
}
