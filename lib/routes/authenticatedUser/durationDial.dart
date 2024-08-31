import 'dart:ffi';

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:switch_up/switch_up.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class DurationDial extends StatefulWidget {
  Map? _params;
  Duration? duration;
  List<Duration>? presetDurations;
  DurationDial({this.duration, this.presetDurations});
  static final String routeName = '/DurationDial';
  @override
  DurationDialState createState() => DurationDialState();
}

class DurationDialState extends State<DurationDial> {
  Key switchUpID = ValueKey(Utility.getUuid);
  Duration _duration = Duration();
  bool _isInitialize = false;
  Duration? _selectedPresetValue = null;
  Map<String, Duration> durationStringToDuration = {};

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['duration'] = _duration;
    }
  }

  onTabTypeChange(value) {
    if (value == AppLocalizations.of(context)!.custom) {
      setState(() {
        _selectedPresetValue = null;
      });
    } else {
      setState(() {
        _selectedPresetValue = durationStringToDuration[value];
        _duration = _selectedPresetValue!;
      });
    }
  }

  onDurationButtonTap(Duration duration) {
    setState(() {
      _duration = duration;
      _selectedPresetValue = duration;
    });
  }

  resetSselectedPresetValue() {
    if (_selectedPresetValue != null) {
      switchUpID = ValueKey(Utility.getUuid);
    }
    _selectedPresetValue = null;
  }

  @override
  Widget build(BuildContext context) {
    Map durationParams = ModalRoute.of(context)?.settings.arguments as Map;
    if (!_isInitialize) {
      _isInitialize = true;
      this.widget._params = durationParams;
      if (durationParams.containsKey('initialDuration') &&
          durationParams['initialDuration'] != null) {
        this.widget.duration = durationParams['initialDuration'];
        _duration = this.widget.duration!;
      }
    }

    List<Widget> widgetColumn = <Widget>[
      Expanded(
          child: DurationPicker(
        duration: _duration,
        onChange: (val) {
          setState(() {
            _duration = val;
            resetSselectedPresetValue();
          });
        },
        snapToMins: 5.0,
      ))
    ];
    if (this.widget.presetDurations != null &&
        this.widget.presetDurations!.length > 0) {
      List<Widget> tabButtons = [];
      List<String> durationTextCollection = <String>[];
      this.widget.presetDurations!.forEach((eachDuration) {
        String durationText = eachDuration.inHours > 0
            ? (eachDuration.inHours == 1
                ? AppLocalizations.of(context)!.oneHour
                : AppLocalizations.of(context)!
                    .countHours(eachDuration.inHours.toString()))
            : (eachDuration.inMinutes > 0
                ? (eachDuration.inMinutes == 1
                    ? AppLocalizations.of(context)!.oneMinute
                    : AppLocalizations.of(context)!
                        .countMinutes(eachDuration.inMinutes.toString()))
                : eachDuration.toHuman);
        durationTextCollection.add(durationText);
        durationStringToDuration[durationText] = eachDuration;
        tabButtons.add(
          Text(durationText),
        );
      });
      if (durationTextCollection.length > 0) {
        durationTextCollection.add(AppLocalizations.of(context)!.custom);
        durationStringToDuration[AppLocalizations.of(context)!.custom] =
            Duration.zero;
        String switchUpvalue = _selectedPresetValue != null
            ? durationTextCollection[
                this.widget.presetDurations!.indexOf(_selectedPresetValue!)]
            : AppLocalizations.of(context)!.custom;
        Widget switchUp = Container(
          padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
          key: switchUpID,
          width: MediaQuery.of(context).size.width * TileStyles.widthRatio,
          child: SwitchUp(
            items: durationTextCollection,
            onChanged: onTabTypeChange,
            value: switchUpvalue,
            color: TileStyles.primaryColor,
          ),
        );
        widgetColumn.insert(0, switchUp);
      }
    }

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.duration,
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
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.topCenter,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: widgetColumn),
        ),
        onProceed: () {
          return this.onProceedTap();
        });

    return retValue;
  }
}
