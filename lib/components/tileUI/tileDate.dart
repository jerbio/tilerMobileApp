import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

//ey: not used
class TileDate extends StatefulWidget {
  DateTime date;
  TileDate({required this.date});
  @override
  _TileDateState createState() => _TileDateState();
}

class _TileDateState extends State<TileDate> {

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme= theme.colorScheme;
    String locale = Localizations.localeOf(context).languageCode;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
              width: 25,
              height: 25,
              decoration: TileDecorations.tileIconContainerBoxDecoration(colorScheme.onSurface),
              margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: Icon(
                Icons.calendar_month,
                color: colorScheme.onSurface,
                size: TileDimensions.tileIconSize,
              )),
          Text(
            DateFormat.yMMMd(locale).format(this.widget.date),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileTextStyles.rubikFontName,
            ),
          )
        ],
      ),
    );
  }
}
