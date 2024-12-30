import 'dart:ui';

import 'package:tiler_app/data/tileObject.dart';

class TileColor extends TilerObj {
  int? red;
  int? green;
  int? blue;
  double? opacity;
  TileColor();
  TileColor.fromColor(Color color) {
    this.blue = color.blue;
    this.red = color.red;
    this.green = color.green;
    this.opacity = color.opacity;
  }
  TileColor.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    String rKey = 'r';
    if (json.containsKey(rKey) && json[rKey] != null) {
      red = json[rKey];
    }
    String gKey = 'g';
    if (json.containsKey(gKey) && json[gKey] != null) {
      green = json[gKey];
    }
    String bKey = 'b';
    if (json.containsKey(bKey) && json[bKey] != null) {
      blue = json[bKey];
    }
    String oKey = 'o';
    if (json.containsKey(oKey) && json[oKey] != null) {
      opacity = json[oKey];
    }
  }

  Color? get toColor {
    if (this.blue != null && this.green != null && this.red != null) {
      return Color.fromRGBO(this.red!, this.green!, this.blue!, 1);
    }
    return null;
  }

  bool isEquivalent(TileColor tilerColor) {
    if (tilerColor == this) {
      return true;
    }
    return this.blue == tilerColor.blue &&
        this.green == tilerColor.blue &&
        this.red == tilerColor.red &&
        this.opacity == tilerColor.opacity;
  }

  Map<String, dynamic> toRequestJson() {
    return {
      "IsEnabled": true,
      "Red": this.red,
      "Green": this.green,
      "Blue": this.blue,
      "Opacity": this.opacity,
    };
  }
}
