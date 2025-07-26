import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';


class DurationUIWidget extends StatefulWidget {
  Duration duration;
  List<Duration>? presetDurations;
  DurationUIWidget({required this.duration, presetDurations, Key? key})
      : super(key: key);
  @override
  State createState() => _DurationUIWidgetState();
}

class _DurationUIWidgetState extends State<DurationUIWidget> {
  late Duration _duration;
  @override
  void initState() {
    _duration = this.widget.duration;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    int days = this._duration.inDays.floor();
    int totalHoursFloor = this._duration.inHours.floor();
    int hour = totalHoursFloor - (days * 24);
    int minute = this._duration.inMinutes.floor() - (totalHoursFloor * 60);
    TextStyle unitTimeStyle= TextStyle(
        fontFamily: TileTextStyles.rubikFontName,
        color: tileThemeExtension.onSurfaceHint,
        fontSize: 35,
        fontWeight: FontWeight.w500);
    const topSpacing = EdgeInsets.fromLTRB(0, 0, 0, 10);

    Widget dayBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              days.toString(),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.day)
        ],
      ),
    );

    Widget hourBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              hour.toString().padLeft(2, '0'),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.hour)
        ],
      ),
    );
    Widget minuteBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              minute.toString().padLeft(2, '0'),
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.min)
        ],
      ),
    );

    Widget columnBox = Container(
      child: Column(
        children: [
          Container(
            margin: topSpacing,
            child: Text(
              ':',
              style: unitTimeStyle,
            ),
          ),
          Text(AppLocalizations.of(context)!.whiteSpace)
        ],
      ),
    );

    List<Widget> childWidgets = <Widget>[hourBox, columnBox, minuteBox];
    if (days > 0) {
      childWidgets.insert(0, columnBox);
      childWidgets.insert(0, dayBox);
    }

    return Column(
      children: [
        Container(
          child: Row(
            children: childWidgets,
          ),
        ),
      ],
    );
  }
}
