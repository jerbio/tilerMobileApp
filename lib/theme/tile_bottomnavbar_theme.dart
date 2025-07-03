import 'package:flutter/material.dart';
import 'tile_colors.dart';

class TileBottomNavTheme {
  TileBottomNavTheme._();

  static const BottomNavigationBarThemeData  theme = BottomNavigationBarThemeData(
    selectedItemColor: TileColors.primary,
    unselectedItemColor: TileColors.primary,
    elevation: 0,
    showSelectedLabels: false,
    showUnselectedLabels: false,
  );
}