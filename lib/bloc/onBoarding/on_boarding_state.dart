part of 'on_boarding_bloc.dart';

enum OnboardingStep {
  initial,
  pageChanged,
  wakeUpTimeChanged,
  startingWorkDayChanged,
  preferredDaySectionChanged,
  locationUpdated,
  loading,
  error,
  submitted,
  skipped,
}

class OnboardingState extends Equatable {
  final OnboardingStep step;
  final int? pageNumber;
  final TimeOfDay? wakeUpTime;
  final TimeOfDay? startingWorkDayTime;
  final String? preferredDaySection;
  final Location? selectedLocation;
  final String? addressText;
  final bool isLocationVerified;
  final String? error;

  const OnboardingState({
    this.step = OnboardingStep.initial,
    this.pageNumber,
    this.wakeUpTime,
    this.startingWorkDayTime,
    this.preferredDaySection,
    this.selectedLocation,
    this.addressText,
    this.isLocationVerified = false,
    this.error,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    int? pageNumber,
    TimeOfDay? wakeUpTime,
    TimeOfDay? startingWorkDayTime,
    String? preferredDaySection,
    Location? selectedLocation,
    String? addressText,
    bool? isLocationVerified,
    String? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      pageNumber: pageNumber ?? this.pageNumber,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      startingWorkDayTime: startingWorkDayTime ?? this.startingWorkDayTime,
      preferredDaySection: preferredDaySection ?? this.preferredDaySection,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      addressText: addressText ?? this.addressText,
      isLocationVerified: isLocationVerified ?? this.isLocationVerified,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    step,
    pageNumber,
    wakeUpTime,
    startingWorkDayTime,
    preferredDaySection,
    selectedLocation,
    addressText,
    isLocationVerified,
    error,
  ];
}
