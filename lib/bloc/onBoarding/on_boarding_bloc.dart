import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import '../../data/location.dart';
import '../../data/onBoarding.dart';
import '../../services/api/onBoardingApi.dart';
import '../../services/onBoardingHelper.dart';
import 'on_boarding_event.dart';
import 'on_boarding_state.dart';
import '../../../constants.dart' as Constants;

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final OnBoardingApi onBoardingApi;
  OnboardingBloc(this.onBoardingApi)
      : super(OnboardingState(
            step: OnboardingStep.initial,
            pageNumber: 0,
            preferredDaySection: "Morning")) {
    on<NextPageEvent>(_onNextPageChanged);
    on<PreviousPageEvent>(_onPreviousPageEvent);
    on<WakeUpTimeUpdated>(_onWakeUpTimeUpdated);
    on<StartingWorkdayTimeUpdated>(_onStartingWorkDayUpdated);
    on<PreferredDaySectionUpdated>(_onPreferredDaySectionUpdated);
    on<AddressTextChanged>(_onAddressTextChanged);
    on<LocationSelected>(_onLocationSelected);
    on<SkipOnboardingEvent>(_onSkipOnboarding);
    on<OnboardingRequestedEvent>(_onOnboardingRequestedEvent);
  }

  void _onNextPageChanged(NextPageEvent event, Emitter<OnboardingState> emit) {
    if (state.pageNumber! < 3) {
      emit(state.copyWith(
        pageNumber: state.pageNumber! + 1,
        step: OnboardingStep.pageChanged,
      ));
    } else if (state.pageNumber! == 3) {
      add(OnboardingRequestedEvent());
    }
  }

  void _onPreviousPageEvent(
      PreviousPageEvent event, Emitter<OnboardingState> emit) {
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

  void _onAddressTextChanged(
      AddressTextChanged event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.locationUpdated,
      addressText: event.addressText,
      selectedLocation: null,
      isLocationVerified: false,
    ));
  }

  void _onLocationSelected(
      LocationSelected event, Emitter<OnboardingState> emit) {
    emit(state.copyWith(
      step: OnboardingStep.locationUpdated,
      selectedLocation: event.location,
      addressText: event.location.address,
      isLocationVerified: event.location.isVerified ?? false,
    ));
  }

  void _onSkipOnboarding(
      SkipOnboardingEvent event, Emitter<OnboardingState> emit) async {
    await OnBoardingSharedPreferencesHelper.setSkipOnboarding(true);
    emit(OnboardingState(step: OnboardingStep.skipped));
  }

  void _onOnboardingRequestedEvent(
      OnboardingRequestedEvent event, Emitter<OnboardingState> emit) async {
    await Future.delayed(
        const Duration(milliseconds: Constants.onTextChangeDelayInMs));
    emit(state.copyWith(
      step: OnboardingStep.loading,
    ));
    OnboardingContent onboardingContent = new OnboardingContent(
        personalHoursStart: _requestFormatTime(state.wakeUpTime),
        workHoursStart: _requestFormatTime(state.startingWorkDayTime),
        workLocation: state.selectedLocation ?? Location.fromDefault(),
        preferredDaySections: [state.preferredDaySection.toString()]);

    try {
      OnboardingContent? result =
          await onBoardingApi.sendOnboardingData(onboardingContent);
      emit(OnboardingState(step: OnboardingStep.submitted));
    } catch (e) {
      print(e.toString());
      emit(state.copyWith(
        step: OnboardingStep.error,
        error: e.toString(),
      ));
    }
  }

  String? _requestFormatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'Am' : 'Pm';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}$period';
  }
}
