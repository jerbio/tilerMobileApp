
part of 'tile_preferences_bloc.dart';

abstract class TilePreferencesState {}

class PreferencesInitial extends TilePreferencesState {}
class PreferencesLoading extends TilePreferencesState {}
class PreferencesLoaded extends TilePreferencesState {
  final RestrictionProfile? workProfile;
  final RestrictionProfile? personalProfile;

  bool get isProceedReady => true;

  PreferencesLoaded({
    required this.workProfile,
    required this.personalProfile,
  });
}
class PreferencesError extends TilePreferencesState {
  final String message;
  PreferencesError(this.message);
}
class UpdateSuccess extends TilePreferencesState {}