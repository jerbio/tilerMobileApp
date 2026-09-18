// Shared form sections for the redesigned editors (Edit Tile, Tile Detail).
//
// Extracted from the Edit Tile shell in Step 6.0 (D19): the calendar-event
// fields — sessions, priority, repetition, location, colour — now render on
// Tile Detail, and both screens draw them from here so they cannot drift.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePriorityScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repeatOptions.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Sessions as a stepper: never below one, never typed (the legacy field was
/// free text parsed with int.tryParse — Step 0.3's documented defect).
class TileSessionsRow extends StatelessWidget {
  const TileSessionsRow({
    super.key,
    required this.count,
    required this.onChanged,
    this.keyPrefix = 'edit',
  });
  final int count;
  final ValueChanged<int> onChanged;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    Widget step(Key key, IconData icon, VoidCallback? onTap) => Semantics(
          button: true,
          enabled: onTap != null,
          onTap: onTap,
          label: icon == Icons.remove ? '−' : '+',
          child: ExcludeSemantics(
            child: Material(
              color: tokens.surfaceSubtle,
              shape: const CircleBorder(),
              child: InkWell(
                key: key,
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(icon,
                      size: 20,
                      color: onTap == null
                          ? tokens.textSecondary.withValues(alpha: 0.4)
                          : tokens.textPrimary),
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const AddTileIconChip(icon: Icons.call_split_rounded),
          const SizedBox(width: 14),
          Expanded(
            child: Text(l10n.editTileFieldSessions,
                style:
                    textTheme.titleSmall?.copyWith(color: tokens.textPrimary)),
          ),
          step(ValueKey('${keyPrefix}SessionsMinus'), Icons.remove,
              count > 1 ? () => onChanged(count - 1) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$count',
                style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary, fontWeight: FontWeight.w600)),
          ),
          step(ValueKey('${keyPrefix}SessionsPlus'), Icons.add,
              () => onChanged(count + 1)),
        ],
      ),
    );
  }
}

/// Low / Medium / High as selectable cards, the shared picker's copy.
class TilePriorityCards extends StatelessWidget {
  const TilePriorityCards({
    super.key,
    required this.selected,
    required this.onSelected,
    this.keyPrefix = 'edit',
  });
  final TilePriority selected;

  /// Null locks the cards: still shown, selected still announced, no tap.
  final ValueChanged<TilePriority>? onSelected;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    IconData icon(TilePriority p) => switch (p) {
          TilePriority.low => Icons.arrow_downward_rounded,
          TilePriority.medium => Icons.drag_handle_rounded,
          TilePriority.high => Icons.arrow_upward_rounded,
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final TilePriority p in TilePriority.values) ...[
              Expanded(
                child: Semantics(
                  key: ValueKey('${keyPrefix}Priority_${p.name}'),
                  button: onSelected != null,
                  selected: p == selected,
                  onTap: onSelected == null ? null : () => onSelected!(p),
                  label: priorityName(l10n, p),
                  child: ExcludeSemantics(
                    child: Material(
                      color: p == selected
                          ? tokens.brand.withValues(alpha: 0.10)
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onSelected == null ? null : () => onSelected!(p),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: p == selected
                                  ? tokens.brand
                                  : tokens.cardBorder,
                              width: p == selected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(icon(p),
                                  color: p == selected
                                      ? tokens.brand
                                      : tokens.textSecondary),
                              const SizedBox(height: 6),
                              Text(priorityName(l10n, p),
                                  textAlign: TextAlign.center,
                                  style: textTheme.labelLarge?.copyWith(
                                      color: tokens.textPrimary,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (p != TilePriority.values.last) const SizedBox(width: 8),
            ],
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AddTileCallout(
            key: ValueKey('${keyPrefix}PriorityCallout'),
            icon: Icons.auto_awesome_outlined,
            text: priorityConsequence(l10n, selected),
          ),
        ),
      ],
    );
  }
}

/// The Repeat row with its detail line and the "multiple instances" callout
/// (plan §4.4 G2). Keys: `repeatRow`, `repeatDetail`, `repeatCallout`,
/// prefixed by [keyPrefix] so two screens can host it.
class TileRepeatSection extends StatelessWidget {
  const TileRepeatSection({
    super.key,
    required this.rule,
    required this.onTap,
    this.keyPrefix = 'edit',
  });
  final RepetitionData? rule;
  final VoidCallback? onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final String? detail = repeatDetail(l10n, rule);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddTileSection(children: [
          AddTileFieldRow(
            key: ValueKey('${keyPrefix}RepeatRow'),
            icon: Icons.repeat_rounded,
            label: l10n.addTileFieldRepeat,
            value: repeatSummary(l10n, rule),
            onTap: onTap,
          ),
          if (detail != null)
            Padding(
              key: ValueKey('${keyPrefix}RepeatDetail'),
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(detail,
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary)),
            ),
        ]),
        if (detail != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: AddTileCallout(
              key: ValueKey('${keyPrefix}RepeatCallout'),
              icon: Icons.event_repeat_rounded,
              title: l10n.editTileRepeatCalloutTitle,
              text: l10n.editTileRepeatCalloutBody,
            ),
          ),
      ],
    );
  }
}

/// The Add Tile location row, verbatim: tap opens the picker; with a place,
/// the name-this-place button and a × to remove it.
class TileLocationRow extends StatelessWidget {
  const TileLocationRow({
    super.key,
    required this.location,
    required this.onTap,
    required this.onClear,
    required this.onName,
    this.keyPrefix = 'edit',
  });
  final Location? location;
  final VoidCallback? onTap;
  final VoidCallback onClear;
  final VoidCallback onName;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    return AddTileNavRow(
      key: ValueKey('${keyPrefix}LocationRow'),
      icon: Icons.place_outlined,
      title: l10n.location,
      subtitle: locationSummary(location) ?? l10n.addTileValueNotSet,
      onTap: onTap,
      trailing: location == null || onTap == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  button: true,
                  onTap: onClear,
                  label: l10n.editTileLocationRemove,
                  child: ExcludeSemantics(
                    child: IconButton(
                      key: ValueKey('${keyPrefix}LocationClear'),
                      icon: const Icon(Icons.close),
                      onPressed: onClear,
                    ),
                  ),
                ),
                NameLocationButton(onTap: onName),
                Icon(Icons.chevron_right, color: tokens.textSecondary),
              ],
            ),
    );
  }
}

/// Colour: Automatic / Custom with a swatch, opening the shared picker.
class TileColorRow extends StatelessWidget {
  const TileColorRow({
    super.key,
    required this.color,
    required this.onTap,
    this.keyPrefix = 'edit',
  });
  final Color? color;
  final VoidCallback? onTap;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    return AddTileFieldRow(
      key: ValueKey('${keyPrefix}ColorRow'),
      icon: Icons.palette_outlined,
      label: l10n.addTileFieldColor,
      value:
          color == null ? l10n.addTileColorAutomatic : l10n.addTileColorCustom,
      trailing: onTap == null
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (color != null) ...[
                  ColorDot(color: color!, size: 22),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.chevron_right, color: tokens.textSecondary),
              ],
            ),
      onTap: onTap,
    );
  }
}

/// The card silhouette with the D63 sweep behind it, instead of a spinner.
/// Shared by Edit Tile and Tile Detail.
class TileLoadSkeleton extends StatelessWidget {
  const TileLoadSkeleton({super.key, required this.sweepKey});
  final Key sweepKey;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    // Each card silhouette shimmers on its own surface (2026-09-17: a
    // sweep BEHIND blank cards read as the background loading, not the
    // content). Clipped to the card's corners; the border stays crisp.
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tokens.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: AddTilePendingSweep(baseColor: tokens.surface),
        );
    return ListView(
      key: sweepKey,
      padding: const EdgeInsets.all(16),
      children: [block(120), block(140), block(220)],
    );
  }
}

class TileLoadFailure extends StatelessWidget {
  const TileLoadFailure({
    super.key,
    required this.retryKey,
    required this.message,
    required this.onRetry,
  });
  final Key retryKey;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(
              key: retryKey,
              onPressed: onRetry,
              child: Text(l10n.addTileRetry),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hero shared by Edit Tile and Tile Detail: the title — editable in
/// place, with a pencil to its left — the type chip (display only, D3) and
/// a two-line note preview. A locked tile shows the title as text and no
/// pencil.
class TileHero extends StatelessWidget {
  const TileHero({
    super.key,
    required this.keyPrefix,
    required this.name,
    required this.isRigid,
    required this.note,
    required this.lockedTitle,
    required this.locked,
    required this.titleController,
    required this.titleFocus,
    required this.onTitleChanged,
  });

  /// `edit` / `detail`: keys are `<prefix>Hero`, `<prefix>TitlePencil`,
  /// `<prefix>TitleField`, `<prefix>TitleLocked`.
  final String keyPrefix;
  final String name;
  final bool isRigid;

  /// Already display-sanitised (`EditTileDraft.presentNote`).
  final String? note;

  /// What a locked hero shows (the name, or the block-out label).
  final String lockedTitle;
  final bool locked;
  final TextEditingController titleController;
  final FocusNode titleFocus;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final String? note = this.note?.trim();
    final TextStyle? titleStyle = textTheme.titleLarge
        ?.copyWith(color: tokens.textPrimary, fontWeight: FontWeight.w600);

    final Widget title = locked
        ? Text(
            key: ValueKey('${keyPrefix}TitleLocked'),
            lockedTitle,
            style: titleStyle,
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                key: ValueKey('${keyPrefix}TitlePencil'),
                container: true,
                button: true,
                label: l10n.editTileEditTitle,
                onTap: titleFocus.requestFocus,
                child: ExcludeSemantics(
                  child: IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 20, color: tokens.brand),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
                    visualDensity: VisualDensity.compact,
                    onPressed: titleFocus.requestFocus,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextField(
                  key: ValueKey('${keyPrefix}TitleField'),
                  controller: titleController,
                  focusNode: titleFocus,
                  onChanged: onTitleChanged,
                  style: titleStyle,
                  maxLines: null,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: l10n.tileName,
                    hintStyle:
                        titleStyle?.copyWith(color: tokens.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
            ],
          );

    return Container(
      key: ValueKey('${keyPrefix}Hero'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 10),
          // Its own read-only node, so the type is announced apart from the
          // title editor.
          Semantics(
            container: true,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: tokens.surfaceSubtle,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isRigid
                        ? Icons.lock_clock_outlined
                        : Icons.auto_awesome_outlined,
                    size: 14,
                    color: tokens.brand,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isRigid ? l10n.addTileTypeFixed : l10n.addTileTypeFlexible,
                    style: textTheme.labelMedium
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
                  textTheme.bodyMedium?.copyWith(color: tokens.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}
