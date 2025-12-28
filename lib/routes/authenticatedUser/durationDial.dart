import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
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
  String? _selectedPresetText = null;
  Duration? _selectedPresetValue = null;
  Map<String, Duration> durationStringToDuration = {};
  List<String>? durationTextCollection;

  @override
  void initState() {
    super.initState();
  }

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['duration'] = _duration;
    }
  }

  onTabTypeChange(value) {
    print("value is:");
    print(value);

    String durationText = AppLocalizations.of(context)!.custom;
    if (durationTextCollection != null) {
      if (value is int) {
        durationText = durationTextCollection![value];
      }
    }

    print("duration text: " + durationText.toString());

    if (durationText == AppLocalizations.of(context)!.custom) {
      setState(() {
        _selectedPresetValue = null;
        _selectedPresetText = durationText;
      });
    } else {
      setState(() {
        _selectedPresetValue = durationStringToDuration[durationText];
        _duration = _selectedPresetValue!;
        _selectedPresetText = durationText;
      });
    }
  }

  onDurationButtonTap(Duration duration) {
    setState(() {
      _duration = duration;
      _selectedPresetValue = duration;
    });
  }

  resetSelectedPresetValue() {
    if (_selectedPresetValue != null) {
      switchUpID = ValueKey(Utility.getUuid);
    }
    _selectedPresetValue = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final Map durationParams =
        ModalRoute.of(context)?.settings.arguments as Map;
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
        key: ValueKey((_selectedPresetValue?.inMinutes ?? "custom-selection")),
        onChange: (val) {
          setState(() {
            _duration = val;
            resetSelectedPresetValue();
          });
        },
        snapToMins: 5.0,
      ))
    ];
    if (this.widget.presetDurations != null &&
        this.widget.presetDurations!.length > 0) {
      List<Widget> tabButtons = [];
      durationTextCollection = <String>[];
      this.widget.presetDurations!.forEach((eachDuration) {
        String durationText = eachDuration.inHours >= 1
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
        if (durationTextCollection != null) {
          durationTextCollection!.add(durationText);
        }
        durationStringToDuration[durationText] = eachDuration;
        tabButtons.add(
          Text(durationText),
        );
      });
      if (durationTextCollection != null &&
          durationTextCollection!.length > 0) {
        durationTextCollection!.add(AppLocalizations.of(context)!.custom);
        durationStringToDuration[AppLocalizations.of(context)!.custom] =
            Duration.zero;
        int? presetIndex = durationTextCollection?.indexOf(
            _selectedPresetText ?? AppLocalizations.of(context)!.custom);
        Widget switchUp = Container(
            padding: EdgeInsets.fromLTRB(0, 100, 0, 0),
            key: switchUpID,
            child: ToggleSwitch(
              labels: durationTextCollection,
              initialLabelIndex: presetIndex,
              onToggle: onTabTypeChange,
              activeBgColor: [colorScheme.primary],
              activeFgColor: colorScheme.onPrimary,
              inactiveBgColor: colorScheme.inversePrimary,
              inactiveFgColor: colorScheme.onPrimary,
              animate: true,
              customWidths: [100, 100, 100],
              animationDuration: 300,
            ));
        widgetColumn.insert(0, switchUp);
      }
    }

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
        routeName: "durationDial",
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.duration),
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
