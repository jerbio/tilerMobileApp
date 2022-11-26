import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ConfigUpdateButton extends StatefulWidget {
  Icon? prefixIcon;
  String text;
  Function? onPress;
  Decoration? decoration;
  Bool? isPopulated;
  Color? textColor = Color.fromRGBO(31, 31, 31, 1);
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
        //selectionColor: Color.fromRGBO(31, 31, 31, 1),
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
