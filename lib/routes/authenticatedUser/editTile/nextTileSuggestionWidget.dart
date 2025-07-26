import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/theme/tile_button_styles.dart';


class NextTileSuggestionWidget extends StatefulWidget {
  NextTileSuggestion nextTileSuggestion;
  NextTileSuggestionWidget({required this.nextTileSuggestion});
  @override
  State<StatefulWidget> createState() => _NextTileSuggestionWidgetState();
}

class _NextTileSuggestionWidgetState extends State<NextTileSuggestionWidget> {
  final int _maxLengthOfSuggestion = 80;
  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme= theme.colorScheme;

    String suggestionName = this.widget.nextTileSuggestion.name!;

    List<String> splitByDots = suggestionName.split('.').toList();
    int? suggestionNumber = int.tryParse(splitByDots[0]);
    String? tileName = this.widget.nextTileSuggestion.name;

    if (suggestionNumber != null) {
      tileName = splitByDots.skip(1).toList().join('.');
    }

    if (tileName != null && tileName.isNotEmpty) {
      String suggestionText = tileName.length > _maxLengthOfSuggestion
          ? tileName.substring(0, _maxLengthOfSuggestion) + "..."
          : tileName;
      return OutlinedButton(
          style: TileButtonStyles.suggested(),
          onPressed: () {
            final autoTile = AutoTile(
              description: tileName!,
            );
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddTile(preTile: autoTile)));
          },
          child: Container(
              // padding: EdgeInsets.all(20),
              child: Stack(
            children: [
              suggestionNumber != null
                  ? Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        suggestionNumber.toString(),
                        style: TextStyle(
                            fontSize: 90,
                            color: colorScheme.onSurface.withValues(alpha: 0.05)),
                      ),
                    )
                  : SizedBox.shrink(),
              Center(
                  child: Text(
                      suggestionText, style:TextStyle(fontSize: 20),
                  ),
              ),
            ],
          )));
    }
    return SizedBox.shrink();
  }
}
