import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tiler_app/constants.dart' as Constants;
import 'package:tiler_app/l10n/app_localizations.dart';

class TileShareReviewCard extends StatefulWidget {
  final Map<String, dynamic> result;
  final bool disabled;
  final Future<Map<String, dynamic>> Function(String token) onConfirm;
  final Future<Map<String, dynamic>> Function() onCheck;
  final void Function(Map<String, dynamic>) onChanged;
  const TileShareReviewCard(
      {super.key,
      required this.result,
      this.disabled = false,
      required this.onConfirm,
      required this.onCheck,
      required this.onChanged});
  @override
  State<TileShareReviewCard> createState() => _TileShareReviewCardState();
}

class _TileShareReviewCardState extends State<TileShareReviewCard> {
  bool busy = false, uncertain = false, rejected = false;
  @override
  void didUpdateWidget(covariant TileShareReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result['ReviewToken'] != widget.result['ReviewToken'])
      rejected = false;
  }

  bool get isAccess => widget.result['Operation'] == 'UpdateAccess' ||
      (widget.result['Review'] is Map && widget.result['Review']['Operation'] == 'UpdateAccess');
  bool get isRecipients => widget.result['Operation'] == 'UpdateRecipients' ||
      (widget.result['Review'] is Map && widget.result['Review']['Operation'] == 'UpdateRecipients');
  bool get isManagement => isAccess || isRecipients;
  bool get isProjectUpdate =>
      widget.result['Operation'] == 'UpdateProject' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'UpdateProject');
  bool get isUpdate =>
      isManagement || isProjectUpdate ||
      widget.result['Operation'] == 'UpdateTilette' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'UpdateTilette');
  bool get isDelete =>
      widget.result['Operation'] == 'DeleteTilette' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'DeleteTilette');
  bool get isNotes =>
      widget.result['Operation'] == 'SetTiletteNotes' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'SetTiletteNotes');
  bool get isTiletteRename =>
      widget.result['Operation'] == 'RenameTilette' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'RenameTilette');
  bool get isRename =>
      isTiletteRename ||
      widget.result['Operation'] == 'RenameProject' ||
      (widget.result['Review'] is Map &&
          widget.result['Review']['Operation'] == 'RenameProject');
  String? notice;
  Future<void> run({bool check = false}) async {
    if (busy ||
        (widget.disabled && !(check && widget.result['State'] == 'Pending')) ||
        rejected ||
        (!check && uncertain)) return;
    final l = AppLocalizations.of(context)!;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      final result = check
          ? await widget.onCheck()
          : await widget.onConfirm(widget.result['ReviewToken'] as String);
      if (!mounted) return;
      if (result['ActionId'] == widget.result['ActionId'] &&
          ['Pending', 'Failed'].contains(result['State'])) {
        uncertain = false;
        widget.onChanged(result);
        return;
      }
      if (result['ActionId'] == widget.result['ActionId'] &&
          result['State'] == 'Rejected') {
        rejected = true;
        uncertain = false;
        notice = l.vibeUpdateRejected;
        widget.onChanged(result);
        return;
      }
      if (result['ActionId'] != widget.result['ActionId'] ||
          !(result['State'] == 'Applied' ||
              (result['State'] == 'NotAttempted' &&
                  result['ReviewToken'] is String &&
                  result['Review'] is Map)))
        throw StateError('Mismatched action');
      widget.onChanged(result);
      uncertain = result['State'] != 'Applied' &&
          !(result['State'] == 'NotAttempted' &&
              result['ReviewToken'] is String &&
              result['Review'] is Map);
      notice = result['State'] == 'Applied' ? null : l.vibeReviewAgain;
    } catch (_) {
      if (!mounted) return;
      uncertain = true;
      notice = isUpdate
          ? l.vibeUpdateUnknown
          : isDelete
              ? l.vibeDeleteUnknown
              : isNotes
                  ? l.vibeNotesUnknown
                  : isRename
                      ? l.vibeRenameUnknown
                      : l.vibeCreationUnknown;
    } finally {
      if (mounted)
        setState(() {
          busy = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    if (widget.result['State'] == 'Pending')
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                        liveRegion: true,
                        child: Text(l.vibeScheduleUpdatePending)),
                    if (notice != null)
                      Text(notice!, style: TextStyle(color: colors.error)),
                    TextButton(
                        onPressed: busy ? null : () => run(check: true),
                        child: Text(l.vibeCheckStatus))
                  ])));
    if (widget.result['State'] == 'Failed')
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Semantics(
                  liveRegion: true,
                  child: Text(
                      widget.result['ErrorCode'] == 'schedule_no_fit'
                          ? l.vibeScheduleNoFit
                          : l.vibeScheduleUpdateFailed,
                      style: TextStyle(color: colors.error)))));
    if (widget.result['State'] == 'Applied')
      return Padding(
          padding: const EdgeInsets.all(12),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isManagement ? l.vibeManagementUpdated : isUpdate
                ? (isProjectUpdate
                    ? l.vibeProjectUpdated
                    : l.vibeTiletteUpdated)
                : isDelete
                    ? l.vibeTiletteDeleted
                    : isNotes
                        ? l.vibeNotesUpdated
                        : isTiletteRename
                            ? l.vibeTiletteRenamed
                            : isRename
                                ? l.vibeProjectRenamed
                                : l.vibeTileShareCreated),
            if (isAccess) Text(l.vibeAccessReconciliation),
            if (widget.result['Url'] is String &&
                (widget.result['Url'] as String).startsWith('/tileshare/'))
              TextButton(
                  onPressed: () async {
                    await launchUrl(Uri.https(
                        Constants.tilerDomain, widget.result['Url'] as String));
                  },
                  child:
                      Text(isDelete ? l.vibeOpenProject : l.vibeOpenTileShare)),
          ]));
    if (widget.result['State'] == 'Rejected')
      return Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(l.vibeUpdateRejected,
                  style: TextStyle(color: colors.error))));
    final review = widget.result['Review'];
    if (review is! Map || widget.result['ReviewToken'] is! String)
      return const SizedBox.shrink();
    String time(dynamic value) =>
        DateTime.fromMillisecondsSinceEpoch((value as num).toInt())
            .toLocal()
            .toString();
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    isManagement ? (isAccess ? l.vibeManageAccess : l.vibeManageRecipients) : isUpdate
                        ? (isProjectUpdate
                            ? l.vibeProjectUpdateReview
                            : l.vibeUpdateReview)
                        : isDelete
                            ? l.vibeDeleteReview
                            : isNotes
                                ? l.vibeNotesReview
                                : isTiletteRename
                                    ? l.vibeTiletteRenameReview
                                    : isRename
                                        ? l.vibeRenameReview
                                        : l.vibeCreationReview,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                    '${isManagement ? (isAccess ? l.vibeManageAccess : l.vibeManageRecipients) : isUpdate ? (isProjectUpdate ? l.vibeUpdateProject : l.vibeUpdateTilette) : isDelete ? l.vibeDeleteTilette : isNotes ? l.vibeEditNotes : isTiletteRename ? l.vibeRenameTilette : isRename ? l.vibeRenameProject : review['CreatesProject'] == true ? l.vibeCreateProject : l.vibeAddTilette}: ${review['Name']}'),
                if (isRename || (isUpdate && review['UpdatesName'] == true))
                  Text('${l.vibePreviousName}: ${review['PreviousName']}'),
                if ((!isRename || isTiletteRename) &&
                    review['ProjectName'] != null)
                  Text('${l.vibeReviewProject}: ${review['ProjectName']}'),
                if (isDelete) ...[
                  Text(
                      '${l.vibeAssignmentCount}: ${review['AssignmentCount']}'),
                  Text(
                      '${l.vibeLinkedCalendarCount}: ${review['LinkedCalendarCount']}'),
                ],
                if (isNotes ||
                    (isUpdate && review['UpdatesNotes'] == true)) ...[
                  Text(l.vibePreviousNotes,
                      style: Theme.of(context).textTheme.titleSmall),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                          child: SelectableText(
                              (review['PreviousNotes'] as String?)
                                          ?.isNotEmpty ==
                                      true
                                  ? review['PreviousNotes']
                                  : l.vibeEmptyNotes))),
                  Text(l.vibeProposedNotes,
                      style: Theme.of(context).textTheme.titleSmall),
                  ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: SingleChildScrollView(
                          child: SelectableText(
                              (review['Notes'] as String?)?.isNotEmpty == true
                                  ? review['Notes']
                                  : l.vibeClearNotes))),
                ],
                if (review['EffectsSummary'] is String) SelectableText(review['EffectsSummary'] as String),
                if (review['ScheduleSummary'] is String)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child:
                          SelectableText(review['ScheduleSummary'] as String)),
                if (review['StartTime'] != null)
                  Text('${l.vibeReviewStarts}: ${time(review['StartTime'])}'),
                if (review['Deadline'] != null)
                  Text('${l.vibeReviewDeadline}: ${time(review['Deadline'])}'),
                for (final item in (review['Tilettes'] as List? ?? []))
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${item['Name']} - ${item['DurationMinutes']} ${l.vibeReviewMinutes}'),
                            if (item['StartTime'] != null)
                              Text(
                                  '${l.vibeReviewStarts}: ${time(item['StartTime'])}'),
                            if (item['Deadline'] != null)
                              Text(
                                  '${l.vibeReviewDeadline}: ${time(item['Deadline'])}'),
                            for (final recipient
                                in (item['Recipients'] as List? ?? []))
                              Text(
                                  '${recipient['name']} - ${recipient['email'] ?? recipient['phone'] ?? ''}'),
                          ])),
                Text(
                    isManagement ? l.vibeManagementNote : isUpdate
                        ? l.vibeUpdateNote
                        : isDelete
                            ? l.vibeDeleteNote
                            : isNotes
                                ? l.vibeNotesNote
                                : isTiletteRename
                                    ? l.vibeTiletteRenameNote
                                    : isRename
                                        ? l.vibeRenameNote
                                        : l.vibeCreationNote,
                    style: Theme.of(context).textTheme.bodySmall),
                if (notice != null ||
                    widget.result['ErrorCode'] == 'review_changed')
                  Text(notice ?? l.vibeReviewAgain,
                      style: TextStyle(color: colors.error)),
                Wrap(spacing: 8, children: [
                  FilledButton(
                      style: isDelete
                          ? FilledButton.styleFrom(
                              backgroundColor: colors.error,
                              foregroundColor: colors.onError)
                          : null,
                      onPressed:
                          busy || uncertain || rejected || widget.disabled
                              ? null
                              : () => run(),
                      child: Text(isUpdate
                          ? l.vibeConfirmUpdate
                          : isDelete
                              ? l.vibeConfirmDeletion
                              : isNotes
                                  ? l.vibeConfirmNotes
                                  : isRename
                                      ? l.vibeConfirmRename
                                      : l.vibeConfirmCreation)),
                  if (uncertain)
                    TextButton(
                        onPressed: busy || widget.disabled
                            ? null
                            : () => run(check: true),
                        child: Text(l.vibeCheckStatus)),
                ]),
                if (busy) const LinearProgressIndicator(),
              ],
            )));
  }
}
