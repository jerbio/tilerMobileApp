import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:markdown_quill/markdown_quill.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';

/// The longest note a form accepts, counted on the stored markdown (T27).
const int defaultNoteMaxLength = 5000;

/// A note's length as it is stored: the markdown, formatting included.
int markdownNoteLength(String markdown) => markdown.length;

/// Markdown parser shared by all note editors. GitHub-flavored so checklists,
/// strikethrough and fenced code blocks round-trip through the Quill document.
final md.Document _markdownDocument = md.Document(
  encodeHtml: false,
  extensionSet: md.ExtensionSet.gitHubFlavored,
);

final MarkdownToDelta _markdownToDelta =
    MarkdownToDelta(markdownDocument: _markdownDocument);

// `relaxed` only escapes markdown control characters inside formatted spans,
// so plain prose like "in-progress + notes" round-trips without backslash
// noise polluting the stored note.
final DeltaToMarkdown _deltaToMarkdown = DeltaToMarkdown(
  customContentHandler: DeltaToMarkdown.escapeSpecialCharactersRelaxed,
);

/// Builds a Quill [Document] from a markdown string. Empty/whitespace input
/// yields an empty document (Quill cannot build a document from an empty
/// delta), and any conversion failure falls back to treating the text as a
/// plain paragraph so the user never loses their note.
Document markdownToNoteDocument(String markdown) {
  if (markdown.trim().isEmpty) return Document();
  try {
    final delta = _markdownToDelta.convert(markdown);
    if (delta.isEmpty) return Document();
    return Document.fromDelta(delta);
  } catch (_) {
    final doc = Document();
    doc.insert(0, markdown);
    return doc;
  }
}

/// Serializes a Quill [Document] back to markdown for persistence. The
/// converter appends a trailing newline; we trim it so the stored value
/// matches what the user sees.
String noteDocumentToMarkdown(Document document) {
  try {
    return _deltaToMarkdown.convert(document.toDelta()).trimRight();
  } catch (_) {
    return document.toPlainText().trimRight();
  }
}

/// [markdown] as the editor will store it, so a note just loaded is not
/// mistaken for an edit when the converter normalizes it.
String normalizeNoteMarkdown(String markdown) =>
    noteDocumentToMarkdown(markdownToNoteDocument(markdown));

/// Imperative access to a [MarkdownNoteEditor]: the current markdown, and
/// replacing it (e.g. with the server's copy) without reporting an edit.
class MarkdownNoteEditorController {
  _MarkdownNoteEditorState? _state;

  /// The note as markdown, as it would be stored.
  String get markdown => _state?._markdown ?? '';

  /// Replaces the note without calling [MarkdownNoteEditor.onChanged].
  void setMarkdown(String markdown) => _state?._setMarkdown(markdown);
}

/// The rich markdown note editor (redesign T27), shared by tile notes and the
/// TileShare forms. It edits and previews; it never saves - the host does
/// (tile notes auto-save, a form keeps a draft).
///
///  * Edits in Quill with a toolbar limited to what round-trips to markdown;
///    reports every edit as markdown through [onChanged].
///  * Shows the note rendered (`flutter_markdown`) until tapped; leaving the
///    editor with text in it goes back to the rendered note. [previewMode]
///    lets the host show and drive the Edit / Preview toggle.
///  * With [maxLength], an edit that would make the stored markdown longer is
///    refused, and a counter shows from 90% of the limit.
///  * [leading] sits above the editor (a host's status or banners).
class MarkdownNoteEditor extends StatefulWidget {
  final String initialMarkdown;
  final ValueChanged<String>? onChanged;
  final bool readOnly;

  /// Expands to the available height with the toolbar pinned at the bottom
  /// (a notes page); otherwise an inline box.
  final bool fullScreen;
  final int? maxLength;
  final MarkdownNoteEditorController? controller;

  /// `true` while the rendered note is shown; the host may own it.
  final ValueNotifier<bool>? previewMode;
  final List<Widget> leading;

  const MarkdownNoteEditor({
    super.key,
    required this.initialMarkdown,
    this.onChanged,
    this.readOnly = false,
    this.fullScreen = false,
    this.maxLength,
    this.controller,
    this.previewMode,
    this.leading = const <Widget>[],
  });

  @override
  State<MarkdownNoteEditor> createState() => _MarkdownNoteEditorState();
}

class _MarkdownNoteEditorState extends State<MarkdownNoteEditor> {
  late final QuillController _quill;
  late final FocusNode _focusNode;
  late final ScrollController _scrollController;
  late final ValueNotifier<bool> _preview;
  late String _markdown;

  /// The last document within the limit, restored when an edit goes past it.
  late Document _accepted;
  bool _quiet = false;

  bool get _isPreviewing => _preview.value;

  @override
  void initState() {
    super.initState();
    _quill = QuillController(
      document: markdownToNoteDocument(widget.initialMarkdown),
      selection: const TextSelection.collapsed(offset: 0),
      readOnly: widget.readOnly,
    );
    _markdown = noteDocumentToMarkdown(_quill.document);
    _accepted = Document.fromDelta(_quill.document.toDelta());
    _focusNode = FocusNode()..addListener(_handleFocusChange);
    _scrollController = ScrollController();
    _preview = widget.previewMode ??
        ValueNotifier<bool>(widget.initialMarkdown.trim().isNotEmpty);
    _preview.addListener(_handlePreviewChange);
    _quill.addListener(_handleDocumentChange);
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(covariant MarkdownNoteEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      if (identical(oldWidget.controller?._state, this)) {
        oldWidget.controller?._state = null;
      }
      widget.controller?._state = this;
    }
  }

  void _setMarkdown(String markdown) {
    _quiet = true;
    _quill.document = markdownToNoteDocument(markdown);
    final int len = _quill.document.length;
    _quill.updateSelection(
      TextSelection.collapsed(offset: (len - 1).clamp(0, len)),
      ChangeSource.local,
    );
    _quiet = false;
    _markdown = noteDocumentToMarkdown(_quill.document);
    _accepted = Document.fromDelta(_quill.document.toDelta());
    if (mounted) setState(() {});
  }

  void _handleDocumentChange() {
    if (_quiet) return;
    final String next = noteDocumentToMarkdown(_quill.document);
    final int? max = widget.maxLength;
    if (max != null && markdownNoteLength(next) > max) {
      // Refuse the edit: put back the last note within the limit.
      final TextSelection selection = _quill.selection;
      _quiet = true;
      _quill.document = Document.fromDelta(_accepted.toDelta());
      final int len = _quill.document.length;
      _quill.updateSelection(
        TextSelection.collapsed(
            offset: selection.baseOffset.clamp(0, (len - 1).clamp(0, len))),
        ChangeSource.local,
      );
      _quiet = false;
      return;
    }
    _accepted = Document.fromDelta(_quill.document.toDelta());
    if (next == _markdown) return;
    _markdown = next;
    if (max != null) setState(() {});
    widget.onChanged?.call(next);
  }

  void _handlePreviewChange() {
    if (!mounted) return;
    setState(() {});
    if (!_isPreviewing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _handleFocusChange() {
    // When the user leaves the editor and there is rendered markdown to
    // show, drop back to preview so the formatting is visible. Skips the
    // flip when the field is empty (the editor stays ready for typing).
    if (_focusNode.hasFocus || !mounted || widget.readOnly) return;
    if (_isPreviewing) return;
    if (_quill.document.toPlainText().trim().isEmpty) return;
    _preview.value = true;
  }

  void _edit() => _preview.value = false;

  @override
  void dispose() {
    if (identical(widget.controller?._state, this)) {
      widget.controller?._state = null;
    }
    _preview.removeListener(_handlePreviewChange);
    if (widget.previewMode == null) _preview.dispose();
    _quill.removeListener(_handleDocumentChange);
    _quill.dispose();
    _scrollController.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    final bool editing = !widget.readOnly && !_isPreviewing;
    final Widget? counter = _counter(context, colorScheme);

    if (widget.fullScreen) {
      // Page-style layout: minimal chrome, generous whitespace, toolbar
      // pinned to the bottom of the canvas like a writing-app would.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...widget.leading,
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: _isPreviewing
                  ? _buildPreview(colorScheme, localizations)
                  : _buildEditor(colorScheme, localizations),
            ),
          ),
          if (counter != null) counter,
          if (editing)
            MarkdownNoteToolbar(controller: _quill, fullScreen: true),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...widget.leading,
        if (editing) MarkdownNoteToolbar(controller: _quill, fullScreen: false),
        const SizedBox(height: 8),
        _isPreviewing
            ? _buildPreview(colorScheme, localizations)
            : _buildEditor(colorScheme, localizations),
        if (counter != null) counter,
      ],
    );
  }

  /// "4,620/5,000", from 90% of the limit.
  Widget? _counter(BuildContext context, ColorScheme colorScheme) {
    final int? max = widget.maxLength;
    if (max == null || widget.readOnly) return null;
    final int length = markdownNoteLength(_markdown);
    if (length < max * 0.9) return null;
    final NumberFormat number =
        NumberFormat.decimalPattern(Localizations.localeOf(context).toString());
    return Padding(
      key: const Key('note_counter'),
      padding: EdgeInsets.fromLTRB(16, 4, widget.fullScreen ? 24 : 4, 4),
      child: Text(
        '${number.format(length)}/${number.format(max)}',
        textAlign: TextAlign.end,
        style: TextStyle(
          fontSize: 12,
          fontFamily: TileTextStyles.rubikFontName,
          color: length >= max
              ? colorScheme.error
              : colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildEditor(ColorScheme colorScheme, AppLocalizations localizations) {
    final bool fs = widget.fullScreen;
    final editor = QuillEditor(
      controller: _quill,
      focusNode: _focusNode,
      scrollController: _scrollController,
      config: QuillEditorConfig(
        placeholder:
            fs ? localizations.notesTapToAdd : localizations.noteEllipsis,
        padding: fs
            ? const EdgeInsets.fromLTRB(24, 20, 24, 24)
            : const EdgeInsets.fromLTRB(20, 15, 20, 15),
        expands: fs,
        scrollable: true,
        autoFocus: false,
        customStyles: DefaultStyles(
          paragraph: DefaultTextBlockStyle(
            TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: fs ? 17 : 18,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: colorScheme.onSurface,
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(6, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
          placeHolder: DefaultTextBlockStyle(
            TextStyle(
              fontFamily: TileTextStyles.rubikFontName,
              fontSize: fs ? 17 : 18,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const HorizontalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            const VerticalSpacing(0, 0),
            null,
          ),
        ),
      ),
    );

    if (fs) {
      return Container(
        key: const ValueKey('notes-editor'),
        color: Colors.transparent,
        child: editor,
      );
    }

    return Container(
      key: const ValueKey('notes-editor'),
      constraints: const BoxConstraints(minHeight: 140, maxHeight: 320),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.primaryContainer, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: editor,
    );
  }

  Widget _buildPreview(
      ColorScheme colorScheme, AppLocalizations localizations) {
    final bool canEdit = !widget.readOnly;
    final bool fs = widget.fullScreen;

    final String emptyHint = canEdit && fs
        ? localizations.notesTapToAdd
        : localizations.notesPreviewEmpty;
    final Widget inner = _markdown.trim().isEmpty
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
        : MarkdownNoteView(markdown: _markdown);

    final Widget body = Container(
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
    if (!canEdit) return body;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _edit,
      child: body,
    );
  }
}

/// The note toolbar: only formatting that round-trips cleanly to markdown.
/// Anything Quill can express but markdown cannot (font family/size, colors,
/// underline, sub/superscript, alignment, indent) is hidden so the stored
/// note never silently loses formatting on save.
class MarkdownNoteToolbar extends StatelessWidget {
  final QuillController controller;
  final bool fullScreen;

  const MarkdownNoteToolbar(
      {super.key, required this.controller, this.fullScreen = false});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final toolbar = QuillSimpleToolbar(
      controller: controller,
      config: const QuillSimpleToolbarConfig(
        multiRowsDisplay: false,
        showDividers: false,
        showFontFamily: false,
        showFontSize: false,
        showSmallButton: false,
        showUnderLineButton: false,
        showLineHeightButton: false,
        showColorButton: false,
        showBackgroundColorButton: false,
        showClearFormat: false,
        showAlignmentButtons: false,
        showHeaderStyle: true,
        showListNumbers: true,
        showListBullets: true,
        showListCheck: true,
        showCodeBlock: true,
        showQuote: true,
        showIndent: false,
        showLink: true,
        showSearchButton: false,
        showSubscript: false,
        showSuperscript: false,
        showDirection: false,
        showBoldButton: true,
        showItalicButton: true,
        showStrikeThrough: true,
        showInlineCode: true,
        showUndo: true,
        showRedo: true,
        toolbarIconAlignment: WrapAlignment.start,
      ),
    );

    return Material(
      elevation: fullScreen ? 4 : 0,
      color:
          fullScreen ? colorScheme.surface : colorScheme.surfaceContainerLowest,
      borderRadius: fullScreen
          ? const BorderRadius.vertical(top: Radius.circular(12))
          : BorderRadius.circular(8),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: toolbar,
        ),
      ),
    );
  }
}

/// A note, rendered read-only, wherever notes are shown: GitHub-flavored
/// markdown, checklists not tickable, links not followed - as tile notes are.
/// Nothing for an empty note. [maxLines] caps it to a preview (clipped).
class MarkdownNoteView extends StatelessWidget {
  final String markdown;
  final int? maxLines;

  const MarkdownNoteView({super.key, required this.markdown, this.maxLines});

  @override
  Widget build(BuildContext context) {
    if (markdown.trim().isEmpty) return const SizedBox.shrink();
    // `selectable: false` so a tap reaches the host (e.g. to start editing)
    // instead of being swallowed by text selection.
    final Widget body = MarkdownBody(
      data: markdown,
      selectable: false,
      shrinkWrap: true,
      softLineBreak: true,
      extensionSet: md.ExtensionSet.gitHubFlavored,
      checkboxBuilder: (checked) => Semantics(
          checked: checked,
          child: Icon(checked ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: checked
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant)),
    );
    final int? lines = maxLines;
    if (lines == null) return body;
    return ConstrainedBox(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.textScalerOf(context).scale(24) * lines + 12),
      // Markdown contains its own Column. Lay it out at its natural height
      // before clipping so long notes and enlarged text cannot overflow it.
      child: ClipRect(
          child: SingleChildScrollView(
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        child: body,
      )),
    );
  }
}
