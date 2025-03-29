import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/SubCalendarTiles/sub_calendar_tiles_bloc.dart';
import 'package:tiler_app/bloc/calendarTiles/calendar_tile_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/bloc/monthlyUiDateManager/monthly_ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/bloc/settings/settings_bloc.dart';
import 'package:tiler_app/bloc/settings/settings_event.dart';
import 'package:tiler_app/bloc/settings/settings_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/bloc/tilelistCarousel/tile_list_carousel_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/bloc/weeklyUiDateManager/weekly_ui_date_manager_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'package:tiler_app/styles.dart';
// import 'package:tiler_app/routes/authenticatedUser/settings/integrations/integrationsBloc/integrations_bloc.dart';

class Settings extends StatelessWidget {
  static final String routeName = '/Setting';


  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final textColor =  brightness == Brightness.dark ? Colors.white : Colors.black;
    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        NotificationOverlayMessage notificationOverlayMessage =
        NotificationOverlayMessage();
        if (state.navigationRoute != null) {
          if (state.navigationRoute == '/LoggedOut') {
            Navigator.pushNamedAndRemoveUntil(
                context, state.navigationRoute!, (route) => false).then((_) {
                context.read<ScheduleBloc>().add(LogOutScheduleEvent(() => context));
                context.read<SubCalendarTileBloc>().add(LogOutSubCalendarTileBlocEvent());
                context.read<UiDateManagerBloc>().add(LogOutUiDateManagerEvent());
                context.read<WeeklyUiDateManagerBloc>().add(LogOutWeeklyUiDateManagerEvent());
                context.read<MonthlyUiDateManagerBloc>().add(LogOutMonthlyUiDateManagerEvent());
                context.read<CalendarTileBloc>().add(LogOutCalendarTileEvent());
                context.read<TileListCarouselBloc>().add(EnableCarouselScrollEvent(isImmediate: true));
                context.read<IntegrationsBloc>().add(ResetIntegrationsEvent());
                context.read<ScheduleSummaryBloc>().add(LogOutScheduleDaySummaryEvent());
                context.read<SettingsBloc>().add(ResetSettingsEvent());
            });
          } else {
            Navigator.pushNamed(context, state.navigationRoute!);
          }
          context.read<SettingsBloc>().add(ResetSettingsEvent());
        }
        if (state.errorMessage != null) {
          notificationOverlayMessage.showToast(
            context,
            state.errorMessage!,
            NotificationOverlayMessageType.error,
          );
          context.read<SettingsBloc>().add(ResetSettingsEvent());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.settings),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildListTile(
              icon: 'assets/icons/settings/AccountInfo.svg',
              title: AppLocalizations.of(context)!.accountInfo,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/accountInfo')),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/TilePreferences.svg',
              title: AppLocalizations.of(context)!.tilePreferences,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/tilePreferences')),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/NotificationsPreferences.svg',
              title: AppLocalizations.of(context)!.notificationsPreferences,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/notificationsPreferences')),
            ),
            _buildDivider(),
            _buildListTile(
              icon: 'assets/icons/settings/Security.svg',
              title: AppLocalizations.of(context)!.security,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/security')),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/Connections.svg',
              title: AppLocalizations.of(context)!.connections,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/Connections')),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/MyLocations.svg',
              title: AppLocalizations.of(context)!.myLocations,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/myLocations')),
            ),
            _buildDivider(),
            _buildListTile(
              icon: 'assets/icons/settings/AboutTiler.svg',
              title: AppLocalizations.of(context)!.aboutTiler,
              color: textColor,
              onPress: () => context.read<SettingsBloc>().add(NavigateEvent('/aboutTiler')),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/Logout.svg',
              title: AppLocalizations.of(context)!.logout,
              color: TileStyles.primaryColor,
              onPress: () => context.read<SettingsBloc>().add(LogOutEvent()),
            ),
            _buildListTile(
              icon: 'assets/icons/settings/DeleteAccount.svg',
              title: AppLocalizations.of(context)!.deleteAccount,
              color: TileStyles.primaryColor,
              onPress: () => context.read<SettingsBloc>().add(DeleteAccountEvent()),
            ),
            _buildDivider(),
            Center(child: _buildDarkModeSwitch()),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey.shade300,
      margin: EdgeInsets.only(left: 50, right: 40),
    );
  }

  Widget _buildListTile(
      {required String icon,
        required String title,
        required Color color,
        required VoidCallback onPress}) {
    return ListTile(
      leading: SvgPicture.asset(icon, color: color ),
      title: Text(title, style: TextStyle(color: color )),
      onTap: onPress,
    );
  }

  Widget _buildDarkModeSwitch() {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.darkMode,
                    style: TextStyle(fontSize: 16)),
                Switch(
                  value: state.isDarkMode,
                  onChanged: (value) {
                    // Update the theme without triggering a rebuild
                    ThemeManager.setThemeMode(value).then((_) {
                      context.read<SettingsBloc>().add(ToggleDarkModeEvent(value));
                    });
                  },
                  activeColor: Colors.black,
                  inactiveTrackColor: Colors.grey.shade300,
                  activeTrackColor: Colors.black,
                  thumbColor: MaterialStateProperty.all(Colors.white),
                  thumbIcon: MaterialStateProperty.resolveWith((states) {
                    return Icon(
                      state.isDarkMode
                          ? Icons.nightlight_round
                          : Icons.wb_sunny,
                      color: Colors.grey.shade600,
                      size: 18,
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

