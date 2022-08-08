import 'package:flutter/material.dart';

class TileStyles {
  static final double tileWidth = 350;
  static final double tileHeight = 350;
  static final double tileWidthRatio = 0.85;
  static final double borderRadius = 12;
  static Color borderColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color activeColor = HSLColor.fromAHSL(1, 198, 1, 0.33).toColor();
  static Color disabledColor = Color.fromRGBO(225, 225, 225, 1);
  static Color disabledTextColor = HSLColor.fromAHSL(1, 0, 0, 0.7).toColor();
  static Color enabledTextColor = Colors.black87;
}
