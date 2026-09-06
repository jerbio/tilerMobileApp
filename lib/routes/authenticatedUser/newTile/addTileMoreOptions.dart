// Phase 2.3 — More options.
//
// An IN-FLOW disclosure (decision D4: expansion, not a secondary screen) that
// keeps every legacy advanced setting reachable without flattening the
// primary hierarchy. Collapsed by default, so a first-time user can finish
// the "what / how long / by when" flow without ever opening it.
//
// Flexible Tile exposes (Section 5.4):
//   * Priority               Low / Medium / High
//   * Color
//   * Split into sessions    integer, floor 1, plain-language explanation
//   * Flexible completion date  toggle + consequence copy
//
// ADVANCED PREFERRED TIME IS NOT HERE (D34). §5.4 listed it, and it lived
// here until the Preferred time control grew a **Custom** chip that opens the
// same editor. Two rows, two names, one destination is a tautology the user
// has to resolve — and the More options row was the weaker of the pair,
// because it could not show that an advanced profile was already in effect.
// The chip can, and it sits where the decision is actually being made.
//
// Fixed Block exposes only Color (plus any recurrence extras Repeat does not
// already show) — the Flexible-only controls must never render or submit for
// a Block.
//
// "Flexible completion date" is HIDDEN once Repeat owns the end date. That
// mirrors the request mapper, which overrides `endTime` with the repetition
// end and forces `AutoReviseDeadline=false` whenever a repetition end
// exists: offering the toggle in that state would be a control that does
// nothing.
//
// VISUAL LANGUAGE (D32). This section is built from `addTileFormKit.dart`,
// exactly like the forms above it. It was originally written before that kit
// existed and drew its own bare label-over-row layout on a transparent
// background, so opening More options dropped the user out of the card-and-
// icon-chip language the rest of the screen speaks. Everything advanced now
// lives in ONE grouped card with hairline dividers — the same shape as the
// Location/Repeat card — and colors come from `TodayStatusTokens` rather than
// straight off the `ColorScheme`.
//
// Presentation only — every mutation is delegated to [AddTileDraft], and the
// pickers are reached through the typed adapters in tileRouteAdapters.dart.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// User-facing priority label.
String priorityLabel(AppLocalizations l10n, TilePriority priority) {
  switch (priority) {
    case TilePriority.low:
      return l10n.addTilePriorityLow;
    case TilePriority.medium:
      return l10n.addTilePriorityMedium;
    case TilePriority.high:
      return l10n.addTilePriorityHigh;
  }
}

/// Plain-language split summary — never the legacy "How many times".
///
/// Goes through an ICU plural rather than an English `count == 1` test:
/// languages differ in how many plural forms they have, so the decision
/// belongs in the .arb, not here.
String splitCountSummary(AppLocalizations l10n, int count) =>
    l10n.addTileSessionCount(count);

/// Color summary. Absent means the existing random-color fallback still
/// applies (decision D7 keeps that behavior for v1), which reads as
/// "Automatic" rather than exposing the engine's fallback.
///
/// Delegates to the picker's own summary so the row and the screen can never
/// disagree about what the current value is called.
String colorSummary(AppLocalizations l10n, Color? color) =>
    colorChoiceSummary(l10n, color);

/// True when a repetition owns the end date, which makes the flexible
/// completion date meaningless.
///
/// `RepetitionData`'s constructor always populates `repetitionEnd` (it
/// defaults to +180 days), so an ENABLED repetition always supplies the end
/// the mapper will use.
bool repeatOwnsEndDate(RepetitionData? repetition) =>
    repetition != null && repetition.isEnabled;

/// Collapsible advanced-options section for the Add Tile redesign.
class AddTileMoreOptions extends StatefulWidget {
  const AddTileMoreOptions({
    super.key,
    required this.draft,
    this.onColorTap,
    this.onPriorityTap,
    this.onExpanded,
  });

  final AddTileDraft draft;
  final VoidCallback? onColorTap;

  /// Opens the Priority picker. Priority sits behind a row rather than inline
  /// chips because §4.2 keeps that screen reachable only from More options.
  final VoidCallback? onPriorityTap;

  /// Fired only when the section EXPANDS. Collapsing is not an "opened"
  /// event, so the analytics funnel does not double-count a toggle.
  final VoidCallback? onExpanded;

  @override
  State<AddTileMoreOptions> createState() => _AddTileMoreOptionsState();
}

class _AddTileMoreOptionsState extends State<AddTileMoreOptions> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final AddTileDraft draft = widget.draft;
    final bool isFlexible = draft.type == AddTileType.flexible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: l10n.addTileMoreOptions,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              key: const ValueKey('moreOptionsHeader'),
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                final bool nowExpanded = !_expanded;
                setState(() => _expanded = nowExpanded);
                if (nowExpanded) widget.onExpanded?.call();
              },
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.addTileMoreOptions,
                        style: textTheme.titleSmall
                            ?.copyWith(color: tokens.textPrimary),
                      ),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: tokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          // ONE grouped card, the same shape as the Location/Repeat card on
          // the main form. Advanced settings are not a different KIND of
          // thing, so they should not look like one (D32).
          AddTileSection(
            children: [
              if (isFlexible)
                AddTileFieldRow(
                  key: const ValueKey('priorityRow'),
                  icon: Icons.flag_outlined,
                  label: l10n.addTileFieldPriority,
                  value: priorityLabel(l10n, draft.priority),
                  onTap: widget.onPriorityTap,
                ),

              // Color is the one advanced control both types share.
              AddTileFieldRow(
                key: const ValueKey('colorRow'),
                icon: Icons.palette_outlined,
                label: l10n.addTileFieldColor,
                value: colorSummary(l10n, draft.color),
                // The swatch answers "what color is this tile?" — the word
                // "Custom" never could. The chevron stays alongside it, since
                // this row still navigates.
                trailing: draft.color == null
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ColorDot(color: draft.color!, size: 22),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              color: tokens.textSecondary),
                        ],
                      ),
                onTap: widget.onColorTap,
              ),

              if (isFlexible) ...[
                _SplitCountRow(
                  key: const ValueKey('splitCountControl'),
                  count: draft.splitCount,
                  onChanged: draft.setSplitCount,
                ),

                // Hidden when Repeat owns the end date — see the file header.
                if (!repeatOwnsEndDate(draft.repetitionData))
                  _FlexibleCompletionToggle(
                    key: const ValueKey('flexibleCompletionToggle'),
                    value: draft.isAutoRevisable,
                    onChanged: draft.setAutoRevisable,
                  ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// "Split into sessions" as a card row: icon chip, name, consequence copy,
/// and the stepper.
///
/// A stepper rather than a free-text field — the legacy digits-only input
/// with an empty-means-one fallback was a validation trap, and the value is
/// realistically a small integer.
class _SplitCountRow extends StatelessWidget {
  const _SplitCountRow({
    super.key,
    required this.count,
    required this.onChanged,
  });

  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      label: l10n.addTileSplitIntoSessions,
      value: splitCountSummary(l10n, count),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AddTileIconChip(icon: Icons.call_split),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.addTileSplitIntoSessions,
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.addTileSplitHelper,
                    style: textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        _StepperButton(
                          key: const ValueKey('splitCountDecrement'),
                          icon: Icons.remove,
                          semanticLabel: l10n.addTileFewerSessions,
                          // Disabled at the floor so the control cannot
                          // express an invalid value in the first place.
                          onTap: count > 1 ? () => onChanged(count - 1) : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            splitCountSummary(l10n, count),
                            style: textTheme.bodyMedium
                                ?.copyWith(color: tokens.textPrimary),
                          ),
                        ),
                        _StepperButton(
                          key: const ValueKey('splitCountIncrement'),
                          icon: Icons.add,
                          semanticLabel: l10n.addTileMoreSessions,
                          onTap: () => onChanged(count + 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final bool enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: enabled ? tokens.textPrimary : tokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// "Flexible completion date" — the legacy `Soft Deadline`, restated as the
/// behavior it produces rather than the engine term.
class _FlexibleCompletionToggle extends StatelessWidget {
  const _FlexibleCompletionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      toggled: value,
      label: l10n.addTileFlexibleCompletion,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const AddTileIconChip(icon: Icons.event_available_outlined),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.addTileFlexibleCompletion,
                          style: textTheme.titleMedium?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l10n.addTileFlexibleCompletionHelper,
                          style: textTheme.bodySmall
                              ?.copyWith(color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  // Excluded from semantics: the row itself already exposes
                  // the toggled state and the tap target.
                  ExcludeSemantics(
                    child: Switch(value: value, onChanged: onChanged),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
