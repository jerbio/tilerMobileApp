import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/services/accessManager.dart';
import 'package:tiler_app/services/locationDiagnostics.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

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
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;

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

  @override
  void didChangeDependencies() {
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  VoidCallback generateCallBack(
      {bool forceDeviceCheck = false,
      bool statusCheck = false,
      bool? denyAccess,
      bool doNotCallAgain = false,
      bool enableCallBack = true}) {
    VoidCallback retValue = () async {
      final lookupId = Utility.getUuid;
      final timer = Stopwatch()..start();
      locationFlowLog('widget_request_started', fields: {
        'lookupId': lookupId,
        'forceDeviceCheck': forceDeviceCheck,
        'statusCheck': statusCheck,
        'denyAccess': denyAccess ?? false,
        'enableCallBack': enableCallBack,
        'doNotCallAgain': doNotCallAgain,
      });
      setState(() {
        isLocationRequestTriggered = true;
      });
      await accessManager
          .locationAccess(
              forceDeviceCheck: forceDeviceCheck,
              statusCheck: statusCheck,
              denyAccess: denyAccess ?? false,
              diagnosticId: lookupId)
          .then((value) {
        locationFlowLog('widget_result_received', fields: {
          'lookupId': lookupId,
          'elapsedMs': timer.elapsedMilliseconds,
          'mounted': mounted,
          'permissionGranted': value.isGranted,
          'isDefaultPosition': value.position == Utility.getDefaultPosition(),
        });
        if (!mounted) return;
        final deviceSettingBloc = context.read<DeviceSettingBloc>();
        final actualState = deviceSettingBloc.state;
        final loadedId = actualState is DeviceLocationSettingLoading
            ? actualState.id ?? Utility.getUuid
            : Utility.getUuid;
        locationFlowLog('widget_profile_dispatch', fields: {
          'lookupId': lookupId,
          'eventId': loadedId,
          'blocState': actualState.runtimeType.toString(),
          'stateIsLocationLoading': actualState is DeviceLocationSettingLoading,
          'pendingId': actualState is DeviceLocationSettingLoading
              ? actualState.id
              : null,
        });
        deviceSettingBloc.add(LoadedLocationProfileDeviceSettingEvent(
            deviceLocationProfile: value, id: loadedId));

        setState(() {
          locationAccess = value;
          isLocationRequestTriggered = false;
        });
        if (enableCallBack) this.widget.onChange?.call(value);
      }).catchError((error) {
        locationFlowLog('widget_request_failed',
            fields: {
              'lookupId': lookupId,
              'elapsedMs': timer.elapsedMilliseconds,
              'mounted': mounted,
            },
            error: error);
        if (mounted) setState(() => isLocationRequestTriggered = false);
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
            child: Text(
              AppLocalizations.of(context)!.allow,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
      Container(
        margin: EdgeInsets.fromLTRB(0, 430, 0, 0),
        child: SizedBox(
          width: buttonWidth,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: tileThemeExtension.surfaceContainerSuperior),
            onPressed: generateCallBack(denyAccess: true),
            child: Text(
              AppLocalizations.of(context)!.deny,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 25,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      )
    ];
    if (isLocationRequestTriggered) {
      acceptDenyButtons = [
        Container(
            margin: EdgeInsets.fromLTRB(0, 300, 0, 0),
            child: CircularProgressIndicator(
              color: colorScheme.tertiary,
            ))
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: tileThemeExtension.surfaceContainerSuperior),
              onPressed: iosCallBackButtonPress,
              child: Text(
                AppLocalizations.of(context)!.dismiss,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontFamily: TileTextStyles.rubikFontName,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
        )
      ];
      Utility.setTimeOut(
          duration: Duration(seconds: 300),
          callBack: () {
            if (mounted) {
              iosCallBackButtonPress();
            }
          });
    }

    Widget retValue = Scaffold(
      body: Center(
        child: Container(
          color: colorScheme.primaryContainer,
          alignment: Alignment.center,
          width:
              MediaQuery.of(context).size.width * TileDimensions.tileWidthRatio,
          height: MediaQuery.of(context).size.height *
              TileDimensions.tileWidthRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                alignment: Alignment.center,
                margin: EdgeInsets.fromLTRB(0, 0, 0, 400),
                padding: EdgeInsets.all(30),
                width: MediaQuery.of(context).size.width *
                    TileDimensions.tileWidthRatio,
                child: Text(
                    AppLocalizations.of(context)!.allowAccessDescription,
                    style: TextStyle(
                        fontSize: 20,
                        fontFamily: TileTextStyles.rubikFontName,
                        fontWeight: FontWeight.w400,
                        color: colorScheme.onPrimaryContainer)),
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
