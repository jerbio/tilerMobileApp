// Step 4.2 — the Repeat picker.
//
// Built to the Repeat mockup with the decisions in `repeatOptions.dart`
// applied: Yearly kept (D22), "Weekdays" as a preset with the mockup's
// "Custom" row dropped (D23), Sunday = 0 (D25), and a range control the
// mockup does not draw (D26).
//
// WHY THIS ONE HAS A CONFIRM ACTION. The Location picker commits on tap
// (D18), but Repeat does not: choosing "Weekly" and then adjusting days is
// inherently several taps, so committing on the first would fight the
// interaction. Done confirms; Back abandons. D12 still applies — Back, never
// Close.
//
// The mockup shows active weekday chips beside a selected "Does not repeat".
// That state is unreachable here: chips are derived from the selected option
// rather than stored beside it, so a row without a day dimension renders no
// chips at all.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/repeatOptions.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// The Repeat picker. Returns the chosen [RepetitionData], or `null` for
/// "Does not repeat" — confirmed via Done. Backing out returns nothing at all
/// and leaves the draft alone.
class AddTileRepeatScreen extends StatefulWidget {
  const AddTileRepeatScreen({
    super.key,
    required this.now,
    this.initialRepetition,
    this.onDone,
  });

  /// Anchor for the default recurrence range, injected so tests are
  /// deterministic.
  final DateTime now;

  final RepetitionData? initialRepetition;

  /// Invoked by Done with the result. Injected by tests; in the app the screen
  /// pops with the value wrapped so `null` stays distinguishable from Back.
  final void Function(RepetitionData?)? onDone;

  @override
  State<AddTileRepeatScreen> createState() => _AddTileRepeatScreenState();
}

class _AddTileRepeatScreenState extends State<AddTileRepeatScreen> {
  late RepeatOption _option = repeatOptionOf(widget.initialRepetition);

  /// Day selection for the Weekly row. Seeded from an incoming weekly
  /// repetition so reopening the picker preserves what was chosen.
  late Set<int> _days = Set<int>.from(
      widget.initialRepetition?.weeklyRepetition ?? const <int>{});

  /// The recurrence end. Null means "use the default for the chosen
  /// frequency", which is resolved at build time so switching rows updates it
  /// (yearly's default window is far longer than the rest).
  late DateTime? _end = widget.initialRepetition?.repetitionEnd;

  DateTime get _effectiveEnd =>
      _end ??
      defaultRepetitionEnd(
        buildRepetition(option: _option, days: _days, now: widget.now)
                ?.frequency ??
            RepetitionFrequency.weekly,
        widget.now,
      );

  void _selectOption(RepeatOption option) {
    // No seeding (D52). Weekly starts with NO days chosen, and an empty
    // selection is a real answer — it ships a weekly repetition with no
    // `RepeatWeeklyData`, letting the backend decide the day. Pre-ticking
    // Mon-Fri put five choices in the payload the user never made.
    setState(() => _option = option);
  }

  void _toggleDay(int index) {
    if (!optionHasDays(_option)) return;
    setState(() {
      // Every chip toggles freely, including the last one. Emptying the set
      // is not a broken state: it means "weekly, no particular day", which
      // is what the payload carries when `RepeatWeeklyData` is absent (D52).
      if (_days.contains(index)) {
        _days.remove(index);
      } else {
        _days.add(index);
      }
    });
  }

  Future<void> _pickEnd() async {
    final DateTime current = _effectiveEnd;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: widget.now,
      lastDate: widget.now.add(const Duration(days: 3650)),
    );
    if (picked == null || !mounted) return;
    setState(() => _end = picked);
  }

  void _done() {
    final RepetitionData? result = buildRepetition(
      option: _option,
      days: _days,
      now: widget.now,
      end: _option == RepeatOption.doesNotRepeat ? null : _effectiveEnd,
    );
    if (widget.onDone != null) {
      widget.onDone!(result);
      return;
    }
    // Wrapped so a confirmed "Does not repeat" (null) stays distinguishable
    // from backing out (no value at all).
    Navigator.of(context).pop(RepeatPickerResult(result));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final bool showDays = optionHasDays(_option);

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.addTileRepeat),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                AddTileSection(
                  children: [
                    for (final option in RepeatOption.values)
                      _RepeatOptionRow(
                        key: ValueKey('repeatOption_${option.name}'),
                        label: repeatOptionLabel(l10n, option),
                        selected: option == _option,
                        onTap: () => _selectOption(option),
                      ),
                  ],
                ),
                if (showDays) ...[
                  const SizedBox(height: 14),
                  _DaysSection(
                    key: const ValueKey('repeatDaysSection'),
                    days: _days,
                    // Always editable now: touching a Weekdays chip drops to
                    // Weekly and applies the edit, so no chip is ever inert.
                    editable: true,
                    onToggle: _toggleDay,
                  ),
                ],
                if (_option != RepeatOption.doesNotRepeat) ...[
                  const SizedBox(height: 14),
                  AddTileSection(
                    children: [
                      AddTileFieldRow(
                        key: const ValueKey('repeatUntilRow'),
                        icon: Icons.event_busy_outlined,
                        label: l10n.addTileRepeatsUntil,
                        value: DateFormat.yMMMd().format(_effectiveEnd),
                        onTap: _pickEnd,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: tokens.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.addTileRepeatHelper,
                        style: textTheme.bodySmall
                            ?.copyWith(color: tokens.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: RepeatDoneButton(
              key: const ValueKey('repeatDone'),
              onTap: _done,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distinguishes a confirmed "Does not repeat" (a `null` repetition) from
/// backing out of the screen without deciding.
class RepeatPickerResult {
  const RepeatPickerResult(this.repetition);
  final RepetitionData? repetition;
}

/// One radio-style row. Selection reaches assistive tech through
/// `Semantics.selected`, never by the tint alone.
class _RepeatOptionRow extends StatelessWidget {
  const _RepeatOptionRow({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brandTint : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: textTheme.titleMedium?.copyWith(
                          color: tokens.textPrimary,
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w400,
                        ),
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

/// The weekday chips. Rendered only for rows that have a day dimension, and
/// tappable only for Weekly — the Weekdays preset is fixed at Mon-Fri.
class _DaysSection extends StatelessWidget {
  const _DaysSection({
    super.key,
    required this.days,
    required this.editable,
    required this.onToggle,
  });

  final Set<int> days;
  final bool editable;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.addTileRepeatDays,
            style: textTheme.labelSmall
                ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6),
          ),
          const SizedBox(height: 10),
          // A week is SEVEN days on ONE row. An earlier `Wrap` pushed Saturday
          // onto a second line at phone widths, which read as a broken week
          // rather than as reflowed content. The chip shrinks to fit the
          // available width instead — each takes an equal share, capped at the
          // 44px target size so it never inflates on a tablet.
          LayoutBuilder(
            builder: (context, constraints) {
              const double gap = 8;
              final double slot = constraints.maxWidth / 7;
              final double diameter =
                  math.min(44.0, math.max(24.0, slot - gap));
              return Row(
                children: [
                  for (int index = 0; index < 7; index++)
                    Expanded(
                      child: Center(
                        child: _DayChip(
                          key: ValueKey('repeatDay_$index'),
                          index: index,
                          diameter: diameter,
                          selected: days.contains(index),
                          editable: editable,
                          onTap: () => onToggle(index),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    super.key,
    required this.index,
    required this.diameter,
    required this.selected,
    required this.editable,
    required this.onTap,
  });

  final int index;

  /// Sized by the parent so all seven chips share one row.
  final double diameter;
  final bool selected;
  final bool editable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: editable,
      selected: selected,
      // The short labels repeat ('S', 'T'), so the full name carries the
      // meaning for assistive technology.
      label: weekdayFullLabel(l10n, index),
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brand : tokens.surface,
          shape: CircleBorder(
            side: BorderSide(
              color: selected ? tokens.brand : tokens.cardBorder,
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: editable ? onTap : null,
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Center(
                child: Text(
                  weekdayShortLabel(l10n, index),
                  style: textTheme.titleSmall?.copyWith(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : tokens.textPrimary,
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

/// Confirms the selection. Always enabled — "Does not repeat" is a valid
/// answer, so there is no incomplete state to guard against.
class RepeatDoneButton extends StatelessWidget {
  const RepeatDoneButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.done,
      child: ExcludeSemantics(
        child: Material(
          color: tokens.brand,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Center(
                child: Text(
                  l10n.done,
                  style: textTheme.titleMedium?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
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
