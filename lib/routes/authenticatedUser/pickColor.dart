import 'package:flutter/cupertino.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
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
  double colorSelectorRadius = 60;
  late double roundedSelectorRadius;

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
    roundedSelectorRadius = colorSelectorRadius + 10;
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
      width: colorSelectorRadius,
      height: colorSelectorRadius,
      decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.circular(colorSelectorRadius * 4)),
          color: color),
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

  Widget renderCollectionOfColors(
      int gridCount, List<Tuple2<Widget, int>> clickablePresetWidgets) {
    int gridColumnCount = 3;
    List<Widget> rows = [];
    List<Widget> rowWidgets = [];

    Widget roundedSelectedBorder = Container(
      width: roundedSelectorRadius,
      height: roundedSelectorRadius,
      decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.circular(roundedSelectorRadius)),
          border: Border.all(color: TileColors.primaryColor, width: 2),
          color: Colors.transparent),
    );
    Widget tranparentSelectedBorder = Container(
      width: roundedSelectorRadius,
      height: roundedSelectorRadius,
      decoration: BoxDecoration(
          borderRadius:
              BorderRadius.all(Radius.circular(roundedSelectorRadius)),
          border: Border.all(color: Colors.transparent, width: 2),
          color: Colors.transparent),
    );
    for (int i = 0; i < clickablePresetWidgets.length; i++) {
      int modulo = i % gridColumnCount;
      if (modulo == 0) {
        rowWidgets = [];
        rows.add(Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: rowWidgets,
          ),
        ));
      }
      var e = clickablePresetWidgets[i];
      Widget tapableCircle = GestureDetector(
        onTap: () {
          handlePresetColorClick(e.item2);
        },
        child: Stack(
          children: [
            e.item2 == selectedPresetIndex
                ? roundedSelectedBorder
                : tranparentSelectedBorder,
            e.item1
          ],
        ),
      );
      rowWidgets.add(tapableCircle);
    }

    Widget column = Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: rows,
    );

    return column;
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
              // size: 70,
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

    Widget retValue = Container(
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
              padding: EdgeInsets.all(20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: pickerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              child: renderCollectionOfColors(3, clickablePresetWidgets)),
          ElevatedButton(
              style: ButtonStyle(
                side: MaterialStateProperty.all(
                    BorderSide(color: TileColors.primaryColor)),
                shadowColor: MaterialStateProperty.resolveWith((states) {
                  return Colors.transparent;
                }),
                elevation: MaterialStateProperty.resolveWith((states) {
                  return 0;
                }),
                backgroundColor: MaterialStateProperty.resolveWith((states) {
                  return Colors.transparent;
                }),
                foregroundColor: MaterialStateProperty.resolveWith((states) {
                  return TileColors.primaryColor;
                }),
                minimumSize: MaterialStateProperty.resolveWith((states) {
                  return Size(MediaQuery.sizeOf(context).width - 20, 50);

                  // Size.(MediaQuery.sizeOf(context).width);
                }),
              ),
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
        backgroundColor: TileColors.primaryColor,
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
