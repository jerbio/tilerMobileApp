import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class TileStyles {
  TileStyles._();




  static const TextStyle editTimeOrDateTimeStyle = TextStyle(
      fontSize: 18,
      fontFamily: TileTextStyles.rubikFontName,
  );

  static const TextStyle defaultTextStyle = TextStyle(
      fontSize: 18,
      fontFamily: TileTextStyles.rubikFontName,
      color: const Color.fromRGBO(40, 40, 40, 1));

  static EdgeInsets topMargin = EdgeInsets.fromLTRB(0, 20, 0, 0);



  static const datePickersMainStyle =
      TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold);



  static SizedBox bottomPortraitPaddingForTileBatchListOfTiles =
      SizedBox(height: 200);
  static SizedBox bottomLandScapePaddingForTileBatchListOfTiles =
      SizedBox(height: 150);



  static Radius inputFieldRadius = const Radius.circular(50.0);
  static BorderRadius inputFieldBorderRadius =
      BorderRadius.all(inputFieldRadius);
  static EdgeInsets inputFieldPadding = EdgeInsets.fromLTRB(30, 15, 10, 15);
  static TextStyle inputTextStyle(Color color) => TextStyle(
    fontSize: TileDimensions.inputFontSize,
    fontFamily: TileTextStyles.rubikFontName,
    color: color,
  );

  static const EdgeInsets inputPadding = const EdgeInsets.all(8.0);

  static const FontWeight inputFieldFontWeight = FontWeight.w400;
  static const FontWeight inputFieldHintFontWeight = FontWeight.w100;

  // static const double defaultCardElevation = 5.0;




}
