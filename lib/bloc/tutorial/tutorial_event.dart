import 'package:equatable/equatable.dart';

abstract class TutorialEvent extends Equatable {
  const TutorialEvent();

  @override
  List<Object?> get props => [];
}

/// Start the tutorial from step 0.
class StartTutorialEvent extends TutorialEvent {}

/// Advance to the next tutorial step.
class NextTutorialStepEvent extends TutorialEvent {}

/// Go back to the previous step.
class PreviousTutorialStepEvent extends TutorialEvent {}

/// Skip / dismiss the tutorial entirely.
class SkipTutorialEvent extends TutorialEvent {}

/// Complete the tutorial (final step done).
class CompleteTutorialEvent extends TutorialEvent {}

/// Reset the tutorial so it can be replayed.
class ResetTutorialEvent extends TutorialEvent {}
