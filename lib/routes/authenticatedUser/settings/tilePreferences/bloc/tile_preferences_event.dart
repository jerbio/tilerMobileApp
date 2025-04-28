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
class UpdateEndOfDay extends TilePreferencesEvent {
  final StartOfDay? endOfDay;
  UpdateEndOfDay(this.endOfDay);
}

class UpdateSleepDuration extends TilePreferencesEvent {
  final int? durationMs;
  UpdateSleepDuration(this.durationMs);
}

class UpdateTravelMedium extends TilePreferencesEvent {
  final TravelMedium travelMedium;
  UpdateTravelMedium(this.travelMedium);
}
class ProceedUpdate extends TilePreferencesEvent {}
