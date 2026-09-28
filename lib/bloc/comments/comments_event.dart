part of 'comments_state.dart';

abstract class CommentsEvent extends Equatable {
  const CommentsEvent();
  @override
  List<Object?> get props => const [];
}
/// Loads the first page of the thread (roots + participants).
class LoadThreadEvent extends CommentsEvent {
  const LoadThreadEvent();
}
/// Loads the next older page of roots.
class LoadMoreRootsEvent extends CommentsEvent {
  const LoadMoreRootsEvent();
}
/// Posts a root comment or a reply (when [rootCommentId] is set).
///
/// [idempotencyKey] is a UUIDv4 minted by the composer for this logical
/// action; the bloc stores it so a retry of the same action reuses it.
class PostCommentEvent extends CommentsEvent {
  final String text;
  final String? rootCommentId;
  final String idempotencyKey;
  final List<String> attachmentIds;
  final List<String> mentionedUserIds;
  const PostCommentEvent({
    required this.text,
    this.rootCommentId,
    required this.idempotencyKey,
    this.attachmentIds = const [],
    this.mentionedUserIds = const [],
  });
  @override
  List<Object?> get props =>
      [text, rootCommentId, idempotencyKey, attachmentIds, mentionedUserIds];
}
/// Saves an edited comment. [idempotencyKey] follows the same rules as
/// [PostCommentEvent.idempotencyKey].
class EditCommentEvent extends CommentsEvent {
  final Comment comment;
  final String text;
  final String idempotencyKey;
  final List<String> mentionedUserIds;
  const EditCommentEvent({
    required this.comment,
    required this.text,
    required this.idempotencyKey,
    this.mentionedUserIds = const [],
  });
  @override
  List<Object?> get props => [comment.id, text, idempotencyKey];
}
/// Soft-deletes a comment.
class DeleteCommentEvent extends CommentsEvent {
  final Comment comment;
  final String idempotencyKey;
  const DeleteCommentEvent({required this.comment, required this.idempotencyKey});
  @override
  List<Object?> get props => [comment.id, idempotencyKey];
}
/// Lazily loads the first page of replies under a root.
class LoadRepliesEvent extends CommentsEvent {
  final String rootId;
  const LoadRepliesEvent({required this.rootId});
  @override
  List<Object?> get props => [rootId];
}
/// Loads the next older page of replies under a root.
class LoadMoreRepliesEvent extends CommentsEvent {
  final String rootId;
  const LoadMoreRepliesEvent({required this.rootId});
  @override
  List<Object?> get props => [rootId];
}
/// Expands or collapses a root's reply section.
class ToggleRepliesEvent extends CommentsEvent {
  final String rootId;
  final bool expand;
  const ToggleRepliesEvent({required this.rootId, required this.expand});
  @override
  List<Object?> get props => [rootId, expand];
}
/// Sets the composer text. When a mention token `@Name ` is typed at the end
/// the composer emits this with [mentionQuery] set to drive suggestions.
class ComposerTextEvent extends CommentsEvent {
  final String text;
  final List<MentionSelection> mentionSelections;
  final String? mentionQuery;
  const ComposerTextEvent({
    required this.text,
    this.mentionSelections = const [],
    this.mentionQuery,
  });
  @override
  List<Object?> get props => [text, mentionSelections, mentionQuery];
}
/// Targets a root for a new reply (or clears the target with a null id).
class SetReplyTargetEvent extends CommentsEvent {
  final String? rootId;
  const SetReplyTargetEvent({required this.rootId});
  @override
  List<Object?> get props => [rootId];
}
/// Starts uploading [localPath] into the quarantine with [retryKey].
class UploadAttachmentEvent extends CommentsEvent {
  final String localPath;
  final String fileName;
  final int byteSize;
  final String retryKey;
  const UploadAttachmentEvent({
    required this.localPath,
    required this.fileName,
    required this.byteSize,
    required this.retryKey,
  });
  @override
  List<Object?> get props => [localPath, fileName, byteSize, retryKey];
}
/// Removes a composer attachment draft. When [attachmentId] is set (and the
/// row is unclaimed) the bloc also cancels it server-side.
class RemoveAttachmentEvent extends CommentsEvent {
  final String localPath;
  final String? attachmentId;
  const RemoveAttachmentEvent({required this.localPath, this.attachmentId});
  @override
  List<Object?> get props => [localPath, attachmentId];
}
/// Downloads an attachment and reports the saved file location.
class DownloadAttachmentEvent extends CommentsEvent {
  final String attachmentId;
  final String fileName;
  const DownloadAttachmentEvent({
    required this.attachmentId,
    required this.fileName,
  });
  @override
  List<Object?> get props => [attachmentId, fileName];
}

/// Consumes a pending toast ([CommentsState.showToast]); the UI emits this
/// right after it has shown the message.
class ClearToastEvent extends CommentsEvent {
  const ClearToastEvent();
}
