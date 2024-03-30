import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

import '../../styles.dart';

class LocationAccessWidget extends StatefulWidget {
  LocationAccessWidget(this.accessManager, this.onChange);
  final AccessManager? accessManager;
  final Function? onChange;
  @override
  LocationAccessWidgetState createState() => LocationAccessWidgetState();
}

class LocationAccessWidgetState extends State<LocationAccessWidget> {
  late AccessManager accessManager;
  Tuple3<Position, bool, bool> locationAccess =
      Tuple3(Utility.getDefaultPosition(), false, true);
  bool isLocationRequestTriggered = false;
  @override
  void initState() {
    super.initState();
    accessManager = this.widget.accessManager ?? AccessManager();
  }

  VoidCallback generateCallBack(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool denyAccess = false,
      bool doNotCallAgain = false}) {
    VoidCallback retValue = () async => {
          await accessManager
              .locationAccess(
                  forceDeviceCheck: forceDeviceCheck,
                  statusCheck: statusCheck,
                  denyAccess: false)
              .then((value) {
            setState(() {
              if (value != null) {
                locationAccess = value;
                isLocationRequestTriggered = true;
                if (this.widget.onChange != null) {
                  this.widget.onChange!(value);
                }
                return;
              }
              if (!doNotCallAgain) {
                generateCallBack(
                    forceDeviceCheck: true, doNotCallAgain: true)();
              }
            });
          })
        };

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    const lottieAsset = 'assets/lottie/car-on-the-road.json';
    const double buttonWidth = 200;

    var acceptDenyButtons = <Widget>[
      Container(
        margin: EdgeInsets.fromLTRB(0, 300, 0, 0),
        child: SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
              onPressed: generateCallBack(forceDeviceCheck: true),
              child: Text(AppLocalizations.of(context)!.allow,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w400,
                  ))),
        ),
      ),
      Container(
        margin: EdgeInsets.fromLTRB(0, 430, 0, 0),
        child: SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              onPressed: generateCallBack(denyAccess: false),
              child: Text(AppLocalizations.of(context)!.deny,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w400,
                  ))),
        ),
      )
    ];

    if (Platform.isIOS) {
      acceptDenyButtons = [
        Container(
          margin: EdgeInsets.fromLTRB(0, 430, 0, 0),
          child: SizedBox(
            width: buttonWidth,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: () {
                  if (this.widget.onChange != null) {
                    this.widget.onChange!(locationAccess);
                  }
                },
                child: Text(AppLocalizations.of(context)!.dismiss,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: TileStyles.rubikFontName,
                      fontWeight: FontWeight.w400,
                    ))),
          ),
        )
      ];
      generateCallBack(denyAccess: false)();
    }

    Widget retValue = Scaffold(
      body: Center(
        child: Container(
          color: TileStyles.primaryColorLightHSL.toColor(),
          alignment: Alignment.center,
          width: MediaQuery.of(context).size.width * TileStyles.tileWidthRatio,
          height:
              MediaQuery.of(context).size.height * TileStyles.tileWidthRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 400),
                padding: EdgeInsets.all(30),
                width: MediaQuery.of(context).size.width *
                    TileStyles.tileWidthRatio,
                child: Text(
                    AppLocalizations.of(context)!.allowAccessDescription,
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: TileStyles.rubikFontName,
                        fontWeight: FontWeight.w400,
                        color: Colors.white)),
              ),
              Container(
                child: Lottie.asset(lottieAsset, height: 150),
              ),
              ...acceptDenyButtons
            ],
          ),
        ),
      ),
    );

    return retValue;
  }
}
