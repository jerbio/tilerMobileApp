import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_preview_state.dart';
import 'package:tiler_app/components/tilelist/dailyView/dayGridPage.dart';
import 'package:tiler_app/data/tileSharePreview.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/calendarGrid/dayGridWidget.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/preview/previewTiles.dart';
import 'package:tiler_app/theme/tile_colors.dart';
import 'package:tiler_app/util.dart';

/// The accept preview (redesign T21-T25, §5.9): how accepting one invitation
/// would land on the calendar, and the answer.
///
/// * **The strip** is the Daily grid in preview mode, one day at a time: the
///   proposed schedule with the task in the preview accent and selected. It
///   opens on the day the task lands, follows the task when another arrangement
///   is chosen, and steps through the days the server returned (no further).
/// * **The sheet** is the product: the time the task lands and what it moves,
///   then Accept and Accept & lock (naming the time it fixes), Decline, and the
///   details. Both accept actions are reachable without dragging it.
/// * **Other times** are asked for only when wanted and listed as cards, the
///   original first; choosing one swaps the whole arrangement at once (no
///   request) and keeps the list open. Split work lists its **sessions** (the
///   chosen one is the lock target and moves the strip), and **scheduling
///   issues** are a collapsed group - never drawn as appointments.
/// * Every other state says what happened and offers the one useful next step:
///   a stale preview Refresh, an unconfirmed accept Try again (the same command)
///   and Check status, a rejection Review again.
///
/// Pops `true` when something may have changed (an answer was sent), `false`
/// otherwise. Reads [TileSharePreviewCubit] from the context and loads it.
class TileSharePreviewPage extends StatefulWidget {
  /// A fixed clock for the strip's now-line (tests); live when omitted.
  final DateTime? now;

  /// "View in calendar" after an accept: opens the calendar on the day the
  /// task landed. Without it there is no link.
  final void Function(DateTime day)? onViewInCalendar;

  const TileSharePreviewPage({super.key, this.now, this.onViewInCalendar});

  @override
  State<TileSharePreviewPage> createState() => _TileSharePreviewPageState();
}

class _TileSharePreviewPageState extends State<TileSharePreviewPage> {
  static const Duration _fade = Duration(milliseconds: 200);
  static const double _sheetInitial = 0.45;

  /// How far the strip runs under the sheet's rounded top.
  static const double _sheetOverlap = 16;

  /// The strip never gets shorter than its stepper and a slice of the grid.
  static const double _minStripHeight = 200;

  /// The sheet's current height, as a fraction of the body.
  double _sheetExtent = _sheetInitial;

  /// The day the strip shows; `null` until there is a preview.
  DateTime? _day;

  /// What [_day] was last placed for: the preview and the session it follows.
  /// A new one moves the strip to that session's day.
  String? _anchor;

  /// The answer going out is a decline (the cubit does not say which).
  bool _declining = false;

  /// The other-times list and the scheduling-issues group are open.
  bool _otherTimesOpen = false;
  bool _issuesOpen = false;

  @override
  void initState() {
    super.initState();
    final TileSharePreviewCubit cubit = context.read<TileSharePreviewCubit>();
    if (cubit.state.phase == PreviewPhase.idle) cubit.load();
  }

  static bool _answered(PreviewPhase phase) => const <PreviewPhase>{
        PreviewPhase.completed,
        PreviewPhase.needsReview,
        PreviewPhase.rejected,
        PreviewPhase.declined,
        PreviewPhase.adding,
        PreviewPhase.unconfirmed,
      }.contains(phase);

  void _close(bool changed) => Navigator.of(context).pop(changed);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return BlocConsumer<TileSharePreviewCubit, TileSharePreviewState>(
      listenWhen: (previous, current) =>
          previous.phase == PreviewPhase.submitting &&
          current.phase != PreviewPhase.submitting,
      listener: (context, state) => setState(() => _declining = false),
      builder: (context, state) {
        final TileSharePreviewCubit cubit =
            context.read<TileSharePreviewCubit>();
        final bool canRegenerate = !state.isRefreshing &&
            (state.phase == PreviewPhase.ready ||
                state.phase == PreviewPhase.unsupported ||
                state.phase == PreviewPhase.error);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _close(_answered(state.phase));
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              leading: IconButton(
                key: const Key('preview_back'),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _close(_answered(state.phase)),
              ),
              title: Text(state.preview?.name ?? l10n.previewTitleFallback,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              actions: [
                IconButton(
                  key: const Key('preview_regenerate'),
                  tooltip: l10n.previewRegenerate,
                  icon: const Icon(Icons.refresh),
                  onPressed: canRegenerate ? cubit.regenerate : null,
                ),
              ],
              bottom: state.isRefreshing
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(2),
                      child: LinearProgressIndicator(minHeight: 2))
                  : null,
            ),
            body: AnimatedSwitcher(
              duration: _fade,
              child: KeyedSubtree(
                key: ValueKey<String>(_bodyKind(state)),
                child: _body(context, state, cubit),
              ),
            ),
          ),
        );
      },
    );
  }

  String _bodyKind(TileSharePreviewState state) {
    if (state.phase == PreviewPhase.idle ||
        state.phase == PreviewPhase.loading) {
      return 'loading';
    }
    final TileSharePreview? preview = state.preview;
    if (preview == null) return 'bare';
    return preview.isUnsupported ? 'unsupported' : 'preview';
  }

  Widget _body(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (_bodyKind(state)) {
      case 'loading':
        return _Centered(
          key: const Key('preview_loading'),
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(l10n.previewLoading, textAlign: TextAlign.center),
          ],
        );
      case 'bare':
        // Nothing to show around it: an accept resumed on opening, or a
        // preview that could not be built.
        if (state.phase == PreviewPhase.submitting) {
          return _Centered(children: [_submitting(context)]);
        }
        if (_answered(state.phase)) {
          return _Centered(children: [_outcome(context, state, cubit)]);
        }
        return _Centered(
          key: const Key('preview_error'),
          children: [
            Text(_problemText(l10n, state.problem),
                textAlign: TextAlign.center),
            if (state.problem != PreviewProblem.gone) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                key: const Key('preview_retry'),
                onPressed: cubit.load,
                child: Text(l10n.attentionRetry),
              ),
            ],
          ],
        );
      case 'unsupported':
        return ListView(
          padding: const EdgeInsets.all(16),
          children: _unsupported(context, state, cubit),
        );
      default:
        // The strip ends where the sheet begins (under its rounded top) and
        // follows it as it is dragged, so the grid never scrolls the task
        // under the sheet. It keeps room for its stepper when the sheet is up.
        return LayoutBuilder(
          builder: (context, constraints) {
            final double height = constraints.maxHeight;
            final double stripHeight = math.max(
                height * (1 - _sheetExtent) + _sheetOverlap, _minStripHeight);
            return NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                if ((notification.extent - _sheetExtent).abs() > 0.001) {
                  setState(() => _sheetExtent = notification.extent);
                }
                return false;
              },
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: math.min(stripHeight, height),
                    child: _strip(context, state, cubit),
                  ),
                  DraggableScrollableSheet(
                    initialChildSize: _sheetInitial,
                    minChildSize: 0.25,
                    maxChildSize: 0.92,
                    builder: (context, controller) =>
                        _sheet(context, state, cubit, controller),
                  ),
                ],
              ),
            );
          },
        );
    }
  }

  // ---- the strip ----------------------------------------------------------------

  /// The session the strip and the time follow: the one a lock would fix, or
  /// the first one placed.
  static PreviewBlock? _focus(TileSharePreviewState state) {
    final PreviewBlock? target = state.lockTarget;
    if (target != null) return target;
    final List<PreviewBlock> placed =
        state.preview?.proposedSessionBlocks ?? const <PreviewBlock>[];
    return placed.isEmpty ? null : placed.first;
  }

  /// Puts the strip on the focused session's day whenever the preview or the
  /// focused session changes; leaves the user's own stepping alone otherwise.
  List<DateTime> _placeDay(TileSharePreviewState state) {
    final TileSharePreview preview = state.preview!;
    final List<DateTime> days =
        PreviewTiles.days(preview, today: widget.now ?? DateTime.now());
    final PreviewBlock? focus = _focus(state);
    final String anchor = '${preview.previewToken}|${preview.shuffleSeed}|'
        '${focus?.sessionKey}|${focus?.startMs}';
    if (anchor != _anchor || _day == null || !days.contains(_day)) {
      _anchor = anchor;
      _day = (focus == null ? null : PreviewTiles.dayFor(focus, days)) ??
          days.first;
    }
    return days;
  }

  Widget _strip(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final TileSharePreview preview = state.preview!;
    final List<DateTime> days = _placeDay(state);
    final DateTime day = _day!;
    final int index = days.indexOf(day);
    final PreviewBlock? focus = _focus(state);
    final List<TilerEvent> tiles = PreviewTiles.forDay(preview, day);

    void step(int by) => setState(() => _day = days[index + by]);

    return Column(
      children: [
        Material(
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              IconButton(
                key: const Key('preview_day_prev'),
                tooltip: l10n.previewPrevDay,
                icon: const Icon(Icons.chevron_left),
                onPressed: index > 0 ? () => step(-1) : null,
              ),
              Expanded(
                child: Text(
                  DateFormat.MMMEd(locale).format(day),
                  key: const Key('preview_day_label'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                key: const Key('preview_day_next'),
                tooltip: l10n.previewNextDay,
                icon: const Icon(Icons.chevron_right),
                onPressed: index < days.length - 1 ? () => step(1) : null,
              ),
            ],
          ),
        ),
        if (focus != null && !PreviewTiles.isInWindow(focus, preview))
          _Note(
            key: const Key('preview_outside'),
            icon: Icons.event_outlined,
            text: l10n.previewOutsideWindow(PreviewTiles.when(focus, locale)),
          )
        else if (tiles.isEmpty)
          _Note(
            key: const Key('preview_nothing'),
            icon: Icons.event_available_outlined,
            text: l10n.previewNothingThisDay,
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: _fade,
            child: DayGridWidget(
              key: ValueKey<DateTime>(day),
              tiles: DayGridPage.previewGridTiles(tiles),
              day: day,
              dayKey: 'tileshare_preview_${day.millisecondsSinceEpoch}',
              preview: true,
              now: widget.now,
              selectedActionEntityId: focus?.id,
              onTileTap: ({TilerEvent? tilerEvent}) {
                for (final PreviewBlock s in preview.proposedSessionBlocks) {
                  if (s.id == tilerEvent?.id && s.sessionKey != null) {
                    cubit.highlightSession(s.sessionKey!);
                  }
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  // ---- the sheet ----------------------------------------------------------------

  Widget _sheet(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit, ScrollController controller) {
    final ThemeData theme = Theme.of(context);
    return Material(
      key: const Key('preview_sheet'),
      elevation: 8,
      color: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      clipBehavior: Clip.antiAlias,
      // Not lazy: the sheet is short, and every part of it (the time at the
      // top, the lists below) stays built while it scrolls.
      child: SingleChildScrollView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                key: const Key('preview_sheet_handle'),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._banners(context, state, cubit),
            _time(context, state),
            const SizedBox(height: 12),
            AnimatedSize(
              duration: _fade,
              alignment: Alignment.topCenter,
              child: _answers(context, state, cubit),
            ),
            AnimatedSize(
              duration: _fade,
              alignment: Alignment.topCenter,
              child: _otherTimes(context, state, cubit),
            ),
            ..._sessions(context, state, cubit),
            ..._issues(context, state.preview!),
            ..._details(context, state.preview!),
          ],
        ),
      ),
    );
  }

  List<Widget> _banners(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Widget? banner = switch (state.problem) {
      PreviewProblem.stale => _Banner(
          key: const Key('preview_stale'),
          text: l10n.previewStale,
          action: TextButton(
            key: const Key('preview_refresh'),
            onPressed: state.isRefreshing ? null : cubit.regenerate,
            child: Text(l10n.previewRefresh),
          ),
        ),
      PreviewProblem.sessionInvalid => _Banner(
          key: const Key('preview_session_invalid'),
          text: l10n.previewSessionInvalid,
        ),
      null || PreviewProblem.responseInProgress => null,
      final PreviewProblem other => _Banner(
          key: const Key('preview_problem'),
          text: _problemText(l10n, other),
          action: other == PreviewProblem.loadFailed ||
                  state.phase == PreviewPhase.error
              ? TextButton(
                  key: const Key('preview_refresh'),
                  onPressed: state.isRefreshing ? null : cubit.regenerate,
                  child: Text(l10n.previewRefresh),
                )
              : null,
        ),
    };
    return [
      if (banner != null) ...[banner, const SizedBox(height: 12)]
    ];
  }

  /// The time the task lands (or that it does not fit), and what it moves.
  Widget _time(BuildContext context, TileSharePreviewState state) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final TileSharePreview preview = state.preview!;
    final PreviewBlock? focus = _focus(state);
    if (focus == null || !preview.isViable) {
      return _Note(
        key: const Key('preview_cannot_fit'),
        icon: Icons.event_busy_outlined,
        text: l10n.previewCannotFit,
        color: theme.colorScheme.error,
      );
    }
    final int moved = PreviewTiles.movedCount(preview);
    final List<String> meta = <String>[
      Duration(milliseconds: focus.durationMs).toHumanLocalized(context),
      if (preview.timeZone != null) preview.timeZone!,
    ];
    return Column(
      key: const Key('preview_time'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          state.selectedOptionId == null
              ? l10n.previewSuggested
              : l10n.previewSelected,
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 8, top: 2),
              decoration: BoxDecoration(
                color: PreviewTiles.proposedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Text(PreviewTiles.when(focus, locale),
                  style: theme.textTheme.titleMedium),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 2),
          child: Text(
            meta.join(' · '),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (moved > 0)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 2),
            child: Text(
              l10n.previewMoves(moved),
              key: const Key('preview_moves'),
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  /// Accept, Accept & lock and Decline; progress while an answer goes out; the
  /// outcome once it is known.
  Widget _answers(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    if (state.phase == PreviewPhase.submitting) return _submitting(context);
    if (_answered(state.phase)) return _outcome(context, state, cubit);
    final PreviewBlock? target = state.lockTarget;
    final TextStyle? hint = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton(
                key: const Key('preview_accept'),
                onPressed: state.canAccept ? cubit.accept : null,
                child: Text(l10n.previewAccept, textAlign: TextAlign.center),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                key: const Key('preview_accept_lock'),
                onPressed: state.canAcceptAndLock ? cubit.acceptAndLock : null,
                child: Text(l10n.previewAcceptAndLock,
                    textAlign: TextAlign.center),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(l10n.previewAcceptHint, style: hint),
        if (target != null)
          Text(
            l10n.previewLockHint(PreviewTiles.when(target, locale)),
            key: const Key('preview_lock_hint'),
            style: hint,
          ),
        const SizedBox(height: 4),
        _decline(context, state, cubit),
      ],
    );
  }

  Widget _decline(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton(
          key: const Key('preview_decline'),
          style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
          onPressed: () {
            setState(() => _declining = true);
            cubit.decline();
          },
          child: Text(l10n.previewDecline),
        ),
        if (state.declineFailed)
          Text(
            l10n.previewDeclineFailed,
            key: const Key('preview_decline_failed'),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
      ],
    );
  }

  Widget _submitting(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Padding(
      key: const Key('preview_submitting'),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          if (!_declining) ...[
            const SizedBox(width: 12),
            Flexible(child: Text(l10n.previewAdding)),
          ],
        ],
      ),
    );
  }

  Widget _outcome(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final Widget done = FilledButton(
      key: const Key('preview_done'),
      onPressed: () => _close(true),
      child: Text(l10n.previewDone),
    );
    final Widget checkStatus = OutlinedButton(
      key: const Key('preview_check_status'),
      onPressed: cubit.checkStatus,
      child: Text(l10n.previewCheckStatus),
    );
    final PreviewBlock? landed = _focus(state);
    final void Function(DateTime day)? view = widget.onViewInCalendar;
    final List<Widget> calendar = [
      if (view != null && landed != null)
        OutlinedButton(
          key: const Key('preview_view_calendar'),
          onPressed: () {
            final DateTime start =
                DateTime.fromMillisecondsSinceEpoch(landed.startMs);
            view(DateTime(start.year, start.month, start.day));
          },
          child: Text(l10n.previewViewInCalendar),
        ),
    ];
    final (
      IconData icon,
      Color color,
      String title,
      String? detail,
      List<Widget> actions
    ) = switch (state.phase) {
      PreviewPhase.completed => (
          Icons.check_circle_outline,
          theme.colorScheme.primary,
          l10n.previewAdded,
          null,
          [...calendar, done]
        ),
      PreviewPhase.needsReview => (
          Icons.info_outline,
          theme.colorScheme.tertiary,
          l10n.previewNeedsReview,
          null,
          [...calendar, done]
        ),
      PreviewPhase.declined => (
          Icons.do_not_disturb_on_outlined,
          theme.colorScheme.onSurfaceVariant,
          l10n.previewDeclined,
          null,
          [done]
        ),
      PreviewPhase.rejected => (
          Icons.error_outline,
          theme.colorScheme.error,
          l10n.previewNotAdded,
          _reasonText(l10n, state.reason),
          [
            OutlinedButton(
              key: const Key('preview_review_again'),
              onPressed: cubit.load,
              child: Text(l10n.previewReviewAgain),
            ),
            done,
          ]
        ),
      PreviewPhase.unconfirmed => (
          Icons.help_outline,
          theme.colorScheme.tertiary,
          l10n.previewUnconfirmed,
          null,
          [
            FilledButton(
              key: const Key('preview_try_again'),
              onPressed: cubit.retryAccept,
              child: Text(l10n.previewTryAgain),
            ),
            checkStatus,
          ]
        ),
      _ => (
          Icons.hourglass_top,
          theme.colorScheme.tertiary,
          l10n.previewStillAdding,
          null,
          [checkStatus]
        ),
    };
    return Column(
      key: Key('preview_outcome_${state.phase.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        ),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 32),
            child: Text(detail, style: theme.textTheme.bodyMedium),
          ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: actions,
        ),
      ],
    );
  }

  // ---- other times ----------------------------------------------------------

  /// The placed session of [preview] that follows [sessionKey] (the lock
  /// target), else its first placed one.
  static PreviewBlock? _placed(TileSharePreview preview, String? sessionKey) {
    final List<PreviewBlock> placed = preview.proposedSessionBlocks;
    for (final PreviewBlock s in placed) {
      if (s.sessionKey == sessionKey) return s;
    }
    return placed.isEmpty ? null : placed.first;
  }

  Widget _otherTimes(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final TileSharePreview? original = state.original;
    if (original == null ||
        !original.canFindOtherTimes ||
        state.phase == PreviewPhase.submitting ||
        _answered(state.phase)) {
      return const SizedBox(width: double.infinity);
    }
    if (!_otherTimesOpen) {
      return Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton.icon(
          key: const Key('preview_find_times'),
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(l10n.previewFindAnotherTime),
          onPressed: state.canFindOtherTimes || state.optionsStarted
              ? () {
                  setState(() => _otherTimesOpen = true);
                  if (!state.optionsStarted) cubit.findOtherTimes();
                }
              : null,
        ),
      );
    }

    final String? key = state.highlightedSessionKey;
    String moves(TileSharePreview? p) {
      if (p == null) return '';
      final int moved = PreviewTiles.movedCount(p);
      return moved > 0 ? l10n.previewMoves(moved) : l10n.previewNoMoves;
    }

    final PreviewBlock? originalSession = _placed(original, key);
    final TextStyle? quiet = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return Column(
      key: const Key('preview_arrangements'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(height: 24),
        InkWell(
          key: const Key('preview_other_times_toggle'),
          onTap: () => setState(() => _otherTimesOpen = false),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                    child: Text(l10n.previewOtherTimes,
                        style: theme.textTheme.titleSmall)),
                const Icon(Icons.expand_less),
              ],
            ),
          ),
        ),
        if (state.isSelecting) const LinearProgressIndicator(minHeight: 2),
        _OptionCard(
          key: const Key('preview_option_original'),
          label: l10n.previewOriginalSuggestion,
          when: originalSession == null
              ? l10n.previewCannotFit
              : PreviewTiles.when(originalSession, locale),
          detail: moves(original),
          selected: state.selectedOptionId == null,
          onTap: cubit.selectOriginal,
        ),
        for (final PreviewOption option in state.options)
          _OptionCard(
            key: Key('preview_option_${option.optionId}'),
            when: () {
              final TileSharePreview? embedded = option.preview;
              final PreviewBlock? session =
                  embedded == null ? null : _placed(embedded, key);
              return session == null
                  ? PreviewTiles.whenRange(option.startMs, option.endMs, locale)
                  : PreviewTiles.when(session, locale);
            }(),
            detail: moves(option.preview),
            selected: state.selectedOptionId == option.optionId,
            onTap: () => cubit.selectOption(option.optionId),
          ),
        if (state.selectionFailed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.previewSelectFailed,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error)),
          ),
        if (state.optionsLoad == OptionsLoad.loading)
          Padding(
            key: const Key('preview_options_loading'),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Flexible(child: Text(l10n.previewFindingTimes, style: quiet)),
              ],
            ),
          )
        else if (state.optionsLoad == OptionsLoad.error)
          Row(
            key: const Key('preview_options_failed'),
            children: [
              Expanded(
                child: Text(l10n.previewOptionsFailed,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
              TextButton(
                key: const Key('preview_options_retry'),
                onPressed:
                    state.canFindOtherTimes ? cubit.findOtherTimes : null,
                child: Text(l10n.attentionRetry),
              ),
            ],
          )
        else ...[
          if (state.noDifferentFound)
            Padding(
              key: const Key('preview_no_different'),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(l10n.previewNoDifferentTime, style: quiet),
            ),
          if (state.optionsStarted && state.hasMoreOptions)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const Key('preview_more_times'),
                icon: const Icon(Icons.schedule, size: 18),
                label: Text(l10n.previewFindAnotherTime),
                onPressed:
                    state.canFindOtherTimes ? cubit.findOtherTimes : null,
              ),
            ),
        ],
      ],
    );
  }

  // ---- sessions ---------------------------------------------------------------

  /// Split work: every session, the chosen one (the lock target) marked;
  /// choosing a placed one moves the strip and the lock to it.
  List<Widget> _sessions(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final TileSharePreview preview = state.preview!;
    if (preview.sessions.length < 2) return const <Widget>[];
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final String? chosen = state.lockTarget?.sessionKey;
    return [
      const Divider(height: 24),
      Text(l10n.previewSessions,
          key: const Key('preview_sessions'),
          style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      for (int i = 0; i < preview.sessions.length; i++)
        () {
          final PreviewBlock session = preview.sessions[i];
          final String key = session.sessionKey ?? '$i';
          final bool placed = session.isProposed && session.viable;
          final bool selected = placed && key == chosen;
          final String when = placed
              ? (PreviewTiles.isInWindow(session, preview)
                  ? PreviewTiles.when(session, locale)
                  : '${PreviewTiles.when(session, locale)} · '
                      '${l10n.previewSessionOutside}')
              : l10n.previewSessionUnplaced;
          return InkWell(
            key: Key('preview_session_$key'),
            borderRadius: BorderRadius.circular(8),
            onTap: placed && session.sessionKey != null
                ? () => cubit.highlightSession(session.sessionKey!)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    !placed
                        ? Icons.event_busy_outlined
                        : selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                    size: 20,
                    color: !placed
                        ? TileColors.progressMedium
                        : selected
                            ? PreviewTiles.proposedColor
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.previewSessionN(i + 1),
                            style: theme.textTheme.bodyMedium),
                        Text(when,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                      Duration(milliseconds: session.durationMs)
                          .toHumanLocalized(context),
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          );
        }(),
    ];
  }

  // ---- scheduling issues --------------------------------------------------------

  /// Unscheduled work and conflicts, collapsed until asked for; never drawn
  /// on the strip.
  List<Widget> _issues(BuildContext context, TileSharePreview preview) {
    if (preview.conflicts.isEmpty) return const <Widget>[];
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final TextStyle? quiet = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return [
      const Divider(height: 24),
      InkWell(
        key: const Key('preview_issues'),
        onTap: () => setState(() => _issuesOpen = !_issuesOpen),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 20, color: TileColors.progressMedium),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(l10n.previewIssues(preview.conflicts.length),
                      style: theme.textTheme.titleSmall)),
              Icon(_issuesOpen ? Icons.expand_less : Icons.expand_more),
            ],
          ),
        ),
      ),
      AnimatedSize(
        duration: _fade,
        alignment: Alignment.topCenter,
        child: !_issuesOpen
            ? const SizedBox(width: double.infinity)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final PreviewBlock issue in preview.conflicts)
                    () {
                      final (String, String)? window =
                          PreviewTiles.window(issue, locale);
                      return Padding(
                        key: Key('preview_issue_${issue.id}'),
                        padding: const EdgeInsets.fromLTRB(32, 6, 0, 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(issue.name ?? l10n.previewTitleFallback,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(
                                issue.placement == PreviewPlacement.unscheduled
                                    ? l10n.previewIssueUnscheduled
                                    : l10n.previewIssueConflict,
                                style: theme.textTheme.bodySmall),
                            Text(
                                Duration(milliseconds: issue.durationMs)
                                    .toHumanLocalized(context),
                                style: quiet),
                            if (window != null)
                              Text(
                                  l10n.previewIssueWindow(window.$1, window.$2),
                                  style: quiet),
                          ],
                        ),
                      );
                    }(),
                ],
              ),
      ),
    ];
  }

  List<Widget> _details(BuildContext context, TileSharePreview preview) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final ThemeData theme = Theme.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final List<String> lines = <String>[
      if (preview.inviterName != null)
        l10n.clusterRoleFrom(preview.inviterName!),
      if (preview.deadlineMs != null)
        l10n.attentionMetaDue(DateFormat.MMMEd(locale)
            .add_jm()
            .format(DateTime.fromMillisecondsSinceEpoch(preview.deadlineMs!))),
    ];
    // The description is the task's notes: markdown (T27).
    final String notes = (preview.description ?? '').trim();
    if (lines.isEmpty && notes.isEmpty) return const <Widget>[];
    return [
      const Divider(height: 24),
      Text(l10n.previewDetails, style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      for (final String line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(line, style: theme.textTheme.bodyMedium),
        ),
      if (notes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: MarkdownNoteView(markdown: notes),
        ),
    ];
  }

  // ---- unsupported ----------------------------------------------------------------

  List<Widget> _unsupported(BuildContext context, TileSharePreviewState state,
      TileSharePreviewCubit cubit) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TileSharePreview preview = state.preview!;
    final String why = switch (preview.unsupportedReason) {
      PreviewUnsupportedReason.alreadyAccepted =>
        l10n.previewUnsupportedAccepted,
      PreviewUnsupportedReason.missingFutureDeadline =>
        l10n.previewUnsupportedDeadline,
      PreviewUnsupportedReason.unsupportedConstraints =>
        l10n.previewUnsupportedConstraints,
      _ => l10n.previewUnsupportedOther,
    };
    final bool canDecline =
        preview.unsupportedReason != PreviewUnsupportedReason.alreadyAccepted;
    return [
      _Note(
          key: const Key('preview_unsupported'),
          icon: Icons.info_outline,
          text: why),
      const SizedBox(height: 12),
      AnimatedSize(
        duration: _fade,
        alignment: Alignment.topCenter,
        child: state.phase == PreviewPhase.submitting
            ? _submitting(context)
            : _answered(state.phase)
                ? _outcome(context, state, cubit)
                : canDecline
                    ? _decline(context, state, cubit)
                    : const SizedBox.shrink(),
      ),
      ..._details(context, preview),
    ];
  }

  // ---- copy -------------------------------------------------------------------------

  static String _problemText(AppLocalizations l10n, PreviewProblem? problem) =>
      switch (problem) {
        PreviewProblem.gone => l10n.previewGone,
        PreviewProblem.switchedOff => l10n.previewSwitchedOff,
        PreviewProblem.signInAgain => l10n.previewSignIn,
        PreviewProblem.invalidRequest => l10n.previewInvalid,
        PreviewProblem.stale => l10n.previewStale,
        PreviewProblem.sessionInvalid => l10n.previewSessionInvalid,
        _ => l10n.previewLoadFailed,
      };

  static String _reasonText(AppLocalizations l10n, String? reason) =>
      switch (reason) {
        'scheduleChanged' ||
        'invalidProposal' =>
          l10n.previewReasonScheduleChanged,
        'assignmentChanged' || 'alreadyAnswered' => l10n.previewReasonAnswered,
        'previewExpired' => l10n.previewReasonExpired,
        _ => l10n.previewReasonOther,
      };
}

/// One arrangement in the other-times list: when, what it moves, and a clear
/// selected state (an outline and a check - colour is never the only cue).
class _OptionCard extends StatelessWidget {
  final String? label;
  final String when;
  final String detail;
  final bool selected;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    this.label,
    required this.when,
    required this.detail,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Material(
        color: selected
            ? PreviewTiles.proposedColor.withValues(alpha: 0.10)
            : scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color:
                selected ? PreviewTiles.proposedColor : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selected ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (label != null)
                        Text(label!,
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                      Text(when, style: theme.textTheme.bodyMedium),
                      if (detail.isNotEmpty)
                        Text(detail,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      key: Key('preview_option_selected'),
                      color: PreviewTiles.proposedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  final List<Widget> children;

  const _Centered({super.key, required this.children});

  @override
  Widget build(BuildContext context) => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      );
}

/// One line with an icon: a note on the strip, or a state in the sheet.
class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _Note({super.key, required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tone = color ?? theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: tone),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium?.copyWith(color: tone)),
          ),
        ],
      ),
    );
  }
}

/// A problem with the page as a whole, with its one fix when there is one.
class _Banner extends StatelessWidget {
  final String text;
  final Widget? action;

  const _Banner({super.key, required this.text, this.action});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(text,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onErrorContainer)),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
