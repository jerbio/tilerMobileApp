import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/scheduleProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileTime.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/bloc/tile_preferences_bloc.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:tiler_app/util.dart';

class TilePreferencesScreen extends StatelessWidget {
  static const String routeName = '/tilePreferences';
  static final String tilePreferencesCancelAndProceedRouteName =
      "tilePreferencesCancelAndProceedRouteName";
  Widget _buildSectionContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      margin: EdgeInsets.symmetric(vertical:10 ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
  Widget renderPending() {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
            child: CircularProgressIndicator(),
            height: 200.0,
            width: 200.0,
          )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
  }

  Widget _buildTransportOptions(BuildContext context, PreferencesLoaded state) {
    return _buildSectionContainer(
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.transportationMethodQuestion,
            style: TextStyle(fontSize: 18),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _transportOption(
                    context,
                    AppLocalizations.of(context)!.travelMediumBiking,
                    "assets/icons/settings/biking_icon.svg",
                    TravelMedium.bicycling,
                    state
                ),
                _transportOption(
                    context,
                    AppLocalizations.of(context)!.travelMediumTransit,
                    "assets/icons/settings/transit_icon.svg",
                    TravelMedium.transit,
                    state
                ),
                _transportOption(
                    context,
                    AppLocalizations.of(context)!.travelMediumDriving,
                    "assets/icons/settings/driving_icon.svg",
                    TravelMedium.driving,
                    state
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportOption(BuildContext context, String label, String svgPath,
      TravelMedium medium, PreferencesLoaded state) {
    final isSelected = state.userSettings?.scheduleProfile?.travelMedium == medium;
    final bloc = context.read<TilePreferencesBloc>();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () {
            bloc.add(UpdateTravelMedium(medium));
          },
          child: Container(
            padding: EdgeInsets.all(15),
            margin: EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? TileStyles.primaryColor: Colors.grey[200],
              border: Border.all(
                color: isSelected ? TileStyles.primaryColor : Color(0xFF9A9E9F),
              ),
            ),
            child: SvgPicture.asset(
              svgPath,
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isSelected ?  Color(0xFFFFFFFF)  : Color(0xFF9A9E9F),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? TileStyles.primaryColor : Color(0xFF9A9E9F),
          ),
        ),
      ],
    );
  }

  void _handleProfileUpdate(
      BuildContext context,
      RestrictionProfile? profile,
      bool isWorkProfile
      ) {
    final bloc = context.read<TilePreferencesBloc>();
    AnalysticsSignal.send('SETTINGS_OPEN_RESTRICTION_PROFILE_${isWorkProfile ? "WORK" : "PERSONAL"}');

    Map<String, dynamic> restrictionParams = {
      'routeRestrictionProfile': profile,
      'stackRouteHistory': [TilePreferencesScreen.routeName]
    };

    Navigator.pushNamed(context, '/TimeRestrictionRoute', arguments: restrictionParams)
        .whenComplete(() {
      if (restrictionParams.containsKey('routeRestrictionProfile')) {
        RestrictionProfile? updatedProfile = restrictionParams['routeRestrictionProfile'] as RestrictionProfile?;

        if (updatedProfile != null && profile != null) {
          updatedProfile.id = profile.id;
        }

        if (profile != null &&
            (updatedProfile == null || (restrictionParams.containsKey('isAnyTime') && restrictionParams['isAnyTime'] != null))) {
          profile.isEnabled = !restrictionParams['isAnyTime'];
          updatedProfile = profile;
        }

        if (isWorkProfile) {
          bloc.add(UpdateWorkProfile(updatedProfile));
        } else {
          bloc.add(UpdatePersonalProfile(updatedProfile));
        }
      }
    });
  }

  Widget _buildRestrictionButton(
      BuildContext context,
      RestrictionProfile? profile,
      String label, {
        required bool isWorkProfile,
      }) {
    return TextButton(
      onPressed: () => _handleProfileUpdate(context, profile, isWorkProfile),
      child: Text(
        label,
        style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.w300),
      ),
    );
  }

  Widget timeRestrictionWidget(BuildContext context,PreferencesLoaded state){
    return _buildSectionContainer(
      child: Column(
        children: [
          _buildRestrictionButton(
            context,
            state.workProfile,
            AppLocalizations.of(context)!.setWorkHours,
            isWorkProfile: true,
          ),
          _buildRestrictionButton(
            context,
            state.personalProfile,
            AppLocalizations.of(context)!.setPersonalHours,
            isWorkProfile: false,
          ),
        ],
      ),
    );
  }
  TableRow _buildBedTimeWidget(BuildContext context, PreferencesLoaded state) {
    return  TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 25),
          child: Text(
            AppLocalizations.of(context)!.bedTime,
            style: TextStyle(fontSize: 16),
          ),
        ),
        EditTileTime(
              time: state.endOfDay?.timeOfDay ?? Utility.defaultEndOfDay,
              isPref: true,
              onInputChange: (updatedTimeOfDay) {
                final bloc = context.read<TilePreferencesBloc>();
                StartOfDay? updatedEndOfDay = state.endOfDay;

                if (updatedEndOfDay == null) {
                  updatedEndOfDay = StartOfDay();
                }

                updatedEndOfDay.timeOfDay = updatedTimeOfDay;
                bloc.add(UpdateEndOfDay(updatedEndOfDay));
              },
        ),
      ],
    );
  }

  TableRow _buildSleepDurationWidget(BuildContext context, PreferencesLoaded state) {
    final sleepDuration = Duration(
        milliseconds: state.userSettings?.scheduleProfile?.sleepDuration?.toInt() ?? 0
    );

    String displayText = AppLocalizations.of(context)!.sleepDuration;
    if (sleepDuration != null && sleepDuration.inMinutes > 0) {
      int hours = sleepDuration.inHours;
      int minutes = sleepDuration.inMinutes % 60;
      displayText = hours > 0 ?
      "${hours}:${minutes.toString().padLeft(2, '0')}" :
      "00:${minutes.toString().padLeft(2, '0')}";
    }
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 25),
          child: Text(
            AppLocalizations.of(context)!.bedTime,
            style: TextStyle(fontSize: 16),
          ),
        ),
        ElevatedButton(
              style: TileStyles.strippedButtonStyle,
              onPressed: () {
                Map<String, dynamic> durationParams = {'duration': sleepDuration};
                Navigator.pushNamed(context, '/DurationDial', arguments: durationParams)
                    .whenComplete(() {
                  Duration? updatedDuration = durationParams['duration'] as Duration?;
                  if (updatedDuration != null) {
                    final bloc = context.read<TilePreferencesBloc>();
                    bloc.add(UpdateSleepDuration(updatedDuration.inMilliseconds));
                  }
                });
              },
              child: Row(
                children: [
                  Container(
                      margin: EdgeInsets.fromLTRB(0, 0, 10, 0),
                      child: SvgPicture.asset(
                        "assets/icons/settings/sleep_time_icon.svg",
                        width: 14,
                        height: 14,
                      )
                  ),
                  Text(
                    displayText,
                    style: TileStyles.editTimeOrDateTimeStyle.copyWith(
                      color: Color.fromRGBO(154, 158, 159, 1),
                      decoration: TextDecoration.underline,
                      decorationColor: Color.fromRGBO(154, 158, 159, 1),
                    )
                  ),
                ],
              ),
        ),
      ],
    );
  }
  Widget _buildBlockOutHourWidget(BuildContext context, PreferencesLoaded state) {
    return _buildSectionContainer(
      child: Center(
        child: IntrinsicWidth(
          child: Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: IntrinsicColumnWidth(),
            },
            children: [

                  _buildBedTimeWidget(context, state),
                  _buildSleepDurationWidget(context, state),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool>  _saveTilePreferences(BuildContext context)async {
    final completer = Completer<bool>();

    final subscription = context.read<TilePreferencesBloc>().stream.listen((state) {
      if (state is UpdateSuccess ) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
      if ( state is PreferencesError) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });
    context.read<TilePreferencesBloc>().add(ProceedUpdate());
    final result = await completer.future;
    subscription.cancel();
    return result;
  }


  @override
  Widget build(BuildContext context) {
    NotificationOverlayMessage notificationOverlayMessage =
    NotificationOverlayMessage();
    return BlocProvider(
      create: (context) => TilePreferencesBloc(
        settingsApi: SettingsApi(getContextCallBack: () => context),
      )..add(FetchProfiles()),
      child:BlocListener<TilePreferencesBloc, TilePreferencesState>(
        listener: (context, state) {
          if (state is UpdateSuccess) {
            notificationOverlayMessage.showToast(
              context,
              AppLocalizations.of(context)!.tilePreferencesUpdatedSuccessfully,
              NotificationOverlayMessageType.success,
            );
          }
          if(state is PreferencesError){

            notificationOverlayMessage.showToast(
              context,
              state.message,
              NotificationOverlayMessageType.error,
            );
          }
          },
        child: BlocBuilder<TilePreferencesBloc, TilePreferencesState>(
            builder: (context, state) {
              return CancelAndProceedTemplateWidget(

                onProceed:(state is PreferencesLoaded && (state as PreferencesLoaded).hasChanges) ?()=> _saveTilePreferences(context): null,
                routeName: TilePreferencesScreen
                    .tilePreferencesCancelAndProceedRouteName,
                appBar: AppBar(
                  centerTitle: true,
                  title: Text(AppLocalizations.of(context)!.tilePreferences),
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: _buildContent(context, state),
                  ),
                ),
              );
            }
            ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TilePreferencesState state) {
    if (state is! PreferencesLoaded) {
      return renderPending();
    }

    final loadedState = state as PreferencesLoaded;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
           _buildTransportOptions(context, loadedState),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              AppLocalizations.of(context)!.defineYourTimeRestrictions,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          timeRestrictionWidget(context,loadedState),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Text(
              AppLocalizations.of(context)!.setYourBlockOutHours,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          _buildBlockOutHourWidget(context,loadedState)

        ],
      ),
    );
  }

}
