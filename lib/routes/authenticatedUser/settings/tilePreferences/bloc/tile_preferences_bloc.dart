import 'package:bloc/bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:meta/meta.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/scheduleProfile.dart';
import 'package:tiler_app/data/startOfDay.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/services/api/settingsApi.dart';

part 'tile_preferences_event.dart';
part 'tile_preferences_state.dart';

class TilePreferencesBloc extends Bloc<TilePreferencesEvent, TilePreferencesState> {
  final SettingsApi settingsApi;
  String? localTimeZone;

  TilePreferencesBloc({required this.settingsApi}) : super(PreferencesInitial()) {
    on<FetchProfiles>(_fetchProfiles);
    on<UpdateWorkProfile>(_updateWork);
    on<UpdatePersonalProfile>(_updatePersonal);
    on<UpdateEndOfDay>(_updateEndOfDay);
    on<UpdateSleepDuration>(_updateSleepDuration);
    on<UpdateTravelMedium>(_updateTravelMedium);
    on<ProceedUpdate>(_proceedUpdate);
    FlutterTimezone.getLocalTimezone().then((value) {
      localTimeZone = value;
    });
  }

  Future<void> _fetchProfiles(FetchProfiles event, Emitter<TilePreferencesState> emit) async {
    emit(PreferencesLoading());
    try {
      final profiles = await settingsApi.getUserRestrictionProfile();
      final userSettings = await settingsApi.getUserSettings();
      final endOfDay = await settingsApi.getUserStartOfDay();
      emit(PreferencesLoaded(
        workProfile: profiles['work'],
        personalProfile: profiles['personal'],
        userSettings: userSettings,
        endOfDay: endOfDay,
        localTimeZone: localTimeZone,
      ));
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }

  void _updateEndOfDay(UpdateEndOfDay event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      emit(PreferencesLoaded(
        workProfile: current.workProfile,
        personalProfile: current.personalProfile,
        endOfDay: event.endOfDay,
        userSettings: current.userSettings,
        localTimeZone: current.localTimeZone,
        hasChanges: true,
      ));
    }
  }

  void _updateSleepDuration(UpdateSleepDuration event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      final updatedUserSettings = current.userSettings;

      if (updatedUserSettings != null) {
        if (updatedUserSettings.scheduleProfile == null) {
          final scheduleProfile = ScheduleProfile.fromJson({});
          scheduleProfile.sleepDuration = event.durationMs;
          final newUserSettings = UserSettings(
            userPreference: updatedUserSettings.userPreference,
            marketingPreference: updatedUserSettings.marketingPreference,
            scheduleProfile: scheduleProfile,
          );

          emit(PreferencesLoaded(
            workProfile: current.workProfile,
            personalProfile: current.personalProfile,
            endOfDay: current.endOfDay,
            userSettings: newUserSettings,
            localTimeZone: current.localTimeZone,
            hasChanges: true
          ));
        } else {
          updatedUserSettings.scheduleProfile!.sleepDuration = event.durationMs;

          emit(PreferencesLoaded(
            workProfile: current.workProfile,
            personalProfile: current.personalProfile,
            endOfDay: current.endOfDay,
            userSettings: updatedUserSettings,
            localTimeZone: current.localTimeZone,
            hasChanges: true
          ));
        }
      }
    }
  }

  void _updateTravelMedium(UpdateTravelMedium event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      final updatedUserSettings = current.userSettings;

      if (updatedUserSettings != null) {
        if (updatedUserSettings.scheduleProfile == null) {
          final scheduleProfile = ScheduleProfile.fromJson({});
          scheduleProfile.travelMedium = event.travelMedium;

          final newUserSettings = UserSettings(
            userPreference: updatedUserSettings.userPreference,
            marketingPreference: updatedUserSettings.marketingPreference,
            scheduleProfile: scheduleProfile,
          );

          emit(PreferencesLoaded(
            workProfile: current.workProfile,
            personalProfile: current.personalProfile,
            endOfDay: current.endOfDay,
            userSettings: newUserSettings,
            localTimeZone: current.localTimeZone,
            hasChanges: true
          ));
        } else {
          updatedUserSettings.scheduleProfile!.travelMedium = event.travelMedium;

          emit(PreferencesLoaded(
              workProfile: current.workProfile,
              personalProfile: current.personalProfile,
              endOfDay: current.endOfDay,
              userSettings: updatedUserSettings,
              localTimeZone: current.localTimeZone,
              hasChanges: true
          ));
        }
      }
    }
  }
  void _updateWork(UpdateWorkProfile event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      emit(PreferencesLoaded(
          workProfile: event.profile,
          personalProfile: current.personalProfile,
          userSettings: current.userSettings,
          endOfDay: current.endOfDay,
          localTimeZone: current.localTimeZone,
          hasChanges: true
      ));
    }
  }

  void _updatePersonal(UpdatePersonalProfile event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      emit(PreferencesLoaded(
          workProfile: current.workProfile,
          personalProfile: event.profile,
          userSettings: current.userSettings,
          endOfDay: current.endOfDay,
          localTimeZone: current.localTimeZone,
          hasChanges: true
      ));
    }
  }

  Future<void> _proceedUpdate(ProceedUpdate event, Emitter<TilePreferencesState> emit) async {
    if (state is! PreferencesLoaded) return;
    final current = state as PreferencesLoaded;
    try {
      if (current.workProfile != null) {
        await settingsApi.updateRestrictionProfile(
            current.workProfile!,
            restrictionProfileType: 'work'
        );
      }
      if (current.personalProfile != null) {
        await settingsApi.updateRestrictionProfile(
            current.personalProfile!,
            restrictionProfileType: 'personal'
        );
      }
      if (current.userSettings != null) {
        await settingsApi.updateUserSettings(current.userSettings!);
      }
      if (current.endOfDay != null) {
        if (current.localTimeZone != null) {
          current.endOfDay!.timeZone = current.localTimeZone!;
        }
        await settingsApi.updateStartOfDay(current.endOfDay!);
      }

      emit(UpdateSuccess());

    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }
}
