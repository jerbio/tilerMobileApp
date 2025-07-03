import 'package:flutter/material.dart';

class MonthlyRibbon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    return Container(
      margin: EdgeInsets.fromLTRB(16, 50, 16, 0),
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: weekdays.map((day) => _buildDayText(day,colorScheme)).toList(),
      ),
    );
  }

  Widget _buildDayText(String day,ColorScheme colorScheme) {
    return Text(
      day,
      style:TextStyle(fontSize: 16,color:colorScheme.onSurfaceVariant)
    );
  }
}