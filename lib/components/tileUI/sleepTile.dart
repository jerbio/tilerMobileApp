import 'package:flutter/material.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

import '../../constants.dart';
import 'timeScrub.dart';


class SleepTileWidget extends StatefulWidget {
  late Timeline timeline;
  SleepTileWidgetState? _state;
  SleepTileWidget(timeline) {
    assert(timeline != null);
    this.timeline = timeline;
  }

  @override
  SleepTileWidgetState createState() {
    _state = SleepTileWidgetState();
    return _state!;
  }

  Future<SleepTileWidgetState> get state async {
    if (this._state != null && this._state!.mounted) {
      return this._state!;
    } else {
      Future<SleepTileWidgetState> retValue = new Future.delayed(
          const Duration(milliseconds: stateRetrievalRetry), () {
        return this.state;
      });

      return retValue;
    }
  }

  void updateTimeline(Timeline timeline) async {
    this.timeline = timeline;
    var state = await this.state;
    state.updateTimeline(timeline);
  }
}

class SleepTileWidgetState extends State<SleepTileWidget> {
  void updateTimeline(Timeline timeline) async {
    this.widget.timeline = timeline;
  }

  @override
  Widget build(BuildContext context) {
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>();
    var timeline = widget.timeline;

    var sleepName = Container(
      margin: const EdgeInsets.fromLTRB(25, 0, 00, 0),
      child: Text(
        'Sleep',
        style:TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color:  TileColors.lightContent,
        )
      ),
    );

    var sleepIcon = Container(
      width: 76,
      height: 76,
      margin: const EdgeInsets.fromLTRB(25, 0, 20, 0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(38),
      ),
      child: Image.asset(
        'assets/images/crescent_moon.png',
        scale: 2,
      ),
    );

    var sleepIconAndRow = Row(
      children: [sleepIcon, sleepName],
    );

    var sleepInBedIcon = Container(
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/person_in_bed.png',
        scale: 1.5,
      ),
    );

    var timeScrub = Container(
        margin: const EdgeInsets.fromLTRB(20, 35, 20, 0),
        child: TimeScrubWidget(
          timeline: timeline,
          loadTimeScrub: true,
        ));

    var allEntry = Column(
      children: [sleepIconAndRow, sleepInBedIcon, timeScrub],
    );

    print('Sleep is from ' +
        this.widget.timeline.startTime.toString() +
        ' - ' +
        this.widget.timeline.endTime.toString());

    return Container(
      margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
      child: Material(
          type: MaterialType.transparency,
          child: FractionallySizedBox(
              widthFactor: TileDimensions.tileWidthRatio,
              child: Container(
                height: 350,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  border: Border.all(
                    color: colorScheme.onInverseSurface,
                    width: 5,
                  ),
                  borderRadius: BorderRadius.circular(TileDimensions.borderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: tileThemeExtension!.shadowSecondary.withValues(alpha: 0.5),
                      spreadRadius: 10,
                      blurRadius: 20,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Container(
                    padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                    decoration: BoxDecoration(
                      color: TileColors.sleepBackground,
                      border: Border.all(
                        color: colorScheme.onInverseSurface,
                        width: 0.5,
                      ),
                      borderRadius:
                          BorderRadius.circular(TileDimensions.borderRadius),
                    ),
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
                      child: allEntry,
                    )),
              ))),
    );
  }
}
