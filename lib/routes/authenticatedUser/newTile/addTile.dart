import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../../constants.dart' as Constants;

class AddTile extends StatefulWidget {
  Function? onAddTileClose;
  Function? onAddingATile;
  static final String routeName = '/AddTile';
  final ScheduleApi scheduleApi = ScheduleApi();
  Map? newTileParams;
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = Colors.white;
  final Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  final Color populatedTextColor = Colors.white;
  final BoxDecoration boxDecoration = BoxDecoration(
      color: Color.fromRGBO(31, 31, 31, 0.05),
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ));
  final BoxDecoration populatedDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          HSLColor.fromAHSL(1, 198, 1, 0.33).toColor(),
          HSLColor.fromAHSL(1, 191, 1, 0.46).toColor()
        ],
      ));
  TextEditingController tileNameController = TextEditingController();
  TextEditingController tileDeadline = TextEditingController();
  TextEditingController splitCount = TextEditingController();
  Duration? _duration = Duration(hours: 0, minutes: 0);
  bool _isDurationManuallySet = false;
  Location? _location = Location.fromDefault();
  Color? _color;
  bool _isLocationManuallySet = false;
  DateTime? _endTime;

  RestrictionProfile? _restrictionProfile;
  ScheduleApi scheduleApi = ScheduleApi();
  StreamSubscription? pendingSendTextRequest;

  Function generateCallToServer() {
    if (pendingSendTextRequest != null) {
      pendingSendTextRequest!.cancel();
    }

    Function retValue = () async {
      if (_isDurationManuallySet && _isLocationManuallySet) {
        return;
      }
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
            if (!_isDurationManuallySet) {
              _duration = _durationResponse;
            }
            if (!_isLocationManuallySet) {
              _location = _locationResponse;
              if (_locationResponse != null) {
                _location!.isDefault = false;
                _location!.isNull = false;
              }
            }
          });
        });
      });

      setState(() {
        pendingSendTextRequest = streamSubScription;
      });
    };

    return retValue;
  }

  Widget getTileNameWidget() {
    Widget tileNameContainer = FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
            width: 380,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: TextField(
                controller: tileNameController,
                style: TextStyle(
                    color: Color.fromRGBO(31, 31, 31, 1),
                    fontSize: 20,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.tileName,
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
                  ),
                ),
                onChanged: (val) {
                  if (val.length >
                      Constants.autoCompleteTriggerCharacterCount) {
                    Function callAutoResult = generateCallToServer();
                    callAutoResult();
                  }
                })));
    return tileNameContainer;
  }

  Widget getSplitCountWidget() {
    Widget splitCountContainer = FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context)!.howManyTimes,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(
                    width: 60,
                    child: TextField(
                      controller: splitCount,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.once,
                        filled: true,
                        isDense: true,
                        contentPadding: EdgeInsets.all(10),
                        fillColor: textBackgroundColor,
                        border: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(50.0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(5.0),
                          ),
                          borderSide:
                              BorderSide(color: Colors.white, width: 0.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: const BorderRadius.all(
                            const Radius.circular(5.0),
                          ),
                          borderSide:
                              BorderSide(color: textBorderColor, width: 0.5),
                        ),
                      ),
                    ))
              ],
            )));
    return splitCountContainer;
  }

  Widget generateDurationPicker() {
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': _duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        print('done with pop');
        print(durationParams['duration']);
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _duration = populatedDuration;
            _isDurationManuallySet = true;
          }
        });
      });
    };
    String textButtonString = AppLocalizations.of(context)!.duration;
    if (_duration != null && _duration!.inMinutes > 1) {
      textButtonString = "";
      int hour = _duration!.inHours.floor();
      int minute = _duration!.inMinutes.remainder(60);
      if (hour > 0) {
        textButtonString = '${hour}h';
        if (minute > 0) {
          textButtonString = '${textButtonString} : ${minute}m';
        }
      } else {
        if (minute > 0) {
          textButtonString = '${minute}m';
        }
      }
    }
    Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: textBackgroundColor,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: textBorderColor,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.timelapse_outlined, color: iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: setDuration,
                          child: Text(
                            textButtonString,
                            style: TextStyle(
                              fontFamily: TileStyles.rubikFontName,
                            ),
                          ),
                        ))
                  ],
                ))));
    return retValue;
  }

  Widget generateExtraConfigSelection() {
    String locationName = 'Location';
    bool isLocationConfigSet = false;
    bool isColorConfigSet = false;
    bool isTimeRestrictionConfigSet = false;
    if (_location != null) {
      if (_location!.isNotNullAndNotDefault != null &&
          (_location!.isNotNullAndNotDefault!)) {
        if (_location!.description != null &&
            _location!.description!.isNotEmpty) {
          locationName = _location!.description!;
          isLocationConfigSet = true;
        } else {
          if (_location!.address != null && _location!.address!.isNotEmpty) {
            locationName = _location!.address!;
            isLocationConfigSet = true;
          }
        }
      }
    }

    if (_restrictionProfile != null &&
        _restrictionProfile!.daySelection
                .where((eachRestrictionDay) => eachRestrictionDay != null)
                .length >
            0) {
      isTimeRestrictionConfigSet = true;
    }

    if (_color != null) {
      isColorConfigSet = true;
    }

    Widget locationConfigButton = ConfigUpdateButton(
      text: locationName,
      prefixIcon: Icon(
        Icons.location_pin,
        color: isLocationConfigSet ? populatedTextColor : iconColor,
      ),
      decoration: isLocationConfigSet ? populatedDecoration : boxDecoration,
      textColor: isLocationConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Location locationHolder = _location!;
        Map<String, dynamic> locationParams = {
          'location': locationHolder,
          'isFromLookup': false
        };

        Navigator.pushNamed(context, '/LocationRoute',
                arguments: locationParams)
            .whenComplete(() {
          Location? populatedLocation = locationParams['location'] as Location;
          setState(() {
            if (populatedLocation != null &&
                populatedLocation.isNotNullAndNotDefault != null) {
              _location = populatedLocation;
              _isLocationManuallySet = true;
            }
          });
        });
      },
    );
    Widget repetitionConfigButton = ConfigUpdateButton(
        text: AppLocalizations.of(context)!.repetition,
        prefixIcon: Icon(
          Icons.repeat_outlined,
          color: iconColor,
        ),
        decoration: BoxDecoration(
            color: Color.fromRGBO(31, 31, 31, 0.05),
            borderRadius: BorderRadius.all(
              const Radius.circular(10.0),
            )),
        textColor: iconColor,
        onPress: () {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('Repetitions are disabled for now :('),
              action: SnackBarAction(
                  label: AppLocalizations.of(context)!.close,
                  onPressed: scaffold.hideCurrentSnackBar),
            ),
          );
        });
    Widget reminderConfigButton = ConfigUpdateButton(
        text: AppLocalizations.of(context)!.reminder,
        prefixIcon: Icon(
          Icons.doorbell_outlined,
          color: iconColor,
        ),
        decoration: BoxDecoration(
            color: Color.fromRGBO(31, 31, 31, 0.05),
            borderRadius: BorderRadius.all(
              const Radius.circular(10.0),
            )),
        textColor: iconColor,
        onPress: () {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('Reminders are disabled for now :('),
              action: SnackBarAction(
                  label: AppLocalizations.of(context)!.close,
                  onPressed: scaffold.hideCurrentSnackBar),
            ),
          );
        });
    Widget timeRestrictionsConfigButton = ConfigUpdateButton(
      text: AppLocalizations.of(context)!.restriction,
      prefixIcon: Icon(
        Icons.switch_left,
        color: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      ),
      decoration:
          isTimeRestrictionConfigSet ? populatedDecoration : boxDecoration,
      textColor: isTimeRestrictionConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Map<String, dynamic> restrictionParams = {
          'restrictionProfile': _restrictionProfile,
          'stackRouteHistory': [AddTile.routeName]
        };

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          if (restrictionParams.containsKey('restrictionProfile') &&
              restrictionParams['restrictionProfile'] != null)
            populatedRestrictionProfile =
                restrictionParams['restrictionProfile'] as RestrictionProfile;
          setState(() {
            if (populatedRestrictionProfile != null) {
              _restrictionProfile = populatedRestrictionProfile;
            }
          });
        });
      },
    );
    Widget emojiConfigButton = ConfigUpdateButton(
        text: 'Emoji',
        prefixIcon: Icon(
          Icons.emoji_emotions,
          color: iconColor,
        ),
        decoration: BoxDecoration(
            color: Color.fromRGBO(31, 31, 31, 0.05),
            borderRadius: BorderRadius.all(
              const Radius.circular(10.0),
            )),
        textColor: iconColor,
        onPress: () {
          final scaffold = ScaffoldMessenger.of(context);
          scaffold.showSnackBar(
            SnackBar(
              content: const Text('Emojis are disabled for now :('),
              action: SnackBarAction(
                  label: AppLocalizations.of(context)!.close,
                  onPressed: scaffold.hideCurrentSnackBar),
            ),
          );
        });

    Widget colorPickerConfigButton = ConfigUpdateButton(
      text: AppLocalizations.of(context)!.color,
      prefixIcon: Icon(
        Icons.contrast,
        color: isColorConfigSet ? (_color ?? populatedTextColor) : iconColor,
      ),
      decoration: isColorConfigSet ? populatedDecoration : boxDecoration,
      textColor: isColorConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Color? colorHolder = _color;
        Map<String, dynamic> colorParams = {'color': colorHolder};

        Navigator.pushNamed(context, '/PickColor', arguments: colorParams)
            .whenComplete(() {
          Color? populatedColor = colorParams['color'] as Color?;
          setState(() {
            isColorConfigSet = false;
            if (populatedColor != null) {
              _color = populatedColor;
              isColorConfigSet = true;
            }
          });
        });
      },
    );
    Widget firstRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [locationConfigButton, colorPickerConfigButton],
    );
    Widget secondRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [reminderConfigButton, emojiConfigButton],
    );
    Widget thirdRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [timeRestrictionsConfigButton, repetitionConfigButton],
    );

    Widget retValue = Column(
      children: [firstRow, secondRow, thirdRow],
    );
    return retValue;
  }

  void onEndTimeTap() async {
    DateTime _endTime = this._endTime == null
        ? Utility.todayTimeline().endTime!.add(Utility.oneDay)
        : this._endTime!;
    TimeOfDay _endTimeOfDay = TimeOfDay.fromDateTime(_endTime);
    final TimeOfDay? revisedEndTime =
        await showTimePicker(context: context, initialTime: _endTimeOfDay);
    if (revisedEndTime != null) {
      DateTime updatedEndTime = new DateTime(_endTime.year, _endTime.month,
          _endTime.day, revisedEndTime.hour, revisedEndTime.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  void onEndDateTap() async {
    DateTime _endDate = this._endTime == null
        ? Utility.todayTimeline().endTime!.add(Utility.oneDay)
        : this._endTime!;
    DateTime firstDate = _endDate.add(Duration(days: -14));
    DateTime lastDate = _endDate.add(Duration(days: 90));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select a deadline',
    );
    if (revisedEndDate != null) {
      DateTime updatedEndTime = new DateTime(
          revisedEndDate.year,
          revisedEndDate.month,
          revisedEndDate.day,
          _endDate.hour,
          _endDate.minute);
      setState(() => _endTime = updatedEndTime);
    }
  }

  void onSubmitButtonTap() async {
    DateTime? _endTime = this._endTime;

    NewTile tile = new NewTile();
    tile.Name = this.tileNameController.value.text;
    if (this._duration != null) {
      tile.DurationMinute = this._duration!.inMinutes.toString();
    }
    tile.EndYear = _endTime?.year.toString();
    tile.EndMonth = _endTime?.month.toString();
    tile.EndDay = _endTime?.day.toString();
    tile.EndHour = '23';
    tile.EndMinute = '59';

    DateTime now = DateTime.now();
    tile.StartYear = now.year.toString();
    tile.StartMonth = now.month.toString();
    tile.StartDay = now.day.toString();
    tile.StartHour = '0';
    tile.StartMinute = '0';
    tile.isEveryDay = false.toString();
    tile.isRestricted = false.toString();
    tile.isWorkWeek = false.toString();

    var randomColor = _color ??
        HSLColor.fromAHSL(
                1,
                (Utility.randomizer.nextDouble() * 360),
                Utility.randomizer.nextDouble(),
                (1 - (Utility.randomizer.nextDouble() * 0.45)))
            .toColor();

    tile.BColor = randomColor.blue.toString();
    tile.GColor = randomColor.green.toString();
    tile.RColor = randomColor.red.toString();

    tile.ColorSelection = (-1).toString();

    if (_location != null) {
      tile.LocationAddress = _location!.address;
      tile.LocationTag = _location!.description;
      tile.LocationId = _location!.id;
      tile.LocationSource = _location!.source;
      tile.LocationIsVerified = _location!.isVerified.toString();
    }

    tile.Count = this.splitCount.value.text.isNotEmpty
        ? this.splitCount.value.text
        : 1.toString();

    debugPrint(tile.toJson().toString());

    Utility.determineDevicePosition().catchError((onError) async {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.showSnackBar(
        SnackBar(
          duration: Duration(seconds: 20),
          content: Text(AppLocalizations.of(context)!.enableLocations),
          action: SnackBarAction(
            label: AppLocalizations.of(context)!.settings,
            onPressed: () async {
              await Geolocator.openAppSettings();
              await Geolocator.openLocationSettings();
            },
            textColor: Colors.redAccent,
          ),
        ),
      );
      return Utility.getDefaultPosition();
    });

    Future retValue = this.widget.scheduleApi.addNewTile(tile);
    retValue.then((newlyAddedTile) {
      if (newlyAddedTile.item1 != null) {
        SubCalendarEvent subEvent = newlyAddedTile.item1;
        print(subEvent.name);
      }
      if (this.widget.newTileParams != null) {
        this.widget.newTileParams!['newTile'] = newlyAddedTile;
      }
    }).onError((error, stackTrace) {
      if (error != null) {
        String message = error.toString();
        if (error is FormatException) {
          FormatException exception = error;
          message = exception.message;
        }

        debugPrint(message);
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.close,
              onPressed: scaffold.hideCurrentSnackBar,
              textColor: Colors.redAccent,
            ),
          ),
        );
      }
    });

    return retValue;
  }

  Widget generateDeadline() {
    String textButtonString = this._endTime == null
        ? AppLocalizations.of(context)!.deadline_auto
        : DateFormat.yMMMd().format(this._endTime!);
    Widget deadlineContainer = new GestureDetector(
        onTap: this.onEndDateTap,
        child: FractionallySizedBox(
            widthFactor: 0.85,
            child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                decoration: BoxDecoration(
                    color: textBackgroundColor,
                    borderRadius: const BorderRadius.all(
                      const Radius.circular(8.0),
                    ),
                    border: Border.all(
                      color: textBorderColor,
                      width: 1.5,
                    )),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.calendar_month, color: iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: onEndDateTap,
                          child: Text(
                            textButtonString,
                            style: TextStyle(
                              fontFamily: TileStyles.rubikFontName,
                            ),
                          ),
                        ))
                  ],
                ))));
    return deadlineContainer;
  }

  Widget generateSubmitTile() {
    Widget submitContainer = Container(
        child: ElevatedButton(
      onPressed: this.onSubmitButtonTap,
      child: Text('Submit Tile'),
    ));
    return submitContainer;
  }

  @override
  Widget build(BuildContext context) {
    Map? newTileParams = ModalRoute.of(context)?.settings.arguments as Map?;
    this.widget.newTileParams = newTileParams;
    List<Widget> childrenWidgets = [];
    Widget tileNameWidget = this.getTileNameWidget();
    Widget durationPicker = this.generateDurationPicker();
    Widget deadlinePicker = this.generateDeadline();
    Widget splitCountWidget = this.getSplitCountWidget();
    Widget submitTileWidget = this.generateSubmitTile();
    Widget extraConfigCollection = this.generateExtraConfigSelection();
    childrenWidgets.add(tileNameWidget);
    childrenWidgets.add(durationPicker);
    childrenWidgets.add(deadlinePicker);
    childrenWidgets.add(splitCountWidget);
    childrenWidgets.add(extraConfigCollection);
    // childrenWidgets.add(submitTileWidget);

    Function? showLoading;
    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.addTile,
          style: TextStyle(
              color: TileStyles.enabledTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Container(
        margin: TileStyles.topMargin,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: childrenWidgets,
        ),
      ),
      onProceed: () {
        return this.onSubmitButtonTap();
      },
    );

    return retValue;
  }

  @override
  void dispose() {
    tileNameController.dispose();
    super.dispose();
  }
}
