import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';
import 'package:tiler_app/components/comments/comment_composer.dart';
import 'package:tiler_app/components/comments/comment_item.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// The full comments panel for a tile share: count header, paged root
/// comments (with lazy replies) and the docked composer. The parent must
/// provide a [CommentsBloc] above this widget.
class CommentsSection extends StatefulWidget {
  /// Called with [CommentsState] after every bloc transition so the host
  /// can surface toasts and forward the composer's idempotency-key lookup.
  final ValueChanged<CommentsState>? onStateChange;

  /// Forwards toast messages (e.g. attachment errors) to the host overlay.
  final ValueChanged<String> onToast;

  const CommentsSection({
    Key? key,
    this.onStateChange,
    required this.onToast,
  }) : super(key: key);

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  bool _wasShowingToast = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bloc = context.watch<CommentsBloc>();
    final state = bloc.state;

    final count = state.roots.fold<int>(0, (sum, c) => sum + 1 + c.replyCount);

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            l10n.commentsCount(count),
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        _Body(state: state, bloc: bloc),
        CommentComposer(
          onEvent: bloc.add,
          reusablePostKey: bloc.reusablePostKey,
          onToast: widget.onToast,
        ),
      ],
    );
    return BlocListener<CommentsBloc, CommentsState>(
      listener: _onStateTransition,
      child: body,
    );
  }

  /// Surfaces toasts and forwards state changes event-driven, never from
  /// [build]. The "attachment saved" and "open failed" toasts are handled
  /// by the host screen (via [CommentsSection.onStateChange]) because they
  /// need localized text / an Open action; every other toast shows
  /// [CommentsState.error] verbatim.
  void _onStateTransition(BuildContext context, CommentsState state) {
    if (!mounted) return;
    if (state.showToast && !_wasShowingToast) {
      final isHostHandledToast =
          state.toastKind == CommentToastKind.attachmentSaved ||
              state.toastKind == CommentToastKind.attachmentOpenFailed;
      debugPrint('[DownloadDiag] section: toast detected kind='
          '${state.toastKind} error="${state.error}" '
          'savedFileName=${state.savedFileName}');
      if (!isHostHandledToast) {
        // The host shows the "Saved {name} — Open" / "couldn't open"
        // SnackBars itself.
        widget.onToast(state.error);
      }
      // Consume the toast so the next message can be surfaced again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<CommentsBloc>().add(const ClearToastEvent());
      });
    }
    _wasShowingToast = state.showToast;
    widget.onStateChange?.call(state);
  }
}

/// The scrollable root-comments area above the pinned composer.
///
/// Pages the web-style way: when the user scrolls to the top, an earlier
/// page of roots is fetched automatically (the bloc pages by its
/// `pageSize`, 10 on the Tilette Detail screen) and the scroll offset is
/// restored so the list does not jump. The "load earlier" button remains
/// as a manual fallback (it is the only trigger after a failed page).
class _Body extends StatefulWidget {
  final CommentsState state;
  final CommentsBloc bloc;

  const _Body({Key? key, required this.state, required this.bloc})
      : super(key: key);

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  final ScrollController _controller = ScrollController();
  /// An earlier-roots page was auto-triggered at the top; the offset is
  /// restored after the new items have been prepended.
  bool _autoLoadingEarlier = false;
  double _contentBeforeLoad = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The ListView was unmounted (loading/error/empty state) and took its
    // scroll position with it; a pending restore is now impossible.
    _autoLoadingEarlier = false;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (_controller.hasClients) _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    // ListView has no onScrollEnd; the scroll listener fires when the
    // top scroll settles. The latch in _loadEarlier keeps a triggered
    // page from firing again before it is prepended.
    if (_controller.hasClients && _controller.position.pixels <= 40.0) {
      _loadEarlier();
    }
  }

  /// Content height in pixels (the list has no bottom-infinite extent, so
  /// at rest this is the full scrollable content).
  double _contentHeight() {
    final position = _controller.position;
    return position.maxScrollExtent + position.viewportDimension;
  }

  void _loadEarlier() {
    if (_autoLoadingEarlier || widget.state.isLoadingMoreRoots) return;
    if (widget.state.rootsNextCursor == null) return;
    _contentBeforeLoad = _contentHeight();
    _autoLoadingEarlier = true;
    widget.bloc.add(const LoadMoreRootsEvent());
  }

  /// Restores the scroll offset after the prepended page settles and
  /// releases the auto-load latch.
  void _maybeRestoreAfterLoad() {
    if (!_autoLoadingEarlier) return;
    _autoLoadingEarlier = false;
    if (!(_controller.hasClients && _contentBeforeLoad > 0)) return;
    final restoreTo = _contentBeforeLoad -
        _controller.position.viewportDimension;
    final offset = restoreTo.clamp(
        0.0, _controller.position.maxScrollExtent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) {
        _controller.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    // A new page has been prepended — restore the scroll offset.
    _maybeRestoreAfterLoad();

    if (state.step == CommentsStep.loading && state.roots.isEmpty) {
      return _messageBox(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(l10n.commentsLoading,
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    if (state.step == CommentsStep.error && state.roots.isEmpty) {
      return _messageBox(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.error.isNotEmpty ? state.error : l10n.commentsLoadError,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => widget.bloc.add(const LoadThreadEvent()),
              child: Text(l10n.commentsRetry),
            ),
          ],
        ),
      );
    }

    if (state.roots.isEmpty && state.step == CommentsStep.loaded) {
      return _messageBox(
        context,
        child: Text(l10n.commentsEmpty,
            style: TextStyle(color: colorScheme.onSurfaceVariant)),
      );
    }

    return Expanded(
      child: ListView(
        controller: _controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final root in state.roots)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: CommentItem(
                comment: root,
                isRoot: true,
                replies: state.repliesByRoot[root.id],
                repliesExpanded: state.repliesExpanded[root.id] ?? false,
                onEvent: widget.bloc.add,
              ),
            ),
          if (state.isLoadingMoreRoots)
            const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (state.rootsNextCursor != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Center(
                child: TextButton(
                  onPressed:
                      () => widget.bloc.add(const LoadMoreRootsEvent()),
                  child: Text(l10n.commentsLoadEarlier),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _messageBox(BuildContext context, {required Widget child}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(child: child),
      ),
    );
  }
}
