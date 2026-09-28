import 'package:equatable/equatable.dart';
import 'comment.dart';

/// A paged read of comments (roots or replies). The server returns pages
/// newest-first; [nextCursor] is null when there is no older page.
class CommentPage extends Equatable {
  final List<Comment> comments;
  final String? nextCursor;
  final int total;

  const CommentPage({
    required this.comments,
    this.nextCursor,
    required this.total,
  });

  static CommentPage fromJson(Map<String, dynamic> json) {
    final list = (json['comments'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList() ??
        const <Comment>[];
    final cursor = json['nextCursor']?.toString();
    return CommentPage(
      comments: list,
      nextCursor: (cursor == null || cursor.isEmpty) ? null : cursor,
      total: (json['total'] as num?)?.toInt() ?? list.length,
    );
  }

  @override
  List<Object?> get props => [comments, nextCursor, total];
}

/// The people who can be @mentioned on a target.
class CommentParticipantPage extends Equatable {
  final List<CommentParticipant> participants;

  const CommentParticipantPage({required this.participants});

  static CommentParticipantPage fromJson(Map<String, dynamic> json) {
    final list = (json['participants'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CommentParticipant.fromJson)
            .toList() ??
        const <CommentParticipant>[];
    return CommentParticipantPage(participants: list);
  }

  @override
  List<Object?> get props => [participants];
}