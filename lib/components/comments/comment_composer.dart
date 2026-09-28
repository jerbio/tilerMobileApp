import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';
import 'package:tiler_app/components/comments/mention_parsing.dart';
import 'package:tiler_app/components/comments/comment_avatar.dart';
import 'package:tiler_app/data/comments/comment.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// The docked composer: text field, @mention picker, attachment drafts and
/// the send action. Used both for root comments and (with a reply target)
/// for replies.
class CommentComposer extends StatefulWidget {
  final ValueChanged<CommentsEvent> onEvent;
  final String? Function(String? rootCommentId) reusablePostKey;
  final ValueChanged<String> onToast;

  const CommentComposer({
    Key? key,
    required this.onEvent,
    required this.reusablePostKey,
    required this.onToast,
  }) : super(key: key);

  @override
  State<CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<CommentComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _uuid = const Uuid();

  /// The `@` the user is currently typing, or null when no suggestion list
  /// is open.
  int? _mentionTriggerOffset;

  bool _picking = false;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CommentComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bloc = context.read<CommentsBloc>();
    final state = bloc.state;
    if (_controller.text == state.composerText) return;
    // The bloc clears `composerText` only when a post succeeds (or the
    // reply target changes). Apply that clear even while the field still
    // holds focus — on mobile the field keeps focus after the send tap, so
    // gating the sync on focus left the just-sent text on screen.
    if (state.composerText.isEmpty) {
      _controller.clear();
      _mentionTriggerOffset = null;
      return;
    }
    // Any other divergence is an external reset; never clobber live typing.
    if (!_focusNode.hasFocus) {
      _controller.text = state.composerText;
    }
  }


  List<MentionSelection> _reconcile(String text, List<MentionSelection> current) {
    final out = <MentionSelection>[];
    for (final selection in current) {
      final display = '@${selection.participant.displayName}';
      final index = text.indexOf(display);
      if (index >= 0) {
        out.add(MentionSelection(selection.participant, index));
      }
    }
    return out;
  }

  void _onTextChanged(String text) {
    final bloc = context.read<CommentsBloc>();
    var selections = bloc.state.mentionSelections;

    // Reconcile selections after the edit.
    final reconciled = _reconcile(text, selections);

    // Detect a new `@` typed at start or after whitespace.
    final selection = _controller.selection;
    if (selection.isValid &&
        selection.start == selection.end &&
        selection.start > 0) {
      final caret = selection.start;
      final before = text.substring(0, caret);
      final at = before.lastIndexOf('@');
      if (at >= 0 && (at == 0 || before[at - 1] == ' ')) {
        _mentionTriggerOffset = at;
      } else {
        _mentionTriggerOffset = null;
      }
    } else {
      _mentionTriggerOffset = null;
    }

    widget.onEvent(ComposerTextEvent(
      text: text,
      mentionSelections: reconciled,
    ));
    setState(() {});
  }

  void _selectMention(CommentParticipant participant) {
    if (_mentionTriggerOffset == null) return;
    final text = _controller.text;
    final trigger = _mentionTriggerOffset!;
    final caret = _controller.selection.isValid
        ? _controller.selection.end
        : text.length;
    final display = '@${participant.displayName} ';
    // Replace the typed `@query` with `@Display Name `.
    final newText = text.substring(0, trigger) +
        display +
        (caret > trigger ? text.substring(caret) : '');
    _controller.text = newText;
    _controller.selection =
        TextSelection.collapsed(offset: trigger + display.length);
    _focusNode.requestFocus();
    _mentionTriggerOffset = null;

    final bloc = context.read<CommentsBloc>();
    final selections = [
      ...bloc.state.mentionSelections,
      MentionSelection(participant, trigger),
    ];
    widget.onEvent(
      ComposerTextEvent(
        text: newText,
        mentionSelections: _reconcile(newText, selections),
      ),
    );
    setState(() {});
  }

  String? _mentionQuery(String text) {
    if (_mentionTriggerOffset == null) return null;
    final caret = _controller.selection.isValid
        ? _controller.selection.end
        : text.length;
    if (caret < _mentionTriggerOffset! + 1) return null;
    final query = text.substring(_mentionTriggerOffset! + 1, caret);
    return (query.contains(' ') || query.length > 40) ? null : query;
  }

  Future<void> _pickAttachments() async {
    if (_picking) return;
    _picking = true;
    setState(() {});
    final l10n = AppLocalizations.of(context)!;
    try {
      // `withData` guarantees the bytes are available even when the
      // platform only returns a path-less reference (iOS shared-container
      // and cloud sources). The pick is extension-filtered and the bloc
      // caps files at 10 MB × 5, so holding the bytes is bounded.
      final result = await FilePicker.pickFiles(
        dialogTitle: l10n.commentsAttach,
        type: FileType.custom,
        allowedExtensions: CommentsBloc.allowedExtensions,
        withData: true,
      );
      if (result == null) return;
      final bloc = context.read<CommentsBloc>();
      for (final picked in result.files) {
        var path = picked.path;
        if ((path == null || path.isEmpty) &&
            picked.bytes != null &&
            picked.bytes!.isNotEmpty) {
          // No cached path (e.g. iOS cloud source): materialize a local
          // copy so the upload has a real file to read.
          final tempDir = await getTemporaryDirectory();
          final safeName =
              picked.name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
          final materialized = File(
            '${tempDir.path}${Platform.pathSeparator}'
            'comment_attach_${_uuid.v4()}_$safeName',
          );
          await materialized.writeAsBytes(picked.bytes!);
          path = materialized.path;
        }
        if (path == null || path.isEmpty) {
          // The platform returned neither a path nor bytes; say so instead
          // of silently dropping the pick.
          _toast(l10n.commentsAttachmentPickFailed);
          continue;
        }
        final file = File(path);
        final size = file.existsSync() ? file.lengthSync() : 0;
        final error = bloc.validateAttachment(
            picked.name, size, bloc.state.attachmentDrafts.length);
        if (error != null) {
          _toast(_validationMessage(l10n, error));
          continue;
        }
        widget.onEvent(UploadAttachmentEvent(
          localPath: path,
          fileName: picked.name,
          byteSize: size,
          retryKey: _uuid.v4(),
        ));
      }
    } finally {
      _picking = false;
      if (mounted) setState(() {});
    }
  }

  /// Maps [CommentsBloc.validateAttachment] codes to their localized
  /// messages; the raw codes must never reach the UI.
  String _validationMessage(AppLocalizations l10n, String code) {
    switch (code) {
      case 'invalidType':
        return l10n.commentsAttachmentInvalidType;
      case 'empty':
        return l10n.commentsAttachmentEmpty;
      case 'tooLarge':
        return l10n.commentsAttachmentTooLarge;
      case 'limit':
        return l10n.commentsAttachmentLimit(
            CommentsBloc.maxAttachmentsPerComment);
      default:
        return l10n.commentsAttachmentUploadFailed;
    }
  }

  void _toast(String message) {
    widget.onToast(message);
  }

  void _removeDraft(ComposerAttachmentDraft draft) {
    widget.onEvent(RemoveAttachmentEvent(
      localPath: draft.localPath,
      attachmentId: draft.attachmentId,
    ));
  }

  void _send() {
    final bloc = context.read<CommentsBloc>();
    final state = bloc.state;
    final text = _controller.text;
    final trimmed = text.trim();
    if (trimmed.isEmpty && state.attachmentDrafts.isEmpty) return;
    if (trimmed.length > 2000 || state.isSending) return;
    if (state.hasPendingAttachments) return;

    // Only keep mentions whose `@Name` is still present in the text.
    final validSelections = _reconcile(text, state.mentionSelections);
    final (storedText, ids) = MentionParser.toTokens(text, validSelections);
    final attachmentIds = state.attachmentDrafts
        .where((d) => d.isClaimable)
        .map((d) => d.attachmentId!)
        .toList();
    final key =
        widget.reusablePostKey(state.replyTargetRootId) ?? _uuid.v4();
    widget.onEvent(PostCommentEvent(
      text: storedText,
      rootCommentId: state.replyTargetRootId,
      idempotencyKey: key,
      attachmentIds: attachmentIds,
      mentionedUserIds: ids,
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<CommentsBloc>().state;

    final placeholder =
        state.isReplying ? l10n.commentsReplyPlaceholder : l10n.commentsPlaceholder;
    final mentionQuery = _mentionQuery(state.composerText);
    final suggestions = mentionQuery != null
        ? MentionParser.filterSuggestions(state.participants, mentionQuery)
        : const <CommentParticipant>[];

    final drafts = state.attachmentDrafts;
    final hasPending = state.hasPendingAttachments;
    final hasContent = state.composerText.trim().isNotEmpty ||
        drafts.any((d) => d.isClaimable);

    Widget _status(ComposerAttachmentDraft d) {
      switch (d.step) {
        case ComposerAttachmentStep.uploading:
          return const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2));
        case ComposerAttachmentStep.checking:
          return const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5));
        case ComposerAttachmentStep.ready:
          return Text(
            l10n.commentsAttachmentUploaded,
            style: TextStyle(
                fontSize: 11, color: colorScheme.onSurfaceVariant),
          );
        case ComposerAttachmentStep.rejected:
        case ComposerAttachmentStep.failed:
          return Text(
            l10n.commentsAttachmentUploadFailed,
            style: TextStyle(
                fontSize: 11, color: colorScheme.error),
          );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
            top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5))),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state.isReplying)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.commentsReplyPlaceholder,
                      style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                  TextButton(
                    onPressed: () => widget.onEvent(
                        SetReplyTargetEvent(rootId: null)),
                    child: Text(l10n.commentsCancel,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          if (drafts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Column(
                children: [
                  if (hasPending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        l10n.commentsAttachmentUploadingSummary(
                            drafts
                                .where((d) =>
                                    d.step ==
                                        ComposerAttachmentStep.uploading ||
                                    d.step ==
                                        ComposerAttachmentStep.checking)
                                .length),
                        style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  for (final draft in drafts)
                    Row(
                      children: [
                        Icon(Icons.insert_drive_file_outlined,
                            size: 14,
                            color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            draft.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _status(draft),
                        IconButton(
                          tooltip: l10n.commentsAttachmentRemove(
                              draft.fileName),
                          iconSize: 14,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removeDraft(draft),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  onChanged: _onTextChanged,
                  // Lock editing while a post is in flight: keystrokes
                  // typed mid-send would be silently wiped by the
                  // post-success reset (and the draft must stay intact for
                  // the idempotent retry if the post fails).
                  readOnly: state.isSending,
                  maxLines: null,
                  maxLength: 2000,
                  textInputAction: TextInputAction.send,
                  onEditingComplete: _send,
                  decoration: InputDecoration(
                    hintText: placeholder,
                    isDense: true,
                    filled: true,
                    fillColor: colorScheme.surfaceContainerLow,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: colorScheme.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: l10n.commentsAttach,
                // Disabled while a post is in flight: a draft uploaded
                // mid-send would be wiped by the post-success reset without
                // ever being claimed into a comment.
                onPressed: (_picking || state.isSending)
                    ? null
                    : _pickAttachments,
                icon: _picking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.attach_file),
              ),
              IconButton(
                onPressed: (hasContent &&
                        !state.isSending &&
                        !hasPending)
                    ? _send
                    : null,
                icon: state.isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ],
          ),
          if (suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.commentsMentionSuggestions,
                    style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  for (final suggestion in suggestions)
                    InkWell(
                      onTap: () => _selectMention(suggestion),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 6),
                        child: Row(
                          children: [
                            CommentAvatar(
                                userId: suggestion.id,
                                displayName: suggestion.displayName,
                                size: 22),
                            const SizedBox(width: 8),
                            Text(
                              suggestion.displayName +
                                  (suggestion.isViewer
                                      ? ' ${l10n.commentsYou}'
                                      : ''),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
