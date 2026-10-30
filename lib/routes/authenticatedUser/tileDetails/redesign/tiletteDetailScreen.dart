// Shared tilette detail: task context, Overview, Notes and Comments.
// Cards open Overview; notes and comments shortcuts select their own tab.
// A permitted recipient's invitation actions stay in the bottom dock.
// The rendered schedule remains behind the separate Open tile action.
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
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/components/notes/markdownNoteEditor.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/api/comments_api.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/shareWorkWidgets.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_commitment_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_roster_cubit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/detail/projectRows.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/services/tileShare/tileShareSources.dart';
import 'package:tiler_app/services/api/notesApi.dart';
import 'package:tiler_app/services/tileShare/tileShareLog.dart';
import 'package:tiler_app/services/tileShare/tileShareNotesSession.dart';
import 'package:tiler_app/routes/authenticatedUser/editTile/editTileNotePage.dart';
import 'tiletteDetailContent.dart';

enum TiletteDetailTab { overview, notes, comments }

/// The share supplies permissions and borrows its already-open data sources.
/// Opening a tilette never fetches a profile or assumes who may answer it.
class TiletteDetailOptions {
  final String? shareName;
  final TileShareMode? mode;
  final TileShareTemplate? template;
  final TileShareAssignmentsSource? assignments;
  final bool canRespond;
  final VoidCallback? onAnswered;
  final VoidCallback? onOpenTile;

  /// Optional schedule preview for this recipient's pending assignment.
  final Future<DesignatedTile?> Function()? onPreview;
  final NotesApi? notesApi;

  /// Reading shared notes does not grant permission to edit them.
  final NotesApi? notesReadApi;
  final VoidCallback? onNotesChanged;

  /// Supplied only when the signed-in owner may change recipients.
  final TileShareRecipientsSource? ownerRecipients;
  final List<TileShareTemplate> ownerTilettes;
  final VoidCallback? onPeopleChanged;
  final Widget Function(BuildContext context, String templateId)?
      discussionBuilder;
  const TiletteDetailOptions(
      {this.shareName,
      this.mode,
      this.template,
      this.assignments,
      this.canRespond = false,
      this.onAnswered,
      this.onOpenTile,
      this.onPreview,
      this.notesApi,
      this.notesReadApi,
      this.onNotesChanged,
      this.ownerRecipients,
      this.ownerTilettes = const [],
      this.onPeopleChanged,
      this.discussionBuilder});
}

class TiletteDetailScreen extends StatefulWidget {
  const TiletteDetailScreen(
      {Key? key,
      required this.designatedTile,
      this.initialTab = TiletteDetailTab.overview,
      this.options = const TiletteDetailOptions()})
      : super(key: key);

  /// The shared tilette; its `id` is the comments target id.
  final DesignatedTile designatedTile;
  final TiletteDetailTab initialTab;
  final TiletteDetailOptions options;

  /// Opens the shared detail for a recipient's [designatedTile].
  static Future<void> byTilette({
    required BuildContext context,
    required DesignatedTile designatedTile,
    TiletteDetailTab initialTab = TiletteDetailTab.overview,
    TiletteDetailOptions options = const TiletteDetailOptions(),
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TiletteDetailScreen(
            designatedTile: designatedTile,
            initialTab: initialTab,
            options: options),
      ),
    );
  }

  /// The tilette as this screen reads it, from the owner's side: the
  /// owner has the tilette itself, not a copy designated to them. Its id is
  /// the thread's (the one thread every recipient shares).
  static DesignatedTile tileFor(TileShareTemplate tilette) =>
      DesignatedTile.fromJson(const <String, dynamic>{})
        ..name = tilette.name
        ..endInMs = tilette.end
        ..tileTemplate = tilette;

  /// Opens the shared detail for an owner's [tilette].
  static Future<void> byTemplate({
    required BuildContext context,
    required TileShareTemplate tilette,
    TiletteDetailTab initialTab = TiletteDetailTab.overview,
    TiletteDetailOptions options = const TiletteDetailOptions(),
  }) =>
      byTilette(
          context: context,
          designatedTile: tileFor(tilette),
          initialTab: initialTab,
          options: options);

  @override
  State<TiletteDetailScreen> createState() => _TiletteDetailScreenState();
}

class _TiletteDetailScreenState extends State<TiletteDetailScreen> {
  late final BuildContext _hostContext = context;
  late TiletteDetailTab _tab = widget.initialTab;
  TileShareTemplate? get _template =>
      widget.options.template ?? widget.designatedTile.tileTemplate;
  late String _note = (_template?.miscData?.userNote ?? '').trim();
  TileShareCommitmentCubit? _responses;
  TileShareRosterCubit? _ownerRoster;
  bool _pickingPerson = false;
  bool _answering = false;
  bool _notesLoading = false;
  bool _notesFailed = false;
  bool _notesRequested = false;
  late final TileShareNotesSession? _notesSession;
  int _noteRevision = 0;

  @override
  void initState() {
    super.initState();
    final reader = widget.options.notesReadApi ?? widget.options.notesApi;
    _notesSession = reader == null
        ? null
        : TileShareNotesSession(
            reader: reader, writer: widget.options.notesApi);
    if (_tab == TiletteDetailTab.notes) _loadNotes();
    final ownerRecipients = widget.options.ownerRecipients;
    final template = _template;
    if (ownerRecipients != null &&
        (template?.id ?? '').isNotEmpty &&
        (template?.clusterId ?? '').isNotEmpty) {
      _ownerRoster = TileShareRosterCubit(
          source: ownerRecipients,
          clusterId: template!.clusterId!,
          tilettes: [
            for (final t in widget.options.ownerTilettes)
              if (t.id != template.id) t,
            template,
          ]);
    }
    final source = widget.options.assignments;
    if (widget.options.canRespond &&
        source != null &&
        (widget.designatedTile.id ?? '').isNotEmpty) {
      _responses = TileShareCommitmentCubit(
          assignments: source,
          mine: [widget.designatedTile],
          onAnswered: widget.options.onAnswered);
    }
  }

  @override
  void dispose() {
    _responses?.close();
    _ownerRoster?.close();
    _notesSession?.dispose();
    super.dispose();
  }

  void _select(TiletteDetailTab tab) {
    setState(() {
      _tab = tab;
      _commentsBloc = null;
    });
    if (tab == TiletteDetailTab.notes && !_notesRequested) _loadNotes();
  }

  Future<void> _runAnswer(Future<void> Function() action) async {
    if (_answering) return;
    setState(() => _answering = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _answering = false);
    }
  }

  Future<void> _editNotes() async {
    final api = widget.options.notesApi == null ? null : _notesSession;
    final id = _template?.id;
    if (api == null || id == null || id.isEmpty) return;
    final saveCount = api.saveCount;
    await Navigator.of(context).push<String?>(MaterialPageRoute<String?>(
        builder: (_) => NoteFullPage(
              eventId: id,
              initialNote: _note,
              notesApi: api,
              onNotePersisted: (note) {
                if (mounted && note != _note) {
                  setState(() {
                    _noteRevision++;
                    _note = note;
                    _notesLoading = false;
                    _notesFailed = false;
                  });
                }
              },
            )));
    if (mounted && api.saveCount != saveCount) {
      widget.options.onNotesChanged?.call();
    }
  }

  Future<void> _loadNotes() async {
    final api = _notesSession;
    final id = (_template?.id ?? '').trim();
    if (api == null || id.isEmpty || _notesLoading) return;
    final revision = ++_noteRevision;
    setState(() {
      _notesLoading = true;
      _notesFailed = false;
      _notesRequested = true;
    });
    try {
      final payload = await api.getNotes(id);
      if (!mounted || revision != _noteRevision) return;
      setState(() => _note = payload.userNote ?? '');
    } catch (error) {
      if (!mounted || revision != _noteRevision) return;
      TileShareLog.d('TiletteDetail',
          'loading notes for $id failed: ${TileShareLog.describe(error)}');
      setState(() => _notesFailed = true);
    } finally {
      if (mounted && revision == _noteRevision) {
        setState(() => _notesLoading = false);
      }
    }
  }

  Widget _notesContent(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final hasNote = _note.trim().isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (hasNote) MarkdownNoteView(markdown: _note),
      if (_notesLoading)
        Row(key: const Key('tilette_notes_loading'), children: [
          const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: 8),
          Expanded(child: Text(l.notesLoading)),
        ])
      else if (_notesFailed)
        Column(
            key: const Key('tilette_notes_failed'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.shareNotesLoadFailed),
              TextButton(
                  key: const Key('tilette_notes_retry'),
                  onPressed: _loadNotes,
                  child: Text(l.attentionRetry)),
            ])
      else if (!hasNote)
        Text(l.shareNotesEmpty),
    ]);
  }

  Future<void> _preview() async {
    final updated = await widget.options.onPreview!();
    if (mounted && updated != null) _responses?.sync([updated]);
  }

  int get _assignedCount =>
      _ownerRoster?.state.rows
          .where((row) => row.cells
              .any((cell) => cell.tiletteId == _template?.id && cell.isPresent))
          .length ??
      0;

  Future<void> _changePeople(Future<void> Function() change) async {
    final before = _assignedCount;
    await change();
    if (mounted && _assignedCount > before) {
      widget.options.onPeopleChanged?.call();
    }
  }

  Future<void> _addPerson() async {
    final roster = _ownerRoster;
    final id = _template?.id;
    if (roster == null ||
        id == null ||
        _pickingPerson ||
        roster.state.tasks[id]?.phase == TaskChangePhase.working) return;
    setState(() => _pickingPerson = true);
    try {
      final contact = await showProjectAssignSheet(
          context, _template?.name ?? '', roster.state.rows,
          exclude: {
            for (final row in roster.state.rows)
              if (row.cells
                  .any((cell) => cell.tiletteId == id && cell.isPresent))
                row.key,
          });
      if (!mounted || contact == null) return;
      await _changePeople(() => roster.assignTask(id, contact));
    } finally {
      if (mounted) setState(() => _pickingPerson = false);
    }
  }

  Widget? _peopleFeedback(BuildContext context) {
    final change = _ownerRoster?.state.tasks[_template?.id];
    if (change == null) return null;
    final l = AppLocalizations.of(context)!;
    if (change.phase == TaskChangePhase.working) {
      return Row(children: [
        const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 8),
        Expanded(child: Text(l.participantAdding)),
      ]);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.participantAddFailed),
      TextButton(
          key: const Key('tilette_assign_retry'),
          onPressed: () =>
              _changePeople(() => _ownerRoster!.retryTask(_template!.id!)),
          child: Text(l.attentionRetry)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final roster = _ownerRoster;
    if (roster != null) {
      return BlocBuilder<TileShareRosterCubit, TileShareRosterState>(
          bloc: roster, builder: (context, _) => _withResponse(context));
    }
    return _withResponse(context);
  }

  Widget _withResponse(BuildContext context) {
    final responses = _responses;
    if (responses != null)
      return BlocBuilder<TileShareCommitmentCubit, TileShareCommitmentState>(
          bloc: responses,
          builder: (context, state) => _screen(context, state));
    return _screen(context, null);
  }

  Widget _screen(
      BuildContext context, TileShareCommitmentState? responseState) {
    final tile = widget.designatedTile;
    final l10n = AppLocalizations.of(context)!;
    final title =
        (widget.options.shareName ?? tile.name ?? _template?.name ?? '').trim();
    final response = responseState?.statuses[tile.id] ??
        ((tile.id ?? '').isEmpty
            ? null
            : DesignatedTile.stringToInvitationStatus(
                tile.invitationStatus ?? ''));
    // The comments target is the shared template's own id (the server's
    // fail-closed lookup matches TileShareTemplates.Id). The per-user
    // designation id (tile.id) is deliberately NOT used: it can never
    // match and the request would 403 on every tilette.
    final id = (_template?.id ?? '').trim();
    // The comments section is inert without a template id; the button that
    // reaches this screen only renders when the id is non-null.
    return Scaffold(
      appBar: AppBar(
          title: Text(title.isEmpty ? l10n.shareTilette : title,
              maxLines: 1, overflow: TextOverflow.ellipsis)),
      bottomNavigationBar: _invitationFooter(context, responseState, response),
      body: SafeArea(
          top: false,
          child: CustomScrollView(slivers: [
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverToBoxAdapter(
                    child: TiletteDetailHero(
                        tile: tile,
                        template: _template,
                        mode: widget.options.mode,
                        response: response))),
            SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                sliver: SliverToBoxAdapter(
                    child: ShareDetailTabs<TiletteDetailTab>(
                  selected: _tab,
                  onChanged: _select,
                  tabs: [
                    (
                      TiletteDetailTab.overview,
                      l10n.overview,
                      const Key('tilette_tab_overview')
                    ),
                    (
                      TiletteDetailTab.notes,
                      l10n.notesTitle,
                      const Key('tilette_tab_notes')
                    ),
                    (
                      TiletteDetailTab.comments,
                      l10n.commentsTitle,
                      const Key('tilette_tab_comments')
                    )
                  ],
                ))),
            if (_tab == TiletteDetailTab.overview)
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                      child: TiletteOverviewContent(
                          tile: tile,
                          template: _template,
                          response: response,
                          personal: widget.options.canRespond,
                          ownerRows: _ownerRoster?.state.rows,
                          peopleFeedback: _peopleFeedback(context),
                          peopleAction: _ownerRoster == null
                              ? null
                              : TextButton.icon(
                                  key: const Key('tilette_add_person'),
                                  onPressed: _pickingPerson ||
                                          _ownerRoster!
                                                  .state
                                                  .tasks[_template?.id]
                                                  ?.phase ==
                                              TaskChangePhase.working
                                      ? null
                                      : _addPerson,
                                  icon: const Icon(
                                      Icons.person_add_alt_1_outlined),
                                  label: Text(l10n.shareAddPerson)),
                          onNotes: () => _select(TiletteDetailTab.notes),
                          onComments: () =>
                              _select(TiletteDetailTab.comments)))),
            if (_tab == TiletteDetailTab.notes)
              SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverToBoxAdapter(
                      child: TiletteDetailPanel(
                    title: l10n.notesTitle,
                    action: widget.options.notesApi == null
                        ? null
                        : OutlinedButton.icon(
                            key: const Key('tilette_edit_notes'),
                            onPressed: _notesLoading ? null : _editNotes,
                            icon: const Icon(Icons.edit_outlined),
                            label: Text(l10n.shareEditNotes)),
                    child: _notesContent(context),
                  ))),
            if (_tab == TiletteDetailTab.comments)
              SliverFillRemaining(
                hasScrollBody: true,
                child: id.isEmpty
                    ? Center(child: Text(l10n.shareThreadUnavailable))
                    : widget.options.discussionBuilder != null
                        ? widget.options.discussionBuilder!(context, id)
                        : BlocProvider<CommentsBloc>(
                            create: (_) {
                              final bloc = CommentsBloc(
                                targetType:
                                    CommentsApi.tileShareTiletteTargetType,
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
          ])),
    );
  }

  Widget? _invitationFooter(BuildContext context,
      TileShareCommitmentState? state, InvitationStatus? response) {
    final cubit = _responses;
    if (cubit == null || state == null) return null;
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final pending = response == InvitationStatus.none;
    final declined = response == InvitationStatus.declined;
    final accepted = response == InvitationStatus.accepted;
    final canAccept = pending || declined;
    final canOpen = response == InvitationStatus.accepted &&
        widget.options.onOpenTile != null;
    if (!canAccept &&
        !accepted &&
        state.failure == null &&
        !state.scheduleRefreshFailed) return null;
    return DecoratedBox(
      key: const Key('tilette_invitation_footer'),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border:
              Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
      child: SafeArea(
          top: false,
          minimum: const EdgeInsets.all(16),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.failure != null)
                  Row(children: [
                    Expanded(
                        child: Text(
                            state.failure!.status == InvitationStatus.accepted
                                ? l.attentionAcceptFailed
                                : l.attentionDeclineFailed,
                            style: TextStyle(color: theme.colorScheme.error))),
                    TextButton(
                        key: const Key('tilette_response_retry'),
                        onPressed:
                            _answering ? null : () => _runAnswer(cubit.retry),
                        child: Text(l.attentionRetry)),
                  ]),
                if (state.scheduleRefreshFailed)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(state.scheduleRefreshStatus ==
                              InvitationStatus.declined
                          ? l.shareDeclinedScheduleRefreshFailed
                          : l.attentionScheduleRefreshFailed)),
                if (canAccept) ...[
                  if (widget.options.onPreview != null)
                    TextButton.icon(
                        key: const Key('tilette_check_fit'),
                        onPressed:
                            _answering ? null : () => _runAnswer(_preview),
                        icon: const Icon(Icons.calendar_view_day_outlined),
                        label: Text(l.previewCheckFit)),
                  Text(l.shareYourResponse, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(declined ? l.shareDeclinedHint : l.shareInvitationHint,
                      style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (pending) ...[
                      Expanded(
                          child: OutlinedButton(
                              key: const Key('tilette_decline'),
                              onPressed: _answering
                                  ? null
                                  : () => _runAnswer(() => cubit.respond(
                                      [widget.designatedTile.id!],
                                      InvitationStatus.declined)),
                              child: Text(l.attentionDecline))),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                        child: FilledButton(
                            key: const Key('tilette_accept'),
                            onPressed: _answering
                                ? null
                                : () => _runAnswer(() => cubit.respond(
                                    [widget.designatedTile.id!],
                                    InvitationStatus.accepted)),
                            child: _answering
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : Text(l.attentionAccept))),
                  ]),
                ],
                if (accepted)
                  Row(children: [
                    Expanded(
                        child: OutlinedButton(
                            key: const Key('tilette_decline'),
                            onPressed: _answering
                                ? null
                                : () => _runAnswer(() => cubit.respond(
                                    [widget.designatedTile.id!],
                                    InvitationStatus.declined)),
                            child: Text(l.attentionDecline))),
                    if (canOpen) ...[
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton.icon(
                              key: const Key('tilette_open_tile'),
                              onPressed:
                                  _answering ? null : widget.options.onOpenTile,
                              icon: const Icon(Icons.calendar_today_outlined),
                              label: Text(l.commitmentOpenTile))),
                    ],
                  ]),
              ])),
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
            content: Text(l10n?.commentsAttachmentOpenFailed ??
                "Couldn't open the file.")));
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
    // The Open action mirrors the row buttons' enabled/disabled look:
    // brand primary when it can actually open the saved file, muted grey
    // otherwise. The M3 default (theme grey on the light inverseSurface)
    // made a fully functional action look disabled.
    final theme = Theme.of(_hostContext);
    final canOpen = attachmentId != null;
    final actionColor = canOpen
        ? theme.colorScheme.primary
        : theme.colorScheme.onInverseSurface.withValues(alpha: 0.38);
    debugPrint('[DownloadDiag] host: showing saved SnackBar '
        '("$name") with Open action id=$attachmentId');
    ScaffoldMessenger.of(_hostContext)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l10n.commentsAttachmentSaved(name)),
        action: SnackBarAction(
          label: l10n.commentsAttachmentOpen,
          textColor: actionColor,
          onPressed: canOpen
              ? () {
                  debugPrint(
                      '[DownloadDiag] host: Open action tapped id=$attachmentId');
                  _commentsBloc?.add(OpenAttachmentEvent(
                      attachmentId: attachmentId, fileName: name));
                }
              : () {},
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

/// The web-style summary header: note/description (markdown, rendered as
/// every note is - T27) and due date.
/// The tile name is already shown in the AppBar, so it is intentionally
/// omitted here to avoid duplication (matches the desktop layout where
/// the page header only shows metadata).
class TiletteHeader extends StatelessWidget {
  const TiletteHeader({Key? key, required this.tilette, this.showNotes = true})
      : super(key: key);

  final DesignatedTile tilette;
  final bool showNotes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final note = (tilette.tileTemplate?.miscData?.userNote ?? '').trim();
    final DateTime? end = tilette.endTime;

    final rows = <Widget>[
      if (showNotes && note.isNotEmpty) MarkdownNoteView(markdown: note),
      if (!showNotes) ...[
        ShareWorkMeta(durationMs: tilette.tileTemplate?.durationInMs),
        if ((tilette.id ?? '').isNotEmpty)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ShareWorkStatus(
                  response: DesignatedTile.stringToInvitationStatus(
                      tilette.invitationStatus ?? ''),
                  completion: tilette.completionPercentage)),
      ],
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
