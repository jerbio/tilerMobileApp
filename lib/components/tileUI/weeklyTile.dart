import 'package:emoji_regex/emoji_regex.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';

class WeeklyTileWidget extends StatefulWidget {
  late SubCalendarEvent subEvent;
  final Function()? onTap;
  bool isPreceding;
  WeeklyTileWidget({subEvent, this.onTap, this.isPreceding = false})
      : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  WeeklyTileWidgetState createState() => WeeklyTileWidgetState();
}

class WeeklyTileWidgetState extends State<WeeklyTileWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension = theme.extension<TileThemeExtension>()!;

    double screenWidth = MediaQuery.of(context).size.width;
    double calculatedWidth = (screenWidth - 16) / 7 - 6;
    Widget? emojiField;
    if (widget.subEvent.emojis != null && widget.subEvent.emojis!.isNotEmpty) {
      String emojiString = Utility.splittingEmoji(widget.subEvent.emojis!);
      emojiString = emojiRegex().firstMatch(emojiString)?.group(0) ?? "";

      emojiField = Text(emojiString,
          maxLines: 1,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ));
    }

    String? addressString = widget.subEvent.searchdDescription != null
        ? widget.subEvent.searchdDescription
        : widget.subEvent.address;
    addressString = addressString == null || addressString.trim().isEmpty
        ? widget.subEvent.addressDescription
        : addressString;
    String tileName =
        widget.subEvent.name == null || widget.subEvent.name!.isEmpty
            ? ((widget.subEvent.isProcrastinate ?? false)
                ? AppLocalizations.of(context)!.procrastinateBlockOut
                : "")
            : widget.subEvent.name!;
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: EdgeInsets.all(3),
        width: calculatedWidth,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.isPreceding
                ? widget.subEvent.isComplete
                    ? TileColors.completedGreen
                    : tileThemeExtension.onSurfaceVariantSecondary
                : colorScheme.onInverseSurface,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (emojiField != null) emojiField,
            Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 10),
              child: Text(tileName,
                  maxLines: 3,
                  style: TextStyle(
                      fontSize: 8, fontFamily: TileTextStyles.rubikFontName)),
            ),
            if (addressString != null && addressString.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  addressString,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 10,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                    fontFamily: TileTextStyles.rubikFontName,
                  ),
                ),
              ),
            TimeFrameWidget(
              timeRange: widget.subEvent,
              isWeeklyView: true,
              fontSize: 8,
              textColor: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
