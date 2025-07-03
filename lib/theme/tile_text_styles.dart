import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

class TileTextStyles{
  const TileTextStyles._();
  static const String rubikFontName = 'Rubik';
  static const FontWeight inputFieldFontWeight = FontWeight.w400;
  static const FontWeight inputFieldHintFontWeight = FontWeight.w100;

  static const TextStyle fullScreenTextFieldStyle = TextStyle(
      fontSize: TileDimensions.textFontSize,
      fontFamily: rubikFontName,
      fontWeight: FontWeight.w500
  );

  static  TextStyle daySummary({required Color color, double? size}) => TextStyle(
    fontSize: size??TileDimensions.daySummarySize,
    color: color,
  );

  static const TextStyle editTimeOrDateTime = TextStyle(
    fontSize: 18,
    fontFamily: TileTextStyles.rubikFontName,
  );

  static const TextStyle defaultText = TextStyle(
    fontSize: 18,
    fontFamily: rubikFontName,
  );


  static const TextStyle datePickerMain = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle datePickerSave = TextStyle(
    fontFamily: TileTextStyles.rubikFontName,
  );


  static const  datePickersSaveStyle=
  TextStyle(fontFamily: rubikFontName);

  static const datePickersMain =
  TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold
  );

  static TextStyle inputTextStyle(Color color) => TextStyle(
    fontSize: TileDimensions.inputFontSize,
    fontFamily: TileTextStyles.rubikFontName,
    color: color,
  );

  static const appBar=TextStyle(
    fontWeight: FontWeight.w800,
    color: TileColors.lightContent,
    fontSize: 22,
  );


}
