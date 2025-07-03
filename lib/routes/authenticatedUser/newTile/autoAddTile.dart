import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tileinput_styles.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import '../../../constants.dart' as Constants;
//ey: not used
class AutoAddTile extends StatefulWidget {
  @override
  AutoAddTileState createState() => AutoAddTileState();
}

class AutoAddTileState extends State<AutoAddTile> {
  Location? _location;
  Duration? _duration;
  TextEditingController tileNameController = TextEditingController();
  late ScheduleApi scheduleApi;
  StreamSubscription? pendingSendTextRequest;

  @override
  void initState() {
    super.initState();
    scheduleApi = ScheduleApi(getContextCallBack: () => context);
  }

  Function generateCallToServer() {
    if (pendingSendTextRequest != null) {
      pendingSendTextRequest!.cancel();
    }

    Function retValue = () async {
      var future = new Future.delayed(
          const Duration(milliseconds: Constants.onTextChangeDelayInMs));
      // ignore: cancel_subscriptions
      StreamSubscription streamSubScription = future.asStream().listen((event) {
        this
            .scheduleApi
            .getAutoResult(tileNameController.text)
            .then((autoTileResponse) {
          Duration? _durationResponse;
          Location? _locationResponse;
          if (autoTileResponse.item1.isNotEmpty) {
            _durationResponse = autoTileResponse.item1.last;
          }
          if (autoTileResponse.item2.isNotEmpty) {
            _locationResponse = autoTileResponse.item2.last;
          }

          setState(() {
            _duration = _durationResponse;
            _location = _locationResponse;
          });
        });
      });

      setState(() {
        pendingSendTextRequest = streamSubScription;
      });
    };

    return retValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme= Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    bool showAutoContextContainer = false;
    InputDecoration inputFieldDecoration =
    TileInputStyles.generateTextInputDecoration(
      inputHint:  AppLocalizations.of(context)!.tileName,
      fillColor:colorScheme.surfaceContainerLow,
      borderColor: colorScheme.onInverseSurface,
      textColor: tileThemeExtension.onSurfaceTertiary
    );

    Widget inputField = Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 30),
        child: TextField(
          decoration: inputFieldDecoration,
          controller: tileNameController,
          style: TileTextStyles.fullScreenTextFieldStyle,
          onChanged: (val) {
            if (val.length > Constants.autoCompleteTriggerCharacterCount) {
              Function callAutoResult = generateCallToServer();
              callAutoResult();
            }
          },
        ));
    List<Widget> sections = [inputField];
    List<Widget> autoPredictionButtons = [];

    if (_duration != null && _duration!.inMinutes > 1) {
      showAutoContextContainer = true;
      String durationString = "";
      int hour = _duration!.inHours.floor();
      int minute = _duration!.inMinutes.remainder(60);
      if (hour > 0) {
        durationString = '${hour}h';
        if (minute > 0) {
          durationString = '${durationString} : ${minute}m';
        }
      } else {
        if (minute > 0) {
          durationString = '${minute}m';
        }
      }

      Widget durationWidget = ConfigUpdateButton(
        text: durationString,
        prefixIcon: Icon(
          Icons.timelapse_outlined,
          color: colorScheme.onInverseSurface,
        ),
        decoration: TileDecorations.populatedDecoration(colorScheme.surfaceContainerLow),
        textColor: colorScheme.onInverseSurface,
        onPress: () {
          Map<String, dynamic> durationParams = {'duration': _duration};
          Navigator.pushNamed(context, '/DurationDial',
                  arguments: durationParams)
              .whenComplete(() {
            print('done with pop');
            print(durationParams['duration']);
            Duration? populatedDuration =
                durationParams['duration'] as Duration?;
            setState(() {
              if (populatedDuration != null) {
                _duration = populatedDuration;
              }
            });
          });
        },
      );
      autoPredictionButtons.add(durationWidget);
    }

    if (_location != null) {
      showAutoContextContainer = true;
      Widget locationWidget = ConfigUpdateButton(
        text: _location!.description!,
        prefixIcon: Icon(
          Icons.location_pin,
          color: colorScheme.onInverseSurface,
        ),
        decoration:  TileDecorations.populatedDecoration(colorScheme.surfaceContainerLow),
        textColor: colorScheme.onInverseSurface,
        onPress: () {
          Location locationHolder = _location!;
          Map<String, dynamic> locationParams = {'location': locationHolder};

          Navigator.pushNamed(context, '/LocationRoute',
                  arguments: locationParams)
              .whenComplete(() {
            print('done with pop');
            print(locationParams['location'].description);
            Location? populatedLocation =
                locationParams['location'] as Location;
            setState(() {
              if (populatedLocation != null &&
                  populatedLocation.isNotNullAndNotDefault != null &&
                  populatedLocation.isNotNullAndNotDefault!) {
                _location = populatedLocation;
              }
            });
          });
        },
      );
      autoPredictionButtons.add(locationWidget);
    }

    if (showAutoContextContainer) {
      Container containerWrapped = Container(
        child: Row(
          children: autoPredictionButtons,
        ),
      );
      sections.add(containerWrapped);
    }

    Widget predictiveContainer = Container(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
            alignment: FractionalOffset.center,
            widthFactor: TileDimensions.inputWidthFactor,
            child: Container(
              color: TileColors.predictiveContainerBg,
              child: Stack(children: <Widget>[
                AnimatedPositioned(
                  duration: Duration(milliseconds: 500),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: sections,
                  ),
                )
              ]),
            )));

    return predictiveContainer;
  }
}
