import 'dart:ffi';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';

class PickColor extends StatefulWidget {
  Map? _params;
  Color? color;
  PickColor({this.color});
  static final String routeName = '/PickColor';
  @override
  PickColorState createState() => PickColorState();
}

class PickColorState extends State<PickColor> {
  Color pickerColor = Color(0xff443a49);
  Color currentColor = Color(0xff443a49);
  bool _isInitialize = false;

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['color'] = pickerColor;
    }
  }

  void changeColor(Color color) {
    setState(() => pickerColor = color);
  }

  @override
  Widget build(BuildContext context) {
    Map colorParams = ModalRoute.of(context)?.settings.arguments as Map;
    if (!_isInitialize) {
      _isInitialize = true;
      this.widget._params = colorParams;
      if (colorParams.containsKey('initialColor') &&
          colorParams['initialColor'] != null) {
        this.widget.color = colorParams['initialColor'];
        pickerColor = this.widget.color!;
      }
    }

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
        appBar: AppBar(
          backgroundColor: TileStyles.primaryColor,
          title: Text(
            AppLocalizations.of(context)!.color,
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
                    child: ColorPicker(
                  pickerColor: pickerColor,
                  onColorChanged: changeColor,
                ))
              ]),
        ),
        onProceed: () {
          return this.onProceedTap();
        });

    return retValue;
  }
}
