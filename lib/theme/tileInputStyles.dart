import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
class TileInputStyles {
  TileInputStyles._();

  static InputDecoration generateTextInputDecoration(
       {
         String? inputHint,
        Icon? prefixIcon,
        required fillColor,
        required borderColor,
        required textColor,
      }) {
    return InputDecoration(
      hintText: inputHint,
      filled: true,
      isDense: true,
      icon: prefixIcon,
      hintStyle: TextStyle(
          color: textColor,
          fontSize: TileDimensions.textFontSize,
          fontFamily: TileTextStyles.rubikFontName,
          fontWeight: FontWeight.w500),
      contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
      fillColor: fillColor,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(15.0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        borderSide: BorderSide(
          color: borderColor,
          width: 2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(15.0)),
        borderSide: BorderSide(
          color: borderColor,
          width: 1.5,
        ),
      ),
    );
  }
}