import 'package:flutter/material.dart';

class EmptyDayTile extends StatefulWidget {
  @override
  EmptyDayTileState createState() => EmptyDayTileState();
}

class EmptyDayTileState extends State<EmptyDayTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text('We got nothing'),
    );
  }
}
