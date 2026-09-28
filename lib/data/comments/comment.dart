import 'package:equatable/equatable.dart';

/// Wire state values of a comment attachment (see AttachmentLimits.State*).
class AttachmentStates {
  static const String pending = 'pending';
  static const String ready = 'ready';
  static const String attached = 'attached';
  static const String rejected = 'rejected';
  static const String expired = 'expired';

  static bool isTerminal(String state) {
    return state == ready ||
        state == attached ||
        state == rejected ||
        state == expired;
  }
}

/// A file claimed into a comment, or (for the upload flow) a quarantine row.
class Attachment extends Equatable {
  final String id;
  final String fileName;
  final String contentType;
  final int byteSize;
  final String state;

  const Attachment({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.byteSize,
    required this.state,
  });

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      id: json['id']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      contentType: json['contentType']?.toString() ?? '',
      byteSize: (json['byteSize'] as num?)?.toInt() ?? 0,
      state: json['state']?.toString() ?? AttachmentStates.pending,
    );
  }

  bool get isReady {
    return state == AttachmentStates.ready ||
        state == AttachmentStates.attached;
  }

  bool get isTerminal {
    return AttachmentStates.isTerminal(state);
  }

  @override
  List<Object?> get props => [id, fileName, contentType, byteSize, state];
}

/// A person referenced by a mention or shown in a reply summary.
/// Deleted accounts carry no display name.
class CommentPerson extends Equatable {
  final String id;
  final String? displayName;
  final bool isDeleted;

  const CommentPerson({
    required this.id,
    this.displayName,
    this.isDeleted = false,
  });

  factory CommentPerson.fromJson(Map<String, dynamic> json) {
    final name = json['displayName']?.toString();
    return CommentPerson(
      id: json['id']?.toString() ?? '',
      displayName: (name == null || name.isEmpty) ? null : name,
      isDeleted: json['isDeleted'] == true,
    );
  }

  @override
  List<Object?> get props => [id, displayName, isDeleted];
}

/// A user who can read the target and may be @mentioned (composer candidates).
class CommentParticipant extends Equatable {
  final String id;
  final String displayName;
  final bool isViewer;

  const CommentParticipant({
    required this.id,
    required this.displayName,
    this.isViewer = false,
  });

  factory CommentParticipant.fromJson(Map<String, dynamic> json) {
    return CommentParticipant(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      isViewer: json['isViewer'] == true,
    );
  }

  @override
  List<Object?> get props => [id, displayName, isViewer];
}

/// The author of a comment. Deleted accounts carry no display name.
/// [isViewer] is true when the author is the signed-in user and drives the
/// "(you)" highlight in the UI.
class CommentAuthor extends Equatable {
  final String id;
  final String? displayName;
  final bool isOwner;
  final bool isDeleted;
  final bool isViewer;

  const CommentAuthor({
    required this.id,
    this.displayName,
    this.isOwner = false,
    this.isDeleted = false,
    this.isViewer = false,
  });

  factory CommentAuthor.fromJson(Map<String, dynamic> json) {
    final name = json['displayName']?.toString();
    return CommentAuthor(
      id: json['id']?.toString() ?? '',
      displayName: (name == null || name.isEmpty) ? null : name,
      isOwner: json['isOwner'] == true,
      isDeleted: json['isDeleted'] == true,
      isViewer: json['isViewer'] == true,
    );
  }

  @override
  List<Object?> get props =>
      [id, displayName, isOwner, isDeleted, isViewer];
}

/// A single comment (root or reply) in a thread. Timestamps arrive as UTC
/// epoch milliseconds; [createdAtLocal] / [editedAtLocal] expose them as
/// local [DateTime] values for display.
class Comment extends Equatable {
  final String id;
  final String targetType;
  final String targetId;
  final CommentAuthor? author;
  final String text;
  final int? createdAtMs;
  final int? editedAtMs;
  final int? deletedAtMs;
  final bool isDeleted;
  final bool canEdit;
  final bool canDelete;
  final String? rootCommentId;
  final bool isReply;
  final bool hasReplies;
  final int replyCount;
  final List<Attachment> attachments;
  final List<CommentPerson> mentions;
  final List<CommentPerson> replyAuthors;

  const Comment({
    required this.id,
    required this.targetType,
    required this.targetId,
    this.author,
    required this.text,
    this.createdAtMs,
    this.editedAtMs,
    this.deletedAtMs,
    required this.isDeleted,
    required this.canEdit,
    required this.canDelete,
    this.rootCommentId,
    required this.isReply,
    required this.hasReplies,
    required this.replyCount,
    required this.attachments,
    required this.mentions,
    required this.replyAuthors,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final authorJson = json['author'];
    final attachments = (json['attachments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Attachment.fromJson)
            .toList() ??
        const <Attachment>[];
    final mentions = (json['mentions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CommentPerson.fromJson)
            .toList() ??
        const <CommentPerson>[];
    final replyAuthors = (json['replyAuthors'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CommentPerson.fromJson)
            .toList() ??
        const <CommentPerson>[];

    return Comment(
      id: json['id']?.toString() ?? '',
      targetType: json['targetType']?.toString() ?? '',
      targetId: json['targetId']?.toString() ?? '',
      author:
          (authorJson is Map<String, dynamic>)
              ? CommentAuthor.fromJson(authorJson)
              : null,
      text: json['text']?.toString() ?? '',
      createdAtMs: (json['createdAt'] as num?)?.toInt(),
      editedAtMs: (json['editedAt'] as num?)?.toInt(),
      deletedAtMs: (json['deletedAt'] as num?)?.toInt(),
      isDeleted: json['isDeleted'] == true,
      canEdit: json['canEdit'] == true,
      canDelete: json['canDelete'] == true,
      rootCommentId: json['rootCommentId']?.toString(),
      isReply: json['isReply'] == true,
      hasReplies: json['hasReplies'] == true,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      attachments: attachments,
      mentions: mentions,
      replyAuthors: replyAuthors,
    );
  }

  /// Whether the comment was ever edited (drives the "edited" marker).
  bool get wasEdited => editedAtMs != null && editedAtMs! > 0;

  /// Display name of the author, null when the account was deleted.
  String? get authorDisplayName => author?.displayName;

  /// Local time of creation, or null when the row has no timestamp.
  DateTime? get createdAtLocal {
    final ms = createdAtMs;
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Local time of the last edit, or null when never edited.
  DateTime? get editedAtLocal {
    final ms = editedAtMs;
    if (ms == null || ms <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  @override
  List<Object?> get props => [
        id,
        targetType,
        targetId,
        author,
        text,
        createdAtMs,
        editedAtMs,
        deletedAtMs,
        isDeleted,
        canEdit,
        canDelete,
        rootCommentId,
        isReply,
        hasReplies,
        replyCount,
        attachments,
        mentions,
        replyAuthors,
      ];
}