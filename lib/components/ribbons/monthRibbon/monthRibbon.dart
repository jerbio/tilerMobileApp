import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';

class MonthlyRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      margin: EdgeInsets.fromLTRB(16, 50, 16, 0),
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekdays.map((day) => _buildDayText(day)).toList(),
      ),
    );
  }

  Widget _buildDayText(String day) {
    return Text(
      day,
      style: TextStyle(
        fontFamily: TileStyles.rubikFontName,
        fontSize: 16,
        color: Colors.grey,
      ),
    );
  }
}