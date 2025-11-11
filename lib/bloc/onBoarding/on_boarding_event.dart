part of 'on_boarding_bloc.dart';


abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

class FetchOnboardingDataEvent extends OnboardingEvent {}

class NextPageEvent extends OnboardingEvent {}

class PreviousPageEvent extends OnboardingEvent {}


class WakeUpTimeUpdated extends OnboardingEvent {
  final TimeOfDay? wakeUpTime;
  WakeUpTimeUpdated(this.wakeUpTime);
  @override
  List<Object?> get props => [wakeUpTime];
}

class StartingWorkdayTimeUpdated extends OnboardingEvent {
  final TimeOfDay? startingWorkDayTime;
  StartingWorkdayTimeUpdated(this.startingWorkDayTime);
  @override
  List<Object?> get props => [startingWorkDayTime];
}

class PreferredDaySectionUpdated extends OnboardingEvent {
  final String? preferredDaySection;
  PreferredDaySectionUpdated(this.preferredDaySection);
  @override
  List<Object?> get props => [preferredDaySection];
}

class AddressTextChanged extends OnboardingEvent {
  final String addressText;
  AddressTextChanged(this.addressText);
  @override
  List<Object?> get props => [addressText];
}

class LocationSelected extends OnboardingEvent {
  final Location location;
  LocationSelected(this.location);
  @override
  List<Object?> get props => [location];
}

class GetTimeAndLocationEvent extends OnboardingEvent{
  final bool approved;
  GetTimeAndLocationEvent( this.approved);

  @override
  List<Object> get props => [approved];
}

class SetWorkProfileEvent extends OnboardingEvent{
  final Map workMap;
  SetWorkProfileEvent( this.workMap);

  @override
  List<Object?> get props => [workMap];
}

class AddRecurringTaskEvent extends OnboardingEvent {
  final String taskName;
  AddRecurringTaskEvent(this.taskName);
  @override
  List<Object?> get props => [taskName];
}

class RemoveRecurringTaskEvent extends OnboardingEvent {
  final int index;
  RemoveRecurringTaskEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class SetPersonalProfileEvent extends OnboardingEvent{
  final Map personalMap;
  SetPersonalProfileEvent( this.personalMap);

  @override
  List<Object?> get props => [personalMap];
}

class SelectUsageEvent extends OnboardingEvent {
  final String usageItem;
  SelectUsageEvent(this.usageItem);
  @override
  List<Object?> get props => [usageItem];
}

class SelectProfessionEvent extends OnboardingEvent {
  final String profession;
  final bool isCustom;
  SelectProfessionEvent( {required this.profession,this.isCustom = false});
  @override
  List<Object?> get props => [profession];
}
class AddTileSuggestionEvent extends OnboardingEvent {
  final TileSuggestion tile;
  AddTileSuggestionEvent(this.tile);
  @override
  List<Object?> get props => [tile];
}

class RemoveTileSuggestionEvent extends OnboardingEvent {
  final int index;
  RemoveTileSuggestionEvent(this.index);
  @override
  List<Object?> get props => [index];
}
class FetchTileSuggestionsEvent extends OnboardingEvent {
}
class SkipOnboardingEvent extends OnboardingEvent {}

class OnboardingRequestedEvent extends OnboardingEvent{}
