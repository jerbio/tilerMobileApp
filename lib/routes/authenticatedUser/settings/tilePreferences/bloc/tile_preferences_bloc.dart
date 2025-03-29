import 'package:bloc/bloc.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:meta/meta.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
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
    on<ProceedUpdate>(_proceedUpdate);
    FlutterTimezone.getLocalTimezone().then((value) {
      localTimeZone = value;
    });
  }

  Future<void> _fetchProfiles(FetchProfiles event, Emitter<TilePreferencesState> emit) async {
    emit(PreferencesLoading());
    try {
      final profiles = await settingsApi.getUserRestrictionProfile();
      emit(PreferencesLoaded(
        workProfile: profiles['work'],
        personalProfile: profiles['personal'],
      ));
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }

  void _updateWork(UpdateWorkProfile event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      emit(PreferencesLoaded(
        workProfile: event.profile,
        personalProfile: current.personalProfile,
      ));
    }
  }

  void _updatePersonal(UpdatePersonalProfile event, Emitter<TilePreferencesState> emit) {
    if (state is PreferencesLoaded) {
      final current = state as PreferencesLoaded;
      emit(PreferencesLoaded(
        workProfile: current.workProfile,
        personalProfile: event.profile,
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
      emit(UpdateSuccess());
    } catch (e) {
      emit(PreferencesError(e.toString()));
    }
  }
}
