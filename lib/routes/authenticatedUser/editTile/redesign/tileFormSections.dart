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
  const TileSessionsRow(
      {super.key, required this.count, required this.onChanged});
  final int count;
  final ValueChanged<int> onChanged;

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
          step(const ValueKey('editSessionsMinus'), Icons.remove,
              count > 1 ? () => onChanged(count - 1) : null),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('$count',
                style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary, fontWeight: FontWeight.w600)),
          ),
          step(const ValueKey('editSessionsPlus'), Icons.add,
              () => onChanged(count + 1)),
        ],
      ),
    );
  }
}

/// Low / Medium / High as selectable cards, the shared picker's copy.
class TilePriorityCards extends StatelessWidget {
  const TilePriorityCards({required this.selected, required this.onSelected});
  final TilePriority selected;
  final ValueChanged<TilePriority> onSelected;

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
                  key: ValueKey('editPriority_${p.name}'),
                  button: true,
                  selected: p == selected,
                  onTap: () => onSelected(p),
                  label: priorityName(l10n, p),
                  child: ExcludeSemantics(
                    child: Material(
                      color: p == selected
                          ? tokens.brand.withValues(alpha: 0.10)
                          : tokens.surface,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelected(p),
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
            key: const ValueKey('editPriorityCallout'),
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
