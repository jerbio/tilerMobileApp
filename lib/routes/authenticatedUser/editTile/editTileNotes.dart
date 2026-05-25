import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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
  bool get hasUnsavedChanges =>
      _state?._controller.text != _state?._lastSavedText;

  /// The text currently shown in the editor (may be dirty).
  String get currentText => _state?._controller.text ?? '';

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
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final NotesApi _notesApi;

  NotesPayload? _payload;
  NotesSaveStatus _status = NotesSaveStatus.idle;
  String? _errorMessage;
  String _lastSavedText = '';
  Timer? _saveTimer;
  // Default to the rendered markdown view when there is content so users
  // see the formatted output (e.g. **bold** rendered as bold). The editor is
  // revealed when they tap the preview or when the note starts empty.
  bool _isPreviewing = true;
  bool _suppressDirty = false;

  // Conflict descriptor: the server payload that rejected our last write.
  NotesPayload? _conflictPayload;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tileNote);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
    _notesApi = widget.notesApi ?? NotesApi(getContextCallBack: () => context);
    _lastSavedText = widget.tileNote;
    final initialPreview =
        widget.previewModeNotifier?.value ?? widget.tileNote.trim().isNotEmpty;
    _isPreviewing = initialPreview;
    widget.previewModeNotifier?.addListener(_handleExternalPreviewToggle);
    _controller.addListener(_onTextChanged);
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

  void _handleExternalPreviewToggle() {
    final wanted = widget.previewModeNotifier?.value ?? _isPreviewing;
    if (wanted == _isPreviewing) return;
    setState(() => _isPreviewing = wanted);
    if (!wanted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleFocusChange() {
    // When the user leaves the editor and there is rendered markdown to
    // show, drop back to preview so the formatting is visible. Skips the
    // flip when the field is empty (we want the editor available for the
    // next keystroke) or while we are still in the middle of a save.
    if (_focusNode.hasFocus) return;
    if (!mounted) return;
    if (widget.isReadOnly || widget.isProcrastinate) return;
    if (_isPreviewing) return;
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isPreviewing = true);
    _syncPreviewNotifier();
  }

  void _syncPreviewNotifier() {
    final n = widget.previewModeNotifier;
    if (n != null && n.value != _isPreviewing) n.value = _isPreviewing;
  }

  void _syncStatusNotifier() {
    final n = widget.statusNotifier;
    if (n != null && n.value != _status) n.value = _status;
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // Mirror status & preview-mode changes out to optional notifiers so a
    // host page (e.g. NoteFullPage) can render them in its own chrome.
    _syncStatusNotifier();
    _syncPreviewNotifier();
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
      _suppressDirty = true;
      _controller.text = widget.tileNote;
      _lastSavedText = widget.tileNote;
      _suppressDirty = false;
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
      _suppressDirty = true;
      _controller.value = TextEditingValue(
        text: serverNote,
        selection: TextSelection.collapsed(offset: serverNote.length),
      );
      _suppressDirty = false;
      setState(() {
        _payload = payload;
        _lastSavedText = serverNote;
        _status = NotesSaveStatus.idle;
        // Show the rendered markdown when the server returns content;
        // otherwise drop straight into the editor so the user can start typing.
        _isPreviewing = serverNote.trim().isNotEmpty;
      });
      widget.onNotePersisted?.call(serverNote);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = NotesSaveStatus.error;
        _errorMessage = e is TilerError ? e.Message : e.toString();
      });
    }
  }

  void _onTextChanged() {
    if (_suppressDirty) return;
    if (widget.isReadOnly || widget.isProcrastinate) return;
    if (_controller.text == _lastSavedText) return;
    setState(() => _status = NotesSaveStatus.dirty);
    _saveTimer?.cancel();
    _saveTimer = Timer(widget.autoSaveDelay, _flushSave);
  }

  Future<void> _flushSave() async {
    final id = widget.eventId;
    if (id == null || id.isEmpty) return;
    final draft = _controller.text;
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
    if (_controller.text == _lastSavedText) {
      if (_status == NotesSaveStatus.dirty) {
        setState(() => _status = NotesSaveStatus.idle);
      }
      return;
    }
    _suppressDirty = true;
    _controller.value = TextEditingValue(
      text: _lastSavedText,
      selection: TextSelection.collapsed(offset: _lastSavedText.length),
    );
    _suppressDirty = false;
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
        _controller.text != _lastSavedText &&
        widget.eventId != null &&
        widget.eventId!.isNotEmpty) {
      // Fire-and-forget: we're tearing down so no UI update is possible.
      _notesApi
          .updateNotes(
            eventId: widget.eventId!,
            userNote: _controller.text,
            etag: _payload?.etag ?? '',
            scope: widget.scope,
          )
          .catchError((_) => _payload ?? NotesPayload());
    }
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    widget.previewModeNotifier?.removeListener(_handleExternalPreviewToggle);
    widget.controller?._detach(this);
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Toolbar actions — operate on the current TextField selection.
  // ---------------------------------------------------------------------------

  void _wrapSelection(String left, String right, {String placeholder = ''}) {
    final value = _controller.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final selectedText =
        selection.isCollapsed ? placeholder : selection.textInside(value.text);
    final newText = value.text.replaceRange(
      selection.start,
      selection.end,
      '$left$selectedText$right',
    );
    final cursor = selection.start + left.length + selectedText.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: cursor),
    );
  }

  void _toggleLinePrefix(String prefix) {
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = selection.end;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    final lines = text.substring(lineStart, lineEnd).split('\n');
    final allPrefixed = lines.every((l) => l.isEmpty || l.startsWith(prefix));
    final newLines = lines.map((l) {
      if (l.isEmpty) return l;
      if (allPrefixed) {
        return l.startsWith(prefix) ? l.substring(prefix.length) : l;
      }
      return '$prefix$l';
    }).toList();
    final newSegment = newLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newSegment);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + newSegment.length),
    );
  }

  void _toggleNumberedList() {
    final value = _controller.value;
    final text = value.text;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: text.length);
    int lineStart = selection.start;
    while (lineStart > 0 && text[lineStart - 1] != '\n') {
      lineStart--;
    }
    int lineEnd = selection.end;
    while (lineEnd < text.length && text[lineEnd] != '\n') {
      lineEnd++;
    }
    final lines = text.substring(lineStart, lineEnd).split('\n');
    final numberPattern = RegExp(r'^\d+\.\s');
    final allNumbered =
        lines.every((l) => l.isEmpty || numberPattern.hasMatch(l));
    int counter = 1;
    final newLines = lines.map((l) {
      if (l.isEmpty) return l;
      if (allNumbered) {
        return l.replaceFirst(numberPattern, '');
      }
      return '${counter++}. $l';
    }).toList();
    final newSegment = newLines.join('\n');
    final newText = text.replaceRange(lineStart, lineEnd, newSegment);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: lineStart + newSegment.length),
    );
  }

  Future<void> _promptLink() async {
    final localizations = AppLocalizations.of(context)!;
    final selection = _controller.selection;
    final selectedText = selection.isValid && !selection.isCollapsed
        ? selection.textInside(_controller.text)
        : '';
    final urlController = TextEditingController(text: 'https://');
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(localizations.notesLinkPromptTitle),
          content: TextField(
            controller: urlController,
            keyboardType: TextInputType.url,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'https://example.com',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(localizations.cancel)),
            TextButton(
                onPressed: () => Navigator.pop(ctx, urlController.text.trim()),
                child: Text(localizations.ok)),
          ],
        );
      },
    );
    if (url == null || url.isEmpty) return;
    final label = selectedText.isEmpty ? url : selectedText;
    final insertion = '[$label]($url)';
    final value = _controller.value;
    final start =
        value.selection.isValid ? value.selection.start : value.text.length;
    final end =
        value.selection.isValid ? value.selection.end : value.text.length;
    final newText = value.text.replaceRange(start, end, insertion);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + insertion.length),
    );
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

    if (widget.fullScreen) {
      // Page-style layout: minimal chrome, generous whitespace, toolbar
      // pinned to the bottom of the canvas like a writing-app would.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!widget.hideHeader) _buildHeader(colorScheme, localizations),
          if (_conflictPayload != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildConflictBanner(colorScheme, localizations),
            ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _isPreviewing
                  ? _buildPreview(colorScheme)
                  : _buildEditor(colorScheme, localizations),
            ),
          ),
          if (!widget.isReadOnly && !_isPreviewing)
            _buildToolbar(colorScheme, localizations),
        ],
      );
    }

    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Container(
        width: 380,
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(colorScheme, localizations),
            if (_conflictPayload != null)
              _buildConflictBanner(colorScheme, localizations),
            if (!widget.isReadOnly && !_isPreviewing)
              _buildToolbar(colorScheme, localizations),
            const SizedBox(height: 8),
            _isPreviewing
                ? _buildPreview(colorScheme)
                : _buildEditor(colorScheme, localizations),
          ],
        ),
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
              tooltip: _isPreviewing
                  ? localizations.notesShowEditor
                  : localizations.notesShowPreview,
              icon: Icon(
                _isPreviewing ? Icons.edit_note : Icons.visibility_outlined,
                size: 20,
              ),
              onPressed: () => setState(() => _isPreviewing = !_isPreviewing),
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
                  _suppressDirty = true;
                  _controller.value = TextEditingValue(
                    text: serverNote,
                    selection:
                        TextSelection.collapsed(offset: serverNote.length),
                  );
                  _suppressDirty = false;
                  setState(() {
                    _lastSavedText = serverNote;
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

  Widget _buildToolbar(
      ColorScheme colorScheme, AppLocalizations localizations) {
    final buttons = <_ToolbarSpec>[
      _ToolbarSpec(Icons.format_bold, localizations.notesToolBold,
          () => _wrapSelection('**', '**')),
      _ToolbarSpec(Icons.format_italic, localizations.notesToolItalic,
          () => _wrapSelection('*', '*')),
      _ToolbarSpec(
          Icons.format_strikethrough,
          localizations.notesToolStrikethrough,
          () => _wrapSelection('~~', '~~')),
      _ToolbarSpec(Icons.code, localizations.notesToolInlineCode,
          () => _wrapSelection('`', '`')),
      _ToolbarSpec(Icons.title, localizations.notesToolHeading1,
          () => _toggleLinePrefix('# ')),
      _ToolbarSpec(Icons.text_fields, localizations.notesToolHeading2,
          () => _toggleLinePrefix('## ')),
      _ToolbarSpec(Icons.format_list_bulleted,
          localizations.notesToolBulletList, () => _toggleLinePrefix('- ')),
      _ToolbarSpec(Icons.format_list_numbered,
          localizations.notesToolNumberedList, _toggleNumberedList),
      _ToolbarSpec(Icons.check_box_outlined, localizations.notesToolTaskList,
          () => _toggleLinePrefix('- [ ] ')),
      _ToolbarSpec(Icons.format_quote, localizations.notesToolQuote,
          () => _toggleLinePrefix('> ')),
      _ToolbarSpec(Icons.link, localizations.notesToolLink, _promptLink),
    ];

    final bar = Material(
      elevation: widget.fullScreen ? 4 : 0,
      color: widget.fullScreen
          ? colorScheme.surface
          : colorScheme.surfaceContainerLowest,
      borderRadius: widget.fullScreen
          ? const BorderRadius.vertical(top: Radius.circular(12))
          : BorderRadius.circular(8),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: buttons
                .map((b) => IconButton(
                      icon: Icon(b.icon, size: 20),
                      tooltip: b.tooltip,
                      onPressed: b.action,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(8),
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ))
                .toList(),
          ),
        ),
      ),
    );
    return bar;
  }

  Widget _buildEditor(ColorScheme colorScheme, AppLocalizations localizations) {
    final field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      minLines: widget.fullScreen ? null : 5,
      maxLines: widget.fullScreen ? null : 12,
      expands: widget.fullScreen,
      textAlignVertical: TextAlignVertical.top,
      textInputAction:
          Platform.isAndroid ? TextInputAction.newline : TextInputAction.done,
      enabled: !widget.isReadOnly,
      style: TextStyle(
        fontFamily: TileTextStyles.rubikFontName,
        fontSize: widget.fullScreen ? 17 : 18,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText: widget.fullScreen
            ? localizations.notesTapToAdd
            : localizations.noteEllipsis,
        hintStyle: TextStyle(
          color: colorScheme.onSurface.withValues(alpha: 0.4),
          fontFamily: TileTextStyles.rubikFontName,
          fontWeight: FontWeight.w400,
        ),
        filled: false,
        isDense: true,
        fillColor: Colors.transparent,
        contentPadding: widget.fullScreen
            ? const EdgeInsets.fromLTRB(24, 20, 24, 24)
            : const EdgeInsets.fromLTRB(20, 15, 20, 15),
        border: widget.fullScreen
            ? InputBorder.none
            : _outlineBorder(colorScheme.primaryContainer, 1),
        focusedBorder: widget.fullScreen
            ? InputBorder.none
            : _outlineBorder(colorScheme.primaryContainer, 2),
        enabledBorder: widget.fullScreen
            ? InputBorder.none
            : _outlineBorder(colorScheme.primaryContainer, 1),
      ),
    );
    if (!widget.fullScreen) return field;
    return Container(
      key: const ValueKey('notes-editor'),
      color: Colors.transparent,
      child: field,
    );
  }

  Widget _buildPreview(ColorScheme colorScheme) {
    final text = _controller.text;
    final canEdit = !widget.isReadOnly && !widget.isProcrastinate;
    final fs = widget.fullScreen;

    final emptyHint = canEdit && fs
        ? AppLocalizations.of(context)!.notesTapToAdd
        : AppLocalizations.of(context)!.notesPreviewEmpty;
    final inner = text.trim().isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              emptyHint,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: fs ? 15 : 14,
              ),
            ),
          )
        // Use `selectable: false` so a tap drops into edit mode instead of
        // being swallowed by text selection.
        : MarkdownBody(data: text, selectable: false);

    final body = Container(
      key: const ValueKey('notes-preview'),
      width: double.infinity,
      constraints: fs
          ? const BoxConstraints.expand()
          : const BoxConstraints(minHeight: 120),
      padding: fs
          ? const EdgeInsets.fromLTRB(24, 20, 24, 24)
          : const EdgeInsets.fromLTRB(20, 15, 20, 15),
      decoration: fs
          ? null
          : BoxDecoration(
              border: Border.all(color: colorScheme.primaryContainer, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
      child: fs ? SingleChildScrollView(child: inner) : inner,
    );
    if (!canEdit) {
      return body;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() => _isPreviewing = false);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _focusNode.requestFocus();
        });
      },
      child: body,
    );
  }

  OutlineInputBorder _outlineBorder(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _ToolbarSpec {
  final IconData icon;
  final String tooltip;
  final VoidCallback action;
  _ToolbarSpec(this.icon, this.tooltip, this.action);
}
