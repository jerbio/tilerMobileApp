import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../styles.dart';

class ConfigUpdateButton extends StatefulWidget {
  Icon? prefixIcon;
  String text;
  Function? onPress;
  Decoration? decoration;
  Bool? isPopulated;
  Color? textColor = Color.fromRGBO(31, 31, 31, 1);
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
      this.textColor});

  @override
  ConfigUpdateButtonState createState() => ConfigUpdateButtonState();
}

class ConfigUpdateButtonState extends State<ConfigUpdateButton> {
  Widget build(BuildContext context) {
    List<Widget> childWidgets = [];
    if (this.widget.prefixIcon != null) {
      childWidgets.add(this.widget.prefixIcon!);
    }
    String textButtonString = this.widget.text;
    Widget textButton = TextButton(
      style: TextButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        primary: this.widget.textColor,
      ),
      onPressed: () async {
        if (this.widget.onPress != null) {
          await this.widget.onPress!();
        }
      },
      child: Text(
        textButtonString,
        style: TextStyle(
          fontFamily: TileStyles.rubikFontName,
        ),
      ),
    );
    childWidgets.add(textButton);
    Widget retValue = new GestureDetector(
        onTap: () {
          if (this.widget.onPress != null) {
            this.widget.onPress!();
          }
        },
        child: Container(
            decoration: this.widget.decoration,
            margin: EdgeInsets.all(10),
            padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: childWidgets,
            )));

    return retValue;
  }
}
