import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/styles.dart';
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
  final DateFormat formatter = DateFormat.jm();
  @override
  void initState() {
    super.initState();
    peekDay = this.widget.peekDay;
  }

  Widget renderDayOfWeek() {
    return Container(
      width: 50,
      child: Text(
        peekDay.endTime?.tilerDayOfWeekName(context).substring(0, 3) ?? "",
        style: TextStyle(
            fontSize: 17,
            fontFamily: TileStyles.rubikFontName,
            fontWeight: FontWeight.w500),
      ),
    );
  }

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
          color: Colors.green,
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
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                color: Colors.red),
          ),
        )
      ],
    );
  }

  Widget renderUnallocatedTime() {
    int durationInMs = peekDay.unallocatedTime?.toInt() ?? 0;
    durationInMs =
        durationInMs < Utility.oneMin.inMilliseconds ? 0 : durationInMs;
    return Row(
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
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                color: Colors.green),
          ),
        )
      ],
    );
  }

  Widget renderLateResults() {
    int tardyCount =
        peekDay.subEvents?.where((e) => e.isTardy == true).length ?? 0;
    return Row(
      children: [
        Icon(
          Icons.error,
          color: Colors.amber,
          size: 30.0,
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(15.0, 0, 0, 0),
          child: Text(
            tardyCount.toString(),
            style: TextStyle(
                fontSize: 15,
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                color: Colors.blue),
          ),
        )
      ],
    );
  }

  Widget renderEntryAndExit() {
    if (peekDay.outHomeEnd == null && peekDay.outHomeEnd == null) {
      return SizedBox.shrink();
    }

    TextStyle timeStyle = TextStyle(
      fontSize: 12,
      fontFamily: TileStyles.rubikFontName,
      fontWeight: FontWeight.w300,
    );
    const timeTextSize = 60.0;
    return Row(
      children: [
        if (peekDay.outHomeStart != null) ...[
          SvgPicture.asset(
            'assets/images/iconScout/logout.svg',
            height: 25,
            width: 25,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
            width: timeTextSize,
            child: Text(
                formatter.format(
                    DateTime.fromMillisecondsSinceEpoch(peekDay.outHomeStart!)),
                style: timeStyle),
          )
        ],
        Container(
          child: Text(
            '---  ',
          ),
        ),
        if (peekDay.outHomeEnd != null) ...[
          Container(
            width: timeTextSize,
            child: Text(
              formatter.format(
                  DateTime.fromMillisecondsSinceEpoch(peekDay.outHomeEnd!)),
              style: timeStyle,
            ),
          ),
          SvgPicture.asset(
            'assets/images/iconScout/login.svg',
            height: 25,
            width: 25,
          )
        ]
      ],
    );
  }

  Widget renderSubEventCount() {
    return Container(
      color: Colors.blue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          renderDayOfWeek(),
          renderUnallocatedTime(),
          renderEntryAndExit()
        ],
      ),
    );
  }
}
