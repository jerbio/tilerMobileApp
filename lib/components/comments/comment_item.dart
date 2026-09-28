import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';
import 'package:tiler_app/components/comments/comment_avatar.dart';
import 'package:tiler_app/components/comments/comment_text.dart';
import 'package:tiler_app/components/comments/mention_parsing.dart';
import 'package:tiler_app/data/comments/comment.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

/// One comment (root or reply). Roots carry the reply summary chip and the
/// per-root reply section; replies are rendered inside a root's section.
/// All actions dispatch [CommentsEvent]s through [onEvent].
///
/// Sizing and proportions mirror the desktop web view: compact avatars,
/// 14–15 px body text, subtle grey action links, and tight vertical rhythm.
class CommentItem extends StatefulWidget {
  final Comment comment;
  final bool isRoot;
  final RootRepliesData? replies;
  final bool repliesExpanded;
  final ValueChanged<CommentsEvent> onEvent;

  const CommentItem({
    Key? key,
    required this.comment,
    required this.isRoot,
    this.replies,
    this.repliesExpanded = false,
    required this.onEvent,
  }) : super(key: key);

  @override
  State<CommentItem> createState() => _CommentItemState();
}

/// Sizing tokens that keep every comment visually proportional to the
/// desktop layout while remaining legible on a phone screen.
class _S {
  static const double avatarRoot = 30;
  static const double avatarReply = 22;
  static const double avatarChip = 16;
  static const double nameSize = 14;
  static const double metaSize = 12;
  static const double bodySize = 15;
  static const double actionSize = 13;
  static const double chipSize = 12;
  static const double avatarGap = 8;
  static const double bodyGap = 4;
  static const double actionGap = 6;
}

class _CommentItemState extends State<CommentItem> {
  bool _editing = false;
  final _controller = TextEditingController();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(DateTime? time) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final sameDay = time != null &&
        time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
    if (time == null) return '';
    return sameDay
        ? DateFormat('hh:mm a', locale).format(time)
        : DateFormat('MMM d, hh:mm a', locale).format(time);
  }

  void _startEdit() {
    final lookup = {for (final m in widget.comment.mentions) m.id: m};
    _controller.text =
        MentionParser.toDisplayText(widget.comment.text, lookup);
    _editing = true;
    setState(() {});
  }

  void _cancelEdit() {
    _editing = false;
    _controller.clear();
    setState(() {});
  }

  void _saveEdit() {
    final text = _controller.text;
    if (text.trim().isEmpty || text.length > 2000) {
      _cancelEdit();
      return;
    }
    final ids = MentionParser.extractDistinctIds(text);
    _editing = false;
    _controller.clear();
    widget.onEvent(EditCommentEvent(
      comment: widget.comment,
      text: text,
      idempotencyKey: _uuid.v4(),
      mentionedUserIds: ids,
    ));
    setState(() {});
  }

  void _delete() {
    widget.onEvent(DeleteCommentEvent(
      comment: widget.comment,
      idempotencyKey: _uuid.v4(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final comment = widget.comment;
    final author = comment.author;
    final name = author?.displayName;
    final displayName =
        (name == null || name.isEmpty) ? l10n.commentsDeletedAuthor : name;
    final isViewer = author?.isViewer ?? false;

    Widget textWidget;
    if (comment.isDeleted) {
      textWidget = Text(
        l10n.commentsDeletedPlaceholder,
        style: TextStyle(
          fontSize: _S.bodySize,
          color: colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    } else if (_editing) {
      textWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            maxLength: 2000,
            style: TextStyle(fontSize: _S.bodySize),
            decoration: const InputDecoration(
                isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: _S.actionSize)),
                  onPressed: _cancelEdit,
                  child: Text(l10n.commentsCancel)),
              TextButton(
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: _S.actionSize)),
                  onPressed: _saveEdit, child: Text(l10n.commentsSave)),
            ],
          ),
        ],
      );
    } else {
      textWidget = CommentText(
        text: comment.text,
        mentions: comment.mentions,
        style: TextStyle(fontSize: _S.bodySize),
      );
    }

    final attachments = comment.attachments;
    Widget? attachmentsWidget;
    if (attachments.isNotEmpty) {
      attachmentsWidget = Column(
        children: [
          const SizedBox(height: 6),
          for (final attachment in attachments)
            _AttachmentFileCard(
              attachment: attachment,
              onDownload: () => widget.onEvent(DownloadAttachmentEvent(
                attachmentId: attachment.id,
                fileName: attachment.fileName,
              )),
            ),
        ],
      );
    }

    final actions = <Widget>[];
    if (!comment.isDeleted) {
      final actionStyle = TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        textStyle: TextStyle(
          fontSize: _S.actionSize,
          color: colorScheme.onSurfaceVariant,
        ),
      );
      if (widget.isRoot) {
        actions.add(TextButton(
            style: actionStyle,
            onPressed: () => widget.onEvent(
                SetReplyTargetEvent(rootId: comment.id)),
            child: Text(l10n.commentsReply)));
      }
      if (comment.canEdit) {
        actions.add(TextButton(
            style: actionStyle,
            onPressed: _startEdit, child: Text(l10n.commentsEdit)));
      }
      if (comment.canDelete) {
        actions.add(TextButton(
            style: actionStyle,
            onPressed: _delete, child: Text(l10n.commentsDelete)));
      }
    }

    Widget? repliesChip;
    if (widget.isRoot && (comment.hasReplies || comment.replyCount > 0)) {
      repliesChip = Row(
        children: [
          ...comment.replyAuthors.take(3).map(
                (person) => Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: CommentAvatar(
                    userId: person.id,
                    displayName: person.displayName,
                    size: _S.avatarChip,
                  ),
                ),
              ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => widget.onEvent(ToggleRepliesEvent(
              rootId: comment.id,
              expand: !widget.repliesExpanded,
            )),
            child: Text(
              widget.repliesExpanded
                  ? l10n.commentsHideReplies
                  : l10n.commentsReplies(comment.replyCount),
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: _S.chipSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    Widget? replySection;
    if (widget.isRoot && widget.repliesExpanded && widget.replies != null) {
      replySection = _ReplySection(
        rootId: comment.id,
        data: widget.replies!,
        onEvent: widget.onEvent,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CommentAvatar(
              userId: author?.id ?? '',
              displayName: displayName,
              size: widget.isRoot ? _S.avatarRoot : _S.avatarReply,
            ),
            const SizedBox(width: _S.avatarGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author name + timestamp (desktop-style inline).
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: _S.nameSize,
                            fontWeight: FontWeight.w600,
                            color: isViewer
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (isViewer)
                        Text(
                          ' ${l10n.commentsYou}',
                          style: TextStyle(
                            fontSize: _S.nameSize,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: _S.metaSize,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatTime(comment.createdAtLocal),
                          style: TextStyle(
                              fontSize: _S.metaSize,
                              color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                      if (comment.wasEdited) ...[
                        const SizedBox(width: 4),
                        Text(
                          l10n.commentsEdited,
                          style: TextStyle(
                            fontSize: _S.metaSize,
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: _S.bodyGap),
                  textWidget,
                  if (attachmentsWidget != null) attachmentsWidget,
                  if (repliesChip != null) ...[
                    const SizedBox(height: _S.actionGap),
                    repliesChip,
                  ],
                  if (replySection != null) replySection,
                  if (actions.isNotEmpty)
                    Row(children: actions),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The lazy-loaded, paged reply list under a root comment (oldestâ†’newest,
/// "Load earlier replies" at the top of the section).
class _ReplySection extends StatelessWidget {
  final String rootId;
  final RootRepliesData data;
  final ValueChanged<CommentsEvent> onEvent;

  const _ReplySection({
    Key? key,
    required this.rootId,
    required this.data,
    required this.onEvent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.hasMore)
            Center(
              child: data.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : TextButton(
                      onPressed: () => onEvent(
                          LoadMoreRepliesEvent(rootId: rootId)),
                      child: Text(
                        l10n.commentsLoadEarlierReplies,
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
            ),
          if (data.isLoading && data.replies.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: Text(l10n.commentsLoading,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
              ),
            ),
          if (data.error != null && data.replies.isEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data.error!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant)),
                TextButton(
                  onPressed: () => onEvent(LoadRepliesEvent(rootId: rootId)),
                  child: Text(l10n.commentsRetry),
                ),
              ],
            ),
          for (final reply in data.replies)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: CommentItem(
                comment: reply,
                isRoot: false,
                onEvent: onEvent,
              ),
            ),
        ],
      ),
    );
  }
}

/// A file card under a comment or in the composer's draft list.
class _AttachmentFileCard extends StatelessWidget {
  final Attachment attachment;
  final VoidCallback? onDownload;

  const _AttachmentFileCard({
    Key? key,
    required this.attachment,
    this.onDownload,
  }) : super(key: key);

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes b';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} kb';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _icon() {
    final type = attachment.contentType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('png') ||
        type.contains('jpeg') ||
        type.contains('jpg')) {
      return Icons.image_outlined;
    }
    if (type.contains('docx') || type.contains('word')) {
      return Icons.description_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon(), size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              attachment.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatSize(attachment.byteSize),
            style: TextStyle(
                fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
          if (onDownload != null)
            TextButton(
              onPressed: onDownload,
              child: Text(
                l10n.commentsAttachmentDownload,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
      ),
    );
  }
}
