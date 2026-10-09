import 'package:flutter/material.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_cubit.dart';
import 'package:tiler_app/bloc/tileShare/tile_share_detail_state.dart';
import 'package:tiler_app/data/tileShareClusterData.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/deadlinePicker.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/forms/shareDetailsForm.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Opens Edit share for the share [cubit] shows.
Future<void> showEditShare(
  BuildContext context,
  TileShareDetailCubit cubit, {
  DeadlinePickDate pickDate = platformPickDate,
  DeadlinePickTime pickTime = platformPickTime,
}) =>
    Navigator.of(context).push<void>(MaterialPageRoute<void>(
      builder: (_) =>
          EditShareScreen(cubit: cubit, pickDate: pickDate, pickTime: pickTime),
    ));

/// Edit share (redesign T27): the share's own details in the share details
/// form - its name and deadline; its mode and total effort as information.
///
///  * One *Save changes*: only what changed is sent (`PUT
///    api/TileShareCluster`), and the screen closes; a refused save keeps it
///    and what was typed, said here (not again on the detail).
///  * Save stays tappable to say what is missing; nothing changed, nothing
///    sent.
///  * A deadline earlier than some tilettes' says how many are due after it;
///    they keep their own deadlines.
///  * Leaving with changes asks first.
///  * Tilettes are not here - each tilette change is its own call, in the
///    Tilettes tab. The description joins when the backend returns it (O25).
class EditShareScreen extends StatefulWidget {
  final TileShareDetailCubit cubit;
  final DeadlinePickDate pickDate;
  final DeadlinePickTime pickTime;

  const EditShareScreen({
    super.key,
    required this.cubit,
    this.pickDate = platformPickDate,
    this.pickTime = platformPickTime,
  });

  @override
  State<EditShareScreen> createState() => _EditShareScreenState();
}

class _EditShareScreenState extends State<EditShareScreen> {
  late final TextEditingController _name;
  final FocusNode _nameFocus = FocusNode();
  late DateTime _deadline;
  late final ShareDetailsValue _initial;
  String? _nameError;
  bool _busy = false;
  bool _failed = false;

  TileShareDetailState get _detail => widget.cubit.state;

  @override
  void initState() {
    super.initState();
    final TileShareClusterData? cluster = _detail.cluster;
    _name = TextEditingController(text: (cluster?.name ?? '').trim());
    final int? end = cluster?.endTimeInMs;
    _deadline = end != null
        ? DateTime.fromMillisecondsSinceEpoch(end)
        : DateTime.now().add(const Duration(days: 1));
    _initial = _value;
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  ShareDetailsValue get _value =>
      ShareDetailsValue(name: _name.text, deadline: _deadline);

  bool get _changed => _value != _initial;
  bool get _nameValid => _name.text.trim().length >= shareNameMinLength;

  String? _nameProblem(AppLocalizations l10n) {
    final String name = _name.text.trim();
    if (name.isEmpty) return l10n.addTileNameRequired;
    if (name.length < shareNameMinLength) return l10n.taskSheetNameTooShort;
    return null;
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await pickDeadline(context, _deadline,
        pickDate: widget.pickDate, pickTime: widget.pickTime);
    if (picked != null && mounted) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (_busy) return;
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String? problem = _nameProblem(l10n);
    if (problem != null) {
      setState(() => _nameError = problem);
      return;
    }
    final ShareChanges changes = _value.changesSince(_initial);
    if (changes.isEmpty) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    final bool ok = await widget.cubit
        .updateShare(name: changes.name, endMs: changes.endMs);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
      return;
    }
    widget.cubit.dismissEditFailure();
    setState(() {
      _busy = false;
      _failed = true;
    });
  }

  /// Leaves, asking first when there are changes.
  Future<void> _leave() async {
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editTileDiscardTitle),
        content: Text(l10n.shareEditDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.notesConflictKeepEditing),
          ),
          TextButton(
            key: const Key('edit_share_discard'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(dialogContext).colorScheme.error),
            child: Text(l10n.editTileDiscard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final TodayStatusTokens tokens = TodayStatusTokens.of(context);
    final TileShareMode mode = _detail.mode ?? TileShareMode.broadcast;
    return PopScope(
      canPop: !_changed || _busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        key: const Key('edit_share'),
        backgroundColor: tokens.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: IconButton(
            key: const Key('edit_share_close'),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            icon: const Icon(Icons.close),
            onPressed: _busy ? null : _leave,
          ),
          title: Text(l10n.detailEditShare),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ShareDetailsFields(
                      name: _name,
                      nameFocus: _nameFocus,
                      nameError: _nameError,
                      onNameChanged: (_) => setState(() => _nameError = null),
                      deadline: _deadline,
                      onPickDeadline: _pickDeadline,
                      mode: mode,
                      effort: totalEffort(_detail.tilettes, mode),
                      dueAfter: tilettesDueAfter(_detail.tilettes, _deadline),
                    ),
                    if (_failed) ...[
                      const SizedBox(height: 12),
                      AddTileCallout(
                        key: const Key('edit_share_failed'),
                        icon: Icons.error_outline,
                        text: l10n.editTileSaveFailed,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            AddTilePrimaryButton(
              key: const Key('edit_share_save'),
              label: l10n.tileShareSaveChanges,
              busyLabel: l10n.editTileSaving,
              enabled: _nameValid && _changed,
              busy: _busy,
              onTap: _save,
            ),
          ],
        ),
      ),
    );
  }
}
