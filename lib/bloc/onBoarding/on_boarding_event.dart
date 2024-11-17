part of 'on_boarding_bloc.dart';


abstract class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => [];
}

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


class SkipOnboardingEvent extends OnboardingEvent {}

class OnboardingRequestedEvent extends OnboardingEvent{}