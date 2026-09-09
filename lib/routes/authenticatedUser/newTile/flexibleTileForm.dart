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
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDurationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationOwnership.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Compact Location row summary, or `null` when nothing is selected (the row
/// then reads "Add location").
///
/// A `Location.fromDefault()` ghost is the draft's *absent* state, not a
/// choice. [locationHasContent] is what distinguishes the two — see the note
/// there for why the legacy `isNotNullAndNotDefault` predicate could not
/// (D53).
String? locationSummary(Location? location) {
  if (location == null || !locationHasContent(location)) return null;
  final String description = (location.description ?? '').trim();
  if (description.isNotEmpty) return description;
  final String address = (location.address ?? '').trim();
  return address.isEmpty ? null : address;
}

/// Compact Repeat row summary. A disabled or absent rule reads "Does not
/// repeat" — the user-facing wording for `RepetitionFrequency.none`.
String repeatSummary(AppLocalizations l10n, RepetitionData? repetition) {
  if (repetition == null || !repetition.isEnabled)
    return l10n.addTileRepeatNever;
  switch (repetition.frequency) {
    case RepetitionFrequency.daily:
      return l10n.daily;
    case RepetitionFrequency.weekly:
      return l10n.weekly;
    case RepetitionFrequency.monthly:
      return l10n.monthly;
    case RepetitionFrequency.yearly:
      return l10n.yearly;
    case RepetitionFrequency.none:
      return l10n.addTileRepeatNever;
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
    this.predicting = false,
    this.onNameChanged,
    this.onNameSubmitted,
    this.onDurationTap,
    this.onDeadlineTap,
    this.onPreferredTimeSelected,
    this.onAdvancedPreferredTimeTap,
    this.onLocationTap,
    this.onNameLocationTap,
    this.onRepeatTap,
  });

  final AddTileDraft draft;
  final TextEditingController nameController;
  final FocusNode nameFocus;
  final String? nameError;

  /// A name-driven prediction is in flight for this draft.
  final bool predicting;

  /// Invoked on every keystroke in the name field so the shell can keep the
  /// draft in sync (and clear an inline "required" error once addressed).
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNameSubmitted;
  final VoidCallback? onDurationTap;
  final VoidCallback? onDeadlineTap;

  /// Fired with the tapped day part. The shell applies it directly; choosing
  /// a day part while Custom is selected REPLACES the advanced profile (D40).
  final ValueChanged<PreferredTimeOfDay>? onPreferredTimeSelected;

  /// Opens the advanced profile editor behind the **Custom** chip. Same
  /// destination as More options' "Advanced preferred time" row — one editor,
  /// two entry points, so the chip is a shortcut rather than a second flow.
  final VoidCallback? onAdvancedPreferredTimeTap;
  final VoidCallback? onLocationTap;

  /// Opens the "name this place" affordance. Null when there is no location
  /// to name. Naming lives here because the picker commits on tap.
  final VoidCallback? onNameLocationTap;
  final VoidCallback? onRepeatTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final durationSummary = formatDurationSummary(l10n, draft.duration);
    final deadlineText = draft.endTime == null
        ? l10n.anytime
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
              label: l10n.addTileFieldTaskName,
              required: true,
              controller: nameController,
              focusNode: nameFocus,
              hint: l10n.addTileTaskNameHint,
              error: nameError,
              busy: predicting,
              onChanged: onNameChanged,
              onSubmitted: onNameSubmitted,
            ),
            AddTileFieldRow(
              key: const ValueKey('durationRow'),
              icon: Icons.schedule,
              label: l10n.addTileFieldDuration,
              required: true,
              value: durationSummary ?? l10n.addTileValueNotSet,
              valueIsPlaceholder: durationSummary == null,
              onTap: onDurationTap,
            ),
            // COMPLETE BY is the DEADLINE. Its "Anytime" means "no deadline",
            // a different concept from Preferred time's "Anytime" below; the
            // two carry distinct labels so they are never conflated.
            AddTileFieldRow(
              key: const ValueKey('completeByRow'),
              icon: Icons.event_outlined,
              label: l10n.addTileFieldCompleteBy,
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
          onCustomTap: onAdvancedPreferredTimeTap,
        ),
        const SizedBox(height: 14),

        // Secondary shortcuts. Location and Repeat stay on the main form
        // (they materially change scheduling); everything else is under More
        // options.
        AddTileSection(
          children: [
            // The title is the FIELD, always — "Location" — with the chosen
            // place as its value, exactly like the Repeat row beneath it.
            // It used to flip between "Add location" and the place itself,
            // with the word "Location" demoted to a subtitle only once a
            // place was set, so the row named two different things depending
            // on its state and moved its own label around (D35).
            AddTileNavRow(
              key: const ValueKey('locationRow'),
              icon: Icons.location_on_outlined,
              title: l10n.location,
              subtitle: locationText ?? l10n.addTileValueNotSet,
              onTap: onLocationTap,
              // A chevron, not a circled plus: this row NAVIGATES, and it
              // navigates to the same place whether or not a location is set
              // — so the affordance must not change with the state (§7.1).
              trailing: locationText == null || onNameLocationTap == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        NameLocationButton(onTap: onNameLocationTap!),
                        Icon(Icons.chevron_right,
                            color: TodayStatusTokens.of(context).textSecondary),
                      ],
                    ),
            ),
            AddTileNavRow(
              key: const ValueKey('repeatRow'),
              icon: Icons.repeat,
              title: l10n.addTileRepeat,
              subtitle: repeatSummary(l10n, draft.repetitionData),
              onTap: onRepeatTap,
            ),
          ],
        ),
      ],
    );
  }
}

/// The chip order, SELECTED FIRST.
///
/// The row scrolls horizontally (D31), so canonical order would let the
/// current answer sit off-screen — a control that cannot show its own value.
/// Promoting the selection to the front makes it unconditionally visible
/// without a scroll controller or an auto-scroll animation.
///
/// `null` stands for the Custom chip, mirroring [preferredTimeOfProfile],
/// which returns `null` for exactly the profiles Custom represents. The rest
/// keep their canonical order, so the row is not reshuffled beyond the one
/// move.
///
/// KNOWN COST: tapping a chip moves it leftwards under the user's finger and
/// shifts the ones it passes. Accepted deliberately — a selection that cannot
/// be seen is worse than one that moves once when chosen.
List<PreferredTimeOfDay?> preferredTimeChipOrder(PreferredTimeOfDay? selected) {
  const List<PreferredTimeOfDay?> canonical = <PreferredTimeOfDay?>[
    ...PreferredTimeOfDay.values,
    null, // Custom
  ];
  return <PreferredTimeOfDay?>[
    selected,
    ...canonical.where((option) => option != selected),
  ];
}

/// The compact Preferred time control: Anytime / Morning / Afternoon /
/// Evening / Custom, on ONE line.
///
/// **Custom** is a peer of the four day parts rather than a state that
/// replaces them. An advanced profile — one [preferredTimeOfProfile] cannot
/// express as a day part — simply shows Custom as the selected chip, and
/// tapping it opens the profile editor. An earlier revision swapped the whole
/// control for a read-only "Custom" row in that case, which left a user with
/// an advanced profile no way back to the four simple choices and no way into
/// the editor from here.
///
/// Tapping a day part while Custom is selected replaces the advanced profile
/// (D40). That is not silent: Custom is rendered as the selected chip, so the
/// user can see what they are replacing.
///
/// Selection is conveyed by label + selected semantics, never by color alone.
class PreferredTimeControl extends StatelessWidget {
  const PreferredTimeControl({
    super.key,
    required this.profile,
    this.onSelected,
    this.onCustomTap,
  });

  final RestrictionProfile? profile;
  final ValueChanged<PreferredTimeOfDay>? onSelected;

  /// Opens the advanced profile editor. Null leaves the Custom chip inert.
  final VoidCallback? onCustomTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final tokens = TodayStatusTokens.of(context);

    // A `null` here means the profile is advanced, which is precisely what the
    // Custom chip stands for — so it selects that chip instead of hiding the
    // control.
    final PreferredTimeOfDay? selected = preferredTimeOfProfile(profile);
    final bool customSelected = selected == null;

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
            l10n.addTileFieldPreferredTime,
            style: textTheme.labelSmall?.copyWith(
              color: tokens.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),
          // ONE line, always. Five labelled options do not fit a phone width
          // at a readable text size, so the row SCROLLS rather than wrapping:
          // on device the wrapped version read as a lopsided grid, and
          // shrinking labels to fit would break at large text scale. Scroll
          // physics stay platform-default so the row bounces at its end and
          // advertises that there is more.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (int position, PreferredTimeOfDay? option)
                    in preferredTimeChipOrder(selected).indexed) ...[
                  if (position > 0) const SizedBox(width: 8),
                  if (option == null)
                    _PreferredTimeChip(
                      key: const ValueKey('preferredTimeCustom'),
                      label: l10n.addTilePreferredTimeCustom,
                      icon: Icons.tune,
                      selected: customSelected,
                      onTap: onCustomTap,
                      textTheme: textTheme,
                      scheme: scheme,
                    )
                  else
                    _PreferredTimeChip(
                      key: ValueKey('preferredTime${_suffix(option)}'),
                      label: preferredTimeLabel(l10n, option),
                      icon: _iconFor(option),
                      selected: option == selected,
                      onTap:
                          onSelected == null ? null : () => onSelected!(option),
                      textTheme: textTheme,
                      scheme: scheme,
                    ),
                ],
              ],
            ),
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
