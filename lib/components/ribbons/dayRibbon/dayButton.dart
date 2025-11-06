import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/util.dart';

class DayButton extends StatefulWidget {
  bool showMonth = false;
  bool isSelected;
  DateTime dateTime;
  Function? onTapped;
  DayButton({
    required this.dateTime,
    this.onTapped,
    this.showMonth = false,
    this.isSelected = false,
  }) : super(
            key: ValueKey(
                dateTime.toString() + Utility.currentTime().day.toString()));
  @override
  State<StatefulWidget> createState() => _DayButtonState();
}

class _DayButtonState extends State<DayButton> {
  late DateTime dateTime;
  @override
  void initState() {
    super.initState();
    this.dateTime = this.widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme= Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    var decoration = this.widget.isSelected ? TileDecorations.ribbonsButtonSelectedDecoration(colorScheme.primary) : TileDecorations.ribbonsButtonDefaultDecoration(colorScheme.surfaceContainer);
    double buttonHeight = 40 * (this.widget.isSelected ? 1.3 : 1);
    double buttonWidth = 40 * (this.widget.isSelected ? 1.3 : 1);
    List<Widget> childWidgets = [
      Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        alignment: Alignment.center,
        height: buttonHeight,
        width: buttonWidth,
        decoration: decoration,
        child: Text(
          DateFormat(DateFormat.DAY).format(this.dateTime),
          style: TextStyle(
              fontSize: 20,
              fontWeight: this.widget.isSelected ? FontWeight.w500 : null,
              color: this.widget.isSelected
                  ? colorScheme.onPrimary
                  : tileThemeExtension.onSurfaceVariantSecondary
          ),
        )
      ),
      Container(
          padding:
              this.widget.isSelected ? EdgeInsets.all(11) : EdgeInsets.all(17),
          child: Text(DateFormat(DateFormat.ABBR_WEEKDAY).format(this.dateTime),
              style: TextStyle(
                  fontFamily: TileStyles.rubikFontName,
                  color: this.widget.isSelected ? colorScheme.onSurface: tileThemeExtension.onSurfaceVariantSecondary,
              ),
          )
      ,)
    ];
    if (this.widget.showMonth) {
      childWidgets.add(Container(
        child: Text(
          DateFormat(DateFormat.ABBR_MONTH).format(this.dateTime),
          style: TextStyle(
              color: this.widget.isSelected ? colorScheme.onSurface :  tileThemeExtension.onSurfaceVariantSecondary),
        ),
      ));
    }

    return GestureDetector(
      onTap: () {
        if (this.widget.onTapped != null) {
          this.widget.onTapped!(this.dateTime);
        }
      },
      child: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: childWidgets,
        ),
      ),
    );
  }
}
