import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/components/scheduleNotices/scheduleNoticeBus.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Handler guard as well as API admission: a second tap gets an explanation
/// naming the change still in progress, shown where the user is looking
/// (over an open sheet, not behind it).
bool scheduleChangesAllowed(BuildContext context,
    {ScheduleChangeKind? requestedKind}) {
  try {
    final bloc = context.read<ScheduleBloc>();
    if (!bloc.scheduleChangesBlocked) return true;
    bloc.reportBlockedChange(requestedKind);
    final l10n = AppLocalizations.of(context)!;
    final evaluation = bloc.activeEvaluation;
    final message = scheduleChangeFailureMessage(context,
        fallback: l10n.scheduleChangesBlocked);
    final bus = ScheduleNoticeBus.maybeOf(context);
    if (bus != null) {
      bus.interrupt(context, message, stillRelevant: () {
        final current = bloc.activeEvaluation;
        return !bloc.isClosed &&
            bloc.scheduleChangesBlocked &&
            current?.id == evaluation?.id &&
            current?.account == evaluation?.account;
      });
    } else {
      ScaffoldMessenger.maybeOf(context)
          ?.showSnackBar(SnackBar(content: Text(message)));
    }
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

/// The change as a finished command, e.g. "Complete · Gym".
String scheduleChangeDoneLabel(
        AppLocalizations l10n, ScheduleEvaluation evaluation) =>
    '${scheduleChangeCommand(l10n, evaluation.kind)} · '
    '${scheduleChangeTarget(l10n, evaluation)}';

/// What to tell the user about how an unconfirmed change turned out.
String scheduleChangeOutcomeMessage(
    AppLocalizations l10n, ScheduleChangeOutcome outcome) {
  final change = scheduleChangeDoneLabel(l10n, outcome.evaluation);
  return switch (outcome.kind) {
    ScheduleChangeOutcomeKind.acknowledged =>
      l10n.scheduleChangeAcknowledged(change),
    ScheduleChangeOutcomeKind.confirmed =>
      l10n.scheduleChangeWentThrough(change),
    ScheduleChangeOutcomeKind.failed => l10n.scheduleChangeFailedLate(change),
    ScheduleChangeOutcomeKind.unconfirmed =>
      l10n.scheduleChangeUnconfirmed(change),
  };
}

/// The command label, used for failures rather than an in-progress verb.
String scheduleChangeCommand(AppLocalizations l10n, ScheduleChangeKind kind) =>
    switch (kind) {
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

String scheduleChangeFailureMessage(BuildContext context,
    {String? fallback,
    ScheduleChangeKind? kind,
    String? eventName,
    int affectedEventCount = 0}) {
  final l10n = AppLocalizations.of(context)!;
  try {
    final bloc = context.read<ScheduleBloc>();
    final declined = bloc.lastDeclinedChange;
    if (declined != null) {
      return l10n.scheduleChangeReattemptDeclined(
          scheduleChangeDoneLabel(l10n, declined));
    }
    // The change's outcome became known before its screen reported the
    // error: say how it turned out, once (the calendar then stays quiet).
    final latest = bloc.latestOutcome;
    if (latest != null) {
      bloc.markOutcomeTold(latest.evaluation.id);
      return scheduleChangeOutcomeMessage(l10n, latest);
    }
    final evaluation = bloc.activeEvaluation;
    if (evaluation?.phase == ScheduleEvaluationPhase.uncertain) {
      return '${l10n.scheduleChangeUncertain} · '
          '${scheduleChangeLabel(l10n, evaluation!)}\n'
          '${l10n.scheduleChangeUncertainBody}';
    }
    if (bloc.scheduleChangesBlocked) {
      return evaluation == null
          ? l10n.scheduleChangesBlocked
          : l10n
              .scheduleChangesBlockedBy(scheduleChangeLabel(l10n, evaluation));
    }
    if (bloc.lastChangeUnconfirmed) {
      final outcome = bloc.lastOutcome;
      if (outcome == null) return l10n.scheduleChangeUnconfirmedGeneric;
      bloc.markOutcomeTold(outcome.evaluation.id);
      return scheduleChangeOutcomeMessage(l10n, outcome);
    }
  } on ProviderNotFoundException {}
  if (kind != null) {
    final target = affectedEventCount > 1
        ? l10n.scheduleChangeEventCount(affectedEventCount)
        : (eventName?.trim().isNotEmpty ?? false)
            ? eventName!.trim()
            : affectedEventCount == 1 ||
                    const {
                      ScheduleChangeKind.add,
                      ScheduleChangeKind.edit,
                      ScheduleChangeKind.complete,
                      ScheduleChangeKind.delete,
                      ScheduleChangeKind.startNow,
                      ScheduleChangeKind.pause,
                      ScheduleChangeKind.resume,
                      ScheduleChangeKind.accept,
                    }.contains(kind)
                ? l10n.scheduleChangeTargetEvent
                : kind == ScheduleChangeKind.defer
                    ? l10n.scheduleChangeAllEvents
                    : l10n.scheduleChangeTargetSchedule;
    final message =
        l10n.operationFailed('${scheduleChangeCommand(l10n, kind)} · $target');
    return fallback == null ? message : '$message\n$fallback';
  }
  return fallback ?? l10n.scheduleChangeFailed;
}

/// Retry must not replay a mutation whose outcome is still unknown.
bool scheduleChangeRetryAllowed(BuildContext context) {
  try {
    final bloc = context.read<ScheduleBloc>();
    return !bloc.scheduleChangesBlocked &&
        !bloc.lastChangeUnconfirmed &&
        bloc.latestOutcome == null &&
        bloc.activeEvaluation?.phase != ScheduleEvaluationPhase.uncertain;
  } on ProviderNotFoundException {
    return true;
  }
}

void showScheduleChangeFailure(BuildContext context,
    {required ScheduleChangeKind kind,
    String? eventName,
    int affectedEventCount = 0,
    String? fallback,
    Key? key,
    VoidCallback? onRetry}) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      key: key,
      content: Text(scheduleChangeFailureMessage(context,
          kind: kind,
          eventName: eventName,
          affectedEventCount: affectedEventCount,
          fallback: fallback)),
      action: onRetry != null && scheduleChangeRetryAllowed(context)
          ? SnackBarAction(label: l10n.addTileRetry, onPressed: onRetry)
          : null,
    ));
}

/// Editors keep the current change visible even when its calendar is covered.
class ScheduleEvaluationProgress extends StatelessWidget {
  const ScheduleEvaluationProgress({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ScheduleBloc bloc;
    try {
      bloc = context.read<ScheduleBloc>();
    } on ProviderNotFoundException {
      return child;
    }
    return BlocBuilder<ScheduleBloc, ScheduleState>(
        bloc: bloc,
        builder: (context, state) {
          return Column(children: [
            if (state is ScheduleEvaluationState &&
                state.evaluation?.phase != ScheduleEvaluationPhase.failed)
              ScheduleEvaluationFeedback(state: state),
            Expanded(child: child),
          ]);
        });
  }
}

/// Calendar-local feedback preserves the mounted day content and navigation.
/// The evaluation state owns its lifetime, including after an editor closes.
class ScheduleEvaluationFeedback extends StatelessWidget {
  const ScheduleEvaluationFeedback(
      {super.key, required this.state, this.inSlot = false});
  final ScheduleEvaluationState state;

  /// Placed by a notice surface: the card only, no alignment or margin.
  final bool inSlot;

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
    final Widget card = Material(
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
                child: Stack(alignment: Alignment.center, children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              Theme.of(context).colorScheme.primaryContainer),
                      child: Icon(icon,
                          key: const ValueKey('scheduleEvaluationActionIcon'),
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer)),
                  if (phase == ScheduleEvaluationPhase.pending)
                    const Positioned.fill(
                        child: CircularProgressIndicator(strokeWidth: 2)),
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
                      context.read<ScheduleBloc>().dismissEvaluationFailure),
            // Hides the card only; the change is still checked and its
            // outcome still told.
            if (phase == ScheduleEvaluationPhase.uncertain)
              IconButton(
                  key: const ValueKey('scheduleEvaluationDismiss'),
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: context.read<ScheduleBloc>().dismissUncertainty)
          ]),
        ),
      ),
    );
    if (inSlot) return card;
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(padding: const EdgeInsets.all(8), child: card),
    );
  }
}

/// Tells the user how unconfirmed changes turned out, and asks before an
/// identical change is sent again.
class ScheduleChangeOutcomeNotices extends StatefulWidget {
  const ScheduleChangeOutcomeNotices({super.key, required this.child});
  final Widget child;

  @override
  State<ScheduleChangeOutcomeNotices> createState() =>
      _ScheduleChangeOutcomeNoticesState();
}

class _ScheduleChangeOutcomeNoticesState
    extends State<ScheduleChangeOutcomeNotices> {
  ScheduleBloc? _bloc;
  StreamSubscription<ScheduleChangeOutcome>? _subscription;
  final Set<Timer> _pending = <Timer>{};

  /// How long an outcome waits for the screen that sent the change to tell
  /// it first; told by the screen, the calendar skips it.
  static const Duration _screenFirst = Duration(milliseconds: 250);
  late final Future<bool> Function(ScheduleEvaluation) _confirm = _ask;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ScheduleBloc? bloc;
    try {
      bloc = context.read<ScheduleBloc>();
    } on ProviderNotFoundException {
      bloc = null;
    }
    if (identical(bloc, _bloc)) return;
    _release();
    _bloc = bloc;
    if (bloc == null) return;
    _subscription = bloc.outcomes.listen(_tell);
    bloc.confirmReattempt = _confirm;
  }

  void _release() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    final bloc = _bloc;
    if (bloc != null && identical(bloc.confirmReattempt, _confirm)) {
      bloc.confirmReattempt = null;
    }
  }

  @override
  void dispose() {
    for (final timer in _pending) {
      timer.cancel();
    }
    _pending.clear();
    _release();
    super.dispose();
  }

  void _tell(ScheduleChangeOutcome outcome) {
    late final Timer timer;
    timer = Timer(_screenFirst, () {
      _pending.remove(timer);
      _show(outcome);
    });
    _pending.add(timer);
  }

  void _show(ScheduleChangeOutcome outcome) {
    if (!mounted) return;
    final bloc = _bloc;
    if (bloc != null && bloc.outcomeTold(outcome.evaluation.id)) return;
    bloc?.markOutcomeTold(outcome.evaluation.id);
    final message =
        scheduleChangeOutcomeMessage(AppLocalizations.of(context)!, outcome);
    final bus = ScheduleNoticeBus.maybeOf(context);
    if (bus != null) {
      bus.interrupt(context, message);
    } else {
      // The newest outcome replaces one still showing.
      ScaffoldMessenger.maybeOf(context)
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _ask(ScheduleEvaluation unconfirmed) async {
    if (!mounted) return false;
    final l10n = AppLocalizations.of(context)!;
    final again = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
              title: Text(l10n.scheduleChangeReattemptTitle),
              content: Text(l10n.scheduleChangeReattemptBody(
                  scheduleChangeDoneLabel(l10n, unconfirmed))),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(l10n.cancel)),
                TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(l10n.scheduleChangeReattemptConfirm)),
              ],
            ));
    return again ?? false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Publishes the evaluation card to the calendar's top slot for as long as
/// the schedule is evaluating a change.
class ScheduleEvaluationNotices extends StatefulWidget {
  const ScheduleEvaluationNotices({super.key, required this.child});
  final Widget child;

  static const Object noticeId = #scheduleEvaluation;

  @override
  State<ScheduleEvaluationNotices> createState() =>
      _ScheduleEvaluationNoticesState();
}

class _ScheduleEvaluationNoticesState extends State<ScheduleEvaluationNotices> {
  ScheduleNoticeBus? _bus;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = ScheduleNoticeBus.maybeOf(context);
    if (identical(bus, _bus)) return;
    _bus?.hide(ScheduleEvaluationNotices.noticeId);
    _bus = bus;
    try {
      _publish(context.read<ScheduleBloc>().state);
    } on ProviderNotFoundException {}
  }

  @override
  void dispose() {
    _bus?.hide(ScheduleEvaluationNotices.noticeId);
    super.dispose();
  }

  void _publish(ScheduleState state) {
    final bus = _bus;
    if (bus == null) return;
    if (state is ScheduleEvaluationState) {
      bus.show(ScheduleNotice(
          id: ScheduleEvaluationNotices.noticeId,
          slot: ScheduleNoticeSlot.top,
          priority: ScheduleNotice.statusPriority,
          builder: (_) =>
              ScheduleEvaluationFeedback(state: state, inSlot: true)));
    } else {
      bus.hide(ScheduleEvaluationNotices.noticeId);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<ScheduleBloc, ScheduleState>(
          listener: (_, state) => _publish(state), child: widget.child);
}
