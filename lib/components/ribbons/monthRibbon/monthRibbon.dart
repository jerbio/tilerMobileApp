import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class MonthlyRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final theme=Theme.of(context);
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 50, 16, 0),
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekdays.map((day) => _buildDayText(day,tileThemeExtension)).toList(),
      ),
    );
  }

  Widget _buildDayText(String day,TileThemeExtension tileThemeExtension) {
    return Text(
      day,
      style:TextStyle(fontSize: 14,color:tileThemeExtension.onSurfaceVariantSecondary)
    );
  }
}