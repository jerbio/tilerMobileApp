import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

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
  LocationProfile locationAccess = LocationProfile.empty();
  bool isLocationRequestTriggered = false;
  @override
  void initState() {
    super.initState();
    accessManager = this.widget.accessManager ?? AccessManager();
    if (Platform.isIOS) {
      // this is needed because we want to trigger the native permission UI only for iOS.
      //If this is added to the build function it'll cause an infinite call to setState.
      generateCallBack(denyAccess: false, enableCallBack: false)();
    }
  }

  VoidCallback generateCallBack(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool? denyAccess,
      bool doNotCallAgain = false,
      bool enableCallBack = true}) {
    VoidCallback retValue = () async {
      setState(() {
        isLocationRequestTriggered = true;
      });
      await accessManager
          .locationAccess(
              forceDeviceCheck: forceDeviceCheck,
              statusCheck: statusCheck,
              denyAccess: denyAccess ?? false)
          .then((value) {
        print('LocationAccessWidgetState.generateCallBack: value: $value');
        String loadedId = Utility.getUuid;
        if (BlocProvider.of<DeviceSettingBloc>(context)
                is DeviceLocationSettingLoading &&
            (BlocProvider.of<DeviceSettingBloc>(context)
                        as DeviceLocationSettingLoading)
                    .id !=
                null) {
          loadedId = (BlocProvider.of<DeviceSettingBloc>(context)
                  as DeviceLocationSettingLoading)
              .id!;
        } else {
          print('Not DeviceLocationSettingLoading');
        }
        BlocProvider.of<DeviceSettingBloc>(context).add(
            LoadedLocationProfileDeviceSettingEvent(
                deviceLocationProfile: value ?? LocationProfile.empty(),
                id: loadedId));

        if (!mounted) return;

        setState(() {
          if (value != null) {
            locationAccess = value;
            if (this.widget.onChange != null && enableCallBack) {
              this.widget.onChange!(value);
            }
            return;
          }
          if (!doNotCallAgain) {
            generateCallBack(forceDeviceCheck: true, doNotCallAgain: true)();
          }
        });
      }).catchError((error) {
        print('LocationAccessWidgetState.generateCallBack: error: $error');
      });
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
                    fontFamily: TileTextStyles.rubikFontName,
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
              onPressed: generateCallBack(denyAccess: true),
              child: Text(AppLocalizations.of(context)!.deny,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 25,
                    fontFamily: TileTextStyles.rubikFontName,
                    fontWeight: FontWeight.w400,
                  ))),
        ),
      )
    ];
    if (isLocationRequestTriggered) {
      acceptDenyButtons = [
        Container(
            margin: EdgeInsets.fromLTRB(0, 300, 0, 0),
            child: CircularProgressIndicator())
      ];
    }

    if (Platform.isIOS) {
      var iosCallBackButtonPress =
          generateCallBack(denyAccess: false, forceDeviceCheck: true);
      acceptDenyButtons = [
        Container(
          margin: EdgeInsets.fromLTRB(0, 430, 0, 0),
          child: SizedBox(
            width: buttonWidth,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                onPressed: iosCallBackButtonPress,
                child: Text(AppLocalizations.of(context)!.dismiss,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontFamily: TileTextStyles.rubikFontName,
                      fontWeight: FontWeight.w400,
                    ))),
          ),
        )
      ];
      Utility.setTimeOut(
          duration: Duration(seconds: 5),
          callBack: () {
            if (mounted) {
              iosCallBackButtonPress();
            }
          });
    }

    Widget retValue = Scaffold(
      body: Center(
        child: Container(
          color: TileColors.primaryColorLightHSL.toColor(),
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
                        fontFamily: TileTextStyles.rubikFontName,
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
