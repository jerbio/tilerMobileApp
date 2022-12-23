import 'dart:ffi';

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

class DurationDial extends StatefulWidget {
  Map? _params;
  Duration? duration;
  DurationDial({this.duration});
  static final String routeName = '/DurationDial';
  @override
  DurationDialState createState() => DurationDialState();
}

class DurationDialState extends State<DurationDial> {
  Duration _duration = Duration();
  bool _isInitialize = false;

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['duration'] = _duration;
    }
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

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.duration,
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
          margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
          alignment: Alignment.topCenter,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                    child: DurationPicker(
                  duration: _duration,
                  onChange: (val) {
                    setState(() => _duration = val);
                  },
                  snapToMins: 5.0,
                ))
              ]),
        ),
        onProceed: () {
          return this.onProceedTap();
        });

    return retValue;
  }
}
