import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/PendingWidget.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authentication/signin.dart';
import 'package:tiler_app/services/api/appApi.dart';

/// Refresh the failed range and its metrics independently. A metrics failure
/// must not prevent the event list from recovering or completing its gesture.
Future<ScheduleReadOutcome> retryScheduleRead(
    BuildContext context, ScheduleReadFailure failure) {
  try {
    context
        .read<ScheduleSummaryBloc>()
        .add(GetScheduleDaySummaryEvent(timeline: failure.timeline));
  } on ProviderNotFoundException {
    // A standalone calendar/preview may not host summary metrics.
  }
  return context.read<ScheduleBloc>().retryRead(failure);
}

/// Keeps the calendar mounted while a missing day's error/loading panel shows.
/// Read errors are persistent, date-scoped, and independent of change notices.
class ScheduleReadFeedback extends StatelessWidget {
  const ScheduleReadFeedback(
      {super.key, required this.date, required this.child});
  final DateTime date;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScheduleBloc>();
    return BlocBuilder<ScheduleReadCubit, ScheduleReadState>(
      bloc: bloc.reads,
      builder: (context, read) {
        final failure = read.failureFor(date);
        final retained = read.hasDataFor(date);
        final loading = read.loadingFor(date);
        // Missing data needs a full panel. Verified data, including an empty
        // day, stays visible with a warning while refresh recovery is pending.
        final blocked = !retained && (failure != null || loading);
        return LayoutBuilder(
            builder: (context, constraints) => Column(children: [
                  if (retained && failure != null)
                    ConstrainedBox(
                        // Large text can make the warning tall. Let it scroll
                        // within its own area while keeping events reachable.
                        constraints: BoxConstraints(
                            maxHeight: constraints.hasBoundedHeight
                                ? constraints.maxHeight * 0.45
                                : double.infinity),
                        child: SingleChildScrollView(
                            child: ScheduleReadFailureView(
                          failure: failure,
                          retained: true,
                          busy: loading,
                          onRetry: () => retryScheduleRead(context, failure),
                        ))),
                  Expanded(
                    key: const ValueKey('scheduleReadContent'),
                    child: Stack(fit: StackFit.expand, children: [
                      // Keep the calendar mounted behind a missing-day panel
                      // so returning to retained days preserves list/card state.
                      Offstage(offstage: blocked, child: child),
                      if (blocked)
                        failure == null
                            ? PendingWidget()
                            : ScheduleReadFailureView(
                                failure: failure,
                                busy: loading,
                                onRetry: () =>
                                    retryScheduleRead(context, failure),
                              ),
                    ]),
                  ),
                ]));
      },
    );
  }
}

class ScheduleReadFailureView extends StatelessWidget {
  const ScheduleReadFailureView({
    super.key,
    required this.failure,
    required this.onRetry,
    this.retained = false,
    this.busy = false,
  });
  static const panelKey = ValueKey('scheduleReadErrorPanel');
  static const bannerKey = ValueKey('scheduleReadErrorBanner');
  static const retryKey = ValueKey('scheduleReadRetry');
  final ScheduleReadFailure failure;
  final Future<ScheduleReadOutcome> Function() onRetry;
  final bool retained;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final auth = failure.error is ScheduleAuthenticationRequired;
    Future<void> retry() async {
      if (auth) {
        await Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => SignInRoute()));
      } else {
        await onRetry();
      }
    }

    final action = FilledButton.tonal(
      key: retryKey,
      onPressed: busy ? null : retry,
      child: Text(busy
          ? l10n.scheduleReadRetrying
          : auth
              ? l10n.signIn
              : l10n.previewRetry),
    );
    final title = auth
        ? l10n.scheduleReadSignIn
        : retained
            ? l10n.scheduleReadRefreshFailed
            : l10n.scheduleReadFailedTitle;
    final body =
        retained ? l10n.scheduleReadRetained : l10n.scheduleReadFailedBody;
    if (retained) {
      return Material(
        key: bannerKey,
        color: theme.colorScheme.errorContainer,
        child: Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer)),
                    Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        children: [Text(body), action]),
                    if (busy) const LinearProgressIndicator(),
                  ]),
            )),
      );
    }
    return LayoutBuilder(
        builder: (context, constraints) => RefreshIndicator(
              onRefresh: retry,
              child: SingleChildScrollView(
                key: panelKey,
                // An error may contain less than a screen of content; the
                // refresh gesture must still work without overflow to scroll.
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 48)
                          .clamp(0, double.infinity)),
                  child: Center(
                      child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Semantics(
                        liveRegion: true,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(auth ? Icons.lock_outline : Icons.cloud_off,
                                size: 36,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 16),
                            Text(title,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 8),
                            Text(body, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            action,
                            if (busy) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                            ],
                          ],
                        )),
                  )),
                ),
              ),
            ));
  }
}
