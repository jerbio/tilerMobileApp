import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/components/tileUI/tileName.dart';
import 'package:tiler_app/components/tileUI/tileAddress.dart';
import 'package:tiler_app/components/tileUI/timeFrame.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';


class MonthlyDailyTile extends StatelessWidget {
  late SubCalendarEvent subEvent;

  MonthlyDailyTile(subEvent) : super(key: Key(subEvent.id)) {
    assert(subEvent != null);
    this.subEvent = subEvent;
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    return FractionallySizedBox(
      widthFactor: TileDimensions.tileWidthRatio,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 10),
        padding:  EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
          boxShadow: [
            BoxShadow(
              color: tileThemeExtension!.shadowSecondary.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TileName(subEvent),
            ),
            if (subEvent.address != null && subEvent.address!.isNotEmpty||subEvent.searchdDescription !=null && subEvent.searchdDescription!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: TileAddress(subEvent,isMonthlyView: true,),
              ),
            Padding(
              padding: const EdgeInsets.only(left:18.0,top: 8,bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    margin: const EdgeInsets.fromLTRB(0, 0, 20, 0),
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.access_time_sharp,
                      color: tileThemeExtension.onSurfaceMonthlyIntegration,
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 4),
                  TimeFrameWidget(
                    timeRange: subEvent,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
