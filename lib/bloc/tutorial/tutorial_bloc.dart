import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_event.dart';
import 'package:tiler_app/bloc/tutorial/tutorial_state.dart';
import 'package:tiler_app/services/tutorialPreferencesHelper.dart';

class TutorialBloc extends Bloc<TutorialEvent, TutorialState> {
  final int stepCount;

  /// The tour this bloc instance drives. Defaults to the `home` tour so the
  /// existing AuthorizedRoute wiring keeps working during the Phase 1
  /// transition (stages 1.2/1.3).
  final String tourId;

  TutorialBloc({required this.stepCount, this.tourId = TourPreferencesHelper.homeTourId})
      : super(TutorialState(totalSteps: stepCount)) {
    on<StartTutorialEvent>(_onStart);
    on<NextTutorialStepEvent>(_onNext);
    on<PreviousTutorialStepEvent>(_onPrevious);
    on<SkipTutorialEvent>(_onSkip);
    on<CompleteTutorialEvent>(_onComplete);
    on<ResetTutorialEvent>(_onReset);
  }

  void _onStart(StartTutorialEvent event, Emitter<TutorialState> emit) {
    emit(state.copyWith(
      status: TutorialStatus.active,
      currentStepIndex: 0,
      totalSteps: stepCount,
    ));
  }

  void _onNext(NextTutorialStepEvent event, Emitter<TutorialState> emit) {
    if (state.isLastStep) {
      add(CompleteTutorialEvent());
      return;
    }
    emit(state.copyWith(
      currentStepIndex: state.currentStepIndex + 1,
    ));
  }

  void _onPrevious(
      PreviousTutorialStepEvent event, Emitter<TutorialState> emit) {
    if (state.isFirstStep) return;
    emit(state.copyWith(
      currentStepIndex: state.currentStepIndex - 1,
    ));
  }

  void _onSkip(SkipTutorialEvent event, Emitter<TutorialState> emit) {
    TourPreferencesHelper.setTourCompleted(tourId);
    emit(state.copyWith(status: TutorialStatus.skipped));
  }

  void _onComplete(CompleteTutorialEvent event, Emitter<TutorialState> emit) {
    TourPreferencesHelper.setTourCompleted(tourId);
    emit(state.copyWith(status: TutorialStatus.completed));
  }

  void _onReset(ResetTutorialEvent event, Emitter<TutorialState> emit) {
    TourPreferencesHelper.resetTour(tourId);
    emit(TutorialState(
      status: TutorialStatus.active,
      currentStepIndex: 0,
      totalSteps: stepCount,
    ));
  }
}
