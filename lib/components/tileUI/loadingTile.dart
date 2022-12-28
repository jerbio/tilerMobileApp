import 'package:flutter/material.dart';

class LoadingTile extends StatefulWidget {
  @override
  LoadingTileState createState() => LoadingTileState();
}

class LoadingTileState extends State<LoadingTile> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
          child: Column(
        children: [CircularProgressIndicator(), Text('..Loading..')],
      )),
    );
  }
}
