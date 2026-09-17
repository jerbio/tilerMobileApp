import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/data/RecurringTask.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/onBoarding.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionDay.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/tileSuggestion.dart';
import 'package:tiler_app/services/api/onBoardingApi.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/services/localizationService.dart';
import 'package:tiler_app/services/onBoardingHelper.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/util.dart';
import 'package:timezone/data/latest.dart' as tz;

part 'on_boarding_event.dart';
part 'on_boarding_state.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnBoardingApi onBoardingApi;
  final SettingsApi settingsApi;

  /// Number of pages in the essentials onboarding flow (stage 3.1).
  static const numberOfPages = 2;

  /// The profession page of the essentials flow. Progression validation is
  /// keyed to this page's role and the profession state rather than a magic
  /// page number carried over from the legacy 10-page onboarding.
  static const professionPageIndex = 0;
  OnboardingBloc({required this.onBoardingApi, required this.settingsApi})
      : super(OnboardingState(
          step: OnboardingStep.initial,
          pageNumber: 0,
          preferredDaySection: "Morning",
          wakeUpTime: TimeOfDay(hour: 7, minute: 0),
          startingWorkDayTime: TimeOfDay(hour: 9, minute: 0),
          profession: 'Medical Professional',
        )) {
    on<FetchOnboardingDataEvent>(_onFetchOnboardingData);
    on<NextPageEvent>(_onNextPageChanged);
    on<PreviousPageEvent>(_onPreviousPageEvent);
    on<WakeUpTimeUpdated>(_onWakeUpTimeUpdated);
    on<StartingWorkdayTimeUpdated>(_onStartingWorkDayUpdated);
    on<PreferredDaySectionUpdated>(_onPreferredDaySectionUpdated);
    on<AddressTextChanged>(_onAddressTextChanged);
    on<LocationSelected>(_onLocationSelected);
    on<GetTimeAndLocationEvent>(_onGetTimeAndLocationEvent);
    on<SetPersonalProfileEvent>(_onSetPersonalProfileEvent);
    on<SetWorkProfileEvent>(_onSetWorkProfileEvent);
    on<SkipOnboardingEvent>(_onSkipOnboarding);
    on<OnboardingRequestedEvent>(_onOnboardingRequestedEvent);
    on<AddRecurringTaskEvent>(_onAddRecurringTask);
    on<RemoveRecurringTaskEvent>(_onRemoveRecurringTask);
    on<UpdateRecurringTaskFrequencyEvent>(_onUpdateRecurringTaskFrequency);
    on<SelectUsageEvent>(_onSelectUsageEvent);
    on<SelectProfessionEvent>(_onSelectProfession);
    on<AddTileSuggestionEvent>(_onAddTileSuggestion);
    on<RemoveTileSuggestionEvent>(_onRemoveTileSuggestion);
    on<UpdateTileSuggestionRecurrenceEvent>(_onUpdateTileSuggestionRecurrence);
    on<FetchTileSuggestionsEvent>(_onFetchTileSuggestions);
  }

  RestrictionProfile _createDefaultWorkProfile() {
    List<RestrictionDay?> days = List.filled(7, null);
    for (int i = 1; i <= 5; i++) {
      days[i] = RestrictionDay(
          weekday: i,
          restrictionTimeLine: RestrictionTimeLine(
              start: TimeOfDay(hour: 8, minute: 0),
              duration: Duration(hours: 9),
              weekDay: i));
    }
    return RestrictionProfile(daySelection: days);
  }

  void _onFetchOnboardingData(
      FetchOnboardingDataEvent event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(step: OnboardingStep.loading));

    try {
      tz.initializeTimeZones();

      OnboardingContent? onboardingData =
          await onBoardingApi.fetchOnboardingData();
      Map<String, RestrictionProfile?> profiles =
          await settingsApi.getUserRestrictionProfile();
      if (onboardingData != null) {
        emit(state.copyWith(
            step: OnboardingStep.dataLoaded,
            wakeUpTime: _parseTimeString(onboardingData.personalHoursStart) ??
                state.wakeUpTime,
            startingWorkDayTime:
                _parseTimeString(onboardingData.workHoursStart) ??
                    state.startingWorkDayTime,
            selectedPreferredWorkLocation: onboardingData.workLocation,
            addressText: onboardingData.workLocation?.address,
            preferredDaySection:
                onboardingData.preferredDaySections?.isNotEmpty == true
                    ? onboardingData.preferredDaySections!.first
                    : state.preferredDaySection,
            workProfile: profiles['work'] ?? _createDefaultWorkProfile(),
            personalProfile: profiles['personal'],
            recurringTasks: onboardingData.recurringTasks,
            usage: onboardingData.usage,
            selectedSuggestionTiles: onboardingData.tileSuggestions));
      } else {
        emit(state.copyWith(
            step: OnboardingStep.dataLoaded,
            workProfile: profiles['work'] ?? _createDefaultWorkProfile(),
            personalProfile: profiles['personal']));
      }
    } catch (e) {
      emit(state.copyWith(step: OnboardingStep.error, error: e.toString()));
    }
  }

  TimeOfDay? _parseTimeString(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    final regex = RegExp(r'(\d{1,2}):(\d{2})(Am|Pm)', caseSensitive: false);
    final match = regex.firstMatch(timeString);

    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      String period = match.group(3)!.toLowerCase();

      if (period == 'pm' && hour != 12) hour += 12;
      if (period == 'am' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  void _onNextPageChanged(
      NextPageEvent event, Emitter<OnboardingState> emit) async {
    // Stage 3.3: the terminal skipped state has no page (pageNumber is
    // null). Page navigation is meaningless after Skip, so treat the
    // event as a guarded no-op instead of dereferencing pageNumber.
    if (state.pageNumber == null || state.step == OnboardingStep.skipped) {
      return;
    }
    if (!_canProceedToNextPage(state)) {
      emit(state.copyWith(
          step: OnboardingStep.error,
          error: LocalizationService.instance.translations.enter3chars));
      return;
    }
    if (state.step == OnboardingStep.suggestionLoading ||
        state.step == OnboardingStep.suggestionRefreshing) return;
    if (state.pageNumber! + 1 < numberOfPages) {
      emit(state.copyWith(
        pageNumber: state.pageNumber! + 1,
        step: OnboardingStep.pageChanged,
      ));
    } else {
      // Last essentials page: submit.
      add(OnboardingRequestedEvent());
    }
  }

  void _onPreviousPageEvent(
      PreviousPageEvent event, Emitter<OnboardingState> emit) {
    // Stage 3.3: same terminal-state guard as _onNextPageChanged.
    if (state.pageNumber == null || state.step == OnboardingStep.skipped) {
      return;
    }
    if (state.step == OnboardingStep.suggestionLoading ||
        state.step == OnboardingStep.suggestionRefreshing) return;
    if (state.pageNumber! > 0) {
      emit(state.copyWith(
        step: OnboardingStep.pageChanged,
        pageNumber: state.pageNumber! - 1,
      ));
    }
  }

  void _onWakeUpTimeUpdated(
      WakeUpTimeUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
        step: OnboardingStep.wakeUpTimeChanged, wakeUpTime: event.wakeUpTime));
  }

  void _onStartingWorkDayUpdated(
      StartingWorkdayTimeUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.startingWorkDayChanged,
      startingWorkDayTime: event.startingWorkDayTime,
    ));
  }

  void _onPreferredDaySectionUpdated(
      PreferredDaySectionUpdated event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.preferredDaySectionChanged,
      preferredDaySection: event.preferredDaySection,
    ));
  }

  void _onSelectProfession(
      SelectProfessionEvent event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
        profession: event.profession, isCustomProfession: event.isCustom));
  }

  void _onAddRecurringTask(
      AddRecurringTaskEvent event, Emitter<OnboardingState> emit) {
    final task = RecurringTask(
      name: event.taskName,
      frequency: 'none',
      durationInMs: 1800000,
    );

    final updated = List<RecurringTask>.from(state.recurringTasks ?? [])
      ..add(task);
    emit(state.copyWith(recurringTasks: updated));
  }

  void _onRemoveRecurringTask(
      RemoveRecurringTaskEvent event, Emitter<OnboardingState> emit) {
    final updated = List<RecurringTask>.from(state.recurringTasks ?? [])
      ..removeAt(event.index);
    emit(state.copyWith(recurringTasks: updated));
  }

  void _onUpdateRecurringTaskFrequency(
      UpdateRecurringTaskFrequencyEvent event, Emitter<OnboardingState> emit) {
    final updated = List<RecurringTask>.from(state.recurringTasks ?? []);
    if (event.index < updated.length) {
      final task = updated[event.index];
      updated[event.index] = RecurringTask(
        name: task.name,
        frequency: event.frequency,
        durationInMs: task.durationInMs,
      );
      emit(state.copyWith(recurringTasks: updated));
    }
  }

  void _onAddressTextChanged(
      AddressTextChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.preferredWorkLocationUpdated,
      addressText: event.addressText,
      selectedPreferredWorkLocation: null,
    ));
  }

  void _onLocationSelected(
      LocationSelected event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.preferredWorkLocationUpdated,
      selectedPreferredWorkLocation: event.location,
      addressText: event.location.address,
    ));
  }

  /// Device-location consent (stage 3.1). Invoked ONLY by the in-page button
  /// on the Location page — swiping/Next must never trigger the permission
  /// flow. Records coordinates and timezone in state without advancing
  /// navigation; declining leaves everything untouched because the primary
  /// location is optional.
  void _onGetTimeAndLocationEvent(
      GetTimeAndLocationEvent event, Emitter<OnboardingState> emit) async {
    try {
      if (!event.approved) {
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openLocationSettings();
        return;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        // User declined; the primary location stays optional.
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      int timeZoneOffset = Utility.getTimeZoneOffset();
      String timeZone = await FlutterTimezone.getLocalTimezone();
      emit(state.copyWith(
        step: OnboardingStep.getTimeAndLocation,
        userLatitude: position.latitude.toString(),
        userLongitude: position.longitude.toString(),
        timeZoneOffset: timeZoneOffset,
        timeZone: timeZone,
      ));
    } catch (e) {
      emit(state.copyWith(step: OnboardingStep.error, error: e.toString()));
    }
  }

  void _onAddTileSuggestion(
      AddTileSuggestionEvent event, Emitter<OnboardingState> emit) {
    final updated =
        List<TileSuggestion>.from(state.selectedSuggestionTiles ?? [])
          ..add(event.tile);
    Map<int, TileSuggestion> updatedMap = state.removedSuggestedTilesMap ?? {};
    List<TileSuggestion?> updatedSuggested =
        List<TileSuggestion?>.from(state.suggestedTiles ?? []);
    if (event.isAddedByPill) {
      final index = state.suggestedTiles
              ?.indexWhere((t) => t?.tileName == event.tile.tileName) ??
          -1;
      if (index != -1) {
        updatedMap[index] = event.tile;
        updatedSuggested[index] = null;
      }
    }

    emit(state.copyWith(
        selectedSuggestionTiles: updated,
        suggestedTiles: updatedSuggested,
        removedSuggestedTilesMap: updatedMap));
  }

  void _onRemoveTileSuggestion(
      RemoveTileSuggestionEvent event, Emitter<OnboardingState> emit) {
    final removedTile = state.selectedSuggestionTiles![event.index];
    final updated =
        List<TileSuggestion>.from(state.selectedSuggestionTiles ?? [])
          ..removeAt(event.index);
    List<TileSuggestion?> updatedSuggested =
        List<TileSuggestion?>.from(state.suggestedTiles ?? []);

    state.removedSuggestedTilesMap?.forEach((key, value) {
      if (value.tileName == removedTile.tileName) {
        updatedSuggested[key] = removedTile;
      }
    });
    emit(state.copyWith(
        selectedSuggestionTiles: updated, suggestedTiles: updatedSuggested));
  }

  void _onUpdateTileSuggestionRecurrence(
      UpdateTileSuggestionRecurrenceEvent event,
      Emitter<OnboardingState> emit) {
    final updated =
        List<TileSuggestion>.from(state.selectedSuggestionTiles ?? []);
    if (event.index < updated.length) {
      final tile = updated[event.index];
      updated[event.index] = TileSuggestion(
        id: tile.id,
        tileName: tile.tileName,
        description: tile.description,
        category: tile.category,
        durationInMs: tile.durationInMs,
        repetitionFrequency: tile.repetitionFrequency,
        priority: tile.priority,
        estimatedDurationMinutes: tile.estimatedDurationMinutes,
        recurrencePattern: event.recurrence,
        tags: tile.tags,
        locationAddress: tile.locationAddress,
        locationDescription: tile.locationDescription,
        isActive: tile.isActive,
      );
      emit(state.copyWith(selectedSuggestionTiles: updated));
    }
  }

  void _onSkipOnboarding(
      SkipOnboardingEvent event, Emitter<OnboardingState> emit) async {
    // Stage 4.1: the essentials done flag is the gate's canonical flag;
    // the legacy skip flag is still written for readers that predate the
    // essentials flow.
    await OnBoardingSharedPreferencesHelper.setSkipOnboarding(true);
    await OnBoardingSharedPreferencesHelper.setEssentialsOnboardingDone(true);
    emit(OnboardingState(step: OnboardingStep.skipped));
  }

  void _onSetPersonalProfileEvent(
      SetPersonalProfileEvent event, Emitter<OnboardingState> emit) async {
    RestrictionProfile? personalProfile =
        _processRouteProfile(event.personalMap, state.personalProfile);
    emit(
      state.copyWith(personalProfile: personalProfile),
    );
  }

  void _onSetWorkProfileEvent(
      SetWorkProfileEvent event, Emitter<OnboardingState> emit) async {
    RestrictionProfile? workProfile =
        _processRouteProfile(event.workMap, state.workProfile);
    emit(
      state.copyWith(workProfile: workProfile),
    );
  }

  void _onSelectUsageEvent(
      SelectUsageEvent event, Emitter<OnboardingState> emit) {
    List<String> updatedUsage = List<String>.from(state.usage ?? []);

    if (updatedUsage.contains(event.usageItem)) {
      updatedUsage.remove(event.usageItem);
    } else {
      updatedUsage.add(event.usageItem);
    }

    emit(state.copyWith(usage: updatedUsage));
  }

  void _onOnboardingRequestedEvent(
      OnboardingRequestedEvent event, Emitter<OnboardingState> emit) async {
    // Stage 3.4: wait for the in-flight text-edit debounce (same as
    // before) so the latest entered value is what gets submitted.
    await Future.delayed(
        const Duration(milliseconds: Constants.onTextChangeDelayInMs));
    emit(state.copyWith(
      step: OnboardingStep.loading,
    ));

    // Essentials submit payload (stage 3.4): profession + primary
    // location, plus the optional device coords / timezone captured by
    // the in-page consent button. The legacy payload fields (hours, day
    // sections, recurring tasks, suggestion tiles, usage) are no longer
    // collected by the two-page flow and are not sent.
    OnboardingContent onboardingContent = OnboardingContent(
      personalHoursStart: null,
      workHoursStart: null,
      workLocation:
          state.selectedPreferredWorkLocation ?? Location.fromDefault(),
      userLongitude: state.userLongitude,
      userLatitude: state.userLatitude,
      timeZoneOffset: state.timeZoneOffset,
      timeZone: state.timeZone,
      preferredDaySections: null,
      recurringTasks: null,
      tileSuggestions: null,
      usage: null,
      profession: state.profession,
    );

    try {
      await onBoardingApi.sendOnboardingData(onboardingContent);
      // Stage 3.4: persist the local done flag only after a successful
      // submit; the launch gate reads it on the next start (design
      // section 3.5).
      await OnBoardingSharedPreferencesHelper.setEssentialsOnboardingDone(true);
      emit(OnboardingState(step: OnboardingStep.submitted));
    } catch (e) {
      AnalysticsSignal.send('ESSENTIALS_ONBOARDING_SUBMIT_FAILED');
      // Failed submit: stay in the flow. The view's error branch shows
      // the existing toast and Skip remains available. Restriction
      // profile persistence is no longer part of the onboarding submit
      // (Settings owns it; design section 3.2).
      final String message =
          e is TilerError ? (e.Message ?? e.toString()) : e.toString();
      emit(state.copyWith(
        step: OnboardingStep.error,
        error: message,
      ));
    }
  }

  RestrictionProfile? _processRouteProfile(
      Map restrictionParams, RestrictionProfile? profile) {
    if (restrictionParams.containsKey('routeRestrictionProfile') ||
        restrictionParams.containsKey('restrictionProfile')) {
      RestrictionProfile? updatedProfile =
          restrictionParams['routeRestrictionProfile'] as RestrictionProfile?;

      if (updatedProfile != null && profile != null) {
        updatedProfile.id = profile.id;
      }

      if (profile != null &&
          (updatedProfile == null ||
              (restrictionParams.containsKey('isAnyTime') &&
                  restrictionParams['isAnyTime'] != null))) {
        profile.isEnabled = !restrictionParams['isAnyTime'];
        updatedProfile = profile;
      }

      return updatedProfile;
    }
    return profile;
  }

  void _onFetchTileSuggestions(
      FetchTileSuggestionsEvent event, Emitter<OnboardingState> emit) async {
    emit(state.copyWith(
        suggestedTiles: [],
        step: event.isRefresh
            ? OnboardingStep.suggestionRefreshing
            : OnboardingStep.suggestionLoading));
    try {
      if (state.profession!.isNotEmpty && state.profession != null) {
        List<TileSuggestion> tiles =
            await onBoardingApi.generateSuggestionTiles(
          profession: state.profession!,
          description: state.isCustomProfession
              ? "give me a variant option of tasks to make an exciting balanced schedule"
              : "",
        );

        if (state.selectedSuggestionTiles != null &&
            state.selectedSuggestionTiles!.isNotEmpty) {
          tiles = tiles
              .where((tile) => !state.selectedSuggestionTiles!.any((selected) =>
                  selected.tileName?.toLowerCase() ==
                  tile.tileName?.toLowerCase()))
              .toList();
        }

        emit(state.copyWith(
            suggestedTiles: tiles,
            step: OnboardingStep.suggestionLoaded,
            removedSuggestedTilesMap: {}));
      }
    } catch (e) {
      emit(state
          .copyWith(suggestedTiles: [], step: OnboardingStep.suggestionLoaded));
    }
  }

  bool _canProceedToNextPage(OnboardingState state) {
    // Keyed to the profession page's role ([professionPageIndex]) and the
    // profession state itself rather than a magic page number from the
    // legacy 10-page flow.
    if (state.pageNumber != professionPageIndex) return true;
    if (state.isCustomProfession) {
      return state.profession != null &&
          state.profession != 'Other' &&
          state.profession!.trim().length >= 3;
    }
    return state.profession != null && state.profession!.trim().isNotEmpty;
  }
}
