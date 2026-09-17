// Edit Tile redesign — Step 1.4: the shell.
//
// Header, hero, Title, Timing, pinned Save. The screen holds NO editable
// state of its own: everything the user can change lives in
// `EditTileDraft`, and every row is a stateless read of it. What the screen
// does own is lifecycle — loading, submitting — and navigation.
//
// Three things the legacy screen did not have, all pinned by
// `test/editTile/edit_tile_shell_test.dart`:
//
//   * a load with a skeleton, a frame, and a FAILURE with Retry;
//   * a Save whose absence explains itself (the reason is on screen);
//   * a form that is inert while the save is in flight, keeps the draft on
//     failure, and asks before discarding a dirty draft on Back.
//
// Pickers are injectable seams (as `AddTileDurationScreen.pickEndTime`), so
// tests never open a dialog; the defaults are the platform pickers (D42) and
// the shared Duration screen with its Ends row (D61).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/components/thirdPartyDecisionBar.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/adHoc/autoTile.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/nextTileSuggestions.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileActions.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/tileFormSections.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// How long a time / sessions change settles before the what-if preview is
/// asked (Phase 4.3). The legacy screen previewed on every keystroke.
const Duration editTileWhatIfDebounce = Duration(milliseconds: 500);

typedef EditTilePickDate = Future<DateTime?> Function(
    BuildContext context, DateTime seed);
typedef EditTilePickTime = Future<TimeOfDay?> Function(
    BuildContext context, TimeOfDay seed);
typedef EditTilePickDuration = Future<Duration?> Function(
    BuildContext context, Duration seed, DateTime? startTime);

Future<DateTime?> _platformDate(BuildContext context, DateTime seed) =>
    showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: seed.subtract(const Duration(days: 365)),
      lastDate: seed.add(const Duration(days: 365)),
    );

Future<TimeOfDay?> _platformTime(BuildContext context, TimeOfDay seed) =>
    showTimePicker(context: context, initialTime: seed);

Future<Duration?> _durationScreen(
        BuildContext context, Duration seed, DateTime? startTime) =>
    Navigator.of(context).push<Duration>(MaterialPageRoute<Duration>(
      builder: (_) =>
          AddTileDurationScreen(initialDuration: seed, startTime: startTime),
    ));

/// Opens the series (calendar event) screen — `TileDetail`, kept per D1 —
/// for [calendarEventId]. Injected in tests.
typedef EditTileOpenSeries = Future<void> Function(
    BuildContext context, String calendarEventId);

/// Always the redesigned Tile Detail (D25): the two screens ship together.
Future<void> _openTileDetail(BuildContext context, String calendarEventId) =>
    pushTileDetailRedesign(context, calendarEventId);

/// The user-facing reason a draft cannot be saved.
String editTileInvalidReasonText(
    AppLocalizations l10n, EditTileInvalidReason reason) {
  switch (reason) {
    case EditTileInvalidReason.nameRequired:
      return l10n.editTileReasonNameRequired;
    case EditTileInvalidReason.endNotAfterStart:
      return l10n.editTileReasonEndNotAfterStart;
  }
}

class EditTileRedesignScreen extends StatefulWidget {
  const EditTileRedesignScreen({
    super.key,
    required this.tileId,
    required this.loader,
    required this.submission,
    this.source,
    this.thirdPartyUserId,
    this.pickDate = _platformDate,
    this.pickTime = _platformTime,
    this.pickDuration = _durationScreen,
    this.openSeries = _openTileDetail,
  });

  final String tileId;
  final String? source;
  final String? thirdPartyUserId;
  final EditTileLoader loader;
  final EditTileSubmission submission;
  final EditTilePickDate pickDate;
  final EditTilePickTime pickTime;
  final EditTilePickDuration pickDuration;
  final EditTileOpenSeries openSeries;

  @override
  State<EditTileRedesignScreen> createState() => EditTileRedesignScreenState();
}

class EditTileRedesignScreenState extends State<EditTileRedesignScreen> {
  EditTileDraft? draft;
  List<NextTileSuggestion> _suggestions = const <NextTileSuggestion>[];
  String? _loadFailure;
  bool _loading = true;
  bool _submitting = false;

  // RSVP (4.2)
  bool _rsvpProcessing = false;
  String? _rsvpError;

  // What-if (4.3): debounced, single-flight with last-wins. A result is
  // applied only if it answers the LATEST request.
  Timer? _whatIfTimer;
  int _whatIfSequence = 0;
  bool _whatIfPending = false;
  WhatIfResult? _whatIf;

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _whatIfTimer?.cancel();
    draft?.removeListener(_onDraftChanged);
    _titleController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailure = null;
    });
    final EditTileLoadResult result = await widget.loader.load(widget.tileId,
        source: widget.source, thirdPartyUserId: widget.thirdPartyUserId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.failed) {
        _loadFailure = result.reasonCode ?? editTileFailureNetwork;
        return;
      }
      draft?.removeListener(_onDraftChanged);
      draft = EditTileDraft.fromLoaded(result.tile!)
        ..addListener(_onDraftChanged);
      _suggestions = result.suggestions;
      _titleController.text = draft!.name;
    });
  }

  void _onDraftChanged() {
    setState(() {});
    _scheduleWhatIf();
  }

  /// The legacy screen previewed only when a TIME or SPLIT changed and a
  /// save was available; kept. A clean draft clears the line.
  void _scheduleWhatIf() {
    final EditTileDraft? d = draft;
    _whatIfTimer?.cancel();
    if (d == null) return;
    if (!d.timeIsDirty || !d.canSave) {
      if (_whatIf != null || _whatIfPending) {
        setState(() {
          _whatIf = null;
          _whatIfPending = false;
        });
      }
      // Invalidate anything in flight.
      _whatIfSequence++;
      return;
    }
    _whatIfTimer = Timer(editTileWhatIfDebounce, () => _runWhatIf(d));
  }

  Future<void> _runWhatIf(EditTileDraft d) async {
    final int sequence = ++_whatIfSequence;
    setState(() => _whatIfPending = true);
    final WhatIfResult? result = await widget.submission.preview(d);
    if (!mounted || sequence != _whatIfSequence) return; // stale
    setState(() {
      _whatIfPending = false;
      // Every outcome is shown (4.3b): conflicts, a clean answer, or a
      // failed check. A seam that answers null is a failed check.
      _whatIf = result ?? const WhatIfResult.failed();
    });
  }

  /// Retry after a failed check: at once, no debounce.
  void _retryWhatIf() {
    final EditTileDraft? d = draft;
    if (d == null || !d.timeIsDirty || !d.canSave) return;
    _whatIfTimer?.cancel();
    _runWhatIf(d);
  }

  Future<void> _showWhatIf() async {
    final WhatIfResult? result = _whatIf;
    if (result == null || result.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final textTheme = Theme.of(ctx).textTheme;
        Widget group(String title, List<SubCalendarEvent> tiles) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: Text(title,
                      style: textTheme.labelSmall?.copyWith(
                          color: tokens.textSecondary, letterSpacing: 0.6)),
                ),
                for (final SubCalendarEvent t in tiles)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.circle,
                        size: 12, color: t.color ?? tokens.brand),
                    title: Text(t.name ?? ''),
                  ),
              ],
            );
        return SafeArea(
          child: SingleChildScrollView(
            key: const ValueKey('editWhatIfSheet'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Text(l10n.editTileWhatIfSheetTitle,
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (result.tardy.isNotEmpty)
                  group(l10n.editTileWhatIfLate, result.tardy),
                if (result.overflow.isNotEmpty)
                  group(l10n.editTileWhatIfOverflow, result.overflow),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------------ rsvp

  Future<void> _rsvp(RsvpStatus status) async {
    final EditTileDraft d = draft!;
    if (_rsvpProcessing) return;
    setState(() {
      _rsvpProcessing = true;
      _rsvpError = null;
    });
    final EditTileSaveResult result = await widget.submission.rsvp(d, status);
    if (!mounted) return;
    if (result.outcome == EditTileSaveOutcome.success) {
      setState(() => _rsvpProcessing = false);
      // The answer changes what the tile shows; reload rather than patch.
      await _load();
      return;
    }
    setState(() {
      _rsvpProcessing = false;
      _rsvpError = AppLocalizations.of(context)!.editTileRsvpFailed;
    });
  }

  // ----------------------------------------------------------------- edits

  void _onTitleChanged(String value) => draft!.setName(value);

  // Starts and Ends each carry a time chip and a date chip (D24, the web
  // layout). Moving the START — by day or by clock — moves the end by the
  // same amount: the legacy timeline kept the duration, not the end.
  // Moving the END moves the end alone; an end that lands before the
  // start is held and reported by the draft, never silently fixed.

  Future<void> _editStartDate() async {
    final EditTileDraft d = draft!;
    final DateTime? day = await widget.pickDate(context, d.startTime);
    if (day == null || !mounted) return;
    final Duration length = d.endTime.difference(d.startTime);
    final DateTime start = applyPickedDate(d.startTime, day);
    d
      ..setStartTime(start)
      ..setEndTime(start.add(length));
  }

  Future<void> _editStartTime() async {
    final EditTileDraft d = draft!;
    final TimeOfDay? time = await widget.pickTime(
        context, TimeOfDay(hour: d.startTime.hour, minute: d.startTime.minute));
    if (time == null || !mounted) return;
    final Duration length = d.endTime.difference(d.startTime);
    final DateTime start = applyPickedTime(d.startTime, time);
    d
      ..setStartTime(start)
      ..setEndTime(start.add(length));
  }

  Future<void> _editEndDate() async {
    final EditTileDraft d = draft!;
    final DateTime? day = await widget.pickDate(context, d.endTime);
    if (day == null || !mounted) return;
    d.setEndTime(applyPickedDate(d.endTime, day));
  }

  /// The clock moves on the end's OWN day. When that lands at or before
  /// the start (the end was on the start's day and an earlier clock was
  /// picked) the D61 rule applies: the same clock on the next day.
  Future<void> _editEndTime() async {
    final EditTileDraft d = draft!;
    final TimeOfDay? picked = await widget.pickTime(
        context, TimeOfDay(hour: d.endTime.hour, minute: d.endTime.minute));
    if (picked == null || !mounted) return;
    final DateTime onOwnDay = applyPickedTime(d.endTime, picked);
    d.setEndTime(onOwnDay.isAfter(d.startTime)
        ? onOwnDay
        : d.startTime.add(durationForPickedEnd(d.startTime, picked)));
  }

  /// The deadline is a DAY; the value kept is the end of it, as Add Tile's
  /// "complete by" rule.
  Future<void> _editDeadline() async {
    final EditTileDraft d = draft!;
    final DateTime seed = d.deadline ?? d.endTime;
    final DateTime? day = await widget.pickDate(context, seed);
    if (day == null || !mounted) return;
    d.setDeadline(deadlineForPickedDay(day));
  }

  Future<void> _editDuration() async {
    final EditTileDraft d = draft!;
    final Duration? picked = await widget.pickDuration(
        context, d.endTime.difference(d.startTime), d.startTime);
    if (picked == null || !mounted) return;
    d.setEndTime(d.startTime.add(picked));
  }

  /// The series screen may change what this tile shows (its name, colour,
  /// rule), so the draft is reloaded on return — as the legacy app-bar
  /// icon re-dispatched its load.
  Future<void> _openSeries() async {
    final String? id = draft?.original.calendarEvent?.id;
    if (id == null || id.isEmpty) return;
    await widget.openSeries(context, id);
    if (!mounted) return;
    await _load();
  }

  Future<void> _openNotes() async {
    final EditTileDraft d = draft!;
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) => NoteFullPage(
        eventId: d.original.id ?? '',
        initialNote: d.note ?? '',
        isReadOnly: d.mode != EditTileMode.editable,
        isProcrastinate: d.mode == EditTileMode.procrastinate,
        onNotePersisted: (String note) {
          // Notes persist themselves (D13); mirror the value for the row.
          if (mounted) setState(() => d.original.noteData?.note = note);
        },
      ),
    ));
  }

  // ------------------------------------------------------------------ save

  Future<void> _save() async {
    final EditTileDraft? d = draft;
    if (d == null || _submitting || !d.canSave) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    final EditTileSaveResult result = await widget.submission.save(d);
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result.outcome) {
      case EditTileSaveOutcome.success:
        Navigator.of(context).pop(result.tile);
        return;
      case EditTileSaveOutcome.nothingToSave:
        return;
      case EditTileSaveOutcome.failure:
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          key: const ValueKey('editTileSaveError'),
          content: Text(l10n.editTileSaveFailed),
          action: SnackBarAction(label: l10n.addTileRetry, onPressed: _save),
        ));
    }
  }

  // --------------------------------------------------------------- actions

  /// An action POSTs immediately and closes the screen, independent of Save
  /// (D2, as the legacy buttons did). A dirty draft is discarded, and the
  /// confirmation says so.
  Future<void> _runAction(EditTileAction action) async {
    final EditTileDraft d = draft!;
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final String title = d.name.trim().isEmpty ? l10n.tileName : d.name.trim();
    final String question;
    switch (action) {
      case EditTileAction.complete:
        question = l10n.editTileActionConfirmComplete(title);
      case EditTileAction.startNow:
        question = l10n.editTileActionConfirmStartNow(title);
      case EditTileAction.defer:
        question = l10n.editTileActionConfirmDefer(title);
      case EditTileAction.delete:
        question = l10n.editTileActionConfirmDelete(title);
    }
    final List<String> body = <String>[
      if (action == EditTileAction.delete) l10n.editTileActionDeleteBody,
      if (d.isDirty) l10n.editTileActionDiscardsEdits,
    ];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(question),
        content: body.isEmpty ? null : Text(body.join('\n\n')),
        actions: [
          TextButton(
            key: const ValueKey('editActionCancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('editActionConfirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_actionLabel(l10n, action)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    Duration? deferBy;
    if (action == EditTileAction.defer) {
      // A deferral is a LENGTH, so the wheel is opened without a start and
      // shows no Ends row.
      deferBy =
          await widget.pickDuration(context, const Duration(hours: 1), null);
      if (deferBy == null || !mounted) return;
    }

    setState(() => _submitting = true);
    final SubCalendarEvent tile = d.original;
    final EditTileSaveResult result = switch (action) {
      EditTileAction.complete => await widget.submission.complete(tile),
      EditTileAction.startNow => await widget.submission.startNow(tile),
      EditTileAction.defer => await widget.submission.defer(tile, deferBy!),
      EditTileAction.delete => await widget.submission.delete(tile),
    };
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.outcome == EditTileSaveOutcome.success) {
      Navigator.of(context).pop(result.tile);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      key: const ValueKey('editTileActionError'),
      content: Text(l10n.editTileActionFailed),
    ));
  }

  /// "Create as new tile" hands the suggestion to Add Tile with a prefill.
  ///
  /// Through the flagged `/AddTile` entry, not the direct redesign route,
  /// so it obeys the same rollout as every other way in (D65); the entry
  /// passes the `preTile` to whichever screen renders.
  void _createFromSuggestion(NextTileSuggestion suggestion) {
    Navigator.of(context).pushNamed(
      '/AddTile',
      arguments: <String, dynamic>{
        'preTile': AutoTile(description: suggestion.name ?? ''),
      },
    );
  }

  // ------------------------------------------------------------------ back

  Future<bool> _confirmLeave() async {
    final EditTileDraft? d = draft;
    if (d == null || !d.isDirty) return true;
    final l10n = AppLocalizations.of(context)!;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.editTileDiscardTitle),
        content: Text(l10n.editTileDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.editTileKeepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.editTileDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _onBack() async {
    if (await _confirmLeave() && mounted) Navigator.of(context).pop();
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final EditTileDraft? d = draft;
    final String title = (d?.isRigid ?? false)
        ? l10n.editTileTitleBlock
        : l10n.editTileTitleTile;
    final bool hasSeries = d != null &&
        d.original.isFromTiler &&
        (d.original.calendarEvent?.id ?? '').isNotEmpty;

    return PopScope(
      canPop: d == null || !d.isDirty,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          title: Text(title),
          // ✕, not a back arrow (mockup); same discard rule as Back.
          leading: IconButton(
            key: const ValueKey('editTileClose'),
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: _onBack,
          ),
          actions: [
            // The top-right button IS the hand-off to the series — one tap,
            // no menu (2026-09-16; the ⋯ once also duplicated Delete). The
            // stacked-layers glyph reads as "the whole series behind this
            // occurrence" without implying repetition; the tooltip names it.
            if (d != null && hasSeries)
              IconButton(
                key: const ValueKey('editTileDetails'),
                icon: const Icon(Icons.layers_outlined),
                tooltip: l10n.editTileMenuTileDetails,
                onPressed: _openSeries,
              ),
          ],
        ),
        body: _loading
            ? const TileLoadSkeleton(sweepKey: ValueKey('editTileLoadingSweep'))
            : _loadFailure != null
                ? TileLoadFailure(
                    retryKey: const ValueKey('editTileRetryLoad'),
                    message: l10n.editTileLoadFailed,
                    onRetry: _load)
                : _Frame(
                    draft: d!,
                    submitting: _submitting,
                    titleController: _titleController,
                    titleFocus: _titleFocus,
                    onTitleChanged: _onTitleChanged,
                    suggestions: _suggestions,
                    onStartDateTap: _editStartDate,
                    onStartTimeTap: _editStartTime,
                    onEndDateTap: _editEndDate,
                    onEndTimeTap: _editEndTime,
                    onDurationTap: _editDuration,
                    onDeadlineTap: _editDeadline,
                    onAction: _runAction,
                    onSuggestionTap: _createFromSuggestion,
                    onNotesTap: _openNotes,
                    onProgressTap: _openSeries,
                    onSave: _save,
                    rsvpProcessing: _rsvpProcessing,
                    rsvpError: _rsvpError,
                    onRsvp: _rsvp,
                    whatIf: _whatIf,
                    whatIfPending: _whatIfPending,
                    onWhatIfTap: _showWhatIf,
                    onWhatIfRetry: _retryWhatIf,
                  ),
      ),
    );
  }
}

String _actionLabel(AppLocalizations l10n, EditTileAction a) {
  switch (a) {
    case EditTileAction.complete:
      return l10n.editTileActionComplete;
    case EditTileAction.startNow:
      return l10n.editTileActionStartNow;
    case EditTileAction.defer:
      return l10n.editTileActionDefer;
    case EditTileAction.delete:
      return l10n.editTileActionDelete;
  }
}

String _actionCaption(AppLocalizations l10n, EditTileAction a) {
  switch (a) {
    case EditTileAction.complete:
      return l10n.editTileActionCompleteCaption;
    case EditTileAction.startNow:
      return l10n.editTileActionStartNowCaption;
    case EditTileAction.defer:
      return l10n.editTileActionDeferCaption;
    case EditTileAction.delete:
      return l10n.editTileActionDeleteCaption;
  }
}

IconData _actionIcon(EditTileAction a) {
  switch (a) {
    case EditTileAction.complete:
      return Icons.check_rounded;
    case EditTileAction.startNow:
      return Icons.play_arrow_rounded;
    case EditTileAction.defer:
      return Icons.arrow_forward_rounded;
    case EditTileAction.delete:
      return Icons.delete_outline_rounded;
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.draft,
    required this.submitting,
    required this.titleController,
    required this.titleFocus,
    required this.suggestions,
    required this.onTitleChanged,
    required this.onStartDateTap,
    required this.onStartTimeTap,
    required this.onEndDateTap,
    required this.onEndTimeTap,
    required this.onDurationTap,
    required this.onDeadlineTap,
    required this.onAction,
    required this.onSuggestionTap,
    required this.onNotesTap,
    required this.onProgressTap,
    required this.onSave,
    required this.rsvpProcessing,
    required this.rsvpError,
    required this.onRsvp,
    required this.whatIf,
    required this.whatIfPending,
    required this.onWhatIfTap,
    required this.onWhatIfRetry,
  });

  final EditTileDraft draft;
  final bool submitting;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final List<NextTileSuggestion> suggestions;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onStartDateTap;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndDateTap;
  final VoidCallback onEndTimeTap;
  final VoidCallback onDurationTap;
  final VoidCallback onDeadlineTap;
  final ValueChanged<EditTileAction> onAction;
  final ValueChanged<NextTileSuggestion> onSuggestionTap;
  final VoidCallback onNotesTap;
  final VoidCallback onProgressTap;
  final VoidCallback onSave;
  final bool rsvpProcessing;
  final String? rsvpError;
  final ValueChanged<RsvpStatus> onRsvp;
  final WhatIfResult? whatIf;
  final bool whatIfPending;
  final VoidCallback onWhatIfTap;
  final VoidCallback onWhatIfRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final EditTileInvalidReason? reason = draft.invalidReason;
    final String? hint = draft.isDirty && reason != null
        ? editTileInvalidReasonText(l10n, reason)
        : null;
    final SubCalendarEvent original = draft.original;
    final bool isEditable = draft.mode == EditTileMode.editable;
    // ONE rule for locking, not per-widget flags (plan §1.7): a read-only
    // or provider-owned tile has no editable row; a blocked-out tile keeps
    // its time editable and only its title fixed.
    final bool rowsLocked = draft.mode == EditTileMode.readOnly ||
        draft.mode == EditTileMode.thirdParty;
    final bool titleLocked =
        rowsLocked || draft.mode == EditTileMode.procrastinate;
    final bool showSave = !rowsLocked;
    final bool showRsvp = draft.mode == EditTileMode.thirdParty &&
        const <RsvpStatus>{
          RsvpStatus.needsAction,
          RsvpStatus.tentative,
          RsvpStatus.accepted,
          RsvpStatus.declined,
        }.contains(original.rsvp);
    final String? banner = switch (draft.mode) {
      EditTileMode.editable => null,
      EditTileMode.readOnly => l10n.editTileModeReadOnly,
      EditTileMode.procrastinate => l10n.editTileModeProcrastinate,
      EditTileMode.thirdParty => l10n.editTileModeThirdParty(
          original.thirdpartyType == TileSource.outlook
              ? l10n.editTileProviderOutlook
              : l10n.editTileProviderGoogle),
    };
    final bool showDeadline = original.isRecurring == true && isEditable;
    final bool showNotes = original.isFromTiler;
    final CalendarEvent? series = original.calendarEvent is CalendarEvent
        ? original.calendarEvent as CalendarEvent
        : null;
    final bool showProgress =
        !draft.isRigid && original.isFromTiler && series != null;
    final List<EditTileAction> actions = editTileActionsFor(draft);

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            text,
            style: textTheme.labelSmall
                ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6),
          ),
        );

    final List<Widget> timing = <Widget>[
      // Starts and Ends on ONE line (requested 2026-09-14), each with its
      // own time row and date row (D24 — the web edit form, in the form
      // kit's idiom).
      _TimeSpanRow(
        key: const ValueKey('editSpanRow'),
        start: _SpanCell(
          key: const ValueKey('editStartRow'),
          timeKey: const ValueKey('editStartTime'),
          dateKey: const ValueKey('editStartDate'),
          label: l10n.addTileFieldStarts,
          time: formatClockTime(draft.startTime),
          date: DateFormat.yMMMEd().format(draft.startTime),
          onTimeTap: rowsLocked ? null : onStartTimeTap,
          onDateTap: rowsLocked ? null : onStartDateTap,
        ),
        end: _SpanCell(
          key: const ValueKey('editEndRow'),
          timeKey: const ValueKey('editEndTime'),
          dateKey: const ValueKey('editEndDate'),
          label: l10n.addTileFieldEnds,
          time: formatClockTime(draft.endTime),
          date: DateFormat.yMMMEd().format(draft.endTime),
          onTimeTap: rowsLocked ? null : onEndTimeTap,
          onDateTap: rowsLocked ? null : onEndDateTap,
        ),
      ),
      AddTileFieldRow(
        key: const ValueKey('editDurationRow'),
        icon: Icons.hourglass_empty_rounded,
        label: l10n.addTileFieldDuration,
        value: formatDurationSummary(
                l10n, draft.endTime.difference(draft.startTime)) ??
            '',
        onTap: rowsLocked ? null : onDurationTap,
      ),
      if (showDeadline)
        AddTileFieldRow(
          key: const ValueKey('editDeadlineRow'),
          icon: Icons.flag_outlined,
          label: l10n.editTileFieldDeadline,
          value: draft.deadline == null
              ? l10n.addTileValueNotSet
              : DateFormat.yMMMEd().format(draft.deadline!),
          onTap: onDeadlineTap,
        ),
    ];

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (submitting)
                const Positioned.fill(
                    child:
                        AddTilePendingSweep(key: ValueKey('editTileSaveSweep')))
              // While the what-if check runs the whole form sweeps behind
              // the fields, as Add Tile's prediction does (D63) — the form
              // stays live; the sweep ignores pointers.
              else if (whatIfPending)
                const Positioned.fill(
                    child:
                        AddTilePendingSweep(key: ValueKey('editWhatIfSweep'))),
              ExcludeFocus(
                excluding: submitting,
                child: AbsorbPointer(
                  absorbing: submitting,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (banner != null) ...[
                        AddTileCallout(
                          key: const ValueKey('editModeBanner'),
                          icon: draft.mode == EditTileMode.thirdParty
                              ? Icons.link_rounded
                              : Icons.info_outline_rounded,
                          text: banner,
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (showRsvp) ...[
                        AddTileSection(children: [
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: ThirdPartyDecisionBar(
                              source: original.thirdpartyType,
                              rsvpStatus: original.rsvp,
                              isProcessing: rsvpProcessing,
                              errorText: rsvpError,
                              onAccept: () => onRsvp(RsvpStatus.accepted),
                              onDecline: () => onRsvp(RsvpStatus.declined),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 14),
                      ],
                      // The hero IS the title editor (2026-09-15): a pencil
                      // to the left of the title focuses it. The former
                      // Title and Type rows repeated what the hero shows.
                      TileHero(
                        keyPrefix: 'edit',
                        name: draft.name,
                        isRigid: draft.isRigid,
                        note: draft.note,
                        lockedTitle: draft.mode == EditTileMode.procrastinate
                            ? l10n.procrastinateBlockOut
                            : draft.name,
                        locked: titleLocked,
                        titleController: titleController,
                        titleFocus: titleFocus,
                        onTitleChanged: onTitleChanged,
                      ),
                      heading(l10n.editTileSectionTiming),
                      AddTileSection(children: timing),
                      if (whatIfPending)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AddTileCallout(
                            key: const ValueKey('editWhatIfPending'),
                            icon: Icons.hourglass_top_rounded,
                            text: l10n.editTileWhatIfChecking,
                          ),
                        )
                      else if (whatIf != null && whatIf!.failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AddTileCallout(
                            key: const ValueKey('editWhatIfFailed'),
                            icon: Icons.info_outline_rounded,
                            text: l10n.editTileWhatIfFailed,
                            action: AddTileCalloutAction(
                              key: const ValueKey('editWhatIfRetry'),
                              label: l10n.editTileWhatIfRetry,
                              onTap: onWhatIfRetry,
                            ),
                          ),
                        )
                      else if (whatIf != null && whatIf!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: AddTileCallout(
                            key: const ValueKey('editWhatIfClean'),
                            icon: Icons.check_circle_outline_rounded,
                            text: l10n.editTileWhatIfClean,
                          ),
                        )
                      else if (whatIf != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Semantics(
                            key: const ValueKey('editWhatIfLine'),
                            button: true,
                            liveRegion: true,
                            onTap: onWhatIfTap,
                            label: l10n.editTileWhatIfSummary(
                                whatIf!.tardy.length, whatIf!.overflow.length),
                            child: ExcludeSemantics(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: onWhatIfTap,
                                child: AddTileCallout(
                                  icon: Icons.warning_amber_rounded,
                                  text: l10n.editTileWhatIfSummary(
                                      whatIf!.tardy.length,
                                      whatIf!.overflow.length),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (actions.isNotEmpty) ...[
                        heading(l10n.editTileSectionActions),
                        _ActionsCard(
                          key: const ValueKey('editActions'),
                          actions: actions,
                          onAction: onAction,
                        ),
                      ],
                      if (showNotes) ...[
                        heading(l10n.editTileSectionAdditional),
                        AddTileSection(children: [
                          AddTileNavRow(
                            key: const ValueKey('editNotesRow'),
                            icon: Icons.notes_rounded,
                            title: l10n.editTileNotesTitle,
                            subtitle: (draft.note ?? '').trim().isEmpty
                                ? l10n.addTileValueNotSet
                                : draft.note!.trim(),
                            // A preview: the full note is on the notes page.
                            subtitleMaxLines: 3,
                            onTap: onNotesTap,
                          ),
                        ]),
                      ],
                      if (suggestions.isNotEmpty) ...[
                        heading(l10n.editTileSectionSuggestions),
                        AddTileSection(
                          key: const ValueKey('editSuggestions'),
                          children: [
                            for (final NextTileSuggestion s in suggestions)
                              AddTileNavRow(
                                icon: Icons.auto_awesome_outlined,
                                title: s.name ?? '',
                                subtitle: l10n.editTileCreateAsNewTile,
                                onTap: () => onSuggestionTap(s),
                              ),
                          ],
                        ),
                      ],
                      if (showProgress) ...[
                        heading(l10n.editTileSectionProgress),
                        AddTileSection(children: [
                          _ProgressRow(
                            key: const ValueKey('editProgress'),
                            series: series,
                            onTap: onProgressTap,
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showSave)
          AddTilePrimaryButton(
            key: const ValueKey('editTileSave'),
            label: l10n.editTileSave,
            busyLabel: l10n.editTileSaving,
            enabled: draft.canSave,
            busy: submitting,
            hint: hint,
            onTap: onSave,
          ),
      ],
    );
  }
}

/// Four equal tiles; two-by-two under 320pt.
class _ActionsCard extends StatelessWidget {
  const _ActionsCard(
      {super.key, required this.actions, required this.onAction});
  final List<EditTileAction> actions;
  final ValueChanged<EditTileAction> onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    Color tint(EditTileAction a) {
      switch (a) {
        case EditTileAction.complete:
          return Colors.green;
        case EditTileAction.startNow:
          return tokens.brand;
        case EditTileAction.defer:
          return tokens.textSecondary;
        case EditTileAction.delete:
          return scheme.error;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final int perRow = constraints.maxWidth < 300 ? 2 : actions.length;
        final double width = constraints.maxWidth / perRow;
        return Wrap(
          children: [
            for (final EditTileAction a in actions)
              SizedBox(
                width: width,
                child: Semantics(
                  key: ValueKey('editAction_${a.name}'),
                  button: true,
                  onTap: () => onAction(a),
                  label: l10n.editTileActionSemantics(
                      _actionLabel(l10n, a), _actionCaption(l10n, a)),
                  child: ExcludeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onAction(a),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: tint(a).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_actionIcon(a), color: tint(a)),
                            ),
                            const SizedBox(height: 8),
                            Text(_actionLabel(l10n, a),
                                textAlign: TextAlign.center,
                                style: textTheme.labelLarge?.copyWith(
                                    color: a == EditTileAction.delete
                                        ? scheme.error
                                        : tokens.textPrimary)),
                            Text(_actionCaption(l10n, a),
                                textAlign: TextAlign.center,
                                style: textTheme.labelSmall
                                    ?.copyWith(color: tokens.textSecondary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}

/// The series counts, as `TileProgress` computes them.
class _ProgressRow extends StatelessWidget {
  const _ProgressRow({super.key, required this.series, required this.onTap});
  final CalendarEvent series;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final int total = series.split ?? 0;
    final int done = series.completeCount ?? 0;
    final int deleted = series.deleteCount ?? 0;
    final int remaining = (total - done - deleted).clamp(0, total);
    final double fraction = total == 0 ? 0 : (done / total).clamp(0, 1);
    return Semantics(
      button: true,
      onTap: onTap,
      label: '${l10n.editTileProgressComplete(done, total)}, '
          '${l10n.editTileProgressRemaining(remaining, deleted)}',
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 5,
                    backgroundColor: tokens.surfaceSubtle,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.editTileProgressComplete(done, total),
                          style: textTheme.titleSmall?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight: FontWeight.w600)),
                      Text(l10n.editTileProgressRemaining(remaining, deleted),
                          style: textTheme.bodySmall
                              ?.copyWith(color: tokens.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: tokens.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Starts and Ends side by side. Two compact cells — label, a time row, a
/// date row; no icon chip — so they fit a 320pt phone. They stack only
/// when a cell would have less than ~130pt at the current text scale.
class _TimeSpanRow extends StatelessWidget {
  const _TimeSpanRow({super.key, required this.start, required this.end});
  final _SpanCell start;
  final _SpanCell end;

  @override
  Widget build(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final bool stack = constraints.maxWidth < 260 * scale;
      if (stack) return Column(children: [start, end]);
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: start),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(child: end),
          ],
        ),
      );
    });
  }
}

/// One side of the span, in the form kit's own idiom (no pills, no
/// outlines): the uppercase label, then two plain rows — the time (bold,
/// as a field value) over the date — each a button with the kit's trailing
/// chevron, separated by the kit's hairline. A locked cell keeps both rows
/// and loses the taps and chevrons.
class _SpanCell extends StatelessWidget {
  const _SpanCell({
    super.key,
    required this.timeKey,
    required this.dateKey,
    required this.label,
    required this.time,
    required this.date,
    required this.onTimeTap,
    required this.onDateTap,
  });
  final Key timeKey;
  final Key dateKey;
  final String label;
  final String time;
  final String date;
  final VoidCallback? onTimeTap;
  final VoidCallback? onDateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Text(label,
              style: textTheme.labelSmall
                  ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6)),
        ),
        _SpanValueRow(
          key: timeKey,
          text: time,
          semanticLabel: l10n.editTileTimeChipSemantics(label, time),
          style: textTheme.titleMedium?.copyWith(
              color: tokens.textPrimary, fontWeight: FontWeight.w600),
          onTap: onTimeTap,
        ),
        Divider(height: 1, thickness: 1, indent: 14, color: tokens.cardBorder),
        _SpanValueRow(
          key: dateKey,
          text: date,
          semanticLabel: l10n.editTileDateChipSemantics(label, date),
          style: textTheme.bodyMedium?.copyWith(color: tokens.textPrimary),
          onTap: onDateTap,
        ),
      ],
    );
  }
}

/// A value row inside a span cell: text, trailing chevron when tappable.
/// Same node shape as `AddTileFieldRow` (D62): the tap lives on the
/// Semantics node, the InkWell is excluded.
class _SpanValueRow extends StatelessWidget {
  const _SpanValueRow({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.style,
    required this.onTap,
  });
  final String text;
  final String semanticLabel;
  final TextStyle? style;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final bool enabled = onTap != null;
    final Widget content = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: style),
            ),
            if (enabled)
              Icon(Icons.chevron_right, size: 20, color: tokens.textSecondary),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      button: enabled,
      onTap: onTap,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: enabled
            ? Material(
                color: Colors.transparent,
                child: InkWell(onTap: onTap, child: content),
              )
            : content,
      ),
    );
  }
}

/// Route-argument adapter for the debug entry `/EditTileRedesign`.
class EditTileRedesignRouteArgs {
  const EditTileRedesignRouteArgs({
    required this.tileId,
    this.source,
    this.thirdPartyUserId,
  });
  final String tileId;
  final String? source;
  final String? thirdPartyUserId;

  static EditTileRedesignRouteArgs? from(Object? arguments) {
    if (arguments is EditTileRedesignRouteArgs) return arguments;
    if (arguments is Map) {
      final Object? id = arguments['tileId'];
      if (id is String) {
        return EditTileRedesignRouteArgs(
          tileId: id,
          source: arguments['source'] as String?,
          thirdPartyUserId: arguments['thirdPartyUserId'] as String?,
        );
      }
    }
    return null;
  }
}
