import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForecastDaySimpleWidget extends StatefulWidget {
  final PeekDay peekDay;
  ForecastDaySimpleWidget({required this.peekDay});
  @override
  _ForecastDayState createState() => _ForecastDayState();
}

class _ForecastDayState extends State<ForecastDaySimpleWidget> {
  late PeekDay peekDay;
  late double height = 20;
  final double dayOfWeekContainerWidth = 50;
  final double unAllocatedContainerWidth = 70;
  final double renderedTimeWidth = 65;
  final DateFormat formatter = DateFormat.jm();
  final double timeBarHeight = 20;
  GlobalKey containerSizeKey = GlobalKey();
  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;

  @override
  void initState() {
    super.initState();
    peekDay = this.widget.peekDay;
  }
  @override
  void didChangeDependencies() {
    theme=Theme.of(context);
    colorScheme=theme.colorScheme;
    tileThemeExtension=theme.extension<TileThemeExtension>()!;
    super.didChangeDependencies();
  }

  Widget renderDayOfWeek() {
    return Container(
      width: dayOfWeekContainerWidth,
      child: Text(
        peekDay.endTime?.tilerDayOfWeekName(context).substring(0, 3) ?? "",
        style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 17,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  //ey: not used
  Widget renderTravelTime() {
    int travelTimeDurationInMs = peekDay.travelTime?.toInt() ?? 0;
    travelTimeDurationInMs =
        travelTimeDurationInMs < Utility.oneMin.inMilliseconds
            ? 0
            : travelTimeDurationInMs;

    return Row(
      children: [
        SvgPicture.asset(
          'assets/images/iconScout/drive-time.svg',
          height: height / (height / 16),
          width: height / (height / 16),
        ),
        Container(
          color: TileColors.activeForesCastTime,
          alignment: Alignment.center,
          width: 75,
          child: Text(
            travelTimeDurationInMs == 0
                ? AppLocalizations.of(context)!.noDriving
                : Utility.toHuman(
                    Duration(milliseconds: travelTimeDurationInMs),
                    abbreviations: true),
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                color: colorScheme.onError),
          ),
        )
      ],
    );
  }

  Widget renderUnallocatedTime() {
    int durationInMs = peekDay.unallocatedTime?.toInt() ?? 0;
    durationInMs =
        durationInMs < Utility.oneMin.inMilliseconds ? 0 : durationInMs;
    return Container(
      width: unAllocatedContainerWidth,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/images/iconScout/deadline.svg',
            height: height / (height / 16),
            width: height / (height / 16),
          ),
          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            width: 50,
            child: Text(
              durationInMs == 0
                  ? AppLocalizations.of(context)!.knotDuration
                  : Utility.toHuman(Duration(milliseconds: durationInMs),
                      abbreviations: true),
              style: TextStyle(
                  fontSize: 15,
                  fontFamily: TileTextStyles.rubikFontName,
                  fontWeight: FontWeight.w300,
                  color: TileColors.activeForesCastTime),
            ),
          )
        ],
      ),
    );
  }

  Widget renderLateResults() {
    int tardyCount =
        peekDay.subEvents?.where((e) => e.isTardy == true).length ?? 0;
    return Row(
      children: [
        Icon(
          Icons.error,
          color: TileColors.accentWarning,
          size: 30.0,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
          child: Text(
            tardyCount.toString(),
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileTextStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                color:TileColors.tardyForecast),
          ),
        )
      ],
    );
  }

  Widget renderDayTimelineBar(Timeline? dayTimeline) {
    return Container(
      margin: EdgeInsets.fromLTRB(0, timeBarHeight / 3, 0, 0),
      key: containerSizeKey,
      width: inAndOutBarWidth,
      height: timeBarHeight / 3,
      decoration: BoxDecoration(
          color: tileThemeExtension.onSurfaceVariantSecondary,
          borderRadius: BorderRadius.all(Radius.circular(5))),
    );
  }

  Widget renderActiveTimelineBar(
      Timeline? activeTimeline, Timeline? dayTimeline) {
    if (activeTimeline == null || dayTimeline == null) {
      return SizedBox.shrink();
    }
    TimeRange? timeRange = activeTimeline.interferingTimeRange(dayTimeline);
    if (timeRange == null) {
      return SizedBox.shrink();
    }

    double fractionalWidthRatio =
        activeTimeline.duration.inMilliseconds.toDouble() /
            dayTimeline.duration.inMilliseconds.toDouble();
    double leftSpacingRatio =
        ((activeTimeline.startTime.millisecondsSinceEpoch -
                    dayTimeline.startTime.millisecondsSinceEpoch)
                .toDouble() /
            dayTimeline.duration.inMilliseconds.toDouble());
    double leftSpacing = leftSpacingRatio * inAndOutBarWidth;
    double fractionalWidth = fractionalWidthRatio * inAndOutBarWidth;

    return Positioned(
        left: leftSpacing,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, timeBarHeight * 0.25, 0, 0),
          width: fractionalWidth,
          height: timeBarHeight * 0.5,
          decoration: BoxDecoration(
              color: TileColors.activeForesCastTime,
              borderRadius: BorderRadius.all(Radius.circular(5))),
        ));
  }

  Widget renderEntryAndExit() {
    if (peekDay.outHomeStartTime == null && peekDay.outHomeEndTime == null) {
      return SizedBox.shrink();
    }
    Timeline? dayTimeline = null;
    Timeline? sleepTimeline = null;
    if (peekDay.startTime != null && peekDay.endTime != null) {
      dayTimeline = Timeline.fromDateTime(peekDay.startTime!, peekDay.endTime!);
    }
    if (peekDay.outHomeStartTime != null && peekDay.outHomeEndTime != null) {
      sleepTimeline = Timeline.fromDateTime(
          peekDay.outHomeStartTime!, peekDay.outHomeEndTime!);
    }

    return Stack(
      children: [
        renderDayTimelineBar(dayTimeline),
        renderActiveTimelineBar(sleepTimeline, dayTimeline)
      ],
    );
  }

  Widget renderTime(DateTime? timeInMs) {
    Widget innerWidget = SizedBox.shrink();
    if (timeInMs != null) {
      innerWidget = renderTimeOfDay(TimeOfDay.fromDateTime(timeInMs));
    }

    return Container(
      child: innerWidget,
      width: renderedTimeWidth,
    );
  }

  Widget renderTimeOfDay(TimeOfDay timeOfDay) {
    return Container(
      child: Text(timeOfDay.format(context),
          style: TextStyle(
              fontSize: 14,
              fontFamily: TileTextStyles.rubikFontName,
              fontWeight: FontWeight.w300)),
    );
  }

  double get screenWidth {
    return MediaQuery.sizeOf(context).width * TileDimensions.widthRatio;
  }

  double get inAndOutBarWidth {
    return screenWidth -
        unAllocatedContainerWidth -
        dayOfWeekContainerWidth -
        (2 * renderedTimeWidth) -
        10;
  }

  @override
  Widget build(BuildContext context) {
    bool containsWhatIfTile = false;
    if (peekDay.subEvents != null) {
      containsWhatIfTile =
          peekDay.subEvents!.any((element) => element.isWhatIf == true);
    }

    return Container(
      padding: EdgeInsets.fromLTRB(10, 5, 5, 5),
      decoration: containsWhatIfTile == true
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: TileColors.whatIfHighlight,
                width: 1,
              ),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderDayOfWeek(),
          renderUnallocatedTime(),
          renderTime(peekDay.outHomeStartTime),
          Container(
              height: timeBarHeight,
              width: inAndOutBarWidth,
              child: renderEntryAndExit()),
          renderTime(peekDay.outHomeEndTime),
        ],
      ),
    );
  }
}
