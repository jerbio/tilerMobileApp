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
    String suggestionName = this.widget.nextTileSuggestion.name!;

    List<String> splitByDots = suggestionName.split('.').toList();
    int? suggestionNumber = int.tryParse(splitByDots[0]);
    String? tileName = this.widget.nextTileSuggestion.name;

    print(splitByDots);

    if (suggestionNumber != null) {
      tileName = splitByDots.skip(1).toList().join('.');
    }

    print(tileName);

    if (tileName != null && tileName.isNotEmpty) {
      return OutlinedButton(
          onPressed: () {
            final autoTile = AutoTile(
              description: tileName!,
            );
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddTile(autoTile: autoTile)));
          },
          child: Container(
              child: Stack(
            children: [
              suggestionNumber != null
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        suggestionNumber.toString(),
                        style: TextStyle(
                            fontSize: 90,
                            color: Color.fromRGBO(10, 10, 10, 0.05)),
                      ),
                    )
                  : SizedBox.shrink(),
              Center(child: Text(tileName, style: TextStyle(fontSize: 20)))
            ],
          )));
    }
    return SizedBox.shrink();
  }
}
