import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';

class TileTextStyles{
  const TileTextStyles._();
  static const String rubikFontName = 'Rubik';

  static const TextStyle fullScreenTextFieldStyle = TextStyle(
      fontSize: TileDimensions.textFontSize,
      fontFamily: rubikFontName,
      fontWeight: FontWeight.w500
  );

  static const TextStyle daySummary = TextStyle(
    fontSize: TileDimensions.daySummarySize,
    color: Color.fromRGBO(153, 153, 153, 1),
  );



  static const TextStyle defaultText = TextStyle(
    fontSize: TileDimensions.textFontSize,
    fontFamily: TileTextStyles.rubikFontName,
  );

  static const TextStyle titleBar = TextStyle(
  );

  static const TextStyle datePickerMain = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle datePickerSave = TextStyle(
    fontFamily: TileTextStyles.rubikFontName,
    // color: TileColors.primaryColor,
  );

  static const TextStyle input = TextStyle(
    fontSize: TileDimensions.inputFontSize,
    fontFamily: TileTextStyles.rubikFontName,
    color: Color.fromRGBO(40, 40, 40, 1), // Use const color
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputHint = TextStyle(
    color: Color.fromRGBO(180, 180, 180, 1),
    fontSize: TileDimensions.textFontSize,
    fontFamily: TileTextStyles.rubikFontName,
    fontWeight: FontWeight.w100,
  );
  static const  datePickersSaveStyle=
  TextStyle(fontFamily: rubikFontName);
  static const datePickersMainStyle =
  TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold);
  static TextStyle daySummaryStyle = const TextStyle(
      fontSize: 30, color: const Color.fromRGBO(153, 153, 153, 1));


  static const TextStyle defaultTextStyle = TextStyle(
  fontSize: 18,
  fontFamily: rubikFontName,
  );
}