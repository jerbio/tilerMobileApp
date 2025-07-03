import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

class TravelTimeBefore extends StatefulWidget {
  SubCalendarEvent? subEvent;
  late Duration travelTimeDuration;
  TravelTimeBefore(travelTimeBeforeMs, this.subEvent) {
    assert(travelTimeBeforeMs != null);
    this.travelTimeDuration = travelTimeBeforeMs;
  }
  @override
  TravelTimeBeforeState createState() => TravelTimeBeforeState();
}

class TravelTimeBeforeState extends State<TravelTimeBefore> {
  @override
  Widget build(BuildContext context) {
    String durationString = Utility.toHuman(this.widget.travelTimeDuration);
    final theme= Theme.of(context);
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: TileColors.travel, borderRadius: BorderRadius.circular(8)),
            child: Icon(
              Icons.directions_walk,
              color: tileThemeExtension.onFixedColors,
              size: 20.0,
            ),
          ),
          Row(
            children: [
              Text(
                'You need to leave in ',
                overflow: TextOverflow.ellipsis,
                style:  TextStyle(
                    fontSize: 15,
                    fontFamily: TileTextStyles.rubikFontName
                ),
              ),
              Text(
                '$durationString',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 15,
                    fontFamily: TileTextStyles.rubikFontName,
                    fontWeight: FontWeight.w600,
                    color: TileColors.travel
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
