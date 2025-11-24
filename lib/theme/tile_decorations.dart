import 'package:flutter/material.dart';
import 'package:tiler_app/util.dart';

class TileDecorations {
  TileDecorations._();

  static BoxDecoration ribbonsButtonDefaultDecoration(Color color) => BoxDecoration(
    borderRadius: BorderRadius.all(
      const Radius.circular(10.0),
    ),
    color: color,
  );

  static BoxDecoration ribbonsButtonSelectedDecoration(Color color) => BoxDecoration(
    borderRadius: BorderRadius.all(
      const Radius.circular(20.0),
    ),
    color:color,
  );
  static BoxDecoration configUpdate_notSelected(Color borderColor) =>BoxDecoration(
      color: Colors.transparent,
      border: Border.all(
        color: borderColor,
        width: 1,
      ),
      borderRadius: const BorderRadius.all(
        const Radius.circular(60.0),
      )
  );

  static BoxDecoration configUpdate_Selected(Color color)=> BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(60.0),
      ),
      color: color);

  static final BoxDecoration defaultBackground =
  BoxDecoration(color: Colors.transparent);

  static BoxDecoration invalidBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.all(
      const Radius.circular(10.0),
    ),
    gradient: LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        HSLColor.fromAHSL(1, 360, 0.9, 0.46).toColor(),
        HSLColor.fromAHSL(1, 350, 1, 0.7).toColor()
      ],
    ),
  );

  static BoxDecoration tileIconContainerBoxDecoration(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(8),
  );

  static BoxDecoration tileIconContainerBoxDecorationMonthly(Color color) => BoxDecoration(
    color: color.withValues(alpha: 0.1),
    shape: BoxShape.circle,
  );

  static BoxDecoration populatedDecoration (Color color)=> BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      gradient: LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          color.withLightness( 0.33),
          color.withLightness( 0.46),
        ],
      )
  );


  static InputDecoration onboardingInputDecoration (Color borderColor, Color focusColor, String hintText)=>InputDecoration(
    contentPadding: EdgeInsets.fromLTRB(20, 10, 20, 10),
    border: OutlineInputBorder(
      gapPadding: 40,
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide(color:  borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      gapPadding: 40,
      borderRadius: BorderRadius.circular(30.0),
      borderSide: BorderSide(color: focusColor
      ),
    ),
    hintText: hintText,
    filled: true,
    isDense: true,
    fillColor: Colors.transparent,
  );

  static BoxDecoration onboardingBoxDecoration(Color borderColor)=>BoxDecoration(
    borderRadius: BorderRadius.circular(30.0),
    border: Border.all(color:borderColor)
  );
}
