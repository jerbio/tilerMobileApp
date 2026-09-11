import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/util.dart';

class DayButton extends StatefulWidget {
  bool showMonth = false;
  bool isSelected;
  DateTime dateTime;
  Function? onTapped;
  final bool preview;

  /// Compact strip variant (grid-mode scroll header): a small circle for
  /// the day number with the weekday abbreviation beneath, no month row,
  /// no top margin. Default `false` keeps the legacy ribbon button
  /// pixel-identical for list / Weekly / Monthly.
  final bool compact;
  DayButton({
    required this.dateTime,
    this.onTapped,
    this.showMonth = false,
    this.isSelected = false,
    this.preview=false,
    this.compact = false,
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

  /// The compact day button: circle + weekday, ~58px tall.
  Widget _buildCompact(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool selected = widget.isSelected;
    final bool today = dateTime.isToday;
    final double size = selected ? 40 : 36;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.preview
          ? null
          : () {
              if (widget.onTapped != null) {
                widget.onTapped!(dateTime);
              }
            },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            alignment: Alignment.center,
            height: size,
            width: size,
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              DateFormat(DateFormat.DAY).format(dateTime),
              style: TextStyle(
                fontSize: selected ? 16 : 15,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colorScheme.onPrimary
                    : (today ? colorScheme.primary : colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat(DateFormat.ABBR_WEEKDAY).format(dateTime),
            style: TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompact(context);
    }
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
                  fontFamily: TileTextStyles.rubikFontName,
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
      onTap: widget.preview?null:() {
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
