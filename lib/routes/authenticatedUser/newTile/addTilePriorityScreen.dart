// Step 4.3a — the Priority picker.
//
// Built to the Priority mockup with the revisions §4.2 attached to it:
//   * reachable only from More options, never the main form;
//   * unambiguous icons — a downward chevron for Low, a level bar for Medium,
//     an upward chevron for High, each paired with its label so the icon never
//     carries the meaning alone;
//   * IMMEDIATE SELECTION-AND-RETURN instead of the mockup's "Save priority"
//     button. A three-way choice has nothing to confirm, and a confirm step
//     would make the cheapest setting on the screen the most expensive to
//     change. Matches the Location picker (D18).
//   * Back, not Close (D12), so the draft is visibly preserved.
//
// UNVERIFIED COPY: "Priority helps Tiler decide what to protect first" is the
// mockup's approved wording, but §4.2 asked for the scheduler to be checked
// against that claim and it has not been — see P2-7 / D5. Rendered as
// designed; the claim is product's to confirm or soften.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// User-facing name for a priority.
String priorityName(AppLocalizations l10n, TilePriority priority) {
  switch (priority) {
    case TilePriority.low:
      return l10n.addTilePriorityLow;
    case TilePriority.medium:
      return l10n.addTilePriorityMedium;
    case TilePriority.high:
      return l10n.addTilePriorityHigh;
  }
}

/// What choosing this priority means, in outcome terms rather than engine
/// terms — the improvement §4.2 credited the mockup with.
String priorityConsequence(AppLocalizations l10n, TilePriority priority) {
  switch (priority) {
    case TilePriority.low:
      return l10n.addTilePriorityLowMeaning;
    case TilePriority.medium:
      return l10n.addTilePriorityMediumMeaning;
    case TilePriority.high:
      return l10n.addTilePriorityHighMeaning;
  }
}

/// Direction-of-emphasis icons. Decorative: every row states its priority in
/// words, so the icon reinforces rather than carries (§11).
IconData priorityIcon(TilePriority priority) {
  switch (priority) {
    case TilePriority.low:
      return Icons.keyboard_arrow_down;
    case TilePriority.medium:
      return Icons.drag_handle;
    case TilePriority.high:
      return Icons.keyboard_arrow_up;
  }
}

/// Three-way priority picker. Tapping a row returns it immediately; backing
/// out returns nothing and leaves the draft untouched.
class AddTilePriorityScreen extends StatelessWidget {
  const AddTilePriorityScreen({
    super.key,
    required this.initial,
    this.onSelected,
  });

  final TilePriority initial;

  /// Invoked with the chosen priority. Injected by tests; in the app the
  /// screen pops with the value.
  final void Function(TilePriority)? onSelected;

  void _select(BuildContext context, TilePriority priority) {
    if (onSelected != null) {
      onSelected!(priority);
      return;
    }
    Navigator.of(context).pop(priority);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.addTilePriority),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: tokens.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.addTilePriorityHelper,
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AddTileSection(
            children: [
              for (final priority in TilePriority.values)
                PriorityOptionRow(
                  key: ValueKey('priorityOption_${priority.name}'),
                  priority: priority,
                  selected: priority == initial,
                  onTap: () => _select(context, priority),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One priority row. [selected] is public so widget tests can assert the
/// assistive-tech-facing state through the widget; `Semantics.selected`
/// mirrors it to the platform, so the tint is never the only signal.
class PriorityOptionRow extends StatelessWidget {
  const PriorityOptionRow({
    super.key,
    required this.priority,
    required this.selected,
    required this.onTap,
  });

  final TilePriority priority;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '${priorityName(l10n, priority)}, ${priorityConsequence(l10n, priority)}',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brandTint : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    AddTileIconChip(icon: priorityIcon(priority)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            priorityName(l10n, priority),
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            priorityConsequence(l10n, priority),
                            style: textTheme.bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: selected ? tokens.brand : tokens.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
