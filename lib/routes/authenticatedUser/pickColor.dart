import 'dart:ffi';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import 'package:tuple/tuple.dart';

class PickColor extends StatefulWidget {
  Map? _params;
  Color? color;
  PickColor({this.color});
  static final String routeName = '/PickColor';
  @override
  PickColorState createState() => PickColorState();
}

class PickColorState extends State<PickColor> {
  bool isCustomColorPicker = false;
  int selectedPresetIndex = 0;
  final presetColors = <Color>[
    Color.fromRGBO(255, 255, 0, 1),
    Color.fromRGBO(135, 255, 221, 1),
    Color.fromRGBO(110, 201, 255, 1),
    Color.fromRGBO(255, 71, 49, 1),
    Color.fromRGBO(61, 230, 107, 1),
    Color.fromRGBO(210, 79, 210, 1),
    Color.fromRGBO(145, 73, 245, 1),
    Color.fromRGBO(255, 128, 231, 1),
    Color.fromRGBO(255, 99, 56, 1),
  ];
  Color pickerColor = HSLColor.fromAHSL(
          1,
          (Utility.randomizer.nextDouble() * 360),
          Utility.randomizer.nextDouble(),
          (1 - (Utility.randomizer.nextDouble() * 0.35)))
      .toColor();
  Color? initialColor;
  bool _isInitialize = false;
  final String _colorPickernRouteName = "PickColorRoute";

  @override
  void initState() {
    super.initState();
    presetColors[0] =
        this.widget.color ?? this.initialColor ?? this.randomColorGenerator();
  }

  void onProceedTap() {
    if (this.widget._params != null) {
      this.widget._params!['color'] = pickerColor;
    }
  }

  void onCanceTap() {
    if (this.widget._params != null) {
      this.widget._params!['color'] = initialColor;
    }
  }

  void changeColor(Color color) {
    setState(() {
      pickerColor = color;
    });
  }

  Color randomColorGenerator() {
    return HSLColor.fromAHSL(
            1,
            (Utility.randomizer.nextDouble() * 360),
            Utility.randomizer.nextDouble(),
            (1 - (Utility.randomizer.nextDouble() * 0.35)))
        .toColor();
  }

  Widget renderEachClickablePreset(Color color) {
    Widget retValue = Container(
      margin: EdgeInsets.fromLTRB(5, 5, 0, 0),
      width: 60,
      height: 60,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(240)), color: color),
    );

    return retValue;
  }

  handlePresetColorClick(int index) {
    if (index == 0 && selectedPresetIndex == index) {
      presetColors[0] = randomColorGenerator();
    }
    setState(() {
      selectedPresetIndex = index;
      changeColor(presetColors[index]);
    });
  }

  Widget renderPresetColors() {
    Widget shufflePreset = GestureDetector(
      child: Stack(
        children: [
          renderEachClickablePreset(presetColors.first),
          Container(
            margin: EdgeInsets.fromLTRB(24, 24, 0, 0),
            child: Icon(
              Icons.shuffle,
            ),
          )
        ],
      ),
    );
    List<Tuple2<Widget, int>> clickablePresetWidgets = [
      Tuple2(shufflePreset, 0)
    ];
    for (int indexCounter = 1;
        indexCounter < presetColors.length;
        indexCounter++) {
      Color eachColor = presetColors[indexCounter];
      Widget eachWidget = renderEachClickablePreset(eachColor);
      clickablePresetWidgets.add(Tuple2(eachWidget, indexCounter));
    }

    Widget roundedSelectedBorder = Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(280)),
          border: Border.all(color: TileStyles.primaryColor, width: 2),
          color: Colors.transparent),
    );
    Widget retValue = Container(
      alignment: Alignment.center,
      child: ListView(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            alignment: Alignment.center,
            height: 300,
            width: 400,
            decoration: BoxDecoration(
                color: pickerColor.withOpacity(0.2),
                borderRadius: BorderRadius.all(Radius.circular(10))),
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                ...clickablePresetWidgets.map<Widget>(
                  (e) => GestureDetector(
                    onTap: () {
                      handlePresetColorClick(e.item2);
                    },
                    child: Stack(
                      children: [
                        e.item2 == selectedPresetIndex
                            ? roundedSelectedBorder
                            : SizedBox.shrink(),
                        e.item1
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          ElevatedButton(
              onPressed: () {
                setState(() {
                  this.isCustomColorPicker = true;
                });
              },
              child: Text(AppLocalizations.of(context)!.custom))
        ],
      ),
    );
    return retValue;
  }

  Widget renderCustomPicker() {
    return ColorPicker(pickerColor: pickerColor, onColorChanged: changeColor);
  }

  @override
  Widget build(BuildContext context) {
    Map colorParams = ModalRoute.of(context)?.settings.arguments as Map;
    if (!_isInitialize) {
      _isInitialize = true;
      this.widget._params = colorParams;
      if (colorParams.containsKey('color') && colorParams['color'] != null) {
        this.widget.color = colorParams['color'];
        pickerColor = this.widget.color!;
        initialColor = this.widget.color!;
      }
    }

    CancelAndProceedTemplateWidget retValue = CancelAndProceedTemplateWidget(
      routeName: _colorPickernRouteName,
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.pickAColor,
          style: TileStyles.titleBarStyle,
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: Container(
          padding: EdgeInsets.fromLTRB(60, 30, 60, 0),
          margin: EdgeInsets.fromLTRB(0, 40, 0, 0),
          child: isCustomColorPicker
              ? renderCustomPicker()
              : renderPresetColors()),
      onProceed: () {
        return this.onProceedTap();
      },
      onCancel: () {
        this.onCanceTap();
      },
    );

    return retValue;
  }
}
