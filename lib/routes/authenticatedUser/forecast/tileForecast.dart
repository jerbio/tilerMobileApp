import 'package:flutter/material.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/dayCast.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/forecastDaySimple.dart';
import 'package:tiler_app/styles.dart';

class TileForecast extends StatefulWidget {
  final List<PeekDay> forecastDays;
  TileForecast({required this.forecastDays});
  @override
  _ForecastState createState() => _ForecastState();
}

class _ForecastState extends State<TileForecast> {
  late List<PeekDay> forecastDays;
  @override
  void initState() {
    super.initState();
    this.forecastDays = this.widget.forecastDays;
  }

  Widget forecastHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 0, 0, 5),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(
            Icons.grading_outlined,
          ),
          Container(
            padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
            child: Text(
                AppLocalizations.of(context)!
                    .numberOfDayForecast(forecastDays.length.toString()),
                style: TextStyle(
                    fontSize: 17,
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget forecastRows() {
    return Container(
      height: 300,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: forecastDays.length,
          itemBuilder: (context, index) {
            return InkWell(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DayCast(forecastDays[index])));
              },
              child: ForecastDaySimpleWidget(peekDay: forecastDays[index]),
            );
          }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        children: [forecastHeader(), forecastRows()],
      ),
    );
  }
}
