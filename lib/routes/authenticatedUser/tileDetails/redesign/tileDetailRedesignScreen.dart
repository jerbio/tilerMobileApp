// Tile Detail redesign — Step 6.3: the shell.
//
// The calendar-event editor, on the Add Tile form kit, the shape of
// `EditTileRedesignScreen`: a loader and a submission seam, ONE draft the
// widgets read from, a skeleton while loading, a pinned Save that names
// why it is disabled, a discard confirm on the way out, ✕ and ⋯.
//
// 6.3 hosts the hero (editable title), the mode banner, the Duration row
// and Save; 6.4 the series sections — Sessions, Repetition, Priority,
// Location, then Colour, Preferred time and Notes under Additional
// Details — on the shared widgets and the shared Add Tile pickers. The
// occurrences list is 6.5, the route drop-in 6.6.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileEntry.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/redesignLog.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileDraft.dart'
    show EditTileDraft, EditTileMode;
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/editTileSubmission.dart'
    show EditTileSaveOutcome;
import 'package:tiler_app/routes/authenticatedUser/editTile/redesign/tileFormSections.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileTimeRestrictionScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/redesign/tileDetailSubmission.dart';
import 'package:tiler_app/routes/authenticatedUser/tileDetails/subEventPaging.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// What Tile details pops with after deleting the series. Distinct from a
/// save (which pops the updated `CalendarEvent`) so a caller that opened
/// this screen for ONE occurrence knows that occurrence is gone too and
/// must not reload it (2026-09-17).
class TileDetailDeleted {
  const TileDetailDeleted(this.event);

  /// What the delete endpoint answered, if anything.
  final CalendarEvent? event;
}

typedef TileDetailPickDuration = Future<Duration?> Function(
    BuildContext context, Duration seed);
typedef TileDetailPickDate = Future<DateTime?> Function(
    BuildContext context, DateTime seed);

Future<DateTime?> _platformDate(BuildContext context, DateTime seed) =>
    showDatePicker(
      context: context,
      initialDate: seed,
      firstDate: seed.subtract(const Duration(days: 365)),
      lastDate: seed.add(const Duration(days: 365 * 5)),
    );

/// The Add Tile duration wheel, with no start time: this is the length of
/// EVERY occurrence, not of one.
Future<Duration?> _durationScreen(BuildContext context, Duration seed) =>
    Navigator.of(context).push<Duration>(MaterialPageRoute<Duration>(
      builder: (_) => AddTileDurationScreen(initialDuration: seed),
    ));

typedef TileDetailPickRepeat = Future<RepeatPickerResult?> Function(
    BuildContext context, RepetitionData? seed);
typedef TileDetailPickLocation = Future<Location?> Function(
    BuildContext context, Location? seed);
typedef TileDetailPickColor = Future<ColorChoice?> Function(
    BuildContext context, Color? seed);

/// Null = the screen was backed out of; a result with a null profile is a
/// confirmed Anytime.
typedef TileDetailPickRestriction = Future<TimeRestrictionResult?> Function(
    BuildContext context, RestrictionProfile? seed);
typedef TileDetailOpenNotes = Future<void> Function(
    BuildContext context, TileDetailNotesRequest request);

/// What the notes page needs: the series id, calendar scope, whether it
/// is read-only, and where a persisted note goes (mirrored, D13).
class TileDetailNotesRequest {
  const TileDetailNotesRequest({
    required this.eventId,
    required this.initialNote,
    required this.readOnly,
    required this.onPersisted,
  });
  final String eventId;
  final String initialNote;
  final bool readOnly;
  final ValueChanged<String> onPersisted;
  NotesScope get scope => NotesScope.calendar;
}

/// The section pickers, bundled so the constructor stays readable. Each
/// defaults to the shared screen; tests script them. Location and the
/// place editor need an [AddTileLocationSource]; without one (and without
/// a seam) those rows do nothing.
class TileDetailPickers {
  const TileDetailPickers({
    this.pickRepeat = _repeatScreen,
    this.pickLocation,
    this.editPlace,
    this.pickColor = _colorScreen,
    this.pickRestriction = _restrictionRoute,
    this.openNotes = _notesPage,
  });

  final TileDetailPickRepeat pickRepeat;
  final TileDetailPickLocation? pickLocation;
  final TileDetailPickLocation? editPlace;
  final TileDetailPickColor pickColor;
  final TileDetailPickRestriction pickRestriction;
  final TileDetailOpenNotes openNotes;

  static Future<RepeatPickerResult?> _repeatScreen(
          BuildContext context, RepetitionData? seed) =>
      Navigator.of(context).push<RepeatPickerResult>(
        MaterialPageRoute<RepeatPickerResult>(
          builder: (_) =>
              AddTileRepeatScreen(now: DateTime.now(), initialRepetition: seed),
        ),
      );

  static Future<ColorChoice?> _colorScreen(BuildContext context, Color? seed) =>
      Navigator.of(context).push<ColorChoice>(
        MaterialPageRoute<ColorChoice>(
          builder: (_) => AddTileColorScreen(initialColor: seed),
        ),
      );

  /// Phase 6: the same Time restrictions screen as Add Tile (one editor,
  /// D25's rule), over the user's named profiles. Back returns null;
  /// Done — including a confirmed Anytime — returns a result.
  static Future<TimeRestrictionResult?> _restrictionRoute(
          BuildContext context, RestrictionProfile? seed) =>
      Navigator.of(context).push<TimeRestrictionResult>(
          MaterialPageRoute<TimeRestrictionResult>(
              builder: (BuildContext _) => AddTileTimeRestrictionScreen(
                  initial: seed,
                  source: CachedRestrictionProfileSource(
                      ApiAddTileRestrictionProfileSource(
                          settingsApi: SettingsApi(
                              getContextCallBack: () => context))))));

  static Future<void> _notesPage(
          BuildContext context, TileDetailNotesRequest r) =>
      Navigator.of(context).push<void>(MaterialPageRoute<void>(
        builder: (_) => NoteFullPage(
          eventId: r.eventId,
          scope: r.scope,
          initialNote: r.initialNote,
          isReadOnly: r.readOnly,
          onNotePersisted: r.onPersisted,
        ),
      ));
}

/// Opens one occurrence in Edit Tile; resolves with whatever the edit
/// screen pops (the saved tile, or null). Injected in tests.
typedef TileDetailOpenOccurrence = Future<Object?> Function(
    BuildContext context, SubCalendarEvent occurrence);

Future<Object?> _openEditTile(BuildContext context, SubCalendarEvent sub) =>
    Navigator.of(context).push<Object?>(MaterialPageRoute<Object?>(
      builder: (_) => EditTileRoute(
        tileId: sub.id ?? '',
        tileSource: sub.thirdpartyType,
        thirdPartyUserId: sub.thirdPartyUserId,
      ),
    ));

/// The user-facing reason a draft cannot be saved.
String tileDetailInvalidReasonText(
    AppLocalizations l10n, TileDetailInvalidReason reason) {
  switch (reason) {
    case TileDetailInvalidReason.nameRequired:
      return l10n.editTileReasonNameRequired;
    case TileDetailInvalidReason.splitRequired:
      return l10n.editTileReasonSplitRequired;
    case TileDetailInvalidReason.deadlineNotAfterStart:
      return l10n.editTileReasonEndNotAfterStart;
  }
}

class TileDetailRedesignScreen extends StatefulWidget {
  /// Exactly one of [calendarEventId] / [designatedTileTemplateId]: the
  /// calendar event to edit, or the tile-share template whose event the
  /// server resolves (`TileDetail.byDesignatedTileId`).
  const TileDetailRedesignScreen({
    super.key,
    this.calendarEventId,
    this.designatedTileTemplateId,
    required this.loader,
    required this.submission,
    this.pickDuration = _durationScreen,
    this.pickDate = _platformDate,
    this.pickers = const TileDetailPickers(),
    this.locationSource,
    this.occurrences,
    this.openOccurrence = _openEditTile,
  });

  final String? calendarEventId;
  final String? designatedTileTemplateId;

  TileDetailTarget get target => calendarEventId != null
      ? TileDetailTarget.calendarEvent(calendarEventId!)
      : TileDetailTarget.designatedTile(designatedTileTemplateId ?? '');

  final TileDetailLoader loader;
  final TileDetailSubmission submission;
  final TileDetailPickDuration pickDuration;
  final TileDetailPickDate pickDate;
  final TileDetailPickers pickers;

  /// Backs the default Location picker and place editor.
  final AddTileLocationSource? locationSource;

  /// The paged occurrences (6.5). Null hides the section.
  final TileDetailOccurrences? occurrences;
  final TileDetailOpenOccurrence openOccurrence;

  @override
  State<TileDetailRedesignScreen> createState() =>
      TileDetailRedesignScreenState();
}

class TileDetailRedesignScreenState extends State<TileDetailRedesignScreen> {
  TileDetailDraft? draft;
  String? _loadFailure;
  bool _loading = true;
  bool _submitting = false;

  // Occurrences (6.5): the legacy paging model, owned here so the list
  // survives an edit-and-return.
  final SubEventPaging _paging = SubEventPaging();
  bool _occurrencesLoading = false;
  bool _occurrencesFailed = false;
  bool _occurrencesLoaded = false;

  final TextEditingController _titleController = TextEditingController();
  final FocusNode _titleFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
    final TileDetailLoadResult result = await widget.loader.load(widget.target);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.failed) {
        _loadFailure = result.reasonCode ?? 'network_timeout';
        return;
      }
      draft?.removeListener(_onDraftChanged);
      draft =
          TileDetailDraft.fromLoaded(result.event!, location: result.location)
            ..addListener(_onDraftChanged);
      _titleController.text = draft!.name;
    });
    final TileDetailDraft? d = draft;
    if (!result.failed && d != null && !d.isProviderOwned) {
      _loadOccurrences();
    }
  }

  void _onDraftChanged() => setState(() {});

  /// The LOADED event's id — what occurrences, saves and logs address.
  /// (A template target has no event id until the load answers.)
  String get _eventId => draft?.id ?? widget.calendarEventId ?? '';

  // ----------------------------------------------------------- occurrences

  Future<void> _loadOccurrences() async {
    final TileDetailOccurrences? source = widget.occurrences;
    if (source == null) return;
    setState(() {
      _occurrencesLoading = true;
      _occurrencesFailed = false;
    });
    try {
      final List<SubCalendarEvent> first = await source.initial(_eventId);
      if (!mounted) return;
      setState(() {
        _paging.setInitial(first);
        _occurrencesLoaded = true;
        _occurrencesLoading = false;
      });
    } catch (e, st) {
      RedesignLog.event('tile_detail_occurrences_failed',
          <String, Object?>{'calendarEventId': _eventId},
          error: e, stack: st);
      if (!mounted) return;
      setState(() {
        _occurrencesFailed = true;
        _occurrencesLoading = false;
      });
    }
  }

  /// A follow-up page; a failure closes that direction quietly, as the
  /// legacy prefetch did.
  Future<void> _loadOccurrencesAfter() async {
    final TileDetailOccurrences? source = widget.occurrences;
    if (source == null || !_paging.canLoadAfter) return;
    setState(() => _paging.isLoadingAfter = true);
    try {
      final List<SubCalendarEvent> page =
          await source.after(_eventId, _paging.rightCursorId!);
      if (!mounted) return;
      setState(() {
        _paging.appendPage(page);
        _paging.isLoadingAfter = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paging.hasMoreAfter = false;
        _paging.isLoadingAfter = false;
      });
    }
  }

  Future<void> _loadOccurrencesBefore() async {
    final TileDetailOccurrences? source = widget.occurrences;
    if (source == null || !_paging.canLoadBefore) return;
    setState(() => _paging.isLoadingBefore = true);
    try {
      final List<SubCalendarEvent> page =
          await source.before(_eventId, _paging.leftCursorId!);
      if (!mounted) return;
      setState(() {
        _paging.prependPage(page);
        _paging.isLoadingBefore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paging.hasMoreBefore = false;
        _paging.isLoadingBefore = false;
      });
    }
  }

  /// An edit that saved pops its tile; the list is reloaded so the moved
  /// occurrence shows where it now is. A dismissed edit keeps the list.
  Future<void> _openOccurrence(SubCalendarEvent sub) async {
    RedesignLog.event('tile_detail_occurrence_opened', <String, Object?>{
      'calendarEventId': _eventId,
      'tileId': sub.id,
      'source': sub.thirdpartyType?.name,
      'hasThirdPartyUserId': sub.thirdPartyUserId.isNotEmpty,
    });
    final Object? result = await widget.openOccurrence(context, sub);
    if (!mounted || result == null) return;
    await _loadOccurrences();
  }

  // ----------------------------------------------------------------- edits

  void _onTitleChanged(String value) => draft!.setName(value);

  Future<void> _editDuration() async {
    final TileDetailDraft d = draft!;
    final Duration? picked = await widget.pickDuration(
        context, d.duration ?? const Duration(hours: 1));
    if (picked == null || !mounted) return;
    d.setDuration(picked);
  }

  /// The deadline is a DAY; the value kept is the end of it, as Add Tile's
  /// "complete by" rule.
  Future<void> _editDeadline() async {
    final TileDetailDraft d = draft!;
    // Anytime seeds the picker on today.
    final DateTime? day = await widget.pickDate(
        context, d.deadline ?? deadlineForPickedDay(DateTime.now()));
    if (day == null || !mounted) return;
    d.setDeadline(deadlineForPickedDay(day));
  }

  Future<void> _editRepeat() async {
    final TileDetailDraft d = draft!;
    final RepeatPickerResult? result =
        await widget.pickers.pickRepeat(context, d.repetition);
    // Back is not an answer; a confirmed "Does not repeat" is (Add Tile D39).
    if (result == null || !mounted) return;
    d.setRepetition(result.repetition);
  }

  Future<void> _editLocation() async {
    final TileDetailDraft d = draft!;
    final TileDetailPickLocation? seam = widget.pickers.pickLocation;
    final Location? picked;
    if (seam != null) {
      picked = await seam(context, d.location);
    } else {
      final AddTileLocationSource? source = widget.locationSource;
      if (source == null) return;
      picked = await Navigator.of(context).push<Location>(
        MaterialPageRoute<Location>(
          builder: (_) => AddTileLocationScreen(
              source: source, initialLocation: d.location),
        ),
      );
    }
    if (picked == null || !mounted) return;
    d.setLocation(picked);
  }

  /// Names the chosen place — the Add Tile flow: an affordance on the
  /// chosen value, never a step every selection pays for.
  Future<void> _nameLocation() async {
    final TileDetailDraft d = draft!;
    if (d.location == null) return;
    final TileDetailPickLocation? seam = widget.pickers.editPlace;
    final Location? picked;
    if (seam != null) {
      picked = await seam(context, d.location);
    } else {
      final AddTileLocationSource? source = widget.locationSource;
      if (source == null) return;
      picked = await Navigator.of(context).push<Location>(
        MaterialPageRoute<Location>(
          builder: (_) => AddTilePlaceEditorScreen(
            source: source,
            initialName: d.location?.description,
            initialAddress: d.location?.address,
            original: d.location,
          ),
        ),
      );
    }
    if (picked == null || !mounted) return;
    d.setLocation(picked);
  }

  Future<void> _editColor() async {
    final TileDetailDraft d = draft!;
    final ColorChoice? choice =
        await widget.pickers.pickColor(context, d.color);
    if (choice == null || !choice.made || !mounted) return;
    d.setColor(choice.color);
  }

  /// A dismissed screen changes nothing; a confirmed Anytime is a null
  /// profile.
  Future<void> _editRestriction() async {
    final TileDetailDraft d = draft!;
    final TimeRestrictionResult? result =
        await widget.pickers.pickRestriction(context, d.restrictionProfile);
    if (result == null || !mounted) return;
    d.setRestrictionProfile(result.profile);
  }

  Future<void> _openNotes() async {
    final TileDetailDraft d = draft!;
    await widget.pickers.openNotes(
      context,
      TileDetailNotesRequest(
        eventId: d.id ?? '',
        initialNote: d.note ?? '',
        readOnly: d.mode != EditTileMode.editable,
        // Notes persist themselves (D13); mirror the value for the row
        // and the next save.
        onPersisted: (String note) {
          if (mounted) d.mirrorNote(note);
        },
      ),
    );
  }

  // ------------------------------------------------------------------ save

  Future<void> _save() async {
    final TileDetailDraft? d = draft;
    if (d == null || _submitting || !d.canSave) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _submitting = true);
    final TileDetailSaveResult result = await widget.submission.save(d);
    if (!mounted) return;
    setState(() => _submitting = false);
    switch (result.outcome) {
      case EditTileSaveOutcome.success:
        Navigator.of(context).pop(result.event);
        return;
      case EditTileSaveOutcome.nothingToSave:
        return;
      case EditTileSaveOutcome.failure:
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          key: const ValueKey('detailSaveError'),
          content: Text(l10n.tileDetailSaveFailed),
          action: SnackBarAction(label: l10n.addTileRetry, onPressed: _save),
        ));
    }
  }

  // ---------------------------------------------------------------- delete

  /// Removes the whole series (every occurrence). Confirms first, and says
  /// so when a dirty draft would be discarded with it (D2).
  Future<void> _deleteSeries() async {
    final TileDetailDraft d = draft!;
    if (_submitting) return;
    final l10n = AppLocalizations.of(context)!;
    final String title = d.name.trim().isEmpty ? l10n.tileName : d.name.trim();
    final List<String> body = <String>[
      l10n.tileDetailDeleteBody,
      if (d.isDirty) l10n.editTileActionDiscardsEdits,
    ];
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.tileDetailDeleteConfirm(title)),
        content: Text(body.join('\n\n')),
        actions: [
          TextButton(
            key: const ValueKey('detailDeleteCancel'),
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            key: const ValueKey('detailDeleteConfirm'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.editTileActionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    final TileDetailSaveResult result = await widget.submission.deleteSeries(d);
    if (!mounted) return;
    setState(() => _submitting = false);
    if (result.outcome == EditTileSaveOutcome.success) {
      Navigator.of(context).pop(TileDetailDeleted(result.event));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      key: const ValueKey('detailDeleteError'),
      content: Text(l10n.tileDetailDeleteFailed),
    ));
  }

  // ----------------------------------------------------------------- leave

  Future<bool> _confirmLeave() async {
    final TileDetailDraft? d = draft;
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
    final TileDetailDraft? d = draft;

    return PopScope(
      canPop: d == null || !d.isDirty,
      onPopInvokedWithResult: (bool didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        backgroundColor: tokens.background,
        appBar: AppBar(
          title: Text(l10n.tileDetailTitle),
          leading: IconButton(
            key: const ValueKey('detailClose'),
            icon: const Icon(Icons.close),
            tooltip: l10n.close,
            onPressed: _onBack,
          ),
          actions: [
            if (d != null)
              PopupMenuButton<String>(
                key: const ValueKey('detailMenu'),
                tooltip: l10n.editTileMoreMenu,
                icon: const Icon(Icons.more_horiz),
                onSelected: (String item) {
                  if (item == 'delete') _deleteSeries();
                },
                itemBuilder: (_) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    key: const ValueKey('detailMenuDelete'),
                    value: 'delete',
                    child: Text(l10n.tileDetailDeleteSeries),
                  ),
                ],
              ),
          ],
        ),
        body: _loading
            ? const TileLoadSkeleton(sweepKey: ValueKey('detailLoadingSweep'))
            : _loadFailure != null
                ? TileLoadFailure(
                    retryKey: const ValueKey('detailRetryLoad'),
                    message: l10n.tileDetailLoadFailed,
                    onRetry: _load)
                : _Frame(
                    draft: d!,
                    submitting: _submitting,
                    titleController: _titleController,
                    titleFocus: _titleFocus,
                    onTitleChanged: _onTitleChanged,
                    onDurationTap: _editDuration,
                    onDeadlineTap: _editDeadline,
                    onDeadlineClear: () => draft!.setDeadline(null),
                    onRepeatTap: _editRepeat,
                    onLocationTap: _editLocation,
                    onNameLocationTap: _nameLocation,
                    onColorTap: _editColor,
                    onRestrictionTap: _editRestriction,
                    onNotesTap: _openNotes,
                    onSave: _save,
                    occurrences: widget.occurrences == null || d.isProviderOwned
                        ? null
                        : _OccurrencesView(
                            items: _paging.orderedItems,
                            loading: _occurrencesLoading,
                            failed: _occurrencesFailed,
                            loaded: _occurrencesLoaded,
                            canEarlier: _paging.hasMoreBefore,
                            canLater: _paging.hasMoreAfter,
                            loadingEarlier: _paging.isLoadingBefore,
                            loadingLater: _paging.isLoadingAfter,
                            onRetry: _loadOccurrences,
                            onEarlier: _loadOccurrencesBefore,
                            onLater: _loadOccurrencesAfter,
                            onOpen: _openOccurrence,
                          ),
                  ),
      ),
    );
  }
}

class _Frame extends StatelessWidget {
  const _Frame({
    required this.draft,
    required this.submitting,
    required this.titleController,
    required this.titleFocus,
    required this.onTitleChanged,
    required this.onDurationTap,
    required this.onDeadlineTap,
    required this.onDeadlineClear,
    required this.onRepeatTap,
    required this.onLocationTap,
    required this.onNameLocationTap,
    required this.onColorTap,
    required this.onRestrictionTap,
    required this.onNotesTap,
    required this.onSave,
    required this.occurrences,
  });

  final TileDetailDraft draft;
  final bool submitting;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final ValueChanged<String> onTitleChanged;
  final VoidCallback onDurationTap;
  final VoidCallback onDeadlineTap;
  final VoidCallback onDeadlineClear;
  final VoidCallback onRepeatTap;
  final VoidCallback onLocationTap;
  final VoidCallback onNameLocationTap;
  final VoidCallback onColorTap;
  final VoidCallback onRestrictionTap;
  final VoidCallback onNotesTap;
  final VoidCallback onSave;

  /// Null: no section (no source, or a provider series).
  final _OccurrencesView? occurrences;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final TileDetailInvalidReason? reason = draft.invalidReason;
    final String? hint = draft.isDirty && reason != null
        ? tileDetailInvalidReasonText(l10n, reason)
        : null;
    // ONE rule for locking (plan §1.7): a finished or provider-owned
    // series has no editable row; a blocked-out one keeps its rows and
    // only its title fixed, as Edit Tile.
    final bool rowsLocked = draft.mode == EditTileMode.readOnly ||
        draft.mode == EditTileMode.thirdParty;
    final bool titleLocked =
        rowsLocked || draft.mode == EditTileMode.procrastinate;
    // A block is one session; a blocked-out or locked series is not
    // re-split here.
    final bool showSessions = !draft.isRigid &&
        draft.mode != EditTileMode.procrastinate &&
        !rowsLocked;
    final String? banner = switch (draft.mode) {
      EditTileMode.editable => null,
      EditTileMode.readOnly => l10n.editTileModeReadOnly,
      EditTileMode.procrastinate => l10n.editTileModeProcrastinate,
      EditTileMode.thirdParty => l10n.editTileModeThirdParty(
          draft.original.thirdpartyType == TileSource.outlook
              ? l10n.editTileProviderOutlook
              : l10n.editTileProviderGoogle),
    };

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            text,
            style: textTheme.labelSmall
                ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6),
          ),
        );

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              if (submitting)
                const Positioned.fill(
                    child:
                        AddTilePendingSweep(key: ValueKey('detailSaveSweep'))),
              ExcludeFocus(
                excluding: submitting,
                child: AbsorbPointer(
                  absorbing: submitting,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (banner != null) ...[
                        AddTileCallout(
                          key: const ValueKey('detailModeBanner'),
                          icon: draft.mode == EditTileMode.thirdParty
                              ? Icons.link_rounded
                              : Icons.info_outline_rounded,
                          text: banner,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TileHero(
                        keyPrefix: 'detail',
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
                      heading(l10n.addTileFieldDuration),
                      AddTileSection(children: [
                        AddTileFieldRow(
                          key: const ValueKey('detailDurationRow'),
                          icon: Icons.hourglass_empty_rounded,
                          label: l10n.addTileFieldDuration,
                          value: draft.duration == null
                              ? l10n.addTileValueNotSet
                              : formatDurationSummary(l10n, draft.duration!) ??
                                  '',
                          valueIsPlaceholder: draft.duration == null,
                          onTap: rowsLocked ? null : onDurationTap,
                        ),
                        // A non-repeating series is ended by its deadline;
                        // a repeating one by its rule (2026-09-17).
                        if (draft.repetition == null)
                          AddTileFieldRow(
                            key: const ValueKey('detailDeadlineRow'),
                            icon: Icons.flag_outlined,
                            label: l10n.editTileFieldDeadline,
                            // Anytime = no deadline (Add Tile's wording).
                            value: draft.deadline == null
                                ? l10n.anytime
                                : DateFormat.yMMMEd().format(draft.deadline!),
                            onTap: rowsLocked ? null : onDeadlineTap,
                            // Back to Anytime: the date picker cannot answer
                            // "no date" (Add Tile D64).
                            trailing: draft.deadline == null || rowsLocked
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Semantics(
                                        key: const ValueKey(
                                            'detailDeadlineClear'),
                                        container: true,
                                        button: true,
                                        label: l10n.addTileDeadlineClear,
                                        onTap: onDeadlineClear,
                                        child: ExcludeSemantics(
                                          child: IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: onDeadlineClear,
                                          ),
                                        ),
                                      ),
                                      Icon(Icons.chevron_right,
                                          color: tokens.textSecondary),
                                    ],
                                  ),
                          ),
                      ]),
                      if (showSessions) ...[
                        heading(l10n.editTileSectionSessions),
                        AddTileSection(children: [
                          TileSessionsRow(
                            keyPrefix: 'detail',
                            count: draft.split,
                            onChanged: draft.setSplit,
                          ),
                        ]),
                      ],
                      heading(l10n.editTileSectionRepetition),
                      TileRepeatSection(
                        keyPrefix: 'detail',
                        rule: draft.repetition,
                        onTap: rowsLocked ? null : onRepeatTap,
                      ),
                      heading(l10n.editTileSectionPriority),
                      TilePriorityCards(
                        keyPrefix: 'detail',
                        selected: draft.priority,
                        onSelected: rowsLocked ? null : draft.setPriority,
                      ),
                      heading(l10n.editTileSectionLocation),
                      AddTileSection(children: [
                        TileLocationRow(
                          keyPrefix: 'detail',
                          location: draft.location,
                          onTap: rowsLocked ? null : onLocationTap,
                          onClear: draft.clearLocation,
                          onName: onNameLocationTap,
                        ),
                      ]),
                      heading(l10n.editTileSectionAdditional),
                      AddTileSection(children: [
                        TileColorRow(
                          keyPrefix: 'detail',
                          color: draft.color,
                          onTap: rowsLocked ? null : onColorTap,
                        ),
                        AddTileFieldRow(
                          key: const ValueKey('detailRestrictionRow'),
                          icon: Icons.schedule_outlined,
                          label: l10n.addTileFieldPreferredTime,
                          value: _restrictionSummary(
                              l10n, draft.restrictionProfile),
                          onTap: rowsLocked ? null : onRestrictionTap,
                        ),
                        AddTileNavRow(
                          key: const ValueKey('detailNotesRow'),
                          icon: Icons.notes_rounded,
                          title: l10n.editTileNotesTitle,
                          subtitle: draft.note ?? l10n.addTileValueNotSet,
                          subtitleMaxLines: 3,
                          onTap: onNotesTap,
                        ),
                      ]),
                      if (occurrences != null) ...[
                        heading(l10n.tileDetailSectionOccurrences),
                        _OccurrencesSection(view: occurrences!),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!rowsLocked)
          AddTilePrimaryButton(
            key: const ValueKey('detailSave'),
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

/// Anytime / Morning / Afternoon / Evening for a simple profile, Custom
/// for anything else — the Add Tile vocabulary.
String _restrictionSummary(AppLocalizations l10n, RestrictionProfile? p) {
  final PreferredTimeOfDay? part = preferredTimeOfProfile(p);
  return part == null
      ? l10n.addTilePreferredTimeCustom
      : preferredTimeLabel(l10n, part);
}

/// What the occurrences section renders: the paging model's view plus
/// the load states, carried as plain values so the section is stateless.
class _OccurrencesView {
  const _OccurrencesView({
    required this.items,
    required this.loading,
    required this.failed,
    required this.loaded,
    required this.canEarlier,
    required this.canLater,
    required this.loadingEarlier,
    required this.loadingLater,
    required this.onRetry,
    required this.onEarlier,
    required this.onLater,
    required this.onOpen,
  });
  final List<SubCalendarEvent> items;
  final bool loading;
  final bool failed;
  final bool loaded;
  final bool canEarlier;
  final bool canLater;
  final bool loadingEarlier;
  final bool loadingLater;
  final VoidCallback onRetry;
  final VoidCallback onEarlier;
  final VoidCallback onLater;
  final ValueChanged<SubCalendarEvent> onOpen;
}

/// The occurrences as kit rows: day · time span · Done, sorted by start,
/// with Show earlier / Show later rows while more may exist.
class _OccurrencesSection extends StatelessWidget {
  const _OccurrencesSection({required this.view});
  final _OccurrencesView view;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    Widget line(Key key, String text, {Widget? trailing}) => Padding(
          key: key,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(children: [
            Expanded(
              child: Text(text,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: tokens.textSecondary)),
            ),
            if (trailing != null) trailing,
          ]),
        );

    Widget pager(Key key, String label, bool busy, VoidCallback onTap) =>
        AddTileNavRow(
          key: key,
          icon: Icons.unfold_more_rounded,
          title: label,
          onTap: busy ? null : onTap,
          trailing: busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : null,
        );

    if (view.loading && !view.loaded) {
      return AddTileSection(children: [
        SizedBox(
          key: const ValueKey('detailOccurrencesLoading'),
          height: 96,
          child: const AddTilePendingSweep(),
        ),
      ]);
    }
    if (view.failed && !view.loaded) {
      return AddTileSection(children: [
        line(const ValueKey('detailOccurrencesFailedLine'),
            l10n.tileDetailOccurrencesFailed,
            trailing: TextButton(
              key: const ValueKey('detailOccurrencesRetry'),
              onPressed: view.onRetry,
              child: Text(l10n.addTileRetry),
            )),
      ]);
    }
    if (view.items.isEmpty) {
      return AddTileSection(children: [
        line(const ValueKey('detailOccurrencesEmpty'),
            l10n.tileDetailOccurrencesEmpty),
      ]);
    }
    return AddTileSection(children: [
      if (view.canEarlier)
        pager(
            const ValueKey('detailOccurrencesEarlier'),
            l10n.tileDetailOccurrencesEarlier,
            view.loadingEarlier,
            view.onEarlier),
      for (final SubCalendarEvent sub in view.items)
        _OccurrenceRow(sub: sub, onTap: () => view.onOpen(sub)),
      if (view.canLater)
        pager(const ValueKey('detailOccurrencesLater'),
            l10n.tileDetailOccurrencesLater, view.loadingLater, view.onLater),
    ]);
  }
}

class _OccurrenceRow extends StatelessWidget {
  const _OccurrenceRow({required this.sub, required this.onTap});
  final SubCalendarEvent sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String day = DateFormat.MMMEd().format(sub.startTime);
    final String span =
        '${formatClockTime(sub.startTime)} – ${formatClockTime(sub.endTime)}';
    final bool done = sub.isComplete;
    return AddTileFieldRow(
      key: ValueKey('detailOccurrence_${sub.id}'),
      icon: done ? Icons.check_circle_outline_rounded : Icons.event_outlined,
      mutedIcon: done,
      label: day,
      value: done ? '$span · ${l10n.tileDetailOccurrenceDone}' : span,
      semanticLabel: l10n.tileDetailOccurrenceSemantics(
          day, span, done ? ', ${l10n.tileDetailOccurrenceDone}' : ''),
      onTap: onTap,
    );
  }
}
