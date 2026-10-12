import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Handler guard as well as API admission: a second tap gets an explanation
/// naming the change still in progress.
bool scheduleChangesAllowed(BuildContext context) {
  try {
    final bloc = context.read<ScheduleBloc>();
    if (!bloc.scheduleChangesBlocked) return true;
    final l10n = AppLocalizations.of(context)!;
    final evaluation = bloc.activeEvaluation;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
        content: Text(evaluation == null
            ? l10n.scheduleChangesBlocked
            : l10n.scheduleChangesBlockedBy(
                scheduleChangeLabel(l10n, evaluation)))));
    return false;
  } on ProviderNotFoundException {
    return true;
  }
}

/// What a change does, as its in-progress title ("Completing").
String scheduleChangeActionTitle(
    AppLocalizations l10n, ScheduleChangeKind? kind,
    {String? fallback}) {
  return switch (kind) {
    ScheduleChangeKind.complete => l10n.completing,
    ScheduleChangeKind.delete => l10n.deleting,
    ScheduleChangeKind.startNow => l10n.movingUp,
    ScheduleChangeKind.pause => l10n.pausing,
    ScheduleChangeKind.resume => l10n.resuming,
    ScheduleChangeKind.defer => l10n.procrastinating,
    ScheduleChangeKind.shuffle => l10n.optimizingSchedule,
    ScheduleChangeKind.add => l10n.scheduleChangeAdding,
    ScheduleChangeKind.edit => l10n.editTileSaving,
    ScheduleChangeKind.settings => l10n.scheduleChangeSettings,
    ScheduleChangeKind.accept => l10n.scheduleChangeAccepting,
    _ => fallback ?? l10n.revisingSchedule,
  };
}

/// What a change acts on: the event's name, a count of events, or the
/// schedule as a whole.
String scheduleChangeTarget(
    AppLocalizations l10n, ScheduleEvaluation evaluation) {
  if (evaluation.affectedEventCount > 1) {
    return l10n.scheduleChangeEventCount(evaluation.affectedEventCount);
  }
  return evaluation.eventName ??
      (evaluation.affectedEventCount == 1 ||
              const {
                ScheduleChangeKind.add,
                ScheduleChangeKind.complete,
                ScheduleChangeKind.delete,
                ScheduleChangeKind.startNow,
                ScheduleChangeKind.pause,
                ScheduleChangeKind.resume,
                ScheduleChangeKind.accept
              }.contains(evaluation.kind)
          ? l10n.scheduleChangeTargetEvent
          : evaluation.kind == ScheduleChangeKind.defer
              ? l10n.scheduleChangeAllEvents
              : l10n.scheduleChangeTargetSchedule);
}

/// The change in one line, e.g. "Completing · Gym".
String scheduleChangeLabel(
        AppLocalizations l10n, ScheduleEvaluation evaluation) =>
    '${scheduleChangeActionTitle(l10n, evaluation.kind)} · '
    '${scheduleChangeTarget(l10n, evaluation)}';

String scheduleChangeFailureMessage(BuildContext context, {String? fallback}) {
  final l10n = AppLocalizations.of(context)!;
  try {
    if (context.read<ScheduleBloc>().lastChangeUnconfirmed) {
      return l10n.scheduleChangeHoldEnded;
    }
    if (context.read<ScheduleBloc>().activeEvaluation?.phase ==
        ScheduleEvaluationPhase.uncertain) {
      return '${l10n.scheduleChangeUncertain}. ${l10n.scheduleChangeUncertainBody}';
    }
  } on ProviderNotFoundException {}
  return fallback ?? l10n.scheduleChangeFailed;
}

/// Calendar-local feedback preserves the mounted day content and navigation.
/// The evaluation state owns its lifetime, including after an editor closes.
class ScheduleEvaluationFeedback extends StatelessWidget {
  const ScheduleEvaluationFeedback({super.key, required this.state});
  final ScheduleEvaluationState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final evaluation = state.evaluation;
    final phase = evaluation?.phase ?? ScheduleEvaluationPhase.pending;
    final command = switch (evaluation?.kind) {
      ScheduleChangeKind.complete => l10n.complete,
      ScheduleChangeKind.delete => l10n.delete,
      ScheduleChangeKind.startNow => l10n.startNow,
      ScheduleChangeKind.pause => l10n.pause,
      ScheduleChangeKind.resume => l10n.resume,
      ScheduleChangeKind.defer => l10n.defer,
      ScheduleChangeKind.add => l10n.addTile,
      ScheduleChangeKind.edit => l10n.edit,
      ScheduleChangeKind.settings => l10n.settings,
      ScheduleChangeKind.accept => l10n.accept,
      _ => l10n.reOptimizeChip,
    };
    final icon = switch (evaluation?.kind) {
      ScheduleChangeKind.complete => Icons.check_circle_outline,
      ScheduleChangeKind.delete => Icons.delete_outline,
      ScheduleChangeKind.startNow => Icons.play_arrow_outlined,
      ScheduleChangeKind.pause => Icons.pause_circle_outline,
      ScheduleChangeKind.resume => Icons.play_circle_outline,
      ScheduleChangeKind.defer => Icons.snooze_outlined,
      ScheduleChangeKind.add => Icons.add_circle_outline,
      ScheduleChangeKind.edit => Icons.edit_calendar_outlined,
      ScheduleChangeKind.settings => Icons.tune,
      ScheduleChangeKind.accept => Icons.task_alt,
      ScheduleChangeKind.shuffle => Icons.shuffle,
      _ => Icons.autorenew,
    };
    final target =
        evaluation == null ? null : scheduleChangeTarget(l10n, evaluation);
    final title = phase == ScheduleEvaluationPhase.uncertain
        ? l10n.scheduleChangeUncertain
        : phase == ScheduleEvaluationPhase.failed
            ? l10n.scheduleChangeFailed
            : scheduleChangeActionTitle(l10n, evaluation?.kind,
                fallback: state.message);
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Material(
          key: const ValueKey('scheduleEvaluationFeedback'),
          elevation: 3,
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Semantics(
              liveRegion: true,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(children: [
                      Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer),
                          child: Icon(icon,
                              key: const ValueKey(
                                  'scheduleEvaluationActionIcon'),
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                      if (phase == ScheduleEvaluationPhase.pending)
                        Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHigh),
                                padding: const EdgeInsets.all(2),
                                child: const CircularProgressIndicator(
                                    strokeWidth: 2))),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(title),
                      if (evaluation != null &&
                          phase != ScheduleEvaluationPhase.pending)
                        Text(command,
                            style: Theme.of(context).textTheme.labelMedium),
                      if (target != null)
                        Tooltip(
                            message: target,
                            child: Text(target,
                                key: const ValueKey('scheduleEvaluationTarget'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleSmall)),
                      if (phase == ScheduleEvaluationPhase.uncertain)
                        Text(l10n.scheduleChangeUncertainBody),
                      if (phase == ScheduleEvaluationPhase.uncertain)
                        TextButton(
                            onPressed: context
                                .read<ScheduleBloc>()
                                .refreshEvaluationSchedule,
                            child: Text(l10n.scheduleChangeRefresh)),
                    ])),
                if (phase == ScheduleEvaluationPhase.failed)
                  IconButton(
                      tooltip: l10n.close,
                      icon: const Icon(Icons.close),
                      onPressed:
                          context.read<ScheduleBloc>().dismissEvaluationFailure)
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
