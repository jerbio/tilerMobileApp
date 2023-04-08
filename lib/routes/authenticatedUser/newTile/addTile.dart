import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:switch_up/switch_up.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';

import 'package:tiler_app/routes/authenticatedUser/startEndDurationTimeline.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/settings.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tuple/tuple.dart';
import '../../../bloc/schedule/schedule_bloc.dart';
import '../../../constants.dart' as Constants;

class AddTile extends StatefulWidget {
  Function? onAddTileClose;
  Function? onAddingATile;
  AutoTile? autoTile;
  DateTime? autoDeadline;
  static final String routeName = '/AddTile';
  Map? newTileParams;

  AddTile({this.autoTile, this.autoDeadline});
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  Key switchUpKey = Key(Utility.getUuid);
  late AutoTile? autoTile;
  bool isAppointment = false;
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  final Color iconColor = TileStyles.iconColor;
  final Color populatedTextColor = Colors.white;
  final CarouselController tilerCarouselController = CarouselController();
  String tileNameText = '';
  String splitCountText = '';
  final LocationApi locationApi = LocationApi();
  Location? home;
  Location? work;
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
          HSLColor.fromColor(TileStyles.primaryColor)
              .withLightness(
                  HSLColor.fromColor(TileStyles.primaryColor).lightness)
              .toColor(),
          HSLColor.fromColor(TileStyles.primaryColor)
              .withLightness(
                  HSLColor.fromColor(TileStyles.primaryColor).lightness + 0.3)
              .toColor(),
        ],
      ));
  TextEditingController tileNameController = TextEditingController();
  TextEditingController tileDeadline = TextEditingController();
  TextEditingController splitCountController = TextEditingController();
  Duration? _duration = Duration(hours: 0, minutes: 0);
  bool _isDurationManuallySet = false;
  Location? _location = Location.fromDefault();
  RepetitionData? _repetitionData;
  Color? _color;
  bool _isLocationManuallySet = false;
  DateTime? _startTime;
  DateTime? _endTime;

  Function? onProceed;

  RestrictionProfile? _restrictionProfile;
  ScheduleApi scheduleApi = ScheduleApi();
  SettingsApi settingsApi = SettingsApi();
  StreamSubscription? pendingSendTextRequest;
  List<Tuple2<String, RestrictionProfile>>? _listedRestrictionProfile;

  @override
  void initState() {
    if (this.widget.autoDeadline != null) {
      _endTime = this.widget.autoDeadline!;
    }
    if (this.widget.autoTile != null) {
      _location = this.widget.autoTile!.location;
      tileNameController =
          TextEditingController(text: this.widget.autoTile!.description);
      _duration = this.widget.autoTile!.duration;

      if (_location == null) {
        var future = new Future.delayed(
            const Duration(milliseconds: Constants.onTextChangeDelayInMs));
        // ignore: cancel_subscriptions
        StreamSubscription streamSubScription =
            future.asStream().listen((event) {
          this
              .scheduleApi
              .getAutoResult(this.widget.autoTile!.description)
              .then((remoteTileResponse) {
            Location? _locationResponse;
            if (remoteTileResponse.item2.isNotEmpty) {
              _locationResponse = remoteTileResponse.item2.last;
            }

            setState(() {
              if (!_isLocationManuallySet) {
                _location = _locationResponse;
                if (_locationResponse != null) {
                  _location!.isDefault = false;
                  _location!.isNull = false;
                }
              }
            });
            isSubmissionReady();
          });
        });

        setState(() {
          pendingSendTextRequest = streamSubScription;
        });
      }
    }

    splitCountController.addListener(() {
      if (splitCountText != splitCountController.text) {
        setState(() {
          splitCountText = splitCountController.text;
        });
        isSubmissionReady();
      }
    });
    tileNameController.addListener(() {
      // isSubmissionReady();
      if (tileNameText != tileNameController.text) {
        if (tileNameController.text.length >
            Constants.autoCompleteTriggerCharacterCount) {
          Function callAutoResult = generateSuggestionCallToServer();
          callAutoResult();
        }
        setState(() {
          tileNameText = tileNameController.text;
        });
        isSubmissionReady();
      }
    });

    locationApi
        .getSpecificLocationByNickName(Location.homeLocationNickName)
        .then((homeLocation) {
      locationApi
          .getSpecificLocationByNickName(Location.workLocationNickName)
          .then((workLocation) {
        setState(() {
          home = homeLocation;
          work = workLocation;
        });
      });
    });

    settingsApi.getUserRestrictionProfile().then((response) {
      if (response.length > 0) {
        setState(() {
          _listedRestrictionProfile = response.entries
              .map<Tuple2<String, RestrictionProfile>>(
                  (e) => Tuple2<String, RestrictionProfile>(e.key, e.value))
              .toList();
        });
        return response;
      }
      setState(() {
        _listedRestrictionProfile = null;
      });
      return response;
    });

    super.initState();
  }

  void _onProceedTap() {
    return this.onSubmitButtonTap();
  }

  isSubmissionReady() {
    bool isDurationReady = false;
    bool isNameReady = false;
    bool isCountReady = false;
    if (_duration != null &&
        _duration!.inMilliseconds > Utility.oneMin.inMilliseconds) {
      isDurationReady = true;
    }

    if (tileNameController.text.trim().isNotEmpty) {
      isNameReady = true;
    }

    int? count = int.tryParse(getSplitCount());
    if (count != null && count > 0) {
      isCountReady = true;
    }
    if (isAppointment) {
      isCountReady = true;
    }

    if (isNameReady && isDurationReady && isCountReady && isRepetitionValid()) {
      setState(() {
        onProceed = _onProceedTap;
      });
    } else {
      setState(() {
        onProceed = null;
      });
    }
  }

  Function generateSuggestionCallToServer() {
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
            .then((remoteTileResponse) {
          Duration? _durationResponse;
          Location? _locationResponse;
          if (remoteTileResponse.item1.isNotEmpty) {
            _durationResponse = remoteTileResponse.item1.last;
          }
          if (remoteTileResponse.item2.isNotEmpty) {
            _locationResponse = remoteTileResponse.item2.last;
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
          isSubmissionReady();
        });
      });

      setState(() {
        pendingSendTextRequest = streamSubScription;
      });
    };

    return retValue;
  }

  String getSplitCount() {
    return this.splitCountController.value.text.isNotEmpty
        ? this.splitCountController.value.text
        : 1.toString();
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
                  color: TileStyles.primaryColorDarkHSL.toColor(),
                  fontSize: 20,
                  fontFamily: TileStyles.rubikFontName,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.tileName,
                hintStyle:
                    TextStyle(color: TileStyles.primaryColorDarkHSL.toColor()),
                filled: true,
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(10, 15, 10, 15),
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
            )));
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
                      controller: splitCountController,
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
        isSubmissionReady();
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
    bool isRepetitionSet = false;
    bool isColorConfigSet = false;
    bool isTimeRestrictionConfigSet = false;
    if (_location != null) {
      if (_location!.isNotNullAndNotDefault) {
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
        _restrictionProfile!.isEnabled &&
        _restrictionProfile!.daySelection
                .where((eachRestrictionDay) => eachRestrictionDay != null)
                .length >
            0) {
      isTimeRestrictionConfigSet = true;
    }

    if (_color != null) {
      isColorConfigSet = true;
    }

    if (_repetitionData != null) {
      isRepetitionSet = true;
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
        Location locationHolder = _location ?? Location.fromDefault();
        Map<String, dynamic> locationParams = {
          'location': locationHolder,
        };
        List<Location> defaultLocations = [];

        if (home != null && home!.isNotNullAndNotDefault) {
          defaultLocations.add(home!);
        }
        if (work != null && work!.isNotNullAndNotDefault) {
          defaultLocations.add(work!);
        }
        if (defaultLocations.isNotEmpty) {
          locationParams['defaults'] = defaultLocations;
        }

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
          color: isRepetitionSet ? populatedTextColor : iconColor,
        ),
        decoration: isRepetitionSet
            ? (isRepetitionValid()
                ? populatedDecoration
                : TileStyles.invalidBoxDecoration)
            : boxDecoration,
        textColor: isRepetitionSet ? populatedTextColor : iconColor,
        onPress: () {
          Timeline tileTimeline = Utility.todayTimeline();
          RepetitionData? repetitionData = _repetitionData?.clone();
          DateTime deadline = DateTime(tileTimeline.startTime.year,
              tileTimeline.startTime.month, tileTimeline.startTime.day, 23, 59);
          tileTimeline =
              Timeline.fromDateTime(tileTimeline.startTime, deadline);
          if (this._endTime != null) {
            tileTimeline =
                Timeline.fromDateTime(tileTimeline.startTime, this._endTime!);
          }

          Map<String, dynamic> repetitionParams = {
            'repetitionData': repetitionData,
            'tileTimeline': tileTimeline,
          };

          Navigator.pushNamed(context, '/repetitionRoute',
                  arguments: repetitionParams)
              .whenComplete(() {
            RepetitionData? updatedRepetitionData =
                repetitionParams['updatedRepetition'] as RepetitionData?;
            bool isRepetitionEndValid = true;
            if (repetitionParams.containsKey('isRepetitionEndValid')) {
              isRepetitionEndValid =
                  repetitionParams['isRepetitionEndValid'] ?? false;
            }

            repetitionParams['updatedRepetition'] as RepetitionData?;
            if (updatedRepetitionData != null) {
              setState(() {
                _repetitionData =
                    isRepetitionEndValid ? updatedRepetitionData : null;
              });
            }
            if (!isRepetitionEndValid) {
              setState(() {
                _repetitionData = null;
              });
            }
            isSubmissionReady();
          });
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
          'routeRestrictionProfile': _restrictionProfile,
          'stackRouteHistory': [AddTile.routeName]
        };
        if (_listedRestrictionProfile != null) {
          restrictionParams['namedRestrictionProfiles'] =
              _listedRestrictionProfile;
        }

        Navigator.pushNamed(context, '/TimeRestrictionRoute',
                arguments: restrictionParams)
            .whenComplete(() {
          RestrictionProfile? populatedRestrictionProfile;
          if (restrictionParams.containsKey('routeRestrictionProfile')) {
            populatedRestrictionProfile =
                restrictionParams['routeRestrictionProfile']
                    as RestrictionProfile?;
            restrictionParams.remove('routeRestrictionProfile');
            setState(() {
              _restrictionProfile = populatedRestrictionProfile;
            });
          }
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
    // Widget secondRow = Row(
    //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    //   children: [reminderConfigButton, emojiConfigButton],
    // );
    List<Widget> thirdRowConfigButtons = [repetitionConfigButton];
    if (!this.isAppointment) {
      thirdRowConfigButtons.add(timeRestrictionsConfigButton);
    }
    Widget thirdRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: thirdRowConfigButtons,
    );

    Widget retValue = Column(
      children: [firstRow, thirdRow],
    );
    return retValue;
  }

  void onEndTimeTap() async {
    DateTime _endTime = this._endTime == null
        ? Utility.todayTimeline().endTime.add(Utility.oneDay)
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
    DateTime _endDate =
        this._endTime ?? Utility.todayTimeline().endTime.add(Utility.oneDay);
    if (this._endTime == null) {
      _endDate = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59);
    }
    DateTime firstDate = _endDate.add(Duration(days: -180));
    DateTime lastDate = _endDate.add(Duration(days: 180));
    final DateTime? revisedEndDate = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AppLocalizations.of(context)!.selectADeadline,
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

  bool isRepetitionValid() {
    bool retValue = true;
    if (_repetitionData != null) {
      if (this._endTime != null) {
        retValue = Utility.utcEpochMillisecondsFromDateTime(
                _repetitionData!.repetitionEnd!) >
            Utility.utcEpochMillisecondsFromDateTime(this._endTime!);
      }
    }

    return retValue;
  }

  void onSubmitButtonTap() async {
    DateTime? _endTime = this._endTime;

    NewTile tile = new NewTile();
    tile.Name = this.tileNameController.value.text;
    if (this._duration != null) {
      tile.DurationMinute = this._duration!.inMinutes.toString();
    }

    if (_repetitionData != null) {
      tile.RepeatFrequency = _repetitionData!.frequency.name;
      if (_repetitionData!.repetitionEnd != null) {
        tile.RepeatEndYear = _repetitionData!.repetitionEnd!.year.toString();
        tile.RepeatEndMonth = _repetitionData!.repetitionEnd!.month.toString();
        tile.RepeatEndDay = _repetitionData!.repetitionEnd!.day.toString();
      }

      if (_repetitionData!.weeklyRepetition != null &&
          _repetitionData!.weeklyRepetition!.length > 0) {
        tile.RepeatWeeklyData = _repetitionData!.weeklyRepetition!
            .map((dayIndex) => dayIndex % 7)
            .join(',');
      }
      tile.RepeatData = _repetitionData!.isAutoRepetitionEnd.toString();
      tile.RepeatType = _repetitionData!.frequency.name;
    }

    DateTime startTime = DateTime.now();
    startTime = DateTime(startTime.year, startTime.month, startTime.day, 0, 0);

    if (this.isAppointment) {
      tile.Rigid = true.toString();
      startTime = this._startTime!;
      _endTime = this._endTime!;
    }

    tile.EndYear = _endTime?.year.toString();
    tile.EndMonth = _endTime?.month.toString();
    tile.EndDay = _endTime?.day.toString();
    tile.EndHour = _endTime?.hour.toString();
    tile.EndMinute = _endTime?.minute.toString();

    tile.StartYear = startTime.year.toString();
    tile.StartMonth = startTime.month.toString();
    tile.StartDay = startTime.day.toString();
    tile.StartHour = startTime.hour.toString();
    tile.StartMinute = startTime.minute.toString();
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

    if (this._restrictionProfile != null &&
        this._restrictionProfile!.isAnyDayNotNull &&
        this._restrictionProfile!.isEnabled) {
      tile.RestrictiveWeek =
          this._restrictionProfile!.toRestrictionWeekConfig();
      tile.isRestricted = true.toString();
      tile.RestrictionProfileId = this._restrictionProfile!.id;
    }

    tile.Count = getSplitCount();

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

    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    Future retValue = this.scheduleApi.addNewTile(tile);
    retValue.then((newlyAddedTile) {
      if (newlyAddedTile.item1 != null) {
        SubCalendarEvent subEvent = newlyAddedTile.item1;
        print(subEvent.name);
      }
      if (this.widget.newTileParams != null) {
        this.widget.newTileParams!['newTile'] = newlyAddedTile.item1;
      }
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetSchedule(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
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
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetSchedule(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
      }
    });

    return retValue;
  }

  Widget generateDeadline() {
    String textButtonString = this._endTime == null
        ? AppLocalizations.of(context)!.deadline_anytime
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

  setAsAppointment() {
    tilerCarouselController.animateToPage(1);
    setState(() {
      isAppointment = true;
      switchUpKey = Key(Utility.getUuid);
    });
  }

  setAsTile() {
    tilerCarouselController.animateToPage(0);
    setState(() {
      isAppointment = false;
      switchUpKey = Key(Utility.getUuid);
    });
  }

  onTabTypeChange(value) {
    onTileTypeChange();
  }

  onTileTypeChange() {
    if (this.isAppointment) {
      setAsTile();
    } else {
      setAsAppointment();
    }
  }

  onCarouselPageChange() {}

  Widget generateNewTileWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  Widget generateAppointmentWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  Widget toggleAppointmentWidget(List<Widget> tileWidgets) {
    Widget retValue = Container(
      child: Column(children: tileWidgets),
    );
    return retValue;
  }

  onTimeLineChange(TimeRange updatedTimeLine) {
    pendingSendTextRequest?.cancel();
    setState(() {
      _startTime = updatedTimeLine.startTime;
      _duration = updatedTimeLine.duration;
      _endTime = updatedTimeLine.endTime;
      _isDurationManuallySet = true;
    });
    isSubmissionReady();
  }

  @override
  Widget build(BuildContext context) {
    Map? newTileParams = ModalRoute.of(context)?.settings.arguments as Map?;
    this.widget.newTileParams = newTileParams;
    List<Widget> childrenWidgets = [];
    List<Widget> appointmentWidgets = [];
    List<Widget> tileWidgets = [];
    Widget tileNameWidget = this.getTileNameWidget();
    Widget durationPicker = this.generateDurationPicker();
    Widget deadlinePicker = this.generateDeadline();
    Widget splitCountWidget = this.getSplitCountWidget();

    StartEndDurationTimeline startAndEndTime = StartEndDurationTimeline(
      start: this._startTime ?? Utility.currentTime(),
      duration: this._duration ?? Duration(),
      onChange: onTimeLineChange,
    );
    Widget extraConfigCollection = this.generateExtraConfigSelection();
    tileWidgets.add(tileNameWidget);
    tileWidgets.add(durationPicker);
    tileWidgets.add(deadlinePicker);
    tileWidgets.add(splitCountWidget);

    appointmentWidgets.add(tileNameWidget);
    appointmentWidgets.add(startAndEndTime);

    Widget tileWidgetWrapper = generateNewTileWidget(tileWidgets);
    Widget appointmentWidget = generateAppointmentWidget(appointmentWidgets);

    List<Widget> carouselItems = [tileWidgetWrapper, appointmentWidget];
    List<String> tabButtons = [
      AppLocalizations.of(context)!.tile,
      AppLocalizations.of(context)!.appointment
    ];

    String switchUpvalue = !isAppointment ? tabButtons.first : tabButtons.last;
    Widget switchUp = SwitchUp(
      key: switchUpKey,
      items: tabButtons,
      onChanged: onTabTypeChange,
      value: switchUpvalue,
    );

    Widget tileTypeCarousel = CarouselSlider(
        carouselController: tilerCarouselController,
        items: carouselItems,
        options: CarouselOptions(
          height: 300,
          aspectRatio: 16 / 9,
          viewportFraction: 1,
          initialPage: 0,
          enableInfiniteScroll: false,
          reverse: false,
          onPageChanged: (pageNumber, carouselData) {
            if (carouselData == CarouselPageChangedReason.manual) {
              if (pageNumber == 0) {
                setAsTile();
              } else {
                setAsAppointment();
              }
            }
          },
          scrollDirection: Axis.horizontal,
        ));

    childrenWidgets.add(tileTypeCarousel);
    childrenWidgets.add(switchUp);
    childrenWidgets.add(extraConfigCollection);

    Function? showLoading;
    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.addTile,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
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
      onProceed: this.onProceed,
    );

    return retValue;
  }

  @override
  void dispose() {
    tileNameController.dispose();
    tileDeadline.dispose();
    splitCountController.dispose();
    super.dispose();
  }
}
