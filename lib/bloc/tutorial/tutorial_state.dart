import 'package:equatable/equatable.dart';

enum TutorialStatus { initial, active, completed, skipped }

class TutorialState extends Equatable {
  final TutorialStatus status;
  final int currentStepIndex;
  final int totalSteps;

  const TutorialState({
    this.status = TutorialStatus.initial,
    this.currentStepIndex = 0,
    this.totalSteps = 0,
  });

  bool get isActive => status == TutorialStatus.active;
  bool get isCompleted => status == TutorialStatus.completed;
  bool get isFirstStep => currentStepIndex == 0;
  bool get isLastStep => currentStepIndex >= totalSteps - 1;

  TutorialState copyWith({
    TutorialStatus? status,
    int? currentStepIndex,
    int? totalSteps,
  }) {
    return TutorialState(
      status: status ?? this.status,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      totalSteps: totalSteps ?? this.totalSteps,
    );
  }

  @override
  List<Object?> get props => [status, currentStepIndex, totalSteps];
}
