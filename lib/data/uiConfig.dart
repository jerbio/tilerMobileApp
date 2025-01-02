import 'package:tiler_app/data/tileColor.dart';
import 'package:tiler_app/data/tileObject.dart';

class UIConfig extends TilerObj {
  String? id;
  TileColor? tileColor;
  UIConfig.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    String colorKey = 'color';
    if (json.containsKey(colorKey) && json[colorKey] != null) {
      tileColor = TileColor.fromJson(json[colorKey]);
    }
  }

  bool isEquivalent(UIConfig uiConfig) {
    if (this == uiConfig) {
      return true;
    }
    if (this.tileColor != null && uiConfig.tileColor != null) {
      return this.tileColor!.isEquivalent(uiConfig.tileColor!);
    }
    return false;
  }
}
