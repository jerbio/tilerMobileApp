// Tilette Detail — the web-style tile-share detail screen (Flutter side).
//
// Reached from the tilette card's comments button (NOT the tile-detail
// AppBar; the obsolete AppBar comments action was removed 2026-07-02).
// Like the web Tilette Detail page, it shows ONLY a summary header
// (name, note, due date) above the infinite-scroll comments thread —
// never the rendered tile schedule, which stays behind the card's "view
// tile" button.
//
// Comments target contract: targetType `tileshare_tilette`, target id
// `TileShareTemplate.Id` (the shared tilette's own id, e.g.
// "TileShareTemplate+<cluster>+<template>"). This is NOT the per-user
// designation id (`DesignatedTile.id`, "DesignatedTileTemplate+...") — the
// server's fail-closed access lookup matches `TileShareTemplates.Id` only,
// so the designation id always answers HTTP 403 "Failed to authenticate
// user account" (CustomErrors.cannotAuthenticate), which is a read-access
// denial, not a rejected Bearer token. Pages of 10 roots
// (comments_section auto-loads earlier roots on scroll-to-top).
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/bloc/comments/comments_state.dart';
import 'package:tiler_app/components/comments/comments_section.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/comments_api.dart';

class TiletteDetailScreen extends StatefulWidget {
  const TiletteDetailScreen({Key? key, required this.designatedTile})
      : super(key: key);

  /// The shared tilette; its `id` is the comments target id.
  final DesignatedTile designatedTile;

  /// Pushes this screen for [designatedTile] — the card comments button
  /// entry point.
  static Future<void> byTilette({
    required BuildContext context,
    required DesignatedTile designatedTile,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TiletteDetailScreen(designatedTile: designatedTile),
      ),
    );
  }

  @override
  State<TiletteDetailScreen> createState() => _TiletteDetailScreenState();
}

class _TiletteDetailScreenState extends State<TiletteDetailScreen> {
  late final BuildContext _hostContext = context;

  @override
  Widget build(BuildContext context) {
    final tile = widget.designatedTile;
    final title = (tile.name ?? '').trim();
    // The comments target is the shared template's own id (the server's
    // fail-closed lookup matches TileShareTemplates.Id). The per-user
    // designation id (tile.id) is deliberately NOT used: it can never
    // match and the request would 403 on every tilette.
    final id = (tile.tileTemplate?.id ?? '').trim();
    // The comments section is inert without a template id; the button that
    // reaches this screen only renders when the id is non-null.
    if (id.isEmpty) {
      debugPrint('[TiletteDetail] no TileShareTemplate id; comments cannot load');
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'This tilette has no comment thread.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          _TiletteHeader(tilette: tile),
          const Divider(height: 1),
          Expanded(
            child: BlocProvider<CommentsBloc>(
              create: (_) {
                final bloc = CommentsBloc(
                  targetType: CommentsApi.tileShareTiletteTargetType,
                  targetId: id,
                  pageSize: 10,
                  getContextCallBack: () => _hostContext,
                );
                // Kept for the saved-SnackBar's Open action; cleared when
                // the panel unmounts.
                _commentsBloc = bloc;
                return bloc..add(const LoadThreadEvent());
              },
              lazy: false,
              child: CommentsSection(
                onStateChange: _onCommentsStateChange,
                onToast: (String message) => _showToast(message),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onCommentsStateChange(CommentsState state) {
    if (!state.showToast) {
      return;
    }
    if (state.toastKind == CommentToastKind.attachmentOpenFailed) {
      // Localized "couldn't open" confirmation; the raw bloc error (e.g.
      // MissingPluginException while a native rebuild is pending) is not
      // user-friendly, so it is only logged above.
      if (!mounted) return;
      final l10n = AppLocalizations.of(_hostContext);
      debugPrint('[DownloadDiag] host: showing open-failed SnackBar');
      ScaffoldMessenger.of(_hostContext)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(
                l10n?.commentsAttachmentOpenFailed ?? "Couldn't open the file.")));
      return;
    }
    if (state.toastKind != CommentToastKind.attachmentSaved) {
      return;
    }
    // The saved-file confirmation carries the real on-device name plus an
    // Open action that re-dispatches through the bloc.
    final name = state.savedFileName;
    if (name == null || name.isEmpty) {
      debugPrint('[DownloadDiag] host: saved toast without savedFileName');
      return;
    }
    final attachmentId = state.savedFileId;
    if (!mounted) return;
    final l10n = AppLocalizations.of(_hostContext);
    if (l10n == null) {
      _showToast('Saved $name');
      return;
    }
    debugPrint('[DownloadDiag] host: showing saved SnackBar '
        '("$name") with Open action id=$attachmentId');
    ScaffoldMessenger.of(_hostContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.commentsAttachmentSaved(name)),
        action: SnackBarAction(
          label: l10n.commentsAttachmentOpen,
          onPressed: () {
            if (attachmentId == null) return;
            debugPrint(
                '[DownloadDiag] host: Open action tapped id=$attachmentId');
            _commentsBloc
                ?.add(OpenAttachmentEvent(attachmentId: attachmentId, fileName: name));
          },
        ),
      ));
  }

  /// The bloc instance while the comments panel is mounted; the Open
  /// action needs it to dispatch [OpenAttachmentEvent].
  CommentsBloc? _commentsBloc;

  void _showToast(String message) {
    debugPrint('[DownloadDiag] host _showToast called: "$message" '
        '(mounted=$mounted)');
    if (!mounted || message.isEmpty) {
      debugPrint('[DownloadDiag] host _showToast SKIPPED '
          '(mounted=$mounted, empty=${message.isEmpty})');
      return;
    }
    ScaffoldMessenger.of(_hostContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The web-style summary header: note/description and due date.
/// The tile name is already shown in the AppBar, so it is intentionally
/// omitted here to avoid duplication (matches the desktop layout where
/// the page header only shows metadata).
class _TiletteHeader extends StatelessWidget {
  const _TiletteHeader({Key? key, required this.tilette}) : super(key: key);

  final DesignatedTile tilette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final note = (tilette.tileTemplate?.miscData?.userNote ?? '').trim();
    final DateTime? end = tilette.endTime;

    final rows = <Widget>[
      if (note.isNotEmpty)
        Text(
          note,
          style: textTheme.bodySmall
              ?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      if (end != null)
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            l10n.deadlineTime(
                DateFormat.yMMMMd().add_jm().format(end.toLocal())),
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
    ];

    // If there is no note and no deadline, render nothing (the AppBar
    // already provides context).
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}