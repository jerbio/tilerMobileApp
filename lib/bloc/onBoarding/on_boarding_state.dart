part of 'on_boarding_bloc.dart';

enum OnboardingStep {
  initial,
  dataLoaded,
  pageChanged,
  wakeUpTimeChanged,
  startingWorkDayChanged,
  preferredDaySectionChanged,
  preferredWorkLocationUpdated,
  getTimeAndLocation,
  setPersonalProfile,
  setWorkProfile,
  loading,
  suggestionLoading,
  suggestionRefreshing,
  suggestionLoaded,
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
  final Location? selectedPreferredWorkLocation;
  final String? userLongitude;
  final String? userLatitude;
  final int? timeZoneOffset;
  final String? timeZone;
  final String? addressText;
  final String? profession;
  final bool isCustomProfession;
  final RestrictionProfile? workProfile;
  final RestrictionProfile? personalProfile;
  final List<RecurringTask>? recurringTasks;
  final List<String>?  usage;
  final List<TileSuggestion?>? suggestedTiles;
  final List<TileSuggestion>? selectedSuggestionTiles;
  final Map<int, TileSuggestion>? removedSuggestedTilesMap;
  final String? error;

  const OnboardingState(  {
    this.step = OnboardingStep.initial,
    this.pageNumber,
    this.wakeUpTime,
    this.startingWorkDayTime,
    this.preferredDaySection,
    this.selectedPreferredWorkLocation,
    this.userLongitude,
    this.userLatitude,
    this.timeZoneOffset,
    this.timeZone,
    this.workProfile,
    this.personalProfile,
    this.addressText,
    this.profession,
    this.isCustomProfession = false,
    this.error,
    this.recurringTasks,
    this.suggestedTiles,
    this.selectedSuggestionTiles,
    this.removedSuggestedTilesMap,
    this.usage
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    int? pageNumber,
    TimeOfDay? wakeUpTime,
    TimeOfDay? startingWorkDayTime,
    String? preferredDaySection,
    Location? selectedPreferredWorkLocation,
    String? userLongitude,
    String?userLatitude,
    int? timeZoneOffset,
    String? timeZone,
    String? addressText,
    String? profession,
    bool? isCustomProfession,
    RestrictionProfile? workProfile,
    RestrictionProfile? personalProfile,
    List<RecurringTask>? recurringTasks,
    List<String>?  usage,
    List<TileSuggestion?>? suggestedTiles,
    List<TileSuggestion>? selectedSuggestionTiles,
    Map<int, TileSuggestion>? removedSuggestedTilesMap,
    String? error,
  }) {
    return OnboardingState(
      step: step ?? this.step,
      pageNumber: pageNumber ?? this.pageNumber,
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      startingWorkDayTime: startingWorkDayTime ?? this.startingWorkDayTime,
      preferredDaySection: preferredDaySection ?? this.preferredDaySection,
      selectedPreferredWorkLocation: selectedPreferredWorkLocation ?? this.selectedPreferredWorkLocation,
      userLongitude: userLongitude ?? this.userLongitude ,
      userLatitude: userLatitude ?? this.userLatitude,
      timeZoneOffset: timeZoneOffset ?? this.timeZoneOffset,
      timeZone: timeZone ?? this.timeZone ,
      addressText: addressText ?? this.addressText,
      profession:  profession ?? this.profession,
      isCustomProfession: isCustomProfession ?? this.isCustomProfession,
      workProfile: workProfile ?? this.workProfile,
      personalProfile: personalProfile ?? this.personalProfile,
      recurringTasks: recurringTasks ?? this.recurringTasks,
      usage:  usage ?? this.usage,
      suggestedTiles: suggestedTiles ?? this.suggestedTiles,
      selectedSuggestionTiles: selectedSuggestionTiles?? this.selectedSuggestionTiles,
      removedSuggestedTilesMap: removedSuggestedTilesMap ?? this.removedSuggestedTilesMap,
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
    selectedPreferredWorkLocation,
    userLongitude,
    userLatitude,
    timeZoneOffset,
    timeZone,
    workProfile,
    personalProfile,
    addressText,
    profession,
    isCustomProfession,
    recurringTasks,
    suggestedTiles,
    selectedSuggestionTiles,
    removedSuggestedTilesMap,
    usage,
    error,
  ];
}
