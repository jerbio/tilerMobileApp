import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';


class MonthlyTileWidget extends StatefulWidget {

  late SubCalendarEvent subEvent;
  MonthlyTileWidget({subEvent}) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  MonthlyTileWidgetState createState() => MonthlyTileWidgetState();
}
class MonthlyTileWidgetState extends State<MonthlyTileWidget> {

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth =( screenWidth * 0.136).floorToDouble();
    int redColor = widget.subEvent.colorRed ?? 127;
    int greenColor = widget.subEvent.colorGreen ?? 127;
    int blueColor = widget.subEvent.colorBlue ?? 127;
    String tileName = widget.subEvent.name == null || widget.subEvent.name!.isEmpty
        ? ((widget.subEvent.isProcrastinate ?? false)
        ? AppLocalizations.of(context)!.procrastinateBlockOut
        : "")
        : widget.subEvent.name!;
    return Container(
      width: calculatedWidth,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 1),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color:Color.fromRGBO(redColor, greenColor, blueColor, 1),
      ),

      padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 1),
      child: Text(
        tileName,
        maxLines: 1,
        style: TextStyle(
          fontFamily: TileTextStyles.rubikFontName,
          fontSize: 10,
        ),
        overflow: TextOverflow.ellipsis,
      ),

    );
  }
}
