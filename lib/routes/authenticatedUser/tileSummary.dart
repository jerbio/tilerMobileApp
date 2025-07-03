import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTile.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tileThemeExtension.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TileSummary extends StatefulWidget {
  SubCalendarEvent subEvent;
  TileSummary(this.subEvent);
  @override
  State<StatefulWidget> createState() => _TileSummaryState();
}

class _TileSummaryState extends State<TileSummary> {
  late SubCalendarEvent subEvent;
  final double iconSize = 25;
  late ThemeData theme;
  late ColorScheme colorScheme;
  late  TileThemeExtension tileThemeExtension;
  @override
  void initState() {
    super.initState();
    subEvent = this.widget.subEvent;
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
  }

  @override
  Widget build(BuildContext context) {
    int redColor = subEvent.colorRed == null ? 127 : subEvent.colorRed!;
    int blueColor = subEvent.colorBlue == null ? 127 : subEvent.colorBlue!;
    int greenColor = subEvent.colorGreen == null ? 127 : subEvent.colorGreen!;
    var tileBackGroundColor = (subEvent.isViable ?? true)
        ? Color.fromRGBO(redColor, greenColor, blueColor, 0.2)
        : tileThemeExtension.surfaceContainerMaximum;
    int currentMsTime = Utility.msCurrentTime;
    late String temporalTextStatus = '';
    Duration duration = Duration();
    if (this.subEvent.end != null && this.subEvent.end! < currentMsTime) {
      duration = Duration(milliseconds: currentMsTime - this.subEvent.end!);
      temporalTextStatus = AppLocalizations.of(context)!
          .elapsedDurationAgo(Utility.toHuman(duration));
    }

    if (this.subEvent.start != null && this.subEvent.end != null) {
      if (this.subEvent.end! > currentMsTime) {
        duration = Duration(milliseconds: this.subEvent.end! - currentMsTime);
        temporalTextStatus = AppLocalizations.of(context)!
            .durationLeft(Utility.toHuman(duration));
        if (this.subEvent.start! > currentMsTime) {
          temporalTextStatus = AppLocalizations.of(context)!
              .startsInDuration(Utility.toHuman(duration));
        }
      }
    }

    if (this.subEvent.isComplete) {
      temporalTextStatus = AppLocalizations.of(context)!.completed;
    }

    if (!this.subEvent.isEnabled) {
      temporalTextStatus = AppLocalizations.of(context)!.deleted;
    }

    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
          color: tileBackGroundColor, borderRadius: BorderRadius.circular(8)),
      child: Stack(
        children: [
          Positioned(
            bottom: 95,
            right: -10,
            child: IconButton(
                onPressed: () {
                  if (subEvent.id != null) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => EditTile(
                                  tileId: (subEvent.isFromTiler
                                          ? subEvent.id
                                          : subEvent.thirdpartyId) ??
                                      "",
                                  tileSource: subEvent.thirdpartyType,
                                  thirdPartyUserId: subEvent.thirdPartyUserId,
                                )));
                  }
                },
                icon: Icon(
                  Icons.edit_outlined,
                  color: colorScheme.onSurface,
                  size: 20.0,
                )),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TileName(
                  subEvent,
                  textStyle:TextStyle(
                    fontSize: 15,
                    fontFamily: TileTextStyles.rubikFontName,
                    fontWeight: FontWeight.w400,
                  )
              ),
              TileAddress(subEvent),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      width: iconSize,
                      height: iconSize,
                      decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(
                        Icons.access_time_sharp,
                        color: (subEvent.isTardy ?? false)
                            ? TileColors.tardy
                            : colorScheme.onSurface,
                        size: 20.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      child: TimeFrameWidget(
                        timeRange: widget.subEvent,
                        textColor: (subEvent.isTardy ?? false)
                            ? TileColors.tardy
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                  child: this.subEvent.isComplete
                      ? Row(
                          children: [
                            Container(
                              margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                              width: iconSize,
                              height: iconSize,
                              decoration: BoxDecoration(
                                  color: colorScheme.onSurface.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Icon(
                                Icons.check_circle_outline_outlined,
                                color:TileColors.completedGreen,
                                size: 20.0,
                              ),
                            ),
                            Padding(
                                padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                child: Text(
                                  temporalTextStatus,
                                  overflow: TextOverflow.ellipsis,
                                  style:TextStyle(
                                      fontSize: 15,
                                      fontFamily: TileTextStyles.rubikFontName
                                  ),
                                ))
                          ],
                        )
                      : !this.subEvent.isEnabled
                          ? Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                      color:colorScheme.onSurface.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                    Icons.cancel_outlined,
                                    color: colorScheme.error,
                                    size: 20.0,
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: Text(
                                      temporalTextStatus,
                                      overflow: TextOverflow.ellipsis,
                                      style:TextStyle(
                                          fontSize: 15,
                                          fontFamily: TileTextStyles.rubikFontName),
                                    )
                                )
                              ],
                            )
                          : Row(
                              children: [
                                Container(
                                  margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(
                                    Icons.timelapse,
                                    size: 20.0,
                                  ),
                                ),
                                Padding(
                                    padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
                                    child: Text(
                                      temporalTextStatus,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontFamily: TileTextStyles.rubikFontName
                                      ),
                                    ))
                              ],
                            ))
            ],
          ),
        ],
      ),
    );
  }
}
