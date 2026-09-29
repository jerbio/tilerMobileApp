part of 'comments_state.dart';

class CommentsBloc extends Bloc<CommentsEvent, CommentsState> {
  static const int maxAttachmentsPerComment = 5;
  static const int maxAttachmentBytes = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedExtensions =
      ['pdf', 'docx', 'png', 'jpg', 'jpeg'];

  /// Leading bytes identifying the real format behind each allowed
  /// extension (PDF marker, PNG/JPEG markers, ZIP container for DOCX).
  /// file_picker v11 exposes no MIME type for a picked file and a
  /// filename-derived MIME would just restate the extension, so the header
  /// is the only client-side source of truth for what the bytes actually
  /// are — see [validateSignature].
  static const Map<String, List<int>> _contentSignatures = {
    'pdf': [0x25, 0x50, 0x44, 0x46], // "%PDF"
    'png': [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
    'jpg': [0xFF, 0xD8, 0xFF],
    'jpeg': [0xFF, 0xD8, 0xFF],
    // DOCX is an OOXML (ZIP) container; PK\x03\x04 is the strongest
    // header-level check without a full archive parser (it still rules
    // out executables, scripts and every non-ZIP disguise).
    'docx': [0x50, 0x4B, 0x03, 0x04],
  };
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
    on<AddAttachmentEvent>(_onAddAttachment);
    on<RemoveAttachmentEvent>(_onRemoveAttachment);
    on<DownloadAttachmentEvent>(_onDownloadAttachment);
    on<OpenAttachmentEvent>(_onOpenAttachment);
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
    return LocalizationService.instance.translations.reachingServerIssues;
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
    if ((trimmed.isEmpty && state.attachmentDrafts.isEmpty) ||
        state.isSending ||
        state.hasPendingAttachments) {
      return;
    }
    emit(state.copyWith(isSending: true, clearError: true));
    try {
      // Uploads happen here, not at pick time: a file only ever reaches the
      // quarantine (and thus storage) if the comment is actually posted.
      // Local drafts and drafts whose previous upload failed are retried
      // with their stored idempotency key.
      for (final target in state.attachmentDrafts) {
        if (target.step != ComposerAttachmentStep.local &&
            target.step != ComposerAttachmentStep.failed) {
          continue;
        }
        emit(state.copyWith(
          attachmentDrafts: _replaceDraft(
              state.attachmentDrafts,
              target.copyWith(
                  step: ComposerAttachmentStep.uploading,
                  clearErrorMessage: true)),
        ));
        final (updatedDraft, uploadError) = await _uploadDraft(target);
        if (_disposed) return;
        emit(state.copyWith(
          attachmentDrafts: _replaceDraft(
              state.attachmentDrafts, updatedDraft),
          error: uploadError.isEmpty ? state.error : uploadError,
          clearError: !uploadError.isEmpty,
          showToast: uploadError.isNotEmpty,
        ));
        if (!updatedDraft.isClaimable) {
          // The comment is aborted, but no request has been made yet — do
          // not park an idempotency key, so a later send mints a fresh one.
          _pendingPostKey = null;
          _pendingPostRootId = null;
          emit(state.copyWith(isSending: false));
          return;
        }
      }
      // Resolve the claimable ids from the current state so a draft removed
      // mid-upload is honored.
      final attachmentIds = state.attachmentDrafts
          .where((d) => d.isClaimable)
          .map((d) => d.attachmentId!)
          .toList();
      final comment = await _api.createComment(
        targetType: _targetType,
        targetId: _targetId,
        text: event.text,
        idempotencyKey: event.idempotencyKey,
        rootCommentId: event.rootCommentId,
        attachmentIds: attachmentIds,
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

  /// Content-level complement of [validateAttachment]: reads the file's
  /// leading bytes and verifies they match the signature of its extension,
  /// so a disallowed file renamed to a permitted extension (the picker's
  /// filter is bypassable on desktop) is rejected at pick time instead of
  /// failing the server scan at send time. Returns the same 'invalidType'
  /// code on a mismatch or when the header cannot be read, null on success.
  static Future<String?> validateSignature(
      String localPath, String fileName) async {
    final dot = fileName.lastIndexOf('.');
    final ext = dot >= 0 ? fileName.substring(dot + 1).toLowerCase() : '';
    final signature = _contentSignatures[ext];
    if (signature == null) return 'invalidType';
    final head = <int>[];
    try {
      // Bounded read: only the header bytes are consumed from the stream.
      await for (final chunk in File(localPath).openRead()) {
        final take =
            head.length + chunk.length > 16 ? 16 - head.length : chunk.length;
        head.addAll(chunk.sublist(0, take));
        if (head.length == 16) break;
      }
    } catch (e) {
      debugPrint('[CommentsBloc] signature check: cannot read header of '
          '$fileName: $e');
      return 'invalidType';
    }
    if (head.length < signature.length) return 'invalidType';
    for (var i = 0; i < signature.length; i++) {
      if (head[i] != signature[i]) return 'invalidType';
    }
    return null;
  }
  Future<void> _onAddAttachment(
      AddAttachmentEvent event, Emitter<CommentsState> emit) async {
    // Local-only: no network traffic and no server storage until the
    // comment is actually sent.
    final draft = ComposerAttachmentDraft(
      localPath: event.localPath,
      fileName: event.fileName,
      byteSize: event.byteSize,
      retryKey: event.retryKey,
    );
    emit(state.copyWith(
        attachmentDrafts: [...state.attachmentDrafts, draft]));
  }

  /// Uploads [draft] into the quarantine and polls until the scan resolves
  /// to a terminal state. Pure: it reports the updated draft and an error
  /// message ('' when none) without emitting; the caller applies both to
  /// the state. [draft.retryKey] keeps the upload idempotent, so a retried
  /// send never uploads the same file twice.
  Future<(ComposerAttachmentDraft, String)> _uploadDraft(
      ComposerAttachmentDraft draft) async {
    try {
      final uploaded = await _api.uploadAttachment(
        targetType: _targetType,
        targetId: _targetId,
        file: File(draft.localPath),
        retryKey: draft.retryKey,
      );
      if (_disposed) {
        return (draft, '');
      }
      // Poll until the scan resolves to a terminal state.
      final resolved =
          await _api.getAttachmentStatus(attachmentId: uploaded.id);
      if (_disposed) {
        return (draft, '');
      }
      final isReady =
          resolved.state == 'ready' || resolved.state == 'attached';
      debugPrint('[CommentsBloc] attachment ${draft.fileName} resolved: '
          'id=${uploaded.id} state=${resolved.state}');
      return (
        draft.copyWith(
          attachmentId: uploaded.id,
          step: isReady
              ? ComposerAttachmentStep.ready
              : ComposerAttachmentStep.rejected,
        ),
        '',
      );
    } catch (e, st) {
      // Release-useful: attachment upload failures are otherwise only
      // visible as the generic toast.
      debugPrint('[CommentsBloc] attachment upload failed '
          '(file=${draft.fileName} bytes=${draft.byteSize} '
          'retryKey=${draft.retryKey}): $e\n$st');
      if (_disposed) {
        return (draft, '');
      }
      return (
        draft.copyWith(step: ComposerAttachmentStep.failed),
        _message(e),
      );
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
  /// Native channel backed by MainActivity's
  /// `tiler_app/comment_downloads` handler. Android 10+ (scoped storage, and
  /// this app targets 36) blocks file-path writes to the public Downloads
  /// folder, so the write happens in Kotlin via MediaStore and returns the
  /// stored file name.
  static const MethodChannel _downloadsChannel =
      MethodChannel('tiler_app/comment_downloads');

  /// In-memory map of attachment id to where its file was stored on this
  /// device during this session: `'media:<contentUri>'` for the shared
  /// Android Downloads folder (MediaStore), `'media:<displayName>'` when the
  /// native side had no URI, or an absolute path for the temp-directory
  /// fallback. Needed so the SnackBar's Open action can reopen the file
  /// without downloading it again.
  final Map<String, String> _savedFiles = {};

  /// Display name per attachment id (for the "Saved {name}" SnackBar and
  /// the MIME lookup when opening a stored content URI).
  final Map<String, String> _savedFileNames = {};

  /// Persists [bytes] somewhere the user can actually find: the shared
  /// Downloads folder on Android (MediaStore) and iOS (path_provider), with a
  /// temp-directory fallback on unsupported platforms or when the write
  /// fails. Returns the resolved location and the display name.
  Future<({String location, String name})> _persistCommentAttachment(
      List<int> bytes, String safeName) async {
    debugPrint('[DownloadDiag] persist: start safeName=$safeName '
        'bytes=${bytes.length} platform=${Platform.operatingSystem}');
    if (Platform.isAndroid) {
      try {
        final saved = await _downloadsChannel.invokeMethod<Map>(
          'saveToDownloads',
          {
            // The standard codec encodes Uint8List as an int list, which the
            // Kotlin side receives as IntArray.
            'bytes': bytes,
            'fileName': safeName,
            // When a file with the same name and size is already in
            // Downloads the native side reuses its name instead of
            // appending "(2)", so re-downloads stay put.
            'expectedBytes': bytes.length,
          },
        );
        final name = saved?['name']?.toString() ?? '';
        final uri = saved?['uri']?.toString() ?? '';
        if (name.isNotEmpty) {
          // Prefer the exact MediaStore row URI the native side wrote: a
          // DISPLAY_NAME re-query right after the insert can miss the fresh
          // row, while the URI stays valid until the user deletes the file.
          if (uri.startsWith('content://')) {
            debugPrint('[DownloadDiag] persist: Android MediaStore channel OK, '
                'name=$name uri=$uri');
            return (location: 'media:$uri', name: name);
          }
          // The native side returns either the MediaStore display name
          // (no separators) or an absolute fallback path.
          final isPath = name.contains(Platform.pathSeparator);
          debugPrint('[DownloadDiag] persist: Android MediaStore channel OK, '
              'name=$name isPath=$isPath');
          return isPath
              ? (location: name,
                  name: name.split(Platform.pathSeparator).last)
              : (location: 'media:$name', name: name);
        }
        debugPrint(
            '[CommentsBloc] Downloads channel returned a null name for $safeName; '
            'falling back to the app temp directory');
      } catch (e, st) {
        debugPrint(
            '[CommentsBloc] Downloads channel failed for $safeName: $e; '
            'falling back to the app temp directory\n$st');
      }
    }
    debugPrint('[DownloadDiag] persist: using Dart fallback '
        '(platform=${Platform.operatingSystem})');
    // Prefer the shared Downloads folder so the file is easy to find, but it
    // is not guaranteed to exist — on iOS the OS does not pre-create a
    // Downloads folder, so path_provider returns a path we must create on
    // demand. If that is not possible we fall back to the temp dir, which is
    // created by path_provider and always writable.
    Directory dir = await getTemporaryDirectory();
    var usingDownloads = false;
    Directory? targetDir;
    try {
      targetDir = await getDownloadsDirectory();
    } catch (e) {
      targetDir = null;
      debugPrint('[DownloadDiag] persist: getDownloadsDirectory threw: $e');
    }
    if (targetDir != null) {
      try {
        // Create the folder on demand; a missing Downloads dir is the cause
        // of the PathNotFoundException on iOS.
        if (!targetDir.existsSync()) {
          await targetDir.create(recursive: true);
        }
        dir = targetDir;
        usingDownloads = true;
      } catch (e) {
        debugPrint('[DownloadDiag] persist: could not use ${targetDir.path} '
            '($e); keeping the temp dir');
      }
    }
    if (!dir.existsSync()) await dir.create(recursive: true);
    debugPrint('[DownloadDiag] persist: writing to dir=${dir.path} '
        'isDownloadsDir=$usingDownloads exists=${dir.existsSync()}');
    final file = File(
        '${dir.path}${Platform.pathSeparator}comment_${_uuid.v4().substring(0, 8)}_$safeName');
    await file.writeAsBytes(bytes);
    debugPrint('[DownloadDiag] persist: wrote ${bytes.length} bytes to '
        '${file.path} exists=${file.existsSync()} '
        'size=${file.existsSync() ? file.lengthSync() : -1}');
    return (location: file.path, name: safeName);
  }

  Future<void> _onDownloadAttachment(
      DownloadAttachmentEvent event, Emitter<CommentsState> emit) async {
    debugPrint(
        '[DownloadDiag] bloc: DownloadAttachmentEvent received '
        'id=${event.attachmentId} fileName=${event.fileName}');
    emit(state.copyWith(
        clearError: true,
        downloadingFileId: event.attachmentId,
        downloadProgress: 0.0));
    int lastPercent = -1;
    try {
      final result = await _api.downloadAttachment(
        attachmentId: event.attachmentId,
        onProgress: (received, total) {
          if (_disposed || total == null || total <= 0) return;
          final fraction = received / total.toDouble();
          final percent = (fraction * 100).floor();
          if (percent == lastPercent) return;
          lastPercent = percent;
          emit(state.copyWith(
              downloadingFileId: event.attachmentId,
              downloadProgress: fraction));
        },
      );
      debugPrint('[DownloadDiag] bloc: download returned '
          '${result.bytes.length} bytes, fileName=${result.fileName}');
      if (_disposed) {
        debugPrint('[DownloadDiag] bloc: disposed after download, aborting');
        return;
      }
      // The server currently does not send a Content-Disposition header, so
      // the API reports the 'attachment' sentinel — fall back to the
      // attachment's known display name (keeps the real name + extension).
      final saved = await _storeDownloaded(
          result.bytes, result.fileName,
          attachmentId: event.attachmentId,
          fallbackName: event.fileName);
      if (saved == null) return;
      debugPrint('[CommentsBloc] attachment saved: ${saved.location}');
      debugPrint('[DownloadDiag] bloc: emitting showToast '
          '(attachmentSaved) onDeviceName=${saved.name}');
      // The host screen surfaces the localized "Saved {name}" SnackBar
      // with an Open action for this state.
      emit(state.copyWith(
          clearError: true,
          clearDownload: true,
          savedFileId: event.attachmentId,
          savedFileName: saved.name,
          showToast: true,
          toastKind: CommentToastKind.attachmentSaved));
    } catch (e, st) {
      debugPrint('[DownloadDiag] bloc: download FAILED id='
          '${event.attachmentId} error=$e\n$st');
      if (_disposed) return;
      emit(state.copyWith(
          clearDownload: true,
          error: _message(e),
          showToast: true,
          toastKind: CommentToastKind.error));
    }
  }

  /// Stores the downloaded [bytes] under the display name the server
  /// reported ([serverFileName]), falling back to the attachment's own
  /// display name when that is the 'attachment' sentinel. Returns the
  /// location record (`media:<name>` or absolute path) or null when the
  /// bloc was disposed mid-write.
  Future<({String location, String name})?> _storeDownloaded(
      List<int> bytes, String serverFileName,
      {required String attachmentId, required String fallbackName}) async {
    // The server currently does not send a Content-Disposition header, so
    // the API reports the 'attachment' sentinel — fall back to the
    // attachment's known display name (keeps the real name + extension).
    final server = serverFileName.trim();
    final chosen = (server.isEmpty || server == 'attachment')
        ? fallbackName.trim()
        : server;
    final sanitized = chosen.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final name = sanitized.isEmpty ? 'attachment' : sanitized;
    debugPrint('[DownloadDiag] bloc: safeName=$name');
    final saved = await _persistCommentAttachment(bytes, name);
    if (_disposed) {
      debugPrint('[DownloadDiag] bloc: disposed after persist, aborting');
      return null;
    }
    _savedFiles[attachmentId] = saved.location;
    _savedFileNames[attachmentId] = saved.name;
    return saved;
  }

  /// Opens a previously saved attachment. The in-memory location is used
  /// when it still exists on disk; otherwise the file is re-downloaded
  /// (which updates the location map) and opened.
  Future<void> _onOpenAttachment(
      OpenAttachmentEvent event, Emitter<CommentsState> emit) async {
    debugPrint('[DownloadDiag] bloc: OpenAttachmentEvent id='
        '${event.attachmentId}');
    final String location = _savedFiles[event.attachmentId] ?? '';
    if (location.isEmpty ||
        !(location.startsWith('media:') || File(location).existsSync())) {
      debugPrint('[DownloadDiag] bloc: stored location unavailable '
          '($location), re-downloading');
      final fresh = await _downloadAndPersist(
          event.attachmentId, event.fileName, emit);
      if (fresh == null) return;
      await _openSavedLocation(event.attachmentId, fresh, emit);
      return;
    }
    await _openSavedLocation(event.attachmentId, location, emit);
  }

  /// Downloads [attachmentId] and stores it; returns the location record
  /// (`media:<name>` or absolute path) or null when the download failed
  /// (an error toast was already shown).
  Future<String?> _downloadAndPersist(String attachmentId, String fileName,
      Emitter<CommentsState> emit) async {
    try {
      final result = await _api.downloadAttachment(attachmentId: attachmentId);
      if (_disposed) return null;
      final saved = await _storeDownloaded(result.bytes, result.fileName,
          attachmentId: attachmentId, fallbackName: fileName);
      if (saved == null) return null;
      return saved.location;
    } catch (e, st) {
      debugPrint('[DownloadDiag] bloc: open re-download FAILED id='
          '$attachmentId error=$e\n$st');
      if (_disposed) return null;
      emit(state.copyWith(
          error: _message(e),
          showToast: true,
          toastKind: CommentToastKind.error));
      return null;
    }
  }

  /// Launches the system viewer for the attachment stored at [location]:
  /// the native channel resolves the MediaStore content URI on Android
  /// (plain file paths are blocked by FileUriExposure), open_filex handles
  /// the other platforms.
  Future<void> _openSavedLocation(String attachmentId, String location,
      Emitter<CommentsState> emit) async {
    debugPrint('[DownloadDiag] bloc: opening $location');
    try {
      if (Platform.isAndroid && location.startsWith('media:')) {
        final target = location.substring('media:'.length);
        final isUri = target.startsWith('content://');
        await _downloadsChannel.invokeMethod<String>('openInDownloads', {
          // Pass the exact row URI when we have one; the native side opens
          // it directly and only falls back to a DISPLAY_NAME query when
          // no activity accepts the URI (e.g. the file was deleted).
          'fileName': _savedFileNames[attachmentId] ??
              (isUri ? target.split('/').last : target),
          if (isUri) 'uri': target,
        });
      } else {
        final openResult = await OpenFilex.open(location);
        if (openResult.type != ResultType.done) {
          throw TilerError(
              Message: openResult.message.isNotEmpty
                  ? openResult.message
                  : 'open failed');
        }
      }
      debugPrint('[DownloadDiag] bloc: open ok id=$attachmentId');
    } catch (e, st) {
      debugPrint('[DownloadDiag] bloc: open FAILED id=$attachmentId '
          'location=$location error=$e\n$st');
      if (_disposed) return;
      _savedFiles.remove(attachmentId);
      _savedFileNames.remove(attachmentId);
      // Use the dedicated open-failed toast kind so the host can show the
      // localized "couldn't open" message instead of the raw error, which
      // is often misleading (e.g. MissingPluginException after a native
      // rebuild is pending is not a server problem).
      emit(state.copyWith(
          error: _message(e),
          showToast: true,
          toastKind: CommentToastKind.attachmentOpenFailed));
    }
  }
}
