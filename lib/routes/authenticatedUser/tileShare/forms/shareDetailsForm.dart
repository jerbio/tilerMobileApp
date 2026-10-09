import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/designatedTile.dart';
import 'package:tiler_app/data/designatedUser.dart';
import 'package:tiler_app/data/tileShareMode.dart';
import 'package:tiler_app/data/tileShareTemplate.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/widgets/modeBadge.dart';

/// The longest share name (T27).
const int shareNameMaxLength = 100;

/// The shortest share name.
const int shareNameMinLength = 3;

/// A share's own details as the form holds them (T27). The description
/// joins when the backend returns it (O25).
class ShareDetailsValue extends Equatable {
  final String name;
  final DateTime deadline;

  const ShareDetailsValue({required this.name, required this.deadline});

  /// What changed since [before] (what the form opened with) - the only
  /// fields an edit sends.
  ShareChanges changesSince(ShareDetailsValue before) {
    final String trimmed = name.trim();
    return ShareChanges(
      name: trimmed == before.name.trim() ? null : trimmed,
      endMs:
          deadline == before.deadline ? null : deadline.millisecondsSinceEpoch,
    );
  }

  @override
  List<Object?> get props => [name.trim(), deadline];
}

/// The fields an edit changed; `null` when unchanged.
class ShareChanges extends Equatable {
  final String? name;
  final int? endMs;

  const ShareChanges({this.name, this.endMs});

  bool get isEmpty => name == null && endMs == null;

  @override
  List<Object?> get props => [name, endMs];
}

/// The [tilettes] due after [deadline], by whether anyone has accepted them:
/// when the share's deadline moves earlier, the server moves accepted ones to
/// it and leaves the others (O27). A tilette without its own deadline follows
/// the share's, so it is never one of them.
({int accepted, int notAccepted}) tilettesDueAfter(
    List<TileShareTemplate> tilettes, DateTime deadline) {
  int accepted = 0;
  int notAccepted = 0;
  for (final TileShareTemplate t in tilettes) {
    if (t.end == null || t.end! <= deadline.millisecondsSinceEpoch) continue;
    if (tiletteAccepted(t)) {
      accepted++;
    } else {
      notAccepted++;
    }
  }
  return (accepted: accepted, notAccepted: notAccepted);
}

/// Whether anyone has accepted [tilette] - the server's line for moving
/// deadlines (O27).
bool tiletteAccepted(TileShareTemplate tilette) =>
    (tilette.designatedUsers ?? const <DesignatedUser>[])
        .any((u) => u.rsvpStatus == InvitationStatus.accepted);

/// The share's total effort: the sum of its tilettes' durations (a
/// Broadcast has one tilette - everyone their own copy of it).
Duration totalEffort(List<TileShareTemplate> tilettes, TileShareMode mode) {
  final Iterable<TileShareTemplate> counted =
      mode == TileShareMode.broadcast ? tilettes.take(1) : tilettes;
  return Duration(
      milliseconds:
          counted.fold<int>(0, (sum, t) => sum + (t.durationInMs ?? 0)));
}

/// The share details form's fields (T27), in the redesign form kit: the
/// name, the deadline, the mode (shown, fixed once shared) and the total
/// effort (information). The host keeps the values and saves them - Edit
/// share now, the create flow (R6) later.
class ShareDetailsFields extends StatelessWidget {
  final TextEditingController name;
  final FocusNode nameFocus;
  final String? nameError;
  final ValueChanged<String> onNameChanged;
  final DateTime deadline;
  final VoidCallback onPickDeadline;
  final TileShareMode mode;
  final Duration effort;

  /// Tilettes due after [deadline]; what will happen to them when any.
  final ({int accepted, int notAccepted}) dueAfter;

  const ShareDetailsFields({
    super.key,
    required this.name,
    required this.nameFocus,
    required this.nameError,
    required this.onNameChanged,
    required this.deadline,
    required this.onPickDeadline,
    required this.mode,
    required this.effort,
    required this.dueAfter,
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddTileSection(children: [
          AddTileTextFieldRow(
            icon: Icons.edit_outlined,
            label: l10n.shareNameLabel,
            controller: name,
            focusNode: nameFocus,
            fieldKey: const Key('edit_share_name'),
            required: true,
            maxLength: shareNameMaxLength,
            error: nameError,
            onChanged: onNameChanged,
          ),
        ]),
        const SizedBox(height: 12),
        AddTileSection(children: [
          AddTileFieldRow(
            key: const Key('edit_share_deadline'),
            icon: Icons.flag_outlined,
            label: l10n.editTileFieldDeadline,
            value: DateFormat.yMMMEd(locale).add_jm().format(deadline),
            onTap: onPickDeadline,
          ),
          AddTileFieldRow(
            key: const Key('edit_share_effort'),
            icon: Icons.hourglass_empty_rounded,
            label: l10n.shareEditEffort,
            value: formatDurationSummary(l10n, effort) ?? '',
            mutedIcon: true,
            helper: l10n.shareEditEffortHelper,
          ),
          AddTileFieldRow(
            key: const Key('edit_share_mode'),
            icon: TileShareModeBadge.iconOf(mode),
            label: l10n.shareModeLabel,
            value: TileShareModeBadge.labelOf(l10n, mode) ?? '',
            mutedIcon: true,
            helper: l10n.shareEditModeFixed,
          ),
        ]),
        if (dueAfter.accepted > 0 || dueAfter.notAccepted > 0) ...[
          const SizedBox(height: 12),
          Column(
            key: const Key('edit_share_late'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (dueAfter.accepted > 0)
                AddTileCallout(
                  icon: Icons.warning_amber_rounded,
                  text: l10n.shareEditTilettesPulledIn(dueAfter.accepted),
                ),
              if (dueAfter.accepted > 0 && dueAfter.notAccepted > 0)
                const SizedBox(height: 8),
              if (dueAfter.notAccepted > 0)
                AddTileCallout(
                  icon: Icons.info_outline,
                  text: l10n.shareEditTilettesKeep(dueAfter.notAccepted),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
