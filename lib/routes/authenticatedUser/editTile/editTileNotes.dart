import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Save lifecycle of the auto-saving notes editor. Mirrors the
/// `SaveStatus` union used by TilerWeb's `EditNotes` panel.
enum NotesSaveStatus { idle, loading, dirty, saving, saved, error }

/// Lightweight handle a host page can use to trigger an explicit save or to
/// discard in-flight edits (revert the editor to the last persisted text).
/// Attach by passing into [EditTileNote.controller].
class EditTileNoteController {
  _EditTileNoteState? _state;

  void _attach(_EditTileNoteState s) => _state = s;
  void _detach(_EditTileNoteState s) {
    if (identical(_state, s)) _state = null;
  }

  /// Whether the editor currently has unsaved edits.
  bool get hasUnsavedChanges {
    final s = _state;
    if (s == null) return false;
    return s._currentMarkdown != s._lastSavedText;
  }

  /// The text currently shown in the editor (may be dirty).
  String get currentText => _state?._currentMarkdown ?? '';

  /// The last successfully persisted text.
  String get lastSavedText => _state?._lastSavedText ?? '';

  /// Forces an immediate save, bypassing the debounce. Returns the persisted
  /// text (or the last-saved text if no editor is attached).
  Future<String> save() async {
    final s = _state;
    if (s == null) return '';
    await s.saveNow();
    return s._lastSavedText;
  }

  /// Cancels any pending autosave and reverts the editor to the last
  /// persisted text. Safe to call before popping the hosting page when the
  /// user wants to throw away in-progress edits.
  void discard() => _state?._discardEdits();
}

/// Rich-markdown notes editor for a calendar/sub-event tile.
///
/// Mirrors the `EditNotes` panel in TilerWeb:
///  * Auto-loads + auto-saves via [NotesApi] (separate from the regular
///    sub-event update flow).
///  * Markdown formatting toolbar (bold, italic, headings, lists, checklists,
///    quote, code, link).
///  * Optimistic etag handling with a conflict banner offering
///    "discard mine" / "keep editing".
///  * Live preview toggle that renders the markdown via `flutter_markdown`.
///
/// The editing itself is the shared [MarkdownNoteEditor] (T27); this widget
/// adds loading, auto-saving and conflicts on top of it.
class EditTileNote extends StatefulWidget {
  /// Tile id (sub-event id from `EditTile`, calendar event id from
  /// `TileDetail`). When `null` the widget renders as a disabled editor.
  final String? eventId;

  /// Which MiscData blob to target on the server.
  final NotesScope scope;

  /// Initial text shown while the first server payload is loading. Optional —
  /// once the GET resolves it replaces this value.
  final String tileNote;

  /// When `true` the body shows a procrastinate banner instead of an editor.
  final bool isProcrastinate;

  /// When `true` the editor is enabled but cannot be modified.
  final bool isReadOnly;

  /// Optional API override (primarily for tests).
  final NotesApi? notesApi;

  /// Debounce window before flushing a save after the last keystroke.
  final Duration autoSaveDelay;

  /// Notified whenever the persisted note changes (after a successful save or
  /// after the initial load). Useful for keeping the parent screen's cached
  /// `EditTilerEvent.note` in sync so subsequent unrelated updates don't
  /// overwrite the user's text.
  final ValueChanged<String>? onNotePersisted;

  /// When `true` the widget expands to fill the available width and uses a
  /// taller editor surface. Designed for use inside a dedicated note page
  /// (see `NoteFullPage`). When `false` the legacy inline layout is used
  /// (centered, capped at 380px).
  final bool fullScreen;

  /// When `true` the in-body header (status badge + preview toggle) is
  /// suppressed. The hosting page (e.g. `NoteFullPage`) is expected to
  /// render those controls in its own chrome.
  final bool hideHeader;

  /// Optional external control of preview/edit mode. When supplied, the
  /// widget mirrors this notifier in both directions so the host can
  /// render a toggle in its app bar.
  final ValueNotifier<bool>? previewModeNotifier;

  /// Optional outbound status notifier so a host page can render a save
  /// indicator outside the widget tree (e.g. in the app bar subtitle).
  final ValueNotifier<NotesSaveStatus>? statusNotifier;

  /// When `true`, skip the initial GET and trust [tileNote] as the latest
  /// server state. Useful when the hosting screen already loaded the note
  /// (e.g. via the tile detail's eager fetch) to avoid a redundant round
  /// trip. The first save will go out with an empty etag, which the server
  /// treats as a blind write.
  final bool skipInitialLoad;

  /// Optional controller granting the host page imperative access to
  /// [EditTileNoteController.save] and [EditTileNoteController.discard].
  final EditTileNoteController? controller;

  EditTileNote({
    Key? key,
    this.eventId,
    this.scope = NotesScope.auto,
    this.tileNote = '',
    this.isProcrastinate = false,
    this.isReadOnly = false,
    this.notesApi,
    this.autoSaveDelay = const Duration(seconds: 5),
    this.onNotePersisted,
    this.fullScreen = false,
    this.hideHeader = false,
    this.previewModeNotifier,
    this.statusNotifier,
    this.skipInitialLoad = false,
    this.controller,
  }) : super(key: key);

  /// Latest known text. Kept as a back-compat shim for callers that used to
  /// read `widget.note` after each keystroke under the previous
  /// `updateSubEvent`-bound implementation.
  String get note => tileNote;

  @override
  _EditTileNoteState createState() => _EditTileNoteState();
}

class _EditTileNoteState extends State<EditTileNote> {
  final MarkdownNoteEditorController _editor = MarkdownNoteEditorController();
  late final ValueNotifier<bool> _preview;
  late final NotesApi _notesApi;

  NotesPayload? _payload;
  NotesSaveStatus _status = NotesSaveStatus.idle;
  String? _errorMessage;
  String _lastSavedText = '';
  Timer? _saveTimer;

  /// The editor's contents as markdown (the storage format), kept on every
  /// edit so it outlives the editor when this widget is torn down.
  String _draft = '';

  // Conflict descriptor: the server payload that rejected our last write.
  NotesPayload? _conflictPayload;

  /// Current editor contents serialized back to markdown (the storage format).
  String get _currentMarkdown => _draft;

  /// Replaces the editor contents with [markdown] without tripping the dirty
  /// listener.
  void _setDocumentFromMarkdown(String markdown) {
    _editor.setMarkdown(markdown);
    _draft = normalizeNoteMarkdown(markdown);
  }

  @override
  void initState() {
    super.initState();
    _notesApi = widget.notesApi ?? NotesApi(getContextCallBack: () => context);
    // Compare against the round-tripped form so markdown normalization from
    // the converter doesn't register as an unsaved edit on load.
    _draft = normalizeNoteMarkdown(widget.tileNote);
    _lastSavedText = _draft;
    // Default to the rendered markdown view when there is content so users
    // see the formatted output. The editor is revealed when they tap the
    // preview or when the note starts empty.
    _preview = widget.previewModeNotifier ??
        ValueNotifier<bool>(widget.tileNote.trim().isNotEmpty);
    _preview.addListener(_handlePreviewChange);
    widget.controller?._attach(this);
    if (!widget.skipInitialLoad) {
      _loadInitial();
    } else {
      // Caller has already supplied the latest content; just announce idle.
      _status = NotesSaveStatus.idle;
      _syncStatusNotifier();
      // We still need the server's current etag so the first autosave
      // doesn't get rejected as a stale write. Fetch it quietly without
      // touching the editor text or status (so the user can keep typing).
      _primeEtag();
    }
  }

  void _handlePreviewChange() {
    if (mounted) setState(() {});
  }

  void _syncStatusNotifier() {
    final n = widget.statusNotifier;
    if (n != null && n.value != _status) n.value = _status;
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // Mirror status changes out to the optional notifier so a host page
    // (e.g. NoteFullPage) can render them in its own chrome.
    _syncStatusNotifier();
  }

  @override
  void didUpdateWidget(covariant EditTileNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent swapped to a different tile, reload.
    if (oldWidget.eventId != widget.eventId ||
        oldWidget.scope != widget.scope) {
      _saveTimer?.cancel();
      _payload = null;
      _conflictPayload = null;
      _setDocumentFromMarkdown(widget.tileNote);
      _lastSavedText = _currentMarkdown;
      if (!widget.skipInitialLoad) {
        _loadInitial();
      }
    }
  }

  Future<void> _loadInitial() async {
    final id = widget.eventId;
    if (id == null || id.isEmpty || widget.isProcrastinate) {
      setState(() => _status = NotesSaveStatus.idle);
      return;
    }
    setState(() {
      _status = NotesSaveStatus.loading;
      _errorMessage = null;
    });
    try {
      final payload = await _notesApi.getNotes(id, scope: widget.scope);
      if (!mounted) return;
      final serverNote = payload.userNote ?? '';
      _setDocumentFromMarkdown(serverNote);
      setState(() {
        _payload = payload;
        // Compare against the round-tripped form so converter normalization
        // doesn't immediately mark the freshly loaded note as dirty.
        _lastSavedText = _currentMarkdown;
        _status = NotesSaveStatus.idle;
      });
      // Show the rendered markdown when the server returns content;
      // otherwise drop straight into the editor so the user can start typing.
      _preview.value = serverNote.trim().isNotEmpty;
      widget.onNotePersisted?.call(serverNote);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = NotesSaveStatus.error;
        _errorMessage = e is TilerError ? e.Message : e.toString();
      });
    }
  }

  void _onDocumentChanged(String markdown) {
    _draft = markdown;
    if (widget.isReadOnly || widget.isProcrastinate) return;
    if (_currentMarkdown == _lastSavedText) return;
    if (_status != NotesSaveStatus.dirty) {
      setState(() => _status = NotesSaveStatus.dirty);
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(widget.autoSaveDelay, _flushSave);
  }

  Future<void> _flushSave() async {
    final id = widget.eventId;
    if (id == null || id.isEmpty) return;
    final draft = _currentMarkdown;
    if (draft == _lastSavedText) return;
    setState(() {
      _status = NotesSaveStatus.saving;
      _errorMessage = null;
    });
    try {
      final result = await _notesApi.updateNotes(
        eventId: id,
        userNote: draft,
        etag: _payload?.etag ?? '',
        scope: widget.scope,
      );
      if (!mounted) return;
      if (result.concurrencyConflict) {
        setState(() {
          _payload = result;
          _conflictPayload = result;
          _status = NotesSaveStatus.error;
          _errorMessage = AppLocalizations.of(context)!.notesConflictTitle;
        });
        return;
      }
      _lastSavedText = result.userNote ?? draft;
      setState(() {
        _payload = result;
        _status = NotesSaveStatus.saved;
      });
      widget.onNotePersisted?.call(_lastSavedText);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = NotesSaveStatus.error;
        _errorMessage = e is TilerError ? e.Message : e.toString();
      });
    }
  }

  /// Forces an immediate save, bypassing the debounce. Safe to call from
  /// "Save now" buttons or on widget dispose.
  Future<void> saveNow() async {
    _saveTimer?.cancel();
    await _flushSave();
  }

  /// Silently fetch the current server payload just to seed [_payload.etag].
  /// Used when [EditTileNote.skipInitialLoad] is `true` so the first autosave
  /// PUT carries a valid etag and isn't rejected as a stale write.
  ///
  /// Does NOT mutate the editor text, status, or preview mode. If the server
  /// note differs from what the host hydrated us with, the conflict will
  /// surface naturally when the user's edit is sent.
  Future<void> _primeEtag() async {
    final id = widget.eventId;
    if (id == null || id.isEmpty) return;
    if (widget.isReadOnly || widget.isProcrastinate) return;
    try {
      final payload = await _notesApi.getNotes(id, scope: widget.scope);
      if (!mounted) return;
      if (_payload != null) return; // a save already populated it
      _payload = payload;
      // If the server agrees with what the host handed us, also align
      // _lastSavedText so the next dirty-check is accurate.
      final serverNote = payload.userNote ?? '';
      if (serverNote == _lastSavedText) return;
      // Server differs but the user may already be typing — don't clobber
      // their draft. Leave _lastSavedText alone; the etag is what matters
      // for the next PUT.
    } catch (_) {
      // Swallow: a failed prime just means the first save will fall back
      // to the empty-etag path (same as before).
    }
  }

  /// Cancels any pending autosave and reverts the editor to the last
  /// persisted text. Used when the host page wants the back button to mean
  /// "throw away in-progress edits".
  void _discardEdits() {
    _saveTimer?.cancel();
    if (_currentMarkdown == _lastSavedText) {
      if (_status == NotesSaveStatus.dirty) {
        setState(() => _status = NotesSaveStatus.idle);
      }
      return;
    }
    _setDocumentFromMarkdown(_lastSavedText);
    setState(() {
      _status = NotesSaveStatus.idle;
      _errorMessage = null;
      _conflictPayload = null;
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    // Best-effort flush on unmount (mirrors TilerWeb's unmount-flush).
    if (!widget.isReadOnly &&
        !widget.isProcrastinate &&
        _currentMarkdown != _lastSavedText &&
        widget.eventId != null &&
        widget.eventId!.isNotEmpty) {
      // Fire-and-forget: we're tearing down so no UI update is possible.
      _notesApi
          .updateNotes(
            eventId: widget.eventId!,
            userNote: _currentMarkdown,
            etag: _payload?.etag ?? '',
            scope: widget.scope,
          )
          .catchError((_) => _payload ?? NotesPayload());
    }
    _preview.removeListener(_handlePreviewChange);
    if (widget.previewModeNotifier == null) _preview.dispose();
    widget.controller?._detach(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;

    if (widget.isProcrastinate) {
      return _buildProcrastinateBox(
          colorScheme, localizations.procrastinateBlockOut);
    }

    final Widget? banner = _conflictPayload == null
        ? null
        : _buildConflictBanner(colorScheme, localizations);
    final Widget editor = MarkdownNoteEditor(
      initialMarkdown: widget.tileNote,
      onChanged: _onDocumentChanged,
      readOnly: widget.isReadOnly,
      fullScreen: widget.fullScreen,
      controller: _editor,
      previewMode: _preview,
      leading: widget.fullScreen
          ? [
              if (!widget.hideHeader) _buildHeader(colorScheme, localizations),
              if (banner != null)
                Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: banner),
            ]
          : [
              _buildHeader(colorScheme, localizations),
              if (banner != null) banner,
            ],
    );

    if (widget.fullScreen) return editor;

    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Container(
        width: 380,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: editor,
      ),
    );
  }

  Widget _buildProcrastinateBox(ColorScheme colorScheme, String text) {
    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Container(
        width: 380,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: TextFormField(
          minLines: 5,
          maxLines: 10,
          initialValue: text,
          enabled: false,
          style: TextStyle(
            fontFamily: TileTextStyles.rubikFontName,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            filled: true,
            isDense: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
            border: _outlineBorder(colorScheme.primaryContainer, 1),
            enabledBorder: _outlineBorder(colorScheme.primaryContainer, 1),
            disabledBorder: _outlineBorder(colorScheme.primaryContainer, 1),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme, AppLocalizations localizations) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: _buildStatusBadge(colorScheme, localizations)),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.isReadOnly && _status == NotesSaveStatus.dirty)
              TextButton.icon(
                onPressed: saveNow,
                icon: const Icon(Icons.save_outlined, size: 16),
                label: Text(localizations.notesSaveNow),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            IconButton(
              tooltip: _preview.value
                  ? localizations.notesShowEditor
                  : localizations.notesShowPreview,
              icon: Icon(
                _preview.value ? Icons.edit_note : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => _preview.value = !_preview.value,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
      ColorScheme colorScheme, AppLocalizations localizations) {
    IconData? icon;
    String label;
    Color color;
    switch (_status) {
      case NotesSaveStatus.loading:
        icon = null;
        label = localizations.notesLoading;
        color = colorScheme.onSurface.withValues(alpha: 0.6);
        break;
      case NotesSaveStatus.saving:
        icon = null;
        label = localizations.notesSaving;
        color = colorScheme.onSurface.withValues(alpha: 0.6);
        break;
      case NotesSaveStatus.saved:
        icon = Icons.check_circle_outline;
        label = localizations.notesSaved;
        color = colorScheme.primary;
        break;
      case NotesSaveStatus.dirty:
        icon = Icons.edit_outlined;
        label = localizations.notesUnsaved;
        color = colorScheme.onSurface.withValues(alpha: 0.7);
        break;
      case NotesSaveStatus.error:
        icon = Icons.warning_amber_outlined;
        label = _errorMessage ?? localizations.notesSaveError;
        color = colorScheme.error;
        break;
      case NotesSaveStatus.idle:
        return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon == null)
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontFamily: TileTextStyles.rubikFontName,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(
      ColorScheme colorScheme, AppLocalizations localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizations.notesConflictTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontFamily: TileTextStyles.rubikFontName,
              color: colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  final serverNote = _conflictPayload?.userNote ?? '';
                  _setDocumentFromMarkdown(serverNote);
                  setState(() {
                    _lastSavedText = _currentMarkdown;
                    _conflictPayload = null;
                    _status = NotesSaveStatus.saved;
                  });
                  widget.onNotePersisted?.call(serverNote);
                },
                child: Text(localizations.notesConflictDiscardMine),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () {
                  setState(() {
                    _conflictPayload = null;
                    _status = NotesSaveStatus.dirty;
                  });
                },
                child: Text(localizations.notesConflictKeepEditing),
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _outlineBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
