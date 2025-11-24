import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

class WeekDayButton extends StatefulWidget {
  bool showMonth = false;
  DateTime dateTime;
  WeekDayButton({
    required this.dateTime,
    this.showMonth = false,
  }) : super(
      key: ValueKey(
          dateTime.toString() + Utility.currentTime().day.toString()));
  @override
  State<StatefulWidget> createState() => _WeekDayButtonState();
}

class _WeekDayButtonState extends State<WeekDayButton> {
  late DateTime dateTime;
  @override
  void initState() {
    super.initState();
    this.dateTime = this.widget.dateTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    List<Widget> childWidgets = [
      Container(
        margin: EdgeInsets.fromLTRB(0, 10, 0, 0),
        decoration:  dateTime.isToday?
        TileDecorations.ribbonsButtonSelectedDecoration(colorScheme.primary).copyWith(
            borderRadius: BorderRadius.all(Radius.circular(10.0),
            )
        ) : TileDecorations.ribbonsButtonDefaultDecoration(colorScheme.surfaceContainer),
        alignment: Alignment.center,
        height: 40,
        width: 40,
        child: Text(
          DateFormat(DateFormat.DAY).format(this.dateTime),
          style:TextStyle(
              fontSize: 20,
              color:  dateTime.isToday?colorScheme.onPrimary:tileThemeExtension.onSurfaceVariantSecondary
          ),
        ),
      ),
      Container(
          padding: EdgeInsets.all(17),
          child: Text(
                DateFormat(DateFormat.ABBR_WEEKDAY).format(this.dateTime),
                style: TextStyle(
                    color:  tileThemeExtension.onSurfaceVariantSecondary,
                )
              ),
      )
    ];
    if (this.widget.showMonth) {
      childWidgets.add(Container(
        child: Text(
          DateFormat(DateFormat.ABBR_MONTH).format(this.dateTime),
          style:  TextStyle(
            color:  tileThemeExtension.onSurfaceVariantSecondary,
          ),
        ),
      ));
    }

    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: childWidgets,
      ),
    );
  }
}
