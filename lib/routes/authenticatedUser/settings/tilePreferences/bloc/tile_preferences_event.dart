part of 'tile_preferences_bloc.dart';

@immutable
abstract class TilePreferencesEvent {}

class FetchProfiles extends TilePreferencesEvent {}
class UpdateWorkProfile extends TilePreferencesEvent {
  final RestrictionProfile? profile;
  UpdateWorkProfile(this.profile);
}
class UpdatePersonalProfile extends TilePreferencesEvent {
  final RestrictionProfile? profile;
  UpdatePersonalProfile(this.profile);
}
class ProceedUpdate extends TilePreferencesEvent {}
