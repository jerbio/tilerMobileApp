import 'package:emoji_regex/emoji_regex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

class TileName extends StatefulWidget {
  SubCalendarEvent subEvent;
  TextStyle? textStyle;
  TileName(this.subEvent, {this.textStyle});
  @override
  TileNameState createState() => TileNameState();
}

class TileNameState extends State<TileName> {
  TextStyle textStyle = TextStyle(
      fontSize: 20,
      fontFamily: TileTextStyles.rubikFontName,
      fontWeight: FontWeight.w500,
      color: Color.fromRGBO(31, 31, 31, 1));
  @override
  Widget build(BuildContext context) {
    if (this.widget.textStyle != null) {
      textStyle = this.widget.textStyle!;
    }
    SubCalendarEvent subEvent = widget.subEvent;
    int redColor = subEvent.colorRed == null ? 125 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 125 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 125 : subEvent.colorGreen!;
    String name = subEvent.name == null || subEvent.name!.isEmpty
        ? ((subEvent.isProcrastinate ?? false)
            ? AppLocalizations.of(context)!.procrastinateBlockOut
            : "")
        : subEvent.name!;
    double opacity = subEvent.colorOpacity == null ? 1 : subEvent.colorOpacity!;
    Widget emojiField = Text('');
    if (subEvent.emojis != null && subEvent.emojis!.isNotEmpty) {
      double fontSize = 16;
      String emojiString = subEvent.emojis!.trim();
      if (emojiString.length > 0) {
        int emojiCount = emojiRegex().allMatches(emojiString).length;
        emojiCount = emojiCount == 0 ? 1 : emojiCount;
        fontSize = fontSize / emojiCount + 2;
      }
      emojiField = Text(emojiString,
          style: TextStyle(
              fontSize: fontSize,
              fontFamily: TileTextStyles.rubikFontName,
              fontWeight: FontWeight.bold,
              color: Color.fromRGBO(31, 31, 31, 1)));
    }

    if (subEvent.emojis == null || subEvent.emojis!.isEmpty) {
      if (subEvent.thirdpartyType == TileSource.google) {
        String assetLabel = AppLocalizations.of(this.context)!.googleLogo;
        String assetName =
            'assets/icons/svg/google-outline---filled(24x24)@1x.svg';
        emojiField = SvgPicture.asset(assetName, semanticsLabel: assetLabel);
      }
    }

    var nameColor = Color.fromRGBO(redColor, greenColor, blueColor, opacity);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 25,
            height: 25,
            margin: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            decoration: BoxDecoration(
              color: nameColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(children: <Widget>[
              Center(
                child: emojiField,
              )
            ]),
          ),
          Flexible(
              child: new Container(
                  padding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                  child: Text(
                    name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: this.textStyle,
                  )))
        ],
      ),
    );
  }
}
