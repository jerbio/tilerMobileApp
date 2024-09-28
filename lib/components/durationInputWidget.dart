import 'package:flutter/material.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DurationInputWidget extends StatefulWidget {
  final Duration? duration;
  final String? placeholder;
  final Function? onDurationChange;

  DurationInputWidget({this.duration, this.placeholder, this.onDurationChange});
  @override
  State<StatefulWidget> createState() => _DurationInputWidgetState();
}

class _DurationInputWidgetState extends State<DurationInputWidget> {
  Duration? _duration;
  final Color textBackgroundColor = TileStyles.textBackgroundColor;
  final Color textBorderColor = TileStyles.textBorderColor;
  final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();
  @override
  void initState() {
    super.initState();
    this._duration = this.widget.duration;
  }

  @override
  Widget build(BuildContext context) {
    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': _duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        print(durationParams['duration']);
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        setState(() {
          if (populatedDuration != null) {
            _duration = populatedDuration;
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
    Widget retValue = new GestureDetector(
        onTap: setDuration,
        child: Container(
            padding: TileStyles.inputFieldPadding,
            height: TileStyles.inputHeight,
            decoration: BoxDecoration(
                color: textBackgroundColor,
                borderRadius: TileStyles.inputFieldBorderRadius,
                boxShadow: [TileStyles.inputFieldBoxShadow]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.timelapse_outlined, color: inputFieldIconColor),
                Container(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: TileStyles.inputFontSize,
                        ),
                      ),
                      onPressed: setDuration,
                      child: Text(
                        textButtonString,
                        style: TextStyle(
                          fontFamily: TileStyles.rubikFontName,
                        ),
                      ),
                    ))
              ],
            )));
    return retValue;
  }
}
