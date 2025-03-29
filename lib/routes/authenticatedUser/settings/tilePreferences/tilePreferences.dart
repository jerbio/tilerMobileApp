import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/tilePreferences/bloc/tile_preferences_bloc.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/styles.dart';

class TilePreferencesScreen extends StatelessWidget {
  static const String routeName = '/tilePreferences';
  static final String tilePreferencesCancelAndProceedRouteName =
      "tilePreferencesCancelAndProceedRouteName";
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TilePreferencesBloc(
        settingsApi: SettingsApi(getContextCallBack: () => context),
      )..add(FetchProfiles()),
      child: _PreferencesView(),
    );
  }
}

class _PreferencesView extends StatelessWidget {

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
  @override
  Widget build(BuildContext context) {
    NotificationOverlayMessage notificationOverlayMessage =
    NotificationOverlayMessage();
    return BlocListener<TilePreferencesBloc, TilePreferencesState>(
      listener: (context, state) {
        if (state is UpdateSuccess) {
          notificationOverlayMessage.showToast(
            context,
            "Restrictions have been updated successfully.",
            NotificationOverlayMessageType.success,
          );
          // Future.delayed(Duration(seconds: 2), () {
          //   Navigator.pop(context);
          // });
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
            onProceed: state is PreferencesLoaded ? () {
              context.read<TilePreferencesBloc>().add(ProceedUpdate());
            } : null,
            routeName: TilePreferencesScreen
                .tilePreferencesCancelAndProceedRouteName,
            appBar: AppBar(
              centerTitle: true,
              title: Text("Tile Preferences"),
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
    );
  }

  Widget _buildContent(BuildContext context, TilePreferencesState state) {
    if (state is! PreferencesLoaded) {
      return renderPending();
    }

    final loadedState = state as PreferencesLoaded;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 30),
        _buildConfigButton(
          context,
          loadedState.workProfile,
          AppLocalizations.of(context)!.setWorkProfileHours,
          isWorkProfile: true,
        ),
        SizedBox(height: 20),
        _buildConfigButton(
          context,
          loadedState.personalProfile,
          AppLocalizations.of(context)!.setPersonalHours,
          isWorkProfile: false,
        ),
      ],
    );
  }
  Widget _buildConfigButton(
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
}
