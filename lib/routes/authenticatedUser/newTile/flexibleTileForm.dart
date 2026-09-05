// Phase 2.1 / 2.2 — Flexible Tile primary form.
//
// Renders the three primary Flexible decisions in the required visual order,
// followed by the optional scheduling constraints:
//   1. What do you want to do?  (name)
//   2. How long?                (duration)
//   3. Complete by              (deadline / endTime)
//   4. Preferred time           (day-part restriction profile)
//   5. Location, Repeat         (secondary shortcuts)
//
// Steps 3 and 4 both offer an "Anytime" value with DIFFERENT meanings —
// "no deadline" versus "no day-part restriction" — so each keeps its own
// section label and they are never rendered as one control.
//
// The form is a pure presentation layer: it reads from [AddTileDraft] and
// delegates all mutation to the draft (via the setter API that marks
// user-edited fields). Row taps are exposed as callbacks so the shell can
// wire the existing pickers (/DurationDial, showDatePicker, and the typed
// Location/Repeat adapters) without changing their returned semantics.
//
// Step 2.3 adds the More options disclosure (priority, color, split
// sessions, flexible completion date, advanced preferred-time profile).
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/repetitionData.dart';
import 'package:tiler_app/data/repetitionFrequency.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';

/// Formats a [Duration] as a compact, locale-neutral summary for the
/// duration row. Examples:
///   45 min  → "45 min"
///   2 hr    → "2 hr"
///   1 hr 30 → "1 hr 30 min"
///
/// Returns `null` when the duration is zero or negative (caller shows
/// "Duration not set" instead).
String? formatDurationSummary(Duration d) {
  if (d.inMinutes <= 0) return null;
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours == 0) return '$minutes min';
  if (minutes == 0) return '$hours hr';
  return '$hours hr $minutes min';
}

/// Compact Location row summary, or `null` when nothing is selected (the row
/// then reads "Add location").
///
/// A `Location.fromDefault()` ghost is the draft's *absent* state, not a
/// choice — `isNotNullAndNotDefault` is the legacy predicate for "the user
/// actually has a location", so it gates the summary here too.
String? locationSummary(Location? location) {
  if (location == null || !location.isNotNullAndNotDefault) return null;
  final String? description = location.description?.trim();
  if (description != null && description.isNotEmpty) return description;
  final String? address = location.address?.trim();
  if (address != null && address.isNotEmpty) return address;
  return null;
}

/// Compact Repeat row summary. A disabled or absent rule reads "Does not
/// repeat" — the user-facing wording for `RepetitionFrequency.none`.
String repeatSummary(RepetitionData? repetition) {
  if (repetition == null || !repetition.isEnabled) return 'Does not repeat';
  switch (repetition.frequency) {
    case RepetitionFrequency.daily:
      return 'Daily';
    case RepetitionFrequency.weekly:
      return 'Weekly';
    case RepetitionFrequency.monthly:
      return 'Monthly';
    case RepetitionFrequency.yearly:
      return 'Yearly';
    case RepetitionFrequency.none:
      return 'Does not repeat';
  }
}

/// Primary Flexible Tile form: name, duration, and Complete by.
///
/// [nameController] and [nameFocus] are owned by the shell so it can
/// prefill, clear, and focus the name field. [nameError] displays an inline
/// validation message (announced to assistive tech, not color-only).
///
/// [onNameSubmitted] is invoked when the user presses the keyboard "done"
/// action while the name field is focused — the shell uses this to attempt
/// submission.
class FlexibleTileForm extends StatelessWidget {
  const FlexibleTileForm({
    super.key,
    required this.draft,
    required this.nameController,
    required this.nameFocus,
    this.nameError,
    this.onNameChanged,
    this.onNameSubmitted,
    this.onDurationTap,
    this.onDeadlineTap,
    this.onPreferredTimeSelected,
    this.onLocationTap,
    this.onRepeatTap,
  });

  final AddTileDraft draft;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String? nameError;

  /// Invoked on every keystroke in the name field so the shell can keep the
  /// draft in sync (and clear an inline "required" error once addressed).
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNameSubmitted;
  final VoidCallback? onDurationTap;
  final VoidCallback? onDeadlineTap;

  /// Fired with the tapped day part. The shell resolves it through
  /// [applyPreferredTimeSelection] so an advanced profile is preserved.
  final ValueChanged<PreferredTimeOfDay>? onPreferredTimeSelected;
  final VoidCallback? onLocationTap;
  final VoidCallback? onRepeatTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final durationSummary = formatDurationSummary(draft.duration);
    final deadlineText = draft.endTime == null
        ? 'Anytime'
        : DateFormat.yMMMd().format(draft.endTime!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Name
        TextField(
          controller: nameController,
          focusNode: nameFocus,
          textInputAction: TextInputAction.done,
          onChanged: onNameChanged,
          onSubmitted: onNameSubmitted,
          decoration: InputDecoration(
            labelText: 'What do you want to do?',
            errorText: nameError,
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // 2. Duration
        Text('How long? *', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        _FormRow(
          key: const ValueKey('durationRow'),
          summary: durationSummary ?? 'Duration not set',
          summaryColor: durationSummary != null ? null : scheme.error,
          onTap: onDurationTap,
          textTheme: textTheme,
          scheme: scheme,
        ),
        const SizedBox(height: 12),

        // 3. Complete by — the DEADLINE. Its "Anytime" means "no deadline",
        // a different concept from Preferred time's "Anytime" below; the two
        // carry distinct section labels so they are never conflated.
        Text('Complete by', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        _FormRow(
          key: const ValueKey('completeByRow'),
          summary: deadlineText,
          onTap: onDeadlineTap,
          textTheme: textTheme,
          scheme: scheme,
        ),
        const SizedBox(height: 12),

        // 4. Preferred time — WHICH PART OF THE DAY the work may be
        // scheduled in. Its "Anytime" means "no day-part restriction".
        Text('Preferred time', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        PreferredTimeControl(
          profile: draft.restrictionProfile,
          onSelected: onPreferredTimeSelected,
        ),
        const SizedBox(height: 12),

        // 5. Secondary shortcuts. Location and Repeat stay on the main form
        // (they materially change scheduling); everything else is under More
        // options, which arrives in Step 2.3.
        _FormRow(
          key: const ValueKey('locationRow'),
          summary: locationSummary(draft.location) ?? 'Add location',
          onTap: onLocationTap,
          textTheme: textTheme,
          scheme: scheme,
        ),
        _FormRow(
          key: const ValueKey('repeatRow'),
          summary: repeatSummary(draft.repetitionData),
          onTap: onRepeatTap,
          textTheme: textTheme,
          scheme: scheme,
        ),
      ],
    );
  }
}

/// The compact Preferred time control: Anytime / Morning / Afternoon /
/// Evening.
///
/// When [profile] is an advanced/custom restriction the control shows a
/// single read-only **Custom** summary instead of the four choices — tapping
/// a simple day part must never silently discard advanced values (that is
/// what [applyPreferredTimeSelection] enforces in the state layer; showing
/// Custom keeps the UI honest about it).
///
/// Wraps so four options survive a narrow width at large text scale, and
/// selection is conveyed by label + selected semantics, never by color
/// alone.
class PreferredTimeControl extends StatelessWidget {
  const PreferredTimeControl({
    super.key,
    required this.profile,
    this.onSelected,
  });

  final RestrictionProfile? profile;
  final ValueChanged<PreferredTimeOfDay>? onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final PreferredTimeOfDay? selected = preferredTimeOfProfile(profile);

    if (selected == null) {
      // Advanced/custom profile: summarize, do not offer to overwrite it.
      return _FormRow(
        key: const ValueKey('preferredTimeCustom'),
        summary: 'Custom',
        textTheme: textTheme,
        scheme: scheme,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final part in PreferredTimeOfDay.values)
          _PreferredTimeChip(
            key: ValueKey('preferredTime${_suffix(part)}'),
            label: preferredTimeLabel(part),
            selected: part == selected,
            onTap: onSelected == null ? null : () => onSelected!(part),
            textTheme: textTheme,
            scheme: scheme,
          ),
      ],
    );
  }

  static String _suffix(PreferredTimeOfDay part) {
    final String name = part.name;
    return name[0].toUpperCase() + name.substring(1);
  }
}

/// One Preferred time option. Selected state reaches assistive tech through
/// `Semantics.selected` (not color alone) and the target clears 44px.
class _PreferredTimeChip extends StatelessWidget {
  const _PreferredTimeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.textTheme,
    required this.scheme,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
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

/// A single tappable row in the form: a summary value and an optional
/// trailing chevron (navigation affordance). 44px minimum touch target.
class _FormRow extends StatelessWidget {
  const _FormRow({
    super.key,
    required this.summary,
    this.summaryColor,
    this.onTap,
    required this.textTheme,
    required this.scheme,
  });

  final String summary;
  final Color? summaryColor;
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
                  child: Center(
                    child: Text(
                      summary,
                      style: textTheme.bodyMedium?.copyWith(
                        color: summaryColor ?? scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                if (onTap != null)
                  Icon(
                    Icons.chevron_right,
                    color: scheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
