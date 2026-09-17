import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart'; // Add this import
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
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/services/api/locationApi.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';
import 'package:tiler_app/theme/tile_decorations.dart';
import 'package:tiler_app/theme/tile_dimensions.dart';
import 'package:tiler_app/theme/tile_spacing.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/theme/tile_theme.dart';
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

  // final BoxDecoration populatedDecoration = TileStyles.configUpdate_Selected;

  late ThemeData theme;
  late ColorScheme colorScheme;
  late TileThemeExtension tileThemeExtension;
  late BoxDecoration boxDecoration;
  late Color unPopulatedOnSurfaceColor;
  late Color populatedOnSurfaceColor;
  late BoxDecoration populatedDecoration;

  bool isPendingAutoResult = false;
  String? latestPendingResultId = null;
  String? newEventForeCastId = null;
  Set<String> pendingAutoResult = Set<String>();
  @override
  void initState() {
    super.initState();

    scheduleApi = ScheduleApi(getContextCallBack: () => context);
    this.newTile =
        NewTile.fromJson((this.widget.newTile ?? NewTile()).toJson());
  }

  @override
  void dispose() {
    // More options pops this sheet, usually within the name debounce. Left
    // running, the debounce called setState on a disposed State — an
    // assertion in debug — and issued a prediction nobody would read (D64).
    autoPopulateSubscription?.cancel();
    autoPopulateSubscription = null;
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
    tileThemeExtension = theme.extension<TileThemeExtension>()!;
    boxDecoration =
        TileDecorations.configUpdate_notSelected(colorScheme.primary);
    populatedOnSurfaceColor = colorScheme.onPrimary;
    unPopulatedOnSurfaceColor = colorScheme.primary;
    populatedDecoration = BoxDecoration(
        borderRadius: BorderRadius.all(
          const Radius.circular(10.0),
        ),
        color: colorScheme.primary);
    addButtonStyle = ButtonStyle(
      side: WidgetStateProperty.all(BorderSide(color: colorScheme.primary)),
      shadowColor: WidgetStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        return 0;
      }),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        return Colors.transparent;
      }),
      minimumSize: WidgetStateProperty.resolveWith((states) {
        return Size(MediaQuery.sizeOf(context).width - 20, 50);
      }),
    );
  }

  Widget _renderOptionalFields() {
    return Padding(
      padding: TileSpacing.inputPadding,
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
    // The name is recorded on EVERY change, and the parent told, regardless
    // of whether it is long enough to predict on. It used to be set only
    // inside the prediction branch and reported only when a prediction
    // landed, so More options opened blank whenever the user tapped it
    // before the prediction returned, typed fewer than three characters, or
    // got an empty prediction (D64).
    newTile.Name = tileName.isNot_NullEmptyOrWhiteSpace() ? tileName : null;
    onTileUpdate(newTile);
    if (tileName != null &&
        tileName.isNot_NullEmptyOrWhiteSpace(minLength: 3)) {
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
              FontAwesomeIcons.binoculars,
              color: isLoaded ? colorScheme.onPrimary : colorScheme.primary,
              size: 16,
            ),
            Text(AppLocalizations.of(context)!.previewTileForecast,
                style: TextStyle(
                  fontSize: 8,
                  color: isLoaded ? colorScheme.onPrimary : colorScheme.primary,
                ))
          ],
        ),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(0),
          minimumSize: Size(width, height),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isLoaded
              ? colorScheme.primary
              : colorScheme.surfaceContainerLowest,
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
              baseColor: colorScheme.tertiaryContainer.withAlpha(75),
              highlightColor: colorScheme.primary.withLightness(0.7),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
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
        color: isLocationConfigSet
            ? populatedOnSurfaceColor
            : unPopulatedOnSurfaceColor,
      ),
      textStyle: TextStyle(
        fontSize: 15,
        fontFamily: TileTextStyles.rubikFontName,
        color: isLocationConfigSet
            ? populatedOnSurfaceColor
            : unPopulatedOnSurfaceColor,
      ),
      decoration: isLocationConfigSet ? populatedDecoration : boxDecoration,
      textColor: isLocationConfigSet
          ? populatedOnSurfaceColor
          : unPopulatedOnSurfaceColor,
      onPress: () async {
        // The shared picker (P5-1, D66): it loads Home / Work itself and pops
        // with the chosen place, or null when backed out of. The legacy
        // route wrote into a by-reference map and could hand back an empty
        // Location that had to be recognised and discarded.
        final Location? picked = await Navigator.of(context).push<Location>(
          MaterialPageRoute<Location>(
            builder: (BuildContext context) => AddTileLocationScreen(
              source: ApiAddTileLocationSource(
                locationApi: LocationApi(getContextCallBack: () => context),
              ),
              initialLocation: _locationResponse,
            ),
          ),
        );
        AnalysticsSignal.send('ADD_TILE_NEWTILE_MANUAL_LOCATION_NAVIGATION');
        if (picked == null || !mounted) return;
        setState(() {
          onLocationUpdate(picked);
          _isLocationManuallySet = true;
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
                ? TileThemeNew.getShimmerPending(context, colorScheme.primary)
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
                      color: colorScheme.surfaceContainerLowest,
                    ),
                    padding: EdgeInsets.all(16),
                    child: Text(
                      AppLocalizations.of(context)!.addTile,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: TileDimensions.textFontSize,
                      ),
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox.square(
                    dimension: 5,
                  ),
                  Padding(
                    padding: TileSpacing.inputPadding,
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
                    padding: TileSpacing.inputPadding,
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
