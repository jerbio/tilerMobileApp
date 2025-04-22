import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Add this import
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tiler_app/bloc/forecast/forecast_bloc.dart';
import 'package:tiler_app/bloc/forecast/forecast_event.dart';
import 'package:tiler_app/bloc/forecast/forecast_state.dart';
import 'package:tiler_app/components/TextInputWidget.dart';
import 'package:tiler_app/components/durationInputWidget.dart';
import 'package:tiler_app/components/tileUI/configUpdateButton.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';
import '../../../constants.dart' as Constants;

class NewTileSheetWidget extends StatefulWidget {
  final Function? onAddTile;
  final Function? onTileUpdate;
  final Function? onCancel;
  final NewTile? newTile;
  NewTileSheetWidget(
      {this.onAddTile, this.onCancel, this.newTile, this.onTileUpdate});
  @override
  NewTileSheetState createState() => NewTileSheetState();
}

class NewTileSheetState extends State<NewTileSheetWidget> {
  late final NewTile newTile;
  late ButtonStyle addButtonStyle;
  StreamSubscription? autoPopulateSubscription;
  bool? _isDurationManuallySet = false;
  bool? _isLocationManuallySet = false;
  late ScheduleApi scheduleApi;
  Location? _locationResponse;
  final Color iconColor = TileStyles.primaryColor;
  // final Color inputFieldIconColor = TileStyles.primaryColorDarkHSL.toColor();
  // final Color iconColor = TileStyles.primaryColorDarkHSL.toColor();
  final Color populatedTextColor = TileStyles.primaryContrastTextColor;
  final BoxDecoration boxDecoration = TileStyles.configUpdate_notSelected;
  // final BoxDecoration populatedDecoration = TileStyles.configUpdate_Selected;
  final BoxDecoration populatedDecoration = BoxDecoration(
      borderRadius: BorderRadius.all(
        const Radius.circular(10.0),
      ),
      color: TileStyles.primaryColor);
  late final LocationApi locationApi;
  Location? _homeLocation;
  Location? _workLocation;
  bool isPendingAutoResult = false;
  String? latestPendingResultId = null;
  String? newEventForeCastId = null;
  Set<String> pendingAutoResult = Set<String>();
  @override
  void initState() {
    super.initState();

    scheduleApi = ScheduleApi(getContextCallBack: () => context);
    locationApi = LocationApi(getContextCallBack: () => context);
    locationApi
        .getSpecificLocationByNickName(Location.homeLocationNickName)
        .then((homeLocation) {
      locationApi
          .getSpecificLocationByNickName(Location.workLocationNickName)
          .then((workLocation) {
        setState(() {
          _homeLocation = homeLocation;
          _workLocation = workLocation;
        });
      });
    });
    addButtonStyle = ButtonStyle(
      side: WidgetStateProperty.all(BorderSide(color: TileStyles.primaryColor)),
      shadowColor: WidgetStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        return 0;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        return TileStyles.primaryColor;
      }),
      minimumSize: WidgetStateProperty.resolveWith((states) {
        return Size(MediaQuery.sizeOf(context).width - 20, 50);
      }),
    );
    this.newTile =
        NewTile.fromJson((this.widget.newTile ?? NewTile()).toJson());
  }

  Widget _renderOptionalFields() {
    return Padding(
      padding: TileStyles.inpuPadding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              renderLocationButton(),
              const SizedBox.square(
                dimension: 5,
              ),
            ],
          ),
          renderForecastButton(),
        ],
      ),
    );
  }

  void onBlankTileName() {
    if (newTile.Name.isNot_NullEmptyOrWhiteSpace()) {
      newTile.Name = null;
    }

    setState(() {
      pendingAutoResult.clear();
      if (_isLocationManuallySet == null || _isLocationManuallySet == false) {
        _locationResponse = null;
        newTile.LocationAddress = null;
        newTile.LocationTag = null;
        newTile.LocationId = null;
        newTile.LocationSource = null;
        newTile.LocationIsVerified = null;
      }
      if (_isDurationManuallySet == null || _isDurationManuallySet == false) {
        newTile.DurationDays = "";
        newTile.DurationHours = "";
        newTile.DurationMinute = "";
      }
    });
  }

  void onTileNameChange(String? tileName) {
    if (!tileName.isNot_NullEmptyOrWhiteSpace()) {
      onBlankTileName();
    }
    if (newTile.Name == tileName) {
      return;
    }
    if (tileName != null &&
        tileName.isNot_NullEmptyOrWhiteSpace(minLength: 3)) {
      newTile.Name = tileName;
      if (autoPopulateSubscription != null) {
        autoPopulateSubscription!.cancel();
      }

      autoPopulateSubscription = new Future.delayed(
              const Duration(milliseconds: Constants.onTextChangeDelayInMs))
          .asStream()
          .listen((event) {
        setState(() {
          isPendingAutoResult = true;
        });
        if (newTile.Name != tileName) {
          setState(() {
            isPendingAutoResult = false;
          });
          return;
        }
        String pendingId = Utility.getUuid;
        pendingAutoResult.add(pendingId);
        latestPendingResultId = pendingId;
        this.scheduleApi.getAutoResult(tileName).then((remoteTileResponse) {
          if (newTile.Name != tileName) {
            setState(() {
              isPendingAutoResult = false;
            });
            return;
          }
          setState(() {
            isPendingAutoResult = false;
          });
          if (!pendingAutoResult.contains(pendingId) ||
              (latestPendingResultId != pendingId)) {
            pendingAutoResult.remove(pendingId);
            return;
          }
          pendingAutoResult.remove(pendingId);
          Duration? _durationResponse;
          if (remoteTileResponse.item2.isNotEmpty &&
              (_isLocationManuallySet == null ||
                  _isLocationManuallySet == false)) {
            onLocationUpdate(remoteTileResponse.item2.last);
          }
          if (remoteTileResponse.item1.isNotEmpty) {
            _durationResponse = remoteTileResponse.item1.last;
            if (_isDurationManuallySet == null ||
                _isDurationManuallySet == false) {
              onDurationChange(_durationResponse, isManuallySet: false);
            }
          }

          if (mounted) {
            setState(() {
              autoPopulateSubscription = null;
            });
          }
        }).whenComplete(() {
          if (mounted) {
            setState(() {
              isPendingAutoResult = false;
            });
          }
        });
      });
      setState(() {});
    } else {
      if (_isLocationManuallySet == null || _isLocationManuallySet == false) {
        setState(() {
          _locationResponse = null;
        });
      }
    }
  }

  void onLocationUpdate(Location? location) {
    setState(() {
      _locationResponse = location;
      if (location != null) {
        newTile.LocationAddress = location.address;
        newTile.LocationTag = location.description;
        newTile.LocationId = location.id;
        newTile.LocationSource = location.source;
        newTile.LocationIsVerified = location.isVerified.toString();
      } else {
        newTile.LocationAddress = null;
        newTile.LocationTag = null;
        newTile.LocationId = null;
        newTile.LocationSource = null;
        newTile.LocationIsVerified = null;
      }
    });

    onTileUpdate(newTile);
  }

  onTileUpdate(NewTile newTile) {
    if (this.widget.onTileUpdate != null) {
      this.widget.onTileUpdate!(newTile);
    }
    setState(() {
      newEventForeCastId = Utility.getSequentialId;
    });
    this
        .context
        .read<ForecastBloc>()
        .add(NewTileEvent(newTile: newTile, requestId: newEventForeCastId));
  }

  Widget foreCastButton(Function() onPressed,
      {bool isLoaded = false, double width = 65, double height = 30}) {
    return ElevatedButton(
        child: Column(
          children: [
            FaIcon(
              TileStyles.forecastIcon,
              color: isLoaded
                  ? TileStyles.primaryContrastColor
                  : TileStyles.primaryColor,
              size: 16,
            ),
            Text(AppLocalizations.of(context)!.previewTileForecast,
                style: TextStyle(
                  fontSize: 8,
                  color: isLoaded
                      ? TileStyles.primaryContrastColor
                      : TileStyles.primaryColor,
                ))
          ],
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          minimumSize: Size(width, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isLoaded
              ? TileStyles.primaryColor
              : TileStyles.primaryContrastColor,
        ));
  }

  Widget renderForecastButton({double width = 65, double height = 30}) {
    var buttonPressed = () {
      AnalysticsSignal.send('FORECAST_BUTTON_PRESSED');
      Navigator.pushNamed(context, '/ForecastPreview');
    };
    ForecastState forecastState = this.context.read<ForecastBloc>().state;
    if (forecastState is ForecastLoaded &&
        (forecastState.requestId.isNot_NullEmptyOrWhiteSpace() ||
            forecastState.requestId == newEventForeCastId)) {
      return foreCastButton(buttonPressed,
          isLoaded: true, height: height, width: width);
    }
    if (forecastState is ForecastInitial) {
      return foreCastButton(buttonPressed, height: height, width: width);
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
                width: width,
                height: height,
                decoration: BoxDecoration(
                    color: Color.fromRGBO(31, 31, 31, 0.8),
                    borderRadius: BorderRadius.circular(30)),
              )),
        ],
      ),
    );
  }

  void onDurationChange(Duration? duration, {bool isManuallySet = true}) {
    newTile.DurationDays = "";
    newTile.DurationHours = "";
    newTile.DurationMinute = "";
    setState(() {
      if (duration != null && duration.inMinutes > 0) {
        int totalMinutes = duration.inMinutes;
        int dayInMinutes = Duration.minutesPerDay;
        int hourInMinutes = Duration.minutesPerHour;
        int days = totalMinutes ~/ dayInMinutes;
        totalMinutes = totalMinutes % dayInMinutes;
        int hours = totalMinutes ~/ hourInMinutes;
        int minutes = totalMinutes % hourInMinutes;
        newTile.DurationDays = days.toString();
        newTile.DurationHours = hours.toString();
        newTile.DurationMinute = minutes.toString();
        _isDurationManuallySet = isManuallySet;
      }
    });
    onTileUpdate(this.newTile);
  }

  Duration? _getDuration() {
    int dayInMinutes = Duration.minutesPerDay;
    int hourInMinutes = Duration.minutesPerHour;
    int? totalMinutes;
    if (newTile.DurationDays != null && newTile.DurationDays!.isNotEmpty) {
      int? days = int.tryParse(newTile.DurationDays!);
      if (days != null) {
        totalMinutes = (totalMinutes ?? 0) + dayInMinutes * days;
      }
    }

    if (newTile.DurationHours != null && newTile.DurationHours!.isNotEmpty) {
      int? hours = int.tryParse(newTile.DurationHours!);
      if (hours != null) {
        totalMinutes = (totalMinutes ?? 0) + hourInMinutes * hours;
      }
    }

    if (newTile.DurationMinute != null && newTile.DurationMinute!.isNotEmpty) {
      int? minutes = int.tryParse(newTile.DurationMinute!);
      if (minutes != null) {
        totalMinutes = (totalMinutes ?? 0) + minutes;
      }
    }

    return newTile.getDuration();
  }

  renderLocationButton() {
    if (_locationResponse == null) {
      return SizedBox.shrink();
    }
    bool isLocationConfigSet = _locationResponse!.isNotNullAndNotDefault;

    Widget locationConfigButton = ConfigUpdateButton(
      text: _locationResponse!.description ?? "",
      padding: EdgeInsets.fromLTRB(10, 5, 10, 5),
      iconPadding: EdgeInsets.fromLTRB(0, 0, 5, 0),
      constraints:
          BoxConstraints(maxWidth: (MediaQuery.of(context).size.width * 0.30)),
      prefixIcon: Icon(
        Icons.location_pin,
        size: 15,
        color: isLocationConfigSet ? populatedTextColor : iconColor,
      ),
      textStyle: TextStyle(
        fontSize: 15,
        fontFamily: TileStyles.rubikFontName,
        color: isLocationConfigSet ? populatedTextColor : iconColor,
      ),
      decoration: isLocationConfigSet ? populatedDecoration : boxDecoration,
      textColor: isLocationConfigSet ? populatedTextColor : iconColor,
      onPress: () {
        Location locationHolder = _locationResponse ?? Location.fromDefault();
        Map<String, dynamic> locationParams = {
          'location': locationHolder,
        };
        List<Location> defaultLocations = [];

        if (_homeLocation != null && _homeLocation!.isNotNullAndNotDefault) {
          defaultLocations.add(_homeLocation!);
        }
        if (_workLocation != null && _workLocation!.isNotNullAndNotDefault) {
          defaultLocations.add(_workLocation!);
        }
        if (defaultLocations.isNotEmpty) {
          locationParams['defaults'] = defaultLocations;
        }

        Navigator.pushNamed(context, '/LocationRoute',
                arguments: locationParams)
            .whenComplete(() {
          Location? populatedLocation = locationParams['location'] as Location?;
          AnalysticsSignal.send('ADD_TILE_NEWTILE_MANUAL_LOCATION_NAVIGATION');
          setState(() {
            if (populatedLocation != null) {
              Location? updatedLocationRes = populatedLocation;
              if (!updatedLocationRes.address.isNot_NullEmptyOrWhiteSpace() &&
                  !updatedLocationRes.description
                      .isNot_NullEmptyOrWhiteSpace() &&
                  !updatedLocationRes.id.isNot_NullEmptyOrWhiteSpace() &&
                  updatedLocationRes.longitude == null &&
                  updatedLocationRes.latitude == null) {
                updatedLocationRes = null;
              }
              onLocationUpdate(updatedLocationRes);
            }
            _isLocationManuallySet = true;
          });
        });
      },
    );
    return locationConfigButton;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          BlocListener<ForecastBloc, ForecastState>(
            listener: (context, state) {
              if (state is ForecastLoading) {
                Utility.debugPrint(
                    "ForecastLoading state received: ${state.requestId}");
                return;
              } else if (state is ForecastLoaded) {
                Utility.debugPrint(
                    "ForecastLoaded state received: ${state.requestId}");
              }
            },
          )
        ],
        child: Stack(
          children: [
            isPendingAutoResult
                ? Shimmer.fromColors(
                    baseColor: Colors.transparent,
                    highlightColor: TileStyles.primaryColor.withLightness(0.9),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: ColoredBox(
                          color: Colors.yellow,
                          child: Container(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height,
                          )),
                    ))
                : SizedBox.shrink(),
            Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: TileStyles.defaultBackgroundColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                      ),
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.addTile,
                      style: TextStyle(
                        color: TileStyles.accentContrastColor,
                        fontFamily: TileStyles.rubikFontName,
                        fontSize: TileStyles.inputFontSize,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox.square(
                    dimension: 5,
                  ),
                  Padding(
                    padding: TileStyles.inpuPadding,
                    child: TextInputWidget(
                      placeHolder: AppLocalizations.of(context)!.tileName,
                      value: newTile.Name,
                      onTextChange: onTileNameChange,
                    ),
                  ),
                  const SizedBox.square(
                    dimension: 5,
                  ),
                  Padding(
                    padding: TileStyles.inpuPadding,
                    child: DurationInputWidget(
                      duration: _getDuration(),
                      onDurationChange: onDurationChange,
                    ),
                  ),
                  _renderOptionalFields(),
                  const SizedBox.square(
                    dimension: 5,
                  ),
                  this.newTile.Name.isNot_NullEmptyOrWhiteSpace(minLength: 3) &&
                          this.newTile.getDuration() != null
                      ? ElevatedButton.icon(
                          onPressed: () {
                            if (this.widget.onAddTile != null) {
                              this.widget.onAddTile!(newTile);
                            }
                          },
                          style: addButtonStyle,
                          icon: Icon(Icons.check),
                          label: Text(this.widget.newTile == null
                              ? AppLocalizations.of(context)!.add
                              : AppLocalizations.of(context)!.update))
                      : SizedBox.shrink(),
                  SizedBox.square(
                    dimension: 50,
                  )
                ],
              ),
            )
          ],
        ));
  }
}
