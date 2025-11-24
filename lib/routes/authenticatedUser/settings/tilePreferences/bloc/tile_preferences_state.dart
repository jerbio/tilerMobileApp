
part of 'tile_preferences_bloc.dart';

abstract class TilePreferencesState {}

class PreferencesInitial extends TilePreferencesState {}
class PreferencesLoading extends TilePreferencesState {}
class PreferencesLoaded extends TilePreferencesState {
  final RestrictionProfile? workProfile;
  final RestrictionProfile? personalProfile;
  final StartOfDay? endOfDay;
  final UserSettings? userSettings;
  final String? localTimeZone;
  final bool hasChanges;

  PreferencesLoaded({
    required this.workProfile,
    required this.personalProfile,
    required this.endOfDay,
    required this.userSettings,
    required this.localTimeZone,
    this.hasChanges = false,
  });
}
class PreferencesError extends TilePreferencesState {
  final String message;
  PreferencesError(this.message);
}
class UpdateSuccess extends TilePreferencesState {}
