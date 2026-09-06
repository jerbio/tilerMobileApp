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
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

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
    this.onNameLocationTap,
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

  /// Opens the "name this place" affordance. Null when there is no location
  /// to name. Naming lives here because the picker commits on tap.
  final VoidCallback? onNameLocationTap;
  final VoidCallback? onRepeatTap;

  @override
  Widget build(BuildContext context) {
    final durationSummary = formatDurationSummary(draft.duration);
    final deadlineText = draft.endTime == null
        ? 'Anytime'
        : DateFormat.yMMMd().format(draft.endTime!);
    final String? locationText = locationSummary(draft.location);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The three primary decisions, grouped as one surface (§4.1: hierarchy
        // from content and spacing, not a card per field).
        AddTileSection(
          children: [
            AddTileTextFieldRow(
              key: const ValueKey('taskNameField'),
              icon: Icons.edit_outlined,
              label: 'TASK NAME',
              required: true,
              controller: nameController,
              focusNode: nameFocus,
              hint: 'What do you want to do?',
              error: nameError,
              onChanged: onNameChanged,
              onSubmitted: onNameSubmitted,
            ),
            AddTileFieldRow(
              key: const ValueKey('durationRow'),
              icon: Icons.schedule,
              label: 'DURATION',
              required: true,
              value: durationSummary ?? 'Not set',
              valueIsPlaceholder: durationSummary == null,
              onTap: onDurationTap,
            ),
            // COMPLETE BY is the DEADLINE. Its "Anytime" means "no deadline",
            // a different concept from Preferred time's "Anytime" below; the
            // two carry distinct labels so they are never conflated.
            AddTileFieldRow(
              key: const ValueKey('completeByRow'),
              icon: Icons.event_outlined,
              label: 'COMPLETE BY',
              value: deadlineText,
              onTap: onDeadlineTap,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Preferred time — WHICH PART OF THE DAY the work may be scheduled in.
        // Its "Anytime" means "no day-part restriction".
        PreferredTimeControl(
          profile: draft.restrictionProfile,
          onSelected: onPreferredTimeSelected,
        ),
        const SizedBox(height: 14),

        // Secondary shortcuts. Location and Repeat stay on the main form
        // (they materially change scheduling); everything else is under More
        // options.
        AddTileSection(
          children: [
            AddTileNavRow(
              key: const ValueKey('locationRow'),
              icon: Icons.location_on_outlined,
              title: locationText ?? 'Add location',
              subtitle: locationText == null ? null : 'Location',
              onTap: onLocationTap,
              trailing: locationText == null
                  ? Icon(Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary)
                  : (onNameLocationTap == null
                      ? null
                      : NameLocationButton(onTap: onNameLocationTap!)),
            ),
            AddTileNavRow(
              key: const ValueKey('repeatRow'),
              icon: Icons.repeat,
              title: 'Repeat',
              subtitle: repeatSummary(draft.repetitionData),
              onTap: onRepeatTap,
            ),
          ],
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

    final tokens = TodayStatusTokens.of(context);

    if (selected == null) {
      // Advanced/custom profile: summarize, do not offer to overwrite it.
      return AddTileSection(
        children: [
          AddTileFieldRow(
            key: const ValueKey('preferredTimeCustom'),
            icon: Icons.tune,
            label: 'PREFERRED TIME',
            value: 'Custom',
          ),
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERRED TIME',
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          // Wraps so four options survive a narrow width at large text scale
          // rather than overflowing (§4.2 revision 4).
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final part in PreferredTimeOfDay.values)
                _PreferredTimeChip(
                  key: ValueKey('preferredTime${_suffix(part)}'),
                  label: preferredTimeLabel(part),
                  icon: _iconFor(part),
                  selected: part == selected,
                  onTap: onSelected == null ? null : () => onSelected!(part),
                  textTheme: textTheme,
                  scheme: scheme,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Day-part icons. Decorative — each chip's meaning is carried by its
  /// label and selected semantics, so the icons are hidden from assistive
  /// technology by the chip itself.
  static IconData _iconFor(PreferredTimeOfDay part) {
    switch (part) {
      case PreferredTimeOfDay.anytime:
        return Icons.check_circle;
      case PreferredTimeOfDay.morning:
        return Icons.wb_twilight;
      case PreferredTimeOfDay.afternoon:
        return Icons.wb_sunny_outlined;
      case PreferredTimeOfDay.evening:
        return Icons.nightlight_outlined;
    }
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
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.textTheme,
    required this.scheme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;
  final TextTheme textTheme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brandTint : tokens.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? tokens.brand : tokens.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? tokens.brand : tokens.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: textTheme.bodyMedium?.copyWith(
                      color: selected ? tokens.brand : tokens.textPrimary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
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
