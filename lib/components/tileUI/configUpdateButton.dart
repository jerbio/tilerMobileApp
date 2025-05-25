import 'dart:ffi';
import 'dart:ui' as dartUI;
import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import '../../styles.dart';

class ConfigUpdateButton extends StatefulWidget {
  final Icon? prefixIcon;
  final String text;
  final Function? onPress;
  final Decoration? decoration;
  final Bool? isPopulated;
  final Color? textColor;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final ButtonStyle? buttonStyle;
  final EdgeInsets? iconPadding;
  final BoxConstraints? constraints;
  static Color populatedTextColor = Colors.white;
  static Color iconColor = Color.fromRGBO(154, 158, 159, 1);
  static BoxDecoration populatedDecoration = BoxDecoration(
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
  ConfigUpdateButton(
      {required this.text,
      this.decoration,
      this.onPress,
      this.prefixIcon,
      this.isPopulated,
      this.textStyle,
      this.buttonStyle,
      this.constraints,
      this.iconPadding = const EdgeInsets.fromLTRB(5, 2, 5, 5),
      this.padding = const EdgeInsets.fromLTRB(5, 10, 10, 7),
      this.textColor = const Color.fromRGBO(31, 31, 31, 1)});

  @override
  ConfigUpdateButtonState createState() => ConfigUpdateButtonState();
}

class ConfigUpdateButtonState extends State<ConfigUpdateButton> {
  Widget build(BuildContext context) {
    List<Widget> childWidgets = [];
    if (this.widget.prefixIcon != null) {
      childWidgets.add(Container(
          margin: this.widget.iconPadding, child: this.widget.prefixIcon!));
    }
    String textButtonString = this.widget.text;
    Widget textButton = TextButton(
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: dartUI.Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: this.widget.textStyle ??
            TextStyle(
                overflow: TextOverflow.ellipsis,
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: this.widget.textColor),
        foregroundColor: this.widget.textColor,
      ),
      onPressed: () async {
        if (this.widget.onPress != null) {
          await this.widget.onPress!();
        }
      },
      child: Text(
        textButtonString,
        overflow: TextOverflow.ellipsis,
        style: this.widget.textStyle ??
            TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
            ),
      ),
    );

    childWidgets.add(textButton);

    Widget retValue = new ElevatedButton(
      style: this.widget.buttonStyle ?? TileStyles.strippedButtonStyle,
      onPressed: () {
        if (this.widget.onPress != null) {
          this.widget.onPress!();
        }
      },
      child: Container(
        constraints: this.widget.constraints ??
            BoxConstraints(
                minWidth: (MediaQuery.of(context).size.width * 0.30)),
        decoration: this.widget.decoration,
        padding: this.widget.padding,
        child: Wrap(
          alignment: WrapAlignment.center,
          children: childWidgets,
        ),
      ),
    );

    return retValue;
  }
}
