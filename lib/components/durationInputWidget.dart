import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_box_shadows.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class DurationInputWidget extends StatefulWidget {
  final Duration? duration;
  final String? placeholder;
  final Function? onDurationChange;
  final Widget? icon;

  DurationInputWidget(
      {this.icon, this.duration, this.placeholder, this.onDurationChange});
  @override
  State<StatefulWidget> createState() => _DurationInputWidgetState();
}

class _DurationInputWidgetState extends State<DurationInputWidget> {
  Duration? _setDuration;
  @override
  void initState() {
    super.initState();
    this._setDuration = this.widget.duration;
  }

  Duration? get _duration {
    return this._setDuration ?? this.widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': _duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        print(durationParams['duration']);
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _setDuration = populatedDuration;
          }
        });
        if (this.widget.onDurationChange != null) {
          this.widget.onDurationChange!(_duration);
        }
      });
    };
    String? textButtonString =
        this.widget.placeholder ?? AppLocalizations.of(context)!.durationStar;
    if (_duration != null && _duration!.inMinutes > 1) {
      textButtonString = "";
      int hour = _duration!.inHours.floor();
      int minute = _duration!.inMinutes.remainder(60);
      if (hour > 0) {
        textButtonString = '${hour}h';
        if (minute > 0) {
          textButtonString = '${textButtonString} : ${minute}m';
        }
      } else {
        if (minute > 0) {
          textButtonString = '${minute}m';
        }
      }
    }

    Widget durationIcon = this.widget.icon ??
        Icon(Icons.timelapse_outlined, color: colorScheme.onSurface);
    Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: Container(
            padding: EdgeInsets.fromLTRB(30, 10, 10, 10),
            height: TileDimensions.inputHeight,
            decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: TileDimensions.inputFieldBorderRadius,
                boxShadow: [TileBoxShadows.inputFieldBoxShadow(tileThemeExtension!.shadowHigh)]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                durationIcon,
                Container(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: TileDimensions.inputFontSize,
                        ),
                      ),
                      onPressed: setDuration,
                      child: Text(
                        textButtonString,
                        style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          color: colorScheme.onSurface,
                          fontWeight: (_duration ?? Duration.zero).inSeconds >
                                  Duration.secondsPerMinute
                              ? TileTextStyles.inputFieldFontWeight
                              : TileTextStyles.inputFieldHintFontWeight,
                        ),
                      ),
                    ))
              ],
            ),
        ),
    );
    return retValue;
  }
}
