import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';

class NextTileSuggestionWidget extends StatefulWidget {
  NextTileSuggestion nextTileSuggestion;
  NextTileSuggestionWidget({required this.nextTileSuggestion});
  @override
  State<StatefulWidget> createState() => _NextTileSuggestionWidgetState();
}

class _NextTileSuggestionWidgetState extends State<NextTileSuggestionWidget> {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: () {
          final autoTile = AutoTile(
            description: this.widget.nextTileSuggestion.name!,
          );
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddTile(autoTile: autoTile)));
        },
        child: Text(this.widget.nextTileSuggestion.name!));
  }
}
