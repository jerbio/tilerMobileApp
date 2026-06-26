import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import 'package:tiler_app/data/notesPayload.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotes.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// Full-screen page that hosts the rich note editor (or a read-only viewer).
///
/// Pushed from [NotePreviewTile] when the user taps (edit) or long-presses
/// (read). Wraps [EditTileNote] in fullScreen mode so the editor expands to
/// the available height. The chrome (save status, preview toggle, Done) is
/// owned by this page so the body itself stays a clean writing canvas.
class NoteFullPage extends StatefulWidget {
  final String? eventId;
  final NotesScope scope;
  final String initialNote;
  final bool isReadOnly;
  final bool isProcrastinate;
  final NotesApi? notesApi;
  final ValueChanged<String>? onNotePersisted;

  const NoteFullPage({
    Key? key,
    required this.eventId,
    this.scope = NotesScope.auto,
    this.initialNote = '',
    this.isReadOnly = false,
    this.isProcrastinate = false,
    this.notesApi,
    this.onNotePersisted,
  }) : super(key: key);

  @override
  State<NoteFullPage> createState() => _NoteFullPageState();
}

class _NoteFullPageState extends State<NoteFullPage> {
  late final ValueNotifier<bool> _previewMode;
  late final ValueNotifier<NotesSaveStatus> _status;
  late final EditTileNoteController _noteController;
  String _latestNote = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _latestNote = widget.initialNote;
    // Read mode lands on preview. Edit mode lands on preview when there is
    // already content (so formatting is visible — tap drops into the editor).
    _previewMode = ValueNotifier<bool>(
        widget.isReadOnly || widget.initialNote.trim().isNotEmpty);
    _status = ValueNotifier<NotesSaveStatus>(NotesSaveStatus.idle);
    _noteController = EditTileNoteController();
  }

  @override
  void dispose() {
    _previewMode.dispose();
    _status.dispose();
    super.dispose();
  }

  /// Back-button handler: throw away any in-progress edits and pop with
  /// whatever was last persisted by the server.
  Future<void> _discardAndPop() async {
    _noteController.discard();
    if (!mounted) return;
    Navigator.of(context).pop(_latestNote);
  }

  /// Explicit Save action: flush the autosave debounce, then pop with the
  /// freshly persisted text.
  Future<void> _saveAndPop() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await _noteController.save();
    if (!mounted) return;
    _latestNote = saved;
    Navigator.of(context).pop(saved);
  }

  String _statusLabel(NotesSaveStatus s, AppLocalizations l) {
    switch (s) {
      case NotesSaveStatus.loading:
        return l.notesLoading;
      case NotesSaveStatus.saving:
        return l.notesSaving;
      case NotesSaveStatus.saved:
        return l.notesSaved;
      case NotesSaveStatus.dirty:
        return l.notesUnsaved;
      case NotesSaveStatus.error:
        return l.notesSaveError;
      case NotesSaveStatus.idle:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final title = widget.isReadOnly
        ? localizations.notesViewerTitle
        : localizations.notesTitle;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) widget.onNotePersisted?.call(_latestNote);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleSpacing: 0,
          // Force full-opacity onSurface for nav/action icons so they read
          // clearly against the pale surface background (the default Material
          // 3 IconTheme inside an AppBar drops alpha which made these look
          // washed-out in light mode).
          iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),
          actionsIconTheme:
              IconThemeData(color: colorScheme.onSurface, size: 24),
          title: ValueListenableBuilder<NotesSaveStatus>(
            valueListenable: _status,
            builder: (context, status, _) {
              final label = _statusLabel(status, localizations);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (label.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status == NotesSaveStatus.saving ||
                              status == NotesSaveStatus.loading)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                status == NotesSaveStatus.saved
                                    ? Icons.check_circle_outline
                                    : status == NotesSaveStatus.error
                                        ? Icons.warning_amber_outlined
                                        : Icons.edit_outlined,
                                size: 12,
                                color: status == NotesSaveStatus.error
                                    ? colorScheme.error
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.55),
                              ),
                            ),
                          Flexible(
                            child: Text(
                              label,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: TileTextStyles.rubikFontName,
                                color: status == NotesSaveStatus.error
                                    ? colorScheme.error
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: _saving ? null : _discardAndPop,
          ),
          actions: [
            if (!widget.isReadOnly && !widget.isProcrastinate)
              ValueListenableBuilder<bool>(
                valueListenable: _previewMode,
                builder: (context, preview, _) => IconButton(
                  tooltip: preview
                      ? localizations.notesShowEditor
                      : localizations.notesShowPreview,
                  icon: Icon(
                    preview ? Icons.edit_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () => _previewMode.value = !preview,
                ),
              ),
            if (!widget.isReadOnly && !widget.isProcrastinate)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: _saving ? null : _saveAndPop,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: _saving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Text(
                          localizations.notesSaveNow,
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: TileTextStyles.rubikFontName,
                          ),
                        ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: EditTileNote(
            eventId: widget.eventId,
            scope: widget.scope,
            tileNote: widget.initialNote,
            isReadOnly: widget.isReadOnly,
            isProcrastinate: widget.isProcrastinate,
            notesApi: widget.notesApi,
            fullScreen: true,
            hideHeader: true,
            controller: _noteController,
            // The previewing screen (NotePreviewTile / tile detail) already
            // hydrated us with the latest note text; skip the redundant GET
            // in that case so the page opens instantly.
            skipInitialLoad: widget.initialNote.trim().isNotEmpty,
            previewModeNotifier: _previewMode,
            statusNotifier: _status,
            onNotePersisted: (note) {
              _latestNote = note;
              widget.onNotePersisted?.call(note);
            },
          ),
        ),
      ),
    );
  }
}

/// Compact, inline summary of a tile's note. Renders a truncated markdown
/// preview, with affordances to:
///  * Tap → open [NoteFullPage] in edit mode.
///  * Long press → open [NoteFullPage] in read-only mode.
///
/// The tile keeps a local cache of the current note text and updates whenever
/// the full page reports a save, so the inline preview stays in sync without
/// any extra round-trips.
class NotePreviewTile extends StatefulWidget {
  final String? eventId;
  final NotesScope scope;
  final String initialNote;
  final bool isReadOnly;
  final bool isProcrastinate;
  final NotesApi? notesApi;
  final ValueChanged<String>? onNotePersisted;
  final int previewLines;

  const NotePreviewTile({
    Key? key,
    required this.eventId,
    this.scope = NotesScope.auto,
    this.initialNote = '',
    this.isReadOnly = false,
    this.isProcrastinate = false,
    this.notesApi,
    this.onNotePersisted,
    this.previewLines = 3,
  }) : super(key: key);

  @override
  State<NotePreviewTile> createState() => _NotePreviewTileState();
}

class _NotePreviewTileState extends State<NotePreviewTile> {
  late String _note;

  @override
  void initState() {
    super.initState();
    _note = widget.initialNote;
  }

  @override
  void didUpdateWidget(covariant NotePreviewTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialNote != widget.initialNote &&
        _note != widget.initialNote) {
      _note = widget.initialNote;
    }
  }

  Future<void> _openFullPage({required bool readOnly}) async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => NoteFullPage(
          eventId: widget.eventId,
          scope: widget.scope,
          initialNote: _note,
          isReadOnly: readOnly || widget.isReadOnly,
          isProcrastinate: widget.isProcrastinate,
          notesApi: widget.notesApi,
          onNotePersisted: (note) {
            _note = note;
            widget.onNotePersisted?.call(note);
            if (mounted) setState(() {});
          },
        ),
      ),
    );
    if (result != null && result != _note) {
      _note = result;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final hasContent = _note.trim().isNotEmpty;
    final canEdit = !widget.isReadOnly && !widget.isProcrastinate;

    final preview = hasContent
        ? ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: 24.0 * widget.previewLines + 12,
            ),
            child: ClipRect(
              child: MarkdownBody(
                data: _note,
                selectable: false,
                shrinkWrap: true,
                softLineBreak: true,
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              canEdit
                  ? localizations.notesTapToAdd
                  : localizations.notesPreviewEmpty,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.55),
                fontFamily: TileTextStyles.rubikFontName,
                fontSize: 15,
              ),
            ),
          );

    final hint = (canEdit && hasContent)
        ? Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              localizations.notesTapToEdit,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
                fontFamily: TileTextStyles.rubikFontName,
              ),
            ),
          )
        : const SizedBox.shrink();

    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _openFullPage(readOnly: !canEdit),
            onLongPress:
                hasContent ? () => _openFullPage(readOnly: true) : null,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                border:
                    Border.all(color: colorScheme.primaryContainer, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_outlined,
                          size: 18,
                          color: colorScheme.onSurface.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Text(
                        localizations.notesTitle,
                        style: TextStyle(
                          fontFamily: TileTextStyles.rubikFontName,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        canEdit ? Icons.chevron_right : Icons.lock_outline,
                        size: 18,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  preview,
                  hint,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
