import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tuple/tuple.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../../components/tileUI/configUpdateButton.dart';
import '../../../constants.dart' as Constants;

class AutoAddTile extends StatefulWidget {
  @override
  AutoAddTileState createState() => AutoAddTileState();
}

class AutoAddTileState extends State<AutoAddTile> {
  Location? _location;
  Duration? _duration;
  TextEditingController tileNameController = TextEditingController();
  ScheduleApi scheduleApi = ScheduleApi();
  StreamSubscription? pendingSendTextRequest;

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
    bool showAutoContextContainer = false;
    InputDecoration inputFieldDecoration =
        TileStyles.generateTextInputDecoration(
            AppLocalizations.of(context)!.tileName);

    Widget inputField = Container(
        padding: EdgeInsets.fromLTRB(0, 0, 0, 30),
        child: TextField(
          decoration: inputFieldDecoration,
          controller: tileNameController,
          style: TileStyles.fullScreenTextFieldStyle,
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
          color: ConfigUpdateButton.populatedTextColor,
        ),
        decoration: ConfigUpdateButton.populatedDecoration,
        textColor: ConfigUpdateButton.populatedTextColor,
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
          color: ConfigUpdateButton.populatedTextColor,
        ),
        decoration: ConfigUpdateButton.populatedDecoration,
        textColor: ConfigUpdateButton.populatedTextColor,
        onPress: () {
          Location locationHolder = _location!;
          Map<String, dynamic> locationParams = {
            'location': locationHolder,
            'isFromLookup': false
          };

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
            widthFactor: TileStyles.inputWidthFactor,
            child: Container(
              color: Colors.green,
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
