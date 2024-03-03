import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../../../bloc/forecast/forecast_bloc.dart';
import '../../../components/template/cancelAndProceedTemplate.dart';
import '../../../data/adHoc/autoTile.dart';
import '../../../data/subCalendarEvent.dart';
import '../newTile/addTile.dart';
import '../tileSummary.dart';
import 'package:tiler_app/styles.dart';
import 'dart:math' as math;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ForecastScreen extends StatefulWidget {
  @override
  _ForecastScreenState createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ForecastBloc, ForecastState>(
      builder: (context, state) {
        return Stack(
          children: [
            CancelAndProceedTemplateWidget(
              onCancel: () => context.read<ForecastBloc>().add(ResetForecastStateEvent()),
              appBar: AppBar(
                backgroundColor: TileStyles.primaryColor,
                title: Text(
                  AppLocalizations.of(context)!.forecast,
                  style: TileStyles.titleBarStyle,
                ),
                centerTitle: true,
                elevation: 0,
                automaticallyImplyLeading: false,
              ),

              child: BlocConsumer<ForecastBloc, ForecastState>(
                listener: (context, state) {
                  if (state is ForecastError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error)),
                    );
                  }
                },
                builder: (context, state) {
                  return Column(
                    children: [
                      generateInitialContent(context),
                      if (state is ForecastLoading) Expanded(child: renderPending()),
                      if (state is ForecastLoaded) Expanded(
                          child: buildForecastContent(state)),
                    ],
                  );
                },
              ),
            ),
            state is ForecastLoaded && state.duration != null? _buildCustomRightButton() : SizedBox(),
          ],
        );
      },
    );
  }

  Widget generateInitialContent(BuildContext context) {
    return Container(
      margin: TileStyles.topMargin,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          generateDeadline(context),
          generateDurationPicker(context),
        ],
      ),
    );
  }

  Widget buildForecastContent(ForecastLoaded state) {
    return FractionallySizedBox(
      widthFactor: TileStyles.widthRatio,
      child: Container(
        margin: TileStyles.topMargin,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  if(state.isViable == true)
                    customLabel(
                        color: Colors.green,
                        icon: FontAwesomeIcons.check,
                        text: AppLocalizations.of(context)!.fitsInSchedule ),
                  if (state.suggestedTime != null && state.duration != null)
                    customLabel(
                        color: Colors.grey,
                        icon:  Icons.access_time_sharp,
                        text:AppLocalizations.of(context)!.suggestedTime(formatMillisecondsToLocalTime(state.suggestedTime!),formatMillisecondsToLocalTime(state.suggestedTime! + state.duration!.inMilliseconds))

                    ),
                  if(state.forecastRiskEvents.isNotEmpty)
                    customLabel(color: Colors.orange,
                        icon: FontAwesomeIcons.exclamation,
                        text:AppLocalizations.of(context)!.warningEventAtRisk(state.forecastRiskEvents.length.toString()),
                        ),
                  buildEventList(state.forecastRiskEvents),
                  if(state.forecastConflictEvents.isNotEmpty)
                    customLabel(color: Colors.red,
                        icon: FontAwesomeIcons.exclamation,
                        text: AppLocalizations.of(context)!.eventWouldCauseConflict(state
                            .forecastConflictEvents.length.toString())
                       ),
                  buildEventList(state.forecastConflictEvents),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget buildEventList(List<SubCalendarEvent> events) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: events.length,
      itemBuilder: (context, index) => TileSummary(events[index]),
    );
  }

  Widget generateDurationPicker(BuildContext context) {
    return BlocBuilder<ForecastBloc, ForecastState>(
      builder: (context, state) {
        final void Function()? setDuration = () async {
          Map<String, dynamic> durationParams = {
            'duration': Duration(hours: 0, minutes: 0)
          };
          Navigator.pushNamed(
              context, '/DurationDial', arguments: durationParams)
              .whenComplete(() {
            Duration? populatedDuration = durationParams['duration'] as Duration?;
            if (populatedDuration != null) {
              context.read<ForecastBloc>().add(
                  DurationUpdated(populatedDuration));
            }
          });
        };
        String textButtonString = AppLocalizations.of(context)!.durationStar;
        if (state.duration != null && state.duration!.inMinutes > 1) {
          int hours = state.duration!.inHours.floor();
          int minutes = state.duration!.inMinutes.remainder(60);
          textButtonString = hours > 0 ? "${hours}h" : "";
          if (minutes > 0) {
            textButtonString += hours > 0 ? " : ${minutes}m" : "${minutes}m";
          }
        }
        return GestureDetector(
          onTap: setDuration,
          child: FractionallySizedBox(
            widthFactor: TileStyles.widthRatio,
            child: Container(
              margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
              padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
              decoration: BoxDecoration(
                color: TileStyles.textBackgroundColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(
                  color: TileStyles.textBorderColor,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.timelapse_outlined,
                      color: TileStyles.primaryColorDarkHSL.toColor()),
                  Container(
                    padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                    child: TextButton(
                      style: TextButton.styleFrom(
                        textStyle: const TextStyle(
                          fontSize: 20,
                        ),
                      ),
                      onPressed: setDuration,
                      child: Text(
                        textButtonString,
                        style: TextStyle(
                          fontFamily: TileStyles.rubikFontName,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget generateDeadline(BuildContext context) {
    void onTap() async {
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: context.read<ForecastBloc>().state.endTime ??DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(Duration(days: 365)),
      );
      if (pickedDate != null) {
        context.read<ForecastBloc>().add(EndTimeUpdated(pickedDate));
      }
    }
    return GestureDetector(
      onTap: onTap,
      child: FractionallySizedBox(
        widthFactor: TileStyles.widthRatio,
        child: Container(
          margin: EdgeInsets.fromLTRB(0, 0, 0, 20),
          padding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          decoration: BoxDecoration(
            color: TileStyles.textBackgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: TileStyles.textBorderColor,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.calendar_month,
                  color: TileStyles.primaryColorDarkHSL.toColor()),
              BlocBuilder<ForecastBloc, ForecastState>(
                builder: (context, state) {
                  String textButtonString = AppLocalizations.of(context)!
                      .deadline_anytime;
                  if (state.endTime != null) {
                    textButtonString =
                        DateFormat.yMMMd().format(state.endTime!);
                  }
                  return TextButton(
                    onPressed: onTap,
                    child: Text(
                      textButtonString,
                      style: TextStyle(
                        fontSize: 20,
                        fontFamily: TileStyles.rubikFontName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget renderPending() {
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(
        child: Stack(
          children: [
            Center(
              child: SizedBox(
                child: CircularProgressIndicator(),
                height: 200.0,
                width: 200.0,
              ),
            ),
            Center(
              child: Image.asset('assets/images/tiler_logo_black.png',
                  fit: BoxFit.cover, scale: 7),
            ),
          ],
        ),
      ),
    );
  }

  Widget customLabel(
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 0, 20),
      child: Row(
        children: [
          Container(
            alignment: Alignment.center,
            width: 30,
            height: 30,
            margin: const EdgeInsets.fromLTRB(0, 0, 12, 0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(children: <Widget>[
              Center(
                child: Icon(icon, color: Colors.white,),
              )
            ]),
          ),
          Flexible(
            child: Container(
              padding: EdgeInsets.fromLTRB(0, 0, 20, 0),
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontFamily: TileStyles.rubikFontName,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatMillisecondsToLocalTime(int milliseconds) {
    DateTime localTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    TimeOfDay time = TimeOfDay.fromDateTime(localTime);
    return MaterialLocalizations.of(context).formatTimeOfDay(time);
  }

  Widget _buildCustomRightButton() {
    void onClick(){
      if (context.read<ForecastBloc>().state is ForecastLoaded) {
        ForecastLoaded state = context
            .read<ForecastBloc>()
            .state as ForecastLoaded;

        final autoTile = AutoTile(
            description: "",
            duration: state.duration
        );
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddTile(autoTile: autoTile,autoDeadline: state.endTime,)));
      }
    }
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: EdgeInsets.fromLTRB(0, 0, 0, 55),
        height: 60,
        width: TileStyles.proceedAndCancelButtonWidth,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                HSLColor.fromColor(TileStyles.primaryColor)
                    .withLightness(
                    HSLColor.fromColor(TileStyles.primaryColor).lightness +
                        0.3)
                    .toColor(),
                TileStyles.primaryColor,
              ],
            )),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 0.0,
            foregroundColor: Colors.transparent,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent, // foreground
          ),
          child: Center(
              child: Container(
                margin: EdgeInsets.fromLTRB(0, 0, 0, 5),
                child: IconButton(
                  icon: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                  onPressed: onClick,
                ),
              )),
          onPressed:onClick,
        ),
      ),
    );
  }


}
