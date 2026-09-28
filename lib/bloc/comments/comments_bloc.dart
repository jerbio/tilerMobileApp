part of 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  static const int maxAttachmentsPerComment = 5;
  static const int maxAttachmentBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedExtensions =
      ['pdf', 'docx', 'png', 'jpg', 'jpeg'];
  final CommentsApi _api;
  final String _targetType;
  final String _targetId;
  /// Root/reply page size for the paged loads (the web Tilette Detail
  /// screen pages 10 at a time; the default stays 50 for other hosts).
  final int _pageSize;
  final Uuid _uuid = const Uuid();
  /// Idempotency key of the failed post in flight, kept so a retry of the
  /// same logical action replays the original request.
  String? _pendingPostKey;
  String? _pendingPostRootId;
  bool _disposed = false;
  CommentsBloc({
    required String targetType,
    required String targetId,
    int pageSize = CommentsApi.defaultPageLimit,
    required Function? getContextCallBack,
  })  : _api = CommentsApi(getContextCallBack: getContextCallBack),
        _targetType = targetType,
        _targetId = targetId,
        _pageSize = pageSize,
        super(const CommentsState()) {
    on<LoadThreadEvent>(_onLoadThread);
    on<LoadMoreRootsEvent>(_onLoadMoreRoots);
    on<PostCommentEvent>(_onPostComment);
    on<EditCommentEvent>(_onEditComment);
    on<DeleteCommentEvent>(_onDeleteComment);
    on<LoadRepliesEvent>(_onLoadReplies);
    on<LoadMoreRepliesEvent>(_onLoadMoreReplies);
    on<ToggleRepliesEvent>(_onToggleReplies);
    on<ComposerTextEvent>(_onComposerText);
    on<SetReplyTargetEvent>(_onSetReplyTarget);
    on<UploadAttachmentEvent>(_onUploadAttachment);
    on<RemoveAttachmentEvent>(_onRemoveAttachment);
    on<DownloadAttachmentEvent>(_onDownloadAttachment);
    on<ClearToastEvent>(_onClearToast);
  }
  void _onClearToast(ClearToastEvent event, Emitter<CommentsState> emit) {
    emit(state.copyWith(showToast: false, clearError: true));
  }
  @override
  Future<void> close() async {
    _disposed = true;
    return super.close();
  }
  // ---------------------------------------------------------------- helpers
  String _message(Object e) {
    if (e is TilerError && e.Message != null && e.Message!.isNotEmpty) {
      return e.Message!;
    }
    // Never surface raw ids/tokens to the user.
    return 'Issues with reaching Tiler servers';
  }
  List<ComposerAttachmentDraft> _replaceDraft(
      List<ComposerAttachmentDraft> drafts, ComposerAttachmentDraft next) {
    return [
      for (final draft in drafts)
        if (draft.localPath == next.localPath) next else draft,
    ];
  }
  /// Replaces [updated] in the roots or in a root's reply list.
  void _replaceComment(List<Comment> roots,
      Map<String, RootRepliesData> repliesByRoot, Comment updated) {
    final rootIndex = roots.indexWhere((c) => c.id == updated.id);
    if (rootIndex >= 0) {
      roots[rootIndex] = updated;
      return;
    }
    final rootId = updated.rootCommentId;
    if (rootId != null && repliesByRoot.containsKey(rootId)) {
      final data = repliesByRoot[rootId]!;
      final index = data.replies.indexWhere((c) => c.id == updated.id);
      if (index >= 0) {
        final replies = List<Comment>.from(data.replies)..[index] = updated;
        repliesByRoot[rootId] = data.copyWith(replies: replies);
      }
    }
  }
  /// The key the composer should reuse for its next post when retrying the
  /// action that just failed; null otherwise (mint a new key).
  String? reusablePostKey(String? rootCommentId) {
    if (_pendingPostKey == null) return null;
    if (_pendingPostRootId == rootCommentId) return _pendingPostKey;
    return null;
  }
  // --------------------------------------------------------------- thread
  Future<void> _onLoadThread(
      LoadThreadEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(
        step: CommentsStep.loading,
        clearError: true,
        showToast: true,
        roots: const [],
        rootsNextCursor: null));
    try {
      final page = await _api.getComments(
          targetType: _targetType, targetId: _targetId, limit: _pageSize);
      List<CommentParticipant> participants = const [];
      try {
        participants =
            (await _api.getParticipants(
                    targetType: _targetType, targetId: _targetId))
                .participants;
      } catch (e) {
        // Suggestions are best-effort; the thread works without them.
        debugPrint('[CommentsBloc] getParticipants failed (non-fatal): $e');
      }
      if (_disposed) return;
      emit(state.copyWith(
        step: CommentsStep.loaded,
        // The API returns newest-first; display oldest–newest.
        roots: List<Comment>.from(page.comments).reversed.toList(),
        rootsNextCursor: page.nextCursor,
        participants: participants,
      ));
    } catch (e, st) {
      debugPrint('[CommentsBloc] _onLoadThread failed: $e\n$st');
      if (_disposed) return;
      emit(state.copyWith(
          step: CommentsStep.error, error: _message(e), clearError: true));
    }
  }
  Future<void> _onLoadMoreRoots(
      LoadMoreRootsEvent event, Emitter<CommentsState> emit) async {
    final cursor = state.rootsNextCursor;
    if (cursor == null || state.isLoadingMoreRoots) return;
    emit(state.copyWith(isLoadingMoreRoots: true, clearError: true));
    try {
      final page = await _api.getComments(
          targetType: _targetType,
          targetId: _targetId,
          cursor: cursor,
          limit: _pageSize);
      if (_disposed) return;
      // Older page: prepend in oldest–newest display order.
      final older = List<Comment>.from(page.comments).reversed.toList();
      emit(state.copyWith(
        roots: [...older, ...state.roots],
        rootsNextCursor: page.nextCursor,
        isLoadingMoreRoots: false,
      ));
    } catch (e, st) {
      debugPrint('[CommentsBloc] _onLoadMoreRoots failed: $e\n$st');
      if (_disposed) return;
      emit(state.copyWith(
          isLoadingMoreRoots: false, error: _message(e), clearError: true));
    }
  }
  // ---------------------------------------------------------------- replies
  Future<void> _onLoadReplies(
      LoadRepliesEvent event, Emitter<CommentsState> emit) async {
    final rootId = event.rootId;
    final existing = state.repliesByRoot[rootId];
    if (existing != null && existing.isLoading) return;
    emit(state.copyWith(
      repliesByRoot: {
        ...state.repliesByRoot,
        rootId: (existing ?? const RootRepliesData())
            .copyWith(isLoading: true, clearError: true),
      },
      clearError: true,
    ));
    try {
      final page = await _api.getReplies(
          commentId: rootId, limit: _pageSize);
      if (_disposed) return;
      emit(state.copyWith(
        repliesByRoot: {
          ...state.repliesByRoot,
          rootId: RootRepliesData(
            replies: List<Comment>.from(page.comments).reversed.toList(),
            nextCursor: page.nextCursor,
            hasMore: page.nextCursor != null,
          ),
        },
      ));
    } catch (e, st) {
      debugPrint('[CommentsBloc] _onLoadReplies ($rootId) failed: $e\n$st');
      if (_disposed) return;
      emit(state.copyWith(
        repliesByRoot: {
          ...state.repliesByRoot,
          rootId: (existing ?? const RootRepliesData())
              .copyWith(isLoading: false, error: _message(e)),
        },
        error: _message(e),
        clearError: true,
        showToast: true,
      ));
    }
  }
  Future<void> _onLoadMoreReplies(
      LoadMoreRepliesEvent event, Emitter<CommentsState> emit) async {
    final rootId = event.rootId;
    final data = state.repliesByRoot[rootId];
    if (data == null || !data.hasMore || data.isLoading) return;
    final cursor = data.nextCursor;
    emit(state.copyWith(
      repliesByRoot: {
        ...state.repliesByRoot,
        rootId: data.copyWith(isLoading: true),
      },
      clearError: true,
    ));
    try {
      final page = await _api.getReplies(
          commentId: rootId, cursor: cursor, limit: _pageSize);
      if (_disposed) return;
      final older = List<Comment>.from(page.comments).reversed.toList();
      emit(state.copyWith(
        repliesByRoot: {
          ...state.repliesByRoot,
          rootId: data.copyWith(
            replies: [...older, ...data.replies],
            nextCursor: page.nextCursor,
            hasMore: page.nextCursor != null,
            isLoading: false,
          ),
        },
      ));
    } catch (e, st) {
      debugPrint(
          '[CommentsBloc] _onLoadMoreReplies ($rootId) failed: $e\n$st');
      if (_disposed) return;
      emit(state.copyWith(
        repliesByRoot: {
          ...state.repliesByRoot,
          rootId: data.copyWith(isLoading: false, error: _message(e)),
        },
        error: _message(e),
        clearError: true,
        showToast: true,
      ));
    }
  }
  Future<void> _onToggleReplies(
      ToggleRepliesEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(
      repliesExpanded: {
        ...state.repliesExpanded,
        event.rootId: event.expand,
      },
    ));
    if (event.expand) {
      add(LoadRepliesEvent(rootId: event.rootId));
    }
  }
  // --------------------------------------------------------------- composer
  Future<void> _onComposerText(
      ComposerTextEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(
      composerText: event.text,
      mentionSelections: event.mentionSelections,
    ));
  }
  Future<void> _onSetReplyTarget(
      SetReplyTargetEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(
      replyTargetRootId: event.rootId,
      composerText: '',
      mentionSelections: const [],
    ));
  }
  // -------------------------------------------------------- post / edit / del
  Comment _withReplyCount(Comment root, int newCount) {
    return Comment(
      id: root.id,
      targetType: root.targetType,
      targetId: root.targetId,
      author: root.author,
      text: root.text,
      createdAtMs: root.createdAtMs,
      editedAtMs: root.editedAtMs,
      deletedAtMs: root.deletedAtMs,
      isDeleted: root.isDeleted,
      canEdit: root.canEdit,
      canDelete: root.canDelete,
      rootCommentId: root.rootCommentId,
      isReply: root.isReply,
      hasReplies: newCount > 0,
      replyCount: newCount,
      attachments: root.attachments,
      mentions: root.mentions,
      replyAuthors: root.replyAuthors,
    );
  }
  Future<void> _onPostComment(
      PostCommentEvent event, Emitter<CommentsState> emit) async {
    final trimmed = event.text.trim();
    if ((trimmed.isEmpty && event.attachmentIds.isEmpty) ||
        state.isSending ||
        state.hasPendingAttachments) {
      return;
    }
    emit(state.copyWith(isSending: true, clearError: true));
    try {
      final comment = await _api.createComment(
        targetType: _targetType,
        targetId: _targetId,
        text: event.text,
        idempotencyKey: event.idempotencyKey,
        rootCommentId: event.rootCommentId,
        attachmentIds: event.attachmentIds,
        mentionedUserIds: event.mentionedUserIds,
      );
      _pendingPostKey = null;
      _pendingPostRootId = null;
      if (_disposed) return;
      var roots = List<Comment>.from(state.roots);
      var repliesByRoot =
          Map<String, RootRepliesData>.from(state.repliesByRoot);
      if (comment.isReply && event.rootCommentId != null) {
        final rootId = event.rootCommentId!;
        final data = repliesByRoot[rootId];
        if (data != null) {
          // New reply renders at the end of the oldest–newest list.
          repliesByRoot = {
            ...repliesByRoot,
            rootId: data.copyWith(replies: [...data.replies, comment]),
          };
        }
        final rootIndex = roots.indexWhere((c) => c.id == rootId);
        if (rootIndex >= 0) {
          roots[rootIndex] = _withReplyCount(
              roots[rootIndex], roots[rootIndex].replyCount + 1);
        }
      } else {
        // New root renders at the bottom (newest).
        roots = [...roots, comment];
      }
      emit(state.copyWith(
        roots: roots,
        repliesByRoot: repliesByRoot,
        composerText: '',
        mentionSelections: const [],
        attachmentDrafts: const [],
        replyTargetRootId: null,
        isSending: false,
      ));
    } catch (e) {
      // Keep the draft and its idempotency key so the retry is safe.
      _pendingPostKey = event.idempotencyKey;
      _pendingPostRootId = event.rootCommentId;
      if (_disposed) return;
      emit(state.copyWith(
          isSending: false, error: _message(e), clearError: true));
    }
  }
  Future<void> _onEditComment(
      EditCommentEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      final updated = await _api.editComment(
        commentId: event.comment.id,
        text: event.text,
        idempotencyKey: event.idempotencyKey,
        mentionedUserIds: event.mentionedUserIds,
      );
      if (_disposed) return;
      final roots = List<Comment>.from(state.roots);
      final repliesByRoot =
          Map<String, RootRepliesData>.from(state.repliesByRoot);
      _replaceComment(roots, repliesByRoot, updated);
      emit(state.copyWith(roots: roots, repliesByRoot: repliesByRoot));
    } catch (e) {
      if (_disposed) return;
      emit(state.copyWith(error: _message(e), clearError: true));
    }
  }
  Future<void> _onDeleteComment(
      DeleteCommentEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      final updated = await _api.deleteComment(
        commentId: event.comment.id,
        idempotencyKey: event.idempotencyKey,
      );
      if (_disposed) return;
      final roots = List<Comment>.from(state.roots);
      final repliesByRoot =
          Map<String, RootRepliesData>.from(state.repliesByRoot);
      _replaceComment(roots, repliesByRoot, updated);
      if (updated.isReply &&
          updated.rootCommentId != null &&
          updated.isDeleted) {
        final rootId = updated.rootCommentId!;
        final rootIndex = roots.indexWhere((c) => c.id == rootId);
        if (rootIndex >= 0 && roots[rootIndex].replyCount > 0) {
          roots[rootIndex] = _withReplyCount(
              roots[rootIndex], roots[rootIndex].replyCount - 1);
        }
      }
      emit(state.copyWith(roots: roots, repliesByRoot: repliesByRoot));
    } catch (e) {
      if (_disposed) return;
      emit(state.copyWith(error: _message(e), clearError: true));
    }
  }
  // ------------------------------------------------------------ attachments
  /// Client-side pre-validation mirroring the server allowlist. Returns a
  /// l10n key fragment ('limit' | 'invalidType' | 'empty' | 'tooLarge') or
  /// null when the file is acceptable.
  String? validateAttachment(
      String fileName, int byteSize, int currentCount) {
    if (currentCount >= maxAttachmentsPerComment) {
      return 'limit';
    }
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    if (!allowedExtensions.contains(ext)) {
      return 'invalidType';
    }
    if (byteSize <= 0) {
      return 'empty';
    }
    if (byteSize > maxAttachmentBytes) {
      return 'tooLarge';
    }
    return null;
  }
  Future<void> _onUploadAttachment(
      UploadAttachmentEvent event, Emitter<CommentsState> emit) async {
    final draft = ComposerAttachmentDraft(
      localPath: event.localPath,
      fileName: event.fileName,
      byteSize: event.byteSize,
      retryKey: event.retryKey,
      step: ComposerAttachmentStep.uploading,
    );
    emit(state.copyWith(
        attachmentDrafts: [...state.attachmentDrafts, draft]));
    try {
      final uploaded = await _api.uploadAttachment(
        targetType: _targetType,
        targetId: _targetId,
        file: File(event.localPath),
        retryKey: event.retryKey,
      );
      if (_disposed) return;
      // Poll until the scan resolves to a terminal state.
      final resolved =
          await _api.getAttachmentStatus(attachmentId: uploaded.id);
      if (_disposed) return;
      final isReady =
          resolved.state == 'ready' || resolved.state == 'attached';
      emit(state.copyWith(
        attachmentDrafts: _replaceDraft(state.attachmentDrafts,
            draft.copyWith(
          attachmentId: uploaded.id,
          step: isReady
              ? ComposerAttachmentStep.ready
              : ComposerAttachmentStep.rejected,
        )),
      ));
    } catch (e) {
      // Release-useful: attachment upload failures are otherwise only
      // visible as the generic toast.
      debugPrint('[CommentsBloc] attachment upload failed: $e');
      if (_disposed) return;
      emit(state.copyWith(
        attachmentDrafts: _replaceDraft(state.attachmentDrafts,
            draft.copyWith(step: ComposerAttachmentStep.failed)),
        error: _message(e),
        clearError: true,
        showToast: true,
      ));
    }
  }
  Future<void> _onRemoveAttachment(
      RemoveAttachmentEvent event, Emitter<CommentsState> emit) async {
    final drafts = [
      for (final draft in state.attachmentDrafts)
        if (draft.localPath != event.localPath) draft,
    ];
    emit(state.copyWith(attachmentDrafts: drafts));
    final attachmentId = event.attachmentId;
    if (attachmentId == null) return;
    // Best-effort cancel of the unclaimed quarantine row.
    unawaited(_api.cancelAttachment(attachmentId: attachmentId).catchError(
        (_) => attachmentId));
  }
  Future<void> _onDownloadAttachment(
      DownloadAttachmentEvent event, Emitter<CommentsState> emit) async {
    emit(state.copyWith(clearError: true));
    try {
      final result =
          await _api.downloadAttachment(attachmentId: event.attachmentId);
      if (_disposed) return;
      final tempDir = await getTemporaryDirectory();
      final safeName =
          result.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final suffix = _uuid.v4().substring(0, 8);
      final file = File(
          '${tempDir.path}${Platform.pathSeparator}comment_${suffix}_$safeName');
      await file.writeAsBytes(result.bytes);
      // No in-app viewer exists yet; the section surfaces the localized
      // "attachment saved" toast for this state.
      emit(state.copyWith(
          clearError: true,
          showToast: true,
          toastKind: CommentToastKind.attachmentSaved));
    } catch (e) {
      if (_disposed) return;
      emit(state.copyWith(error: _message(e), clearError: true));
    }
  }
}
