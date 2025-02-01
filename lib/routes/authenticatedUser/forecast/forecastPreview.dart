import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/forecastTemplate/analysisCheckState.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/forecast/tileForecast.dart';
import 'package:tiler_app/routes/authenticatedUser/tileSummary.dart';
import 'package:tiler_app/util.dart';

import '../../../bloc/forecast/forecast_bloc.dart';
import '../../../bloc/forecast/forecast_event.dart';
import '../../../bloc/forecast/forecast_state.dart';
import '../../../components/PendingWidget.dart';
import '../../../components/forecastTemplate/customForecastField.dart';
import '../../../styles.dart';

class ForecastPreview extends StatelessWidget {
  const ForecastPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ForecastBloc(),
      child: ForecastView(),
    );
  }
}

class ForecastView extends StatelessWidget {
  static final String forecastCancelAndProceedRouteName =
      "forecastCancelAndProceed";
  const ForecastView({super.key});

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    return CancelAndProceedTemplateWidget(
      routeName: forecastCancelAndProceedRouteName,
      bottomWidget: GestureDetector(
        onTap: () {
          Map<String, dynamic> newTileParams = {'newTile': null};
          Navigator.pushNamed(context, '/AddTile', arguments: newTileParams);
        },
        child: Container(
          width: width,
          height: height / (height / 52),
          decoration: BoxDecoration(
            color: TileStyles.primaryColor,
            borderRadius: BorderRadius.circular(height / (height / 6)),
          ),
          child: Center(
            child: Text(
              AppLocalizations.of(context)!.create,
              style: TextStyle(
                fontFamily: TileStyles.rubikFontName,
                fontSize: height / (height / 15),
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: TileStyles.primaryColor,
        title: Text(
          AppLocalizations.of(context)!.forecast,
          style: TextStyle(
              color: TileStyles.appBarTextColor,
              fontWeight: FontWeight.w800,
              fontSize: 22),
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: height / (height / 25),
          ),
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              SizedBox(
                height: height / (height / 40),
              ),
              generateDeadline(context, width, height),
              generateDurationPicker(context, width, height),
              BlocBuilder<ForecastBloc, ForecastState>(
                builder: (context, state) {
                  Utility.debugPrint('Current state: $state');
                  if (state is ForecastInitial) {
                    return SizedBox.shrink();
                  } else if (state is ForecastLoading) {
                    return SizedBox(
                        height: height / (height / 450),
                        width: width,
                        child: Center(
                          child: PendingWidget(
                            imageAsset: TileStyles.evaluatingScheduleAsset,
                          ),
                        ));
                  } else if (state is ForecastLoaded) {
                    return RenderLoadedForecast(height, context, state, width);
                  } else if (state is ForecastError) {
                    return Center(
                        child: Text(AppLocalizations.of(context)!
                            .errorMessage(state.error)));
                  } else {
                    return SizedBox.shrink();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Column RenderLoadedForecast(
      double height, BuildContext context, ForecastLoaded state, double width) {
    List<PeekDay> forecastDays = state.foreCastResponse.peekDays ?? [];
    return Column(
      children: [
        SizedBox(
          height: height / (height / 20),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.analysis,
              style: TextStyle(
                fontFamily: TileStyles.rubikFontName,
                fontSize: height / (height / 17),
                fontWeight: FontWeight.w500,
                color: TileStyles.defaultTextColor,
              ),
            )
          ],
        ),
        SizedBox(
          height: height / (height / 10),
        ),
        Column(
          children: [
            Row(
              children: [
                AnalysisCheckState(
                  height: height,
                  isWarning: state.foreCastResponse.isViable == false,
                  isPass: state.foreCastResponse.isViable == true,
                ),
                SizedBox(
                  width: height / (height / 10),
                ),
                Text(
                  state.foreCastResponse.isViable == true
                      ? AppLocalizations.of(context)!.thisFitsInYourSchedule
                      : AppLocalizations.of(context)!.nonViableTimeSlot,
                  style: TextStyle(
                    fontFamily: TileStyles.rubikFontName,
                    fontWeight: FontWeight.w400,
                    fontSize: height / (height / 15),
                    color: TileStyles.defaultTextColor,
                  ),
                )
              ],
            ), //viable status
            SizedBox(
              height: height / (height / 20),
            ),
            forecastDays.isNotEmpty
                ? TileForecast(forecastDays: forecastDays)
                : SizedBox.shrink(),
            SizedBox(
              height: height / (height / 20),
            )
          ],
        )
      ],
    );
  }

  Widget generateDeadline(BuildContext context, double width, double height) {
    final state = context.watch<ForecastBloc>().state;
    final endTime = state.endTime;

    void onEndDateTap() async {
      DateTime _endDate = endTime == null
          ? Utility.todayTimeline().endTime.add(Utility.oneDay)
          : endTime;
      DateTime firstDate = _endDate.add(Duration(days: -14));
      DateTime lastDate = _endDate.add(Duration(days: 90));
      final DateTime? revisedEndDate = await showDatePicker(
        context: context,
        initialDate: _endDate,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: AppLocalizations.of(context)!.whenQ,
      );
      if (revisedEndDate != null) {
        DateTime updatedEndTime = DateTime(
            revisedEndDate.year,
            revisedEndDate.month,
            revisedEndDate.day,
            _endDate.hour,
            _endDate.minute);
        context.read<ForecastBloc>().add(UpdateDateTime(updatedEndTime));
      }
    }

    String textButtonString = endTime == null
        ? AppLocalizations.of(context)!.whenQ
        : DateFormat.yMMMd().format(endTime);

    // Revised
    Widget deadlineContainer = GestureDetector(
      onTap: onEndDateTap,
      child: CustomForecastField(
        leadingIconPath: 'assets/images/Calendar.svg',
        textButtonString: textButtonString,
        height: height,
        width: width,
      ),
    );
    return deadlineContainer;
  }

  Widget generateDurationPicker(
      BuildContext context, double width, double height) {
    final state = context.watch<ForecastBloc>().state;
    final duration = state.duration ?? Duration(minutes: 0);

    final void Function()? setDuration = () async {
      Map<String, dynamic> durationParams = {'duration': duration};
      Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
          .whenComplete(() {
        Duration? populatedDuration = durationParams['duration'] as Duration?;
        if (populatedDuration != null) {
          context.read<ForecastBloc>().add(UpdateDuration(populatedDuration));
        }
      });
    };
    String textButtonString = AppLocalizations.of(context)!.duration;
    if (duration.inMinutes > 1) {
      textButtonString = "";
      int hour = duration.inHours.floor();
      int minute = duration.inMinutes.remainder(60);
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

    // Revised
    Widget retValue = GestureDetector(
      onTap: setDuration,
      child: CustomForecastField(
        leadingIconPath: 'assets/images/timecircle.svg',
        textButtonString: textButtonString,
        height: height,
        width: width,
      ),
    );
    return retValue;
  }
}
