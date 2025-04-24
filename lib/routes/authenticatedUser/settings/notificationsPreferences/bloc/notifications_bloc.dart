import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationPreferencesBloc extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  final SettingsApi settingsApi;

  NotificationPreferencesBloc({required this.settingsApi})
      : super(NotificationPreferencesInitial()) {
    on<FetchNotificationPreferences>(_onFetchNotificationPreferences);
    on<UpdateTileReminders>(_onUpdateTileReminders);
    on<UpdateAppUpdates>(_onUpdateAppUpdates);
    on<UpdateMarketingUpdates>(_onUpdateMarketingUpdates);
    on<UpdateEmailNotifications>(_onUpdateEmailNotifications);
    on<SaveNotificationPreferences>(_onSaveNotificationPreferences);
  }

  Future<void> _onFetchNotificationPreferences(
      FetchNotificationPreferences event,
      Emitter<NotificationPreferencesState> emit,
      ) async {
    emit(NotificationPreferencesLoading());
    try {
      final userSettings = await settingsApi.getUserSettings();
      emit(NotificationPreferencesLoaded(
        userSettings: userSettings,
        tileReminders: userSettings.userPreference?.notificationEnabled ?? false,
        appUpdates: userSettings.userPreference?.textNotificationEnabled ?? false,
        marketingUpdates: !(userSettings.marketingPreference?.disableAll ?? false),
        emailNotifications: userSettings.userPreference?.emailNotificationEnabled ?? false,
        hasChanges: false,
      ));
    } catch (e) {
      emit(NotificationPreferencesError(e.toString()));
    }
  }

  void _onUpdateTileReminders(
      UpdateTileReminders event,
      Emitter<NotificationPreferencesState> emit,
      ) {
    if (state is NotificationPreferencesLoaded) {
      final currentState = state as NotificationPreferencesLoaded;
      final updatedUserPreference = UserPreference(
        notificationEnabled: event.value,
        notificationEnabledMs: currentState.userSettings.userPreference?.notificationEnabledMs ?? 0,
        emailNotificationEnabled: currentState.userSettings.userPreference?.emailNotificationEnabled,
        textNotificationEnabled: currentState.userSettings.userPreference?.textNotificationEnabled,
      );

      final updatedUserSettings = UserSettings(
        userPreference: updatedUserPreference,
        marketingPreference: currentState.userSettings.marketingPreference,
        scheduleProfile: currentState.userSettings.scheduleProfile,
      );

      emit(currentState.copyWith(
        userSettings: updatedUserSettings,
        tileReminders: event.value,
        isDirty: true,
      ));
    }
  }

  void _onUpdateAppUpdates(
      UpdateAppUpdates event,
      Emitter<NotificationPreferencesState> emit,
      ) {
    if (state is NotificationPreferencesLoaded) {
      final currentState = state as NotificationPreferencesLoaded;

      final updatedUserPreference = UserPreference(
        notificationEnabled: currentState.userSettings.userPreference?.notificationEnabled,
        notificationEnabledMs: currentState.userSettings.userPreference?.notificationEnabledMs ?? 0,
        emailNotificationEnabled: currentState.userSettings.userPreference?.emailNotificationEnabled,
        textNotificationEnabled: event.value,
      );

      final updatedUserSettings = UserSettings(
        userPreference: updatedUserPreference,
        marketingPreference: currentState.userSettings.marketingPreference,
        scheduleProfile: currentState.userSettings.scheduleProfile,
      );

      emit(currentState.copyWith(
        userSettings: updatedUserSettings,
        appUpdates: event.value,
        isDirty: true,
      ));
    }
  }

  void _onUpdateMarketingUpdates(
      UpdateMarketingUpdates event,
      Emitter<NotificationPreferencesState> emit,
      ) {
    if (state is NotificationPreferencesLoaded) {
      final currentState = state as NotificationPreferencesLoaded;

      final updatedMarketingPreference = MarketingPreference(
        disableAll: !event.value,
        disableEmail: currentState.userSettings.marketingPreference?.disableEmail,
        disableTextMsg: currentState.userSettings.marketingPreference?.disableTextMsg,
      );

      final updatedUserSettings = UserSettings(
        userPreference: currentState.userSettings.userPreference,
        marketingPreference: updatedMarketingPreference,
        scheduleProfile: currentState.userSettings.scheduleProfile,
      );

      emit(currentState.copyWith(
        userSettings: updatedUserSettings,
        marketingUpdates: event.value,
        isDirty: true,
      ));
    }
  }

  void _onUpdateEmailNotifications(
      UpdateEmailNotifications event,
      Emitter<NotificationPreferencesState> emit,
      ) {
    if (state is NotificationPreferencesLoaded) {
      final currentState = state as NotificationPreferencesLoaded;

      final updatedUserPreference = UserPreference(
        notificationEnabled: currentState.userSettings.userPreference?.notificationEnabled,
        notificationEnabledMs: currentState.userSettings.userPreference?.notificationEnabledMs ?? 0,
        emailNotificationEnabled: event.value,
        textNotificationEnabled: currentState.userSettings.userPreference?.textNotificationEnabled,
      );

      final updatedUserSettings = UserSettings(
        userPreference: updatedUserPreference,
        marketingPreference: currentState.userSettings.marketingPreference,
        scheduleProfile: currentState.userSettings.scheduleProfile,
      );

      emit(currentState.copyWith(
        userSettings: updatedUserSettings,
        emailNotifications: event.value,
        isDirty: true,
      ));
    }
  }

  Future<void> _onSaveNotificationPreferences(
      SaveNotificationPreferences event,
      Emitter<NotificationPreferencesState> emit,
      ) async {
    if (state is NotificationPreferencesLoaded) {
      final currentState = state as NotificationPreferencesLoaded;
      try {
        await settingsApi.updateUserSettings(currentState.userSettings);
        emit(NotificationPreferencesSaved());
        emit(currentState.copyWith(isDirty: false));
      } catch (e) {
        emit(NotificationPreferencesError(e.toString()));
        emit(currentState);
      }
    }
  }
}
