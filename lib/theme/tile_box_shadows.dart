import 'package:flutter/material.dart';

class TileBoxShadows {
  TileBoxShadows._();
  static BoxShadow inputFieldBoxShadow(Color color) => BoxShadow(
    color:color.withValues(alpha:  0.54),
    spreadRadius: 2,
    blurRadius: 50,
    offset: Offset(0, 0),
  );

}