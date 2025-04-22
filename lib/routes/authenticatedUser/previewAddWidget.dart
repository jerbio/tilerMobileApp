import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/deviceSetting/device_setting_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_event.dart';
import 'package:tiler_app/bloc/forecast/forecast_state.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/components/tileUI/newTileSheet.dart';
import 'package:tiler_app/data/adHoc/simeplAdditionTIle.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/previewSummary.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTile.dart';
import 'package:tiler_app/routes/authenticatedUser/preview/previewWidget.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class PreviewAddWidget extends StatefulWidget {
  final PreviewSummary? previewSummary;
  final Function? onSubmit;
  PreviewAddWidget({this.previewSummary, this.onSubmit});
  @override
  State<StatefulWidget> createState() => _PreviewAddWidgetState();
}

class _PreviewAddWidgetState extends State<PreviewAddWidget> {
  final double modalHeight = 420;
  bool isPendingAdd = false;
  NewTile? newTile;
  late final ScheduleApi scheduleApi;

  @override
  void initState() {
    super.initState();
    scheduleApi = ScheduleApi(getContextCallBack: () => context);
    this.context.read<ForecastBloc>().add(ResetEvent());
  }

  Widget renderPreview() {
    var perviewHeight = MediaQuery.sizeOf(context).height - modalHeight;
    if (perviewHeight < 200) {
      return SizedBox.shrink();
    }
    return Container(
        height: perviewHeight,
        width: MediaQuery.sizeOf(context).width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            // Color.fromRGBO(1, 1, 1, 0.9),
            // Color.fromRGBO(1, 1, 1, .85),
            // Color.fromRGBO(1, 1, 1, 1),
            // Color.fromRGBO(1, 1, 1, 1),
            // Color.fromRGBO(1, 1, 1, 1),
            // Color.fromRGBO(1, 1, 1, 1),
            // Color.fromRGBO(1, 1, 1, 1),
            Colors.white,
            Colors.white,
            Colors.white,
            Colors.white
          ],
        )),
        child: PreviewWidget(
          subEvents: this.widget.previewSummary?.tiles ?? [],
          previewSummary: this.widget.previewSummary,
        ));
  }

  onSubmit(NewTile newTile) {
    Color randomColor = Utility.randomColor;
    newTile.RColor = randomColor.red.toString();
    newTile.BColor = randomColor.blue.toString();
    newTile.GColor = randomColor.green.toString();
    newTile.Opacity = '1';
    final currentState = this.context.read<ScheduleBloc>().state;
    if (currentState is ScheduleLoadedState) {
      this.context.read<ScheduleBloc>().add(EvaluateSchedule(
          isAlreadyLoaded: true,
          scheduleStatus: currentState.scheduleStatus,
          renderedScheduleTimeline: currentState.lookupTimeline,
          renderedSubEvents: currentState.subEvents,
          renderedTimelines: currentState.timelines));
    }
    Future retValue = scheduleApi.addNewTile(newTile);
    setState(() {
      isPendingAdd = true;
    });
    retValue.then((newlyAddedTile) {
      if (newlyAddedTile.item1 != null) {
        SubCalendarEvent subEvent = newlyAddedTile.item1;
        print(subEvent.name);
      }

      AnalysticsSignal.send('ADD_TILE_NEWTILE_ADD_SUCCESS_RESPONSE');
      this
          .context
          .read<SubCalendarTileBloc>()
          .add(NewSubCalendarTileBlocEvent(subEvent: newlyAddedTile.item1));

      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
      }
      if (this.widget.onSubmit != null) {
        this.widget.onSubmit!(retValue);
      }
    }).onError((error, stackTrace) {
      AnalysticsSignal.send('ADD_TILE_NEWTILE_ADD_ERROR_RESPONSE');
      if (error != null) {
        String message = error.toString();
        if (error is FormatException) {
          FormatException exception = error;
          message = exception.message;
        }

        debugPrint(message);
        final scaffold = ScaffoldMessenger.of(context);
        scaffold.showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: AppLocalizations.of(context)!.close,
              onPressed: scaffold.hideCurrentSnackBar,
              textColor: Colors.redAccent,
            ),
          ),
        );
      }
      final currentState = this.context.read<ScheduleBloc>().state;
      if (currentState is ScheduleEvaluationState) {
        this.context.read<ScheduleBloc>().add(GetScheduleEvent(
              isAlreadyLoaded: true,
              previousSubEvents: currentState.subEvents,
              scheduleTimeline: currentState.lookupTimeline,
              previousTimeline: currentState.lookupTimeline,
            ));
        refreshScheduleSummary(currentState.lookupTimeline);
      }
    }).whenComplete(() {
      setState(() {
        isPendingAdd = false;
      });
    });
  }

  onTileUpdate(NewTile? updatedTile) {
    setState(() {
      newTile = updatedTile;
    });
  }

  void refreshScheduleSummary(Timeline? lookupTimeline) {
    final currentScheduleSummaryState =
        this.context.read<ScheduleSummaryBloc>().state;

    if (currentScheduleSummaryState is ScheduleSummaryInitial ||
        currentScheduleSummaryState is ScheduleDaySummaryLoaded ||
        currentScheduleSummaryState is ScheduleDaySummaryLoading) {
      this.context.read<ScheduleSummaryBloc>().add(
            GetScheduleDaySummaryEvent(timeline: lookupTimeline),
          );
    }
  }

  Widget renderPending() {
    return Container(
      height: modalHeight,
      width: MediaQuery.sizeOf(context).width,
      child: PendingWidget(
        backgroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        imageAsset: TileStyles.evaluatingScheduleAsset,
      ),
    );
  }

  Widget foreCastButton(Function() onPressed) {
    return ElevatedButton(
        child: Column(
          children: [
            FaIcon(
              TileStyles.forecastIcon,
              color: TileStyles.primaryColor,
              size: 20,
            ),
            Text(AppLocalizations.of(context)!.previewTileForecast,
                style: TextStyle(
                  fontSize: 9,
                ))
          ],
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
  }

  Widget renderForecastButton() {
    var buttonPressed = () {
      AnalysticsSignal.send('FORECAST_BUTTON_PRESSED');
      Navigator.pushNamed(context, '/ForecastPreview');
    };
    ForecastState forecastState = this.context.read<ForecastBloc>().state;
    if (forecastState is ForecastLoaded) {
      return SizedBox.shrink();
    }
    if (forecastState is ForecastInitial) {
      return foreCastButton(buttonPressed);
    }
    return InkWell(
      onTap: buttonPressed,
      child: Stack(
        children: [
          foreCastButton(buttonPressed),
          Shimmer.fromColors(
              baseColor: TileStyles.accentColorHSL.toColor().withAlpha(75),
              highlightColor: TileStyles.primaryColor.withLightness(0.7),
              child: Container(
                width: 65,
                height: 40,
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, 0.8),
                    borderRadius: BorderRadius.circular(30)),
              )),
        ],
      ),
    );
  }

  Widget renderProcastinateAllButton() {
    const Color cheveronColor = TileStyles.primaryColor;
    return ElevatedButton(
        child: Column(
          children: [
            Container(
              width: 60,
              height: 20,
              child: Stack(
                children: [
                  Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      left: -15,
                      child: Icon(Icons.chevron_right, color: cheveronColor)),
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    left: 0,
                    child: Icon(Icons.chevron_right, color: cheveronColor),
                  ),
                  Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      left: 15,
                      child: Icon(Icons.chevron_right, color: cheveronColor)),
                ],
              ),
            ),
            Text(AppLocalizations.of(context)!.previewTileDeferAll,
                style: TextStyle(fontSize: 9, color: TileStyles.primaryColor))
          ],
        ),
        onPressed: () {
          AnalysticsSignal.send('PROCRASTINATE_ALL_BUTTON_PRESSED');

          Navigator.pushNamed(context, '/Procrastinate').whenComplete(() {
            var scheduleBloc = this.context.read<ScheduleBloc>().state;

            Timeline? lookupTimeline;
            if (scheduleBloc is ScheduleLoadedState) {
              this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                  previousSubEvents: scheduleBloc.subEvents,
                  scheduleTimeline: scheduleBloc.lookupTimeline,
                  isAlreadyLoaded: true));
              lookupTimeline = scheduleBloc.lookupTimeline;
            }
            if (scheduleBloc is ScheduleInitialState) {
              this.context.read<ScheduleBloc>().add(GetScheduleEvent(
                  previousSubEvents: [],
                  scheduleTimeline: Utility.initialScheduleTimeline,
                  isAlreadyLoaded: false));
              lookupTimeline = Utility.initialScheduleTimeline;
            }

            refreshScheduleSummary(lookupTimeline);
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
            this.context.read<ForecastBloc>().add(ResetEvent());
          });
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
  }

  Widget renderMoreSettingsButton() {
    return ElevatedButton(
        child: Column(
          children: [
            Icon(
              Icons.more_time,
              color: TileStyles.primaryColor,
              size: 20,
            ),
            Text(AppLocalizations.of(context)!.previewTileOptions,
                style: TextStyle(fontSize: 9, color: TileStyles.primaryColor))
          ],
        ),
        onPressed: () {
          Location? location = null;
          if (newTile != null &&
              ((newTile!.LocationAddress != null &&
                      newTile!.LocationAddress.isNot_NullEmptyOrWhiteSpace()) ||
                  (newTile!.LocationTag != null &&
                      newTile!.LocationTag.isNot_NullEmptyOrWhiteSpace()) ||
                  (newTile!.LocationId != null &&
                      newTile!.LocationId.isNot_NullEmptyOrWhiteSpace()))) {
            location = Location.fromDefault();
            location.isDefault = false;
            location.isNull = false;
            location.id = newTile?.LocationId;
            location.description = newTile?.LocationTag;
            location.address = newTile?.LocationAddress;
            location.source = newTile?.LocationSource;
            if (newTile?.LocationIsVerified.isNot_NullEmptyOrWhiteSpace() ==
                true) {
              bool? isLocationVerified = bool.tryParse(
                  newTile!.LocationIsVerified!,
                  caseSensitive: false);
              if (isLocationVerified != null) {
                location.isVerified = isLocationVerified;
              }
            }
          }

          SimpleAdditionTile preTile = SimpleAdditionTile(
              description: newTile?.Name,
              duration: newTile?.getDuration(),
              location: location);
          AnalysticsSignal.send('ADD_MORE_TILE_SETTINGS_BUTTON');
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          this.context.read<ForecastBloc>().add(ResetEvent());
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AddTile(preTile: preTile)));
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
  }

  Widget renderShuffleButton() {
    return ElevatedButton(
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.shuffle,
              color: TileStyles.primaryColor,
              size: 20,
            ),
            Text(AppLocalizations.of(context)!.previewTileShuffle,
                style: TextStyle(fontSize: 9, color: TileStyles.primaryColor))
          ],
        ),
        onPressed: () {
          AnalysticsSignal.send('SHUFFLE_BUTTON');
          this.context.read<ScheduleBloc>().add(ShuffleScheduleEvent());
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          this.context.read<ForecastBloc>().add(ResetEvent());
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
  }

  Widget renderRefresh() {
    return ElevatedButton(
        child: Column(
          children: [
            Icon(
              Icons.refresh,
              color: TileStyles.primaryColor,
              size: 20,
            ),
            Text(AppLocalizations.of(context)!.previewTileRevise,
                style: TextStyle(fontSize: 9, color: TileStyles.primaryColor))
          ],
        ),
        onPressed: () {
          AnalysticsSignal.send('REVISE_BUTTON');
          this.context.read<ScheduleBloc>().add(ReviseScheduleEvent());
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          this.context.read<ForecastBloc>().add(ResetEvent());
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ));
  }

  Widget renderModal() {
    return Container(
        alignment: Alignment.bottomCenter,
        margin: EdgeInsets.fromLTRB(
            0, 0, 0, MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(255, 255, 255, 1),
            Color.fromRGBO(255, 255, 255, 1),
            Colors.white
          ],
        )),
        width: MediaQuery.sizeOf(context).width,
        height: modalHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  renderRefresh(),
                  renderShuffleButton(),
                  renderProcastinateAllButton(),
                  renderMoreSettingsButton(),
                ],
              ),
            ),
            Stack(
              children: [
                NewTileSheetWidget(
                  onAddTile: onSubmit,
                  onTileUpdate: onTileUpdate,
                ),
                isPendingAdd ? renderPending() : SizedBox.shrink()
              ],
            ),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<ForecastBloc, ForecastState>(
            listener: (context, state) {
              if (state is ForecastLoading) {
                print("ForecastLoading state detected");
              } else if (state is ForecastLoaded) {
                print("ForecastLoaded state detected");
              } else if (state is ForecastInitial) {
                print("ForecastInitial state detected");
              }
              setState(() {});
            },
          ),
        ],
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Utility.isKeyboardVisible(context)
                    ? SizedBox.shrink()
                    : renderPreview(),
                renderModal(),
              ],
            )
          ],
        ));
  }
}
