import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:tiler_app/components/comments/mention_parsing.dart';
import 'package:tiler_app/data/comments/comment.dart';
import 'package:bloc/bloc.dart';
import 'dart:async';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tiler_app/services/api/comments_api.dart';
import 'package:tiler_app/data/request/TilerError.dart';

part 'comments_event.dart';
part 'comments_bloc.dart';
/// Progress of a comment thread read.
enum CommentsStep { initial, loading, loaded, error }
/// The kind of toast message [CommentsState.showToast] is asking the UI to
/// display.
enum CommentToastKind {
  /// Show [CommentsState.error] verbatim.
  error,

  /// An attachment was saved to the device's Downloads folder; the UI shows
  /// the localized "attachment saved" confirmation instead of
  /// [CommentsState.error].
  attachmentSaved,
}
/// Lifecycle of one in-flight attachment inside the composer.
enum ComposerAttachmentStep {
  uploading,
  checking,
  ready,
  rejected,
  failed,
}
/// A file the composer has picked but not yet claimed into a comment.
class ComposerAttachmentDraft extends Equatable {
  final String localPath;
  final String fileName;
  final int byteSize;
  final String retryKey;
  final String? attachmentId;
  final ComposerAttachmentStep step;
  final String? errorMessage;
  const ComposerAttachmentDraft({
    required this.localPath,
    required this.fileName,
    required this.byteSize,
    required this.retryKey,
    this.attachmentId,
    this.step = ComposerAttachmentStep.uploading,
    this.errorMessage,
  });
  bool get isClaimable =>
      step == ComposerAttachmentStep.ready && attachmentId != null;
  ComposerAttachmentDraft copyWith({
    String? localPath,
    String? fileName,
    int? byteSize,
    String? retryKey,
    String? attachmentId,
    ComposerAttachmentStep? step,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ComposerAttachmentDraft(
      localPath: localPath ?? this.localPath,
      fileName: fileName ?? this.fileName,
      byteSize: byteSize ?? this.byteSize,
      retryKey: retryKey ?? this.retryKey,
      attachmentId: attachmentId ?? this.attachmentId,
      step: step ?? this.step,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
  @override
  List<Object?> get props => [
        localPath,
        fileName,
        byteSize,
        retryKey,
        attachmentId,
        step,
        errorMessage,
      ];
}
/// Lazily loaded, paged replies for one root comment.
class RootRepliesData extends Equatable {
  final List<Comment> replies;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoading;
  final String? error;
  const RootRepliesData({
    this.replies = const [],
    this.nextCursor,
    this.hasMore = false,
    this.isLoading = false,
    this.error,
  });
  RootRepliesData copyWith({
    List<Comment>? replies,
    String? nextCursor,
    bool? hasMore,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return RootRepliesData(
      replies: replies ?? this.replies,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
  @override
  List<Object?> get props => [replies, nextCursor, hasMore, isLoading, error];
}
class CommentsState extends Equatable {
  final CommentsStep step;
  final String error;
  /// When true, the UI should surface a toast: [error] for
  /// [CommentToastKind.error], or the localized "attachment saved" for
  /// [CommentToastKind.attachmentSaved]. Permanent (non-toast) problems also
  /// live in [error]; the toast flag distinguishes the two so the same field
  /// drives both surfaces.
  final bool showToast;
  /// The kind of message the toast shows when [showToast] is true.
  final CommentToastKind toastKind;
  // ---- thread (roots, oldest – newest for display)
  final List<Comment> roots;
  final String? rootsNextCursor;
  final bool isLoadingMoreRoots;
  // ---- per-root replies
  final Map<String, RootRepliesData> repliesByRoot;
  final Map<String, bool> repliesExpanded;
  final String? replyComposerRootId;
  // ---- participants (mention candidates)
  final List<CommentParticipant> participants;
  // ---- composer
  final String composerText;
  final String? replyTargetRootId;
  final List<MentionSelection> mentionSelections;
  final List<ComposerAttachmentDraft> attachmentDrafts;
  final bool isSending;
  /// True while the composer targets a root (reply mode).
  bool get isReplying => replyTargetRootId != null;
  const CommentsState({
    this.step = CommentsStep.initial,
    this.error = '',
    this.showToast = false,
    this.toastKind = CommentToastKind.error,
    this.roots = const [],
    this.rootsNextCursor,
    this.isLoadingMoreRoots = false,
    this.repliesByRoot = const {},
    this.repliesExpanded = const {},
    this.replyComposerRootId,
    this.participants = const [],
    this.composerText = '',
    this.replyTargetRootId,
    this.mentionSelections = const [],
    this.attachmentDrafts = const [],
    this.isSending = false,
  });
  bool get hasPendingAttachments =>
      attachmentDrafts.any((d) =>
          d.step == ComposerAttachmentStep.uploading ||
          d.step == ComposerAttachmentStep.checking);
  bool get hasClaimableAttachments =>
      attachmentDrafts.any((d) => d.isClaimable);
  CommentsState copyWith({
    CommentsStep? step,
    String? error,
    bool? showToast,
    CommentToastKind? toastKind,
    bool clearError = false,
    List<Comment>? roots,
    String? rootsNextCursor,
    bool? isLoadingMoreRoots,
    Map<String, RootRepliesData>? repliesByRoot,
    Map<String, bool>? repliesExpanded,
    String? replyComposerRootId,
    List<CommentParticipant>? participants,
    String? composerText,
    String? replyTargetRootId,
    List<MentionSelection>? mentionSelections,
    List<ComposerAttachmentDraft>? attachmentDrafts,
    bool? isSending,
  }) {
    return CommentsState(
      step: step ?? this.step,
      error: clearError ? '' : (error ?? this.error),
      showToast: showToast ?? false,
      toastKind: toastKind ?? CommentToastKind.error,
      roots: roots ?? this.roots,
      rootsNextCursor: rootsNextCursor ?? this.rootsNextCursor,
      isLoadingMoreRoots: isLoadingMoreRoots ?? this.isLoadingMoreRoots,
      repliesByRoot: repliesByRoot ?? this.repliesByRoot,
      repliesExpanded: repliesExpanded ?? this.repliesExpanded,
      replyComposerRootId: replyComposerRootId ?? this.replyComposerRootId,
      participants: participants ?? this.participants,
      composerText: composerText ?? this.composerText,
      replyTargetRootId: replyTargetRootId ?? this.replyTargetRootId,
      mentionSelections: mentionSelections ?? this.mentionSelections,
      attachmentDrafts: attachmentDrafts ?? this.attachmentDrafts,
      isSending: isSending ?? this.isSending,
    );
  }
  @override
  List<Object?> get props => [
        step,
        error,
        showToast,
        toastKind,
        roots,
        rootsNextCursor,
        isLoadingMoreRoots,
        repliesByRoot,
        repliesExpanded,
        replyComposerRootId,
        participants,
        composerText,
        replyTargetRootId,
        mentionSelections,
        attachmentDrafts,
        isSending,
      ];
}
