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
//   * Advanced preferred time   the profile editor, for cases the four
//                               simple day parts cannot express
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
// Presentation only — every mutation is delegated to [AddTileDraft], and the
// pickers are reached through the typed adapters in tileRouteAdapters.dart.
// Strings are English constants for now; they migrate to
// app_en.arb/app_es.arb when the content system lands.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';

/// User-facing priority label.
String priorityLabel(TilePriority priority) {
  switch (priority) {
    case TilePriority.low:
      return 'Low';
    case TilePriority.medium:
      return 'Medium';
    case TilePriority.high:
      return 'High';
  }
}

/// Plain-language split summary — never the legacy "How many times".
String splitCountSummary(int count) =>
    count == 1 ? '1 session' : '$count sessions';

/// Color summary. Absent means the existing random-color fallback still
/// applies (decision D7 keeps that behavior for v1), which reads as
/// "Automatic" rather than exposing the engine's fallback.
String colorSummary(Color? color) => color == null ? 'Automatic' : 'Custom';

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
    this.onAdvancedPreferredTimeTap,
    this.onExpanded,
  });

  final AddTileDraft draft;
  final VoidCallback? onColorTap;
  final VoidCallback? onAdvancedPreferredTimeTap;

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
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final AddTileDraft draft = widget.draft;
    final bool isFlexible = draft.type == AddTileType.flexible;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          label: 'More options',
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
                      child: Text('More options', style: textTheme.titleSmall),
                    ),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (isFlexible) ...[
            _Label('Priority', textTheme: textTheme),
            _PriorityControl(
              key: const ValueKey('priorityControl'),
              priority: draft.priority,
              onSelected: draft.setPriority,
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),
          ],

          // Color is the one advanced control both types share.
          _Label('Color', textTheme: textTheme),
          _OptionRow(
            key: const ValueKey('colorRow'),
            summary: colorSummary(draft.color),
            onTap: widget.onColorTap,
            textTheme: textTheme,
            scheme: scheme,
          ),
          const SizedBox(height: 12),

          if (isFlexible) ...[
            _Label('Split into sessions', textTheme: textTheme),
            Text(
              'Break this into separate work sessions.',
              style:
                  textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            _SplitCountControl(
              key: const ValueKey('splitCountControl'),
              count: draft.splitCount,
              onChanged: draft.setSplitCount,
              textTheme: textTheme,
              scheme: scheme,
            ),
            const SizedBox(height: 12),

            // Hidden when Repeat owns the end date — see the file header.
            if (!repeatOwnsEndDate(draft.repetitionData)) ...[
              _FlexibleCompletionToggle(
                key: const ValueKey('flexibleCompletionToggle'),
                value: draft.isAutoRevisable,
                onChanged: draft.setAutoRevisable,
                textTheme: textTheme,
                scheme: scheme,
              ),
              const SizedBox(height: 12),
            ],

            _Label('Advanced preferred time', textTheme: textTheme),
            _OptionRow(
              key: const ValueKey('advancedPreferredTimeRow'),
              summary: 'Set specific hours',
              onTap: widget.onAdvancedPreferredTimeTap,
              textTheme: textTheme,
              scheme: scheme,
            ),
          ],
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.textTheme});
  final String text;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: textTheme.titleSmall),
      );
}

/// Low / Medium / High. Selected state reaches assistive tech through
/// `Semantics.selected`, never through color alone.
class _PriorityControl extends StatelessWidget {
  const _PriorityControl({
    super.key,
    required this.priority,
    required this.onSelected,
    required this.textTheme,
    required this.scheme,
  });

  final TilePriority priority;
  final ValueChanged<TilePriority> onSelected;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in TilePriority.values)
          _ChoiceChip(
            key: ValueKey('priority${_suffix(option)}'),
            label: priorityLabel(option),
            selected: option == priority,
            onTap: () => onSelected(option),
            textTheme: textTheme,
            scheme: scheme,
          ),
      ],
    );
  }

  static String _suffix(TilePriority p) =>
      p.name[0].toUpperCase() + p.name.substring(1);
}

/// A stepper rather than a free-text field: the legacy digits-only input with
/// an empty-means-one fallback was a validation trap, and the value is
/// realistically a small integer.
class _SplitCountControl extends StatelessWidget {
  const _SplitCountControl({
    super.key,
    required this.count,
    required this.onChanged,
    required this.textTheme,
    required this.scheme,
  });

  final int count;
  final ValueChanged<int> onChanged;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Split into sessions',
      value: splitCountSummary(count),
      child: Row(
        children: [
          _StepperButton(
            key: const ValueKey('splitCountDecrement'),
            icon: Icons.remove,
            semanticLabel: 'Fewer sessions',
            // Disabled at the floor so the control cannot express an
            // invalid value in the first place.
            onTap: count > 1 ? () => onChanged(count - 1) : null,
            scheme: scheme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(splitCountSummary(count), style: textTheme.bodyMedium),
          ),
          _StepperButton(
            key: const ValueKey('splitCountIncrement'),
            icon: Icons.add,
            semanticLabel: 'More sessions',
            onTap: () => onChanged(count + 1),
            scheme: scheme,
          ),
        ],
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
    required this.scheme,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: enabled ? scheme.onSurface : scheme.onSurfaceVariant,
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
    required this.textTheme,
    required this.scheme,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      label: 'Flexible completion date',
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Flexible completion date',
                        style: textTheme.titleSmall),
                    Text(
                      'Tiler may move this date slightly if needed.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Excluded from semantics: the row itself already exposes the
              // toggled state and the tap target.
              ExcludeSemantics(
                child: Switch(value: value, onChanged: onChanged),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable advanced row: summary plus a navigation chevron.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.summary,
    required this.onTap,
    required this.textTheme,
    required this.scheme,
  });

  final String summary;
  final VoidCallback? onTap;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: summary,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Row(
              children: [
                Expanded(
                  child: Text(summary, style: textTheme.bodyMedium),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared selectable chip for the Priority control.
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textTheme,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color:
            selected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: selected ? scheme.primary : scheme.onSurface,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
