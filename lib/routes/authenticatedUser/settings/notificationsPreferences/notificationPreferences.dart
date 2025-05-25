import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/notificationsPreferences/bloc/notifications_bloc.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

class NotificationPreferences extends StatefulWidget {
  static final String routeName = '/notificationsPreferences';
  static final String notificationPreferencesCancelAndProceedRouteName =
      "notificationPreferencesCancelAndProceedRouteName";
  const NotificationPreferences({super.key});

  @override
  State<NotificationPreferences> createState() => _NotificationPreferencesState();
}

class _NotificationPreferencesState extends State<NotificationPreferences> {
  bool tileReminders = true;
  bool appUpdates = true;
  bool marketingUpdates = false;
  bool emailNotifications = true;

  Widget _renderPendingOverlay(){
    return Stack(
      children: [
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 200.0,
                    width: 200.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                    ),
                  ),
                  Image.asset(
                    'assets/images/tiler_logo_black.png',
                    fit: BoxFit.cover,
                    scale: 7,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildSectionHeader(String icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          SvgPicture.asset(
            icon,
            width: 20,
            height: 20,
          ),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildToggle(String text, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      //activeTrackColor: Colors.green[300],
      title: Text(text, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<bool>  _saveNotificationPreferences(BuildContext context)async {

    final completer = Completer<bool>();
    final subscription = context.read<NotificationPreferencesBloc>().stream.listen((state) {
      if (state is NotificationPreferencesSaved ) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
      if ( state is NotificationPreferencesError) {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      }
    });
    context.read<NotificationPreferencesBloc>().add(SaveNotificationPreferences());
    final result = await completer.future;
    subscription.cancel();
    return result;
  }



  Widget _buildContent(BuildContext context,NotificationPreferencesLoaded state){

    return CancelAndProceedTemplateWidget(

      onProceed:(state is NotificationPreferencesLoaded && (state as NotificationPreferencesLoaded).hasChanges) ?() => _saveNotificationPreferences(context): null,
      routeName: NotificationPreferences.notificationPreferencesCancelAndProceedRouteName,
      appBar: AppBar(
        centerTitle: true,
        title: Text(AppLocalizations.of(context)!.notificationsPreferences),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child:  Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("assets/icons/settings/notification_bell.svg", "Push Notifications"),
            _buildToggle(
              AppLocalizations.of(context)!.tileReminders,
              state.tileReminders,
                  (value) {
                context.read<NotificationPreferencesBloc>().add(
                  UpdateTileReminders(value),
                );
              },
            ),
            _buildToggle(
              AppLocalizations.of(context)!.appUpdates,
              state.appUpdates,
                  (value) {
                context.read<NotificationPreferencesBloc>().add(
                  UpdateAppUpdates(value),
                );
              },
            ),
            _buildToggle(
              AppLocalizations.of(context)!.marketingUpdates,
              state.marketingUpdates,
                  (value) {
                context.read<NotificationPreferencesBloc>().add(
                  UpdateMarketingUpdates(value),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader("assets/icons/settings/notification_email.svg", "Emails"),
            _buildToggle(
              AppLocalizations.of(context)!.emailNotifications,
              state.emailNotifications,
                  (value) {
                context.read<NotificationPreferencesBloc>().add(
                  UpdateEmailNotifications(value),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    NotificationOverlayMessage notificationOverlayMessage =
    NotificationOverlayMessage();
    return BlocProvider(
      create: (context) => NotificationPreferencesBloc(
        settingsApi: SettingsApi( getContextCallBack: () => context),
      )..add(FetchNotificationPreferences()),
      child:BlocListener<NotificationPreferencesBloc, NotificationPreferencesState>(
        listener: (context, state) {
          if (state is NotificationPreferencesSaved) {
            notificationOverlayMessage.showToast(
              context,
              AppLocalizations.of(context)!.notificationsPreferencesUpdatedSuccessfully,
              NotificationOverlayMessageType.success,
            );
          }
          if(state is NotificationPreferencesError){
            notificationOverlayMessage.showToast(
              context,
              state.message,
              NotificationOverlayMessageType.error,
            );
          }
        },
        child: BlocBuilder<NotificationPreferencesBloc, NotificationPreferencesState>(
          builder: (context, state) {
            NotificationPreferencesLoaded loadedState;
            if (state is NotificationPreferencesLoaded) {
              loadedState = state;
            } else {
              loadedState = NotificationPreferencesLoaded(
                userSettings: UserSettings(
                  userPreference: UserPreference(
                    notificationEnabled: false,
                    emailNotificationEnabled: false,
                    textNotificationEnabled: false,
                    notificationEnabledMs: 0,
                  ),
                  marketingPreference: MarketingPreference(
                    disableAll: true,
                    disableEmail: false,
                    disableTextMsg: false,
                  ),
                  scheduleProfile: null,
                ),
                tileReminders: false,
                appUpdates: false,
                marketingUpdates: false,
                emailNotifications: false,
                hasChanges: false,
              );
            }
            return Stack(
              children: [
                _buildContent(context,loadedState),
                if (state is NotificationPreferencesLoading || state is NotificationPreferencesInitial)
                  _renderPendingOverlay(),
              ],
            );
            },
        ),
      ),
    );
  }
}
