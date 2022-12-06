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
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';
import 'package:duration_picker_dialog_box/duration_picker_dialog_box.dart'
    as durationPickerDialog;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddTile extends StatefulWidget {
  Function? onAddTileClose;
  Function? onAddingATile;
  static final String routeName = '/AddTile';
  final ScheduleApi scheduleApi = ScheduleApi();
  @override
  AddTileState createState() => AddTileState();
}

class AddTileState extends State<AddTile> {
  final Color textBackgroundColor = Color.fromRGBO(0, 119, 170, .05);
  final Color textBorderColor = Colors.white;
  final Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  final Color populatedColor = Colors.white;
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
  TextEditingController tileName = TextEditingController();
  TextEditingController tileDeadline = TextEditingController();
  TextEditingController splitCount = TextEditingController();
  Duration _duration = Duration(hours: 0, minutes: 0);
  DateTime? _endTime;
  Location _location = Location.fromDefault();
  RestrictionProfile? _restrictionProfile;

  Widget getTileNameWidget() {
    Widget tileNameContainer = FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
            width: 380,
            margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
            child: TextField(
              controller: tileName,
              style: TextStyle(
                  color: Color.fromRGBO(31, 31, 31, 1),
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: 'Tile Name',
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
            )));
    return tileNameContainer;
  }

  Widget getSplitCountWidget() {
    Widget splitCountContainer = FractionallySizedBox(
        widthFactor: 0.85,
        child: Container(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("How Many Times?",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                SizedBox(
                    width: 50,
                    child: TextField(
                      controller: splitCount,
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: InputDecoration(
                        hintText: 'Once',
                        filled: true,
                        isDense: true,
                        contentPadding: EdgeInsets.fromLTRB(10, 20, 0, 0),
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
      durationPickerDialog
          .showDurationPicker(
              context: context,
              initialDuration: _duration,
              durationPickerMode: durationPickerDialog.DurationPickerMode.Hour)
          .then((value) {
        if (value != null) {
          setState(() {
            _duration = value;
          });
        }
      });
    };
    String textButtonString = 'Duration';
    if (_duration.inMinutes > 1) {
      textButtonString = "";
      int hour = _duration.inHours.floor();
      int minute = _duration.inMinutes.remainder(60);
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
                          child: Text(textButtonString),
                        ))
                  ],
                ))));
    return retValue;
  }

  Widget generateExtraConfigSelection() {
    String locationName = 'Location';
    bool isLocationConfigSet = false;
    bool isTimeRestrictionConfigSet = false;
    if (_location.isNotNullAndNotDefault != null &&
        (_location.isNotNullAndNotDefault!)) {
      if (_location.description != null && _location.description!.isNotEmpty) {
        locationName = _location.description!;
        isLocationConfigSet = true;
      } else {
        if (_location.address != null && _location.address!.isNotEmpty) {
          locationName = _location.address!;
          isLocationConfigSet = true;
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

    Widget locationConfigButton = ConfigUpdateButton(
      text: locationName,
      prefixIcon: Icon(
        Icons.location_pin,
        color: isLocationConfigSet ? populatedColor : iconColor,
      ),
      decoration: isLocationConfigSet ? populatedDecoration : boxDecoration,
      textColor: isLocationConfigSet ? populatedColor : iconColor,
      onPress: () {
        Location locationHolder = Location.fromDefault();
        Map<String, dynamic> locationParams = {
          'location': locationHolder,
          'isFromLookup': false
        };

        Navigator.pushNamed(context, '/LocationRoute',
                arguments: locationParams)
            .whenComplete(() {
          print('done with pop');
          print(locationParams['location'].description);
          Location? populatedLocation = locationParams['location'] as Location;
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
    Widget repetitionConfigButton = ConfigUpdateButton(
      text: 'Repetition',
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
    );
    Widget reminderConfigButton = ConfigUpdateButton(
      text: 'Reminder',
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
    );
    Widget timeRestrictionsConfigButton = ConfigUpdateButton(
      text: 'Restriction',
      prefixIcon: Icon(
        Icons.switch_left,
        color: isTimeRestrictionConfigSet ? populatedColor : iconColor,
      ),
      decoration:
          isTimeRestrictionConfigSet ? populatedDecoration : boxDecoration,
      textColor: isTimeRestrictionConfigSet ? populatedColor : iconColor,
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
    );
    Widget firstRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [locationConfigButton, repetitionConfigButton],
    );
    Widget secondRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [reminderConfigButton, emojiConfigButton],
    );
    Widget thirdRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [timeRestrictionsConfigButton],
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
    tile.Name = this.tileName.value.text;
    tile.DurationMinute = this._duration.inMinutes.toString();
    tile.EndYear = _endTime?.year.toString();
    tile.EndMonth = _endTime?.month.toString();
    tile.EndDay = _endTime?.day.toString();
    tile.EndHour = _endTime?.hour.toString();
    tile.EndMins = _endTime?.minute.toString();

    DateTime now = DateTime.now();
    tile.StartYear = now.year.toString();
    tile.StartMonth = now.month.toString();
    tile.StartDay = now.day.toString();
    tile.StartHour = '0';
    tile.StartMins = '0';
    tile.isEveryDay = false.toString();
    tile.isRestricted = false.toString();
    tile.isWorkWeek = false.toString();

    tile.BColor = Utility.randomizer.nextInt(255).toString();
    tile.GColor = Utility.randomizer.nextInt(255).toString();
    tile.RColor = Utility.randomizer.nextInt(255).toString();
    tile.ColorSelection = (-1).toString();

    tile.Count = this.splitCount.value.text.isNotEmpty
        ? this.splitCount.value.text
        : 1.toString();

    Future retValue = this.widget.scheduleApi.addNewTile(tile);
    retValue.then((newlyAddedTile) {
      if (newlyAddedTile.item1 != null) {
        SubCalendarEvent subEvent = newlyAddedTile.item1;
        print(subEvent.name);
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
                    Icon(Icons.timelapse_outlined, color: iconColor),
                    Container(
                        padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            textStyle: const TextStyle(
                              fontSize: 20,
                            ),
                          ),
                          onPressed: onEndDateTap,
                          child: Text(textButtonString),
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
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 50, 0, 0),
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: childrenWidgets,
        ),
      ),
      onProceed: () {
        return this.onSubmitButtonTap();
        if (showLoading != null) {
          showLoading();
        }
      },
    );

    showLoading = retValue.toggleLoading;

    return retValue;
  }

  @override
  void dispose() {
    tileName.dispose();
    super.dispose();
  }
}
