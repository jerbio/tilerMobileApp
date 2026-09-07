// Phase 3.1 — Fixed Block interval form.
//
// A Block is a LOCKED INTERVAL: the user sets Date, Starts and Duration, and
// Ends is derived as start + duration. That derivation is the wire contract
// too (the mapper ships `End = start + duration` for rigid payloads), so the
// end row is display-only in v1 — decision D6 — and deliberately carries no
// editable affordance.
//
// Built to the Add Block mockup, with the deviations locked in plan §4.1/§4.2
// and reconfirmed with the user on 2026-09-05:
//   * no bottom Cancel — the top-left Close is the only cancel path;
//   * Color is under More options, not a primary row;
//   * Location and Repeat remain direct rows.
//
// Presentation only: every mutation is delegated to [AddTileDraft], and the
// pickers are reached through callbacks the shell owns.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';

/// Wall-clock time for the Starts / Ends rows, e.g. `2:00 PM`.
String formatClockTime(DateTime time) => DateFormat.jm().format(time);

/// Date row summary. The current day reads as `Today, Sep 5`; any other date
/// uses the plain localized form. [today] is injected so the "is it today?"
/// comparison is testable without a clock.
String formatBlockDate(AppLocalizations l10n, DateTime date,
    {required DateTime today}) {
  final bool isToday = date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
  final String formatted = DateFormat.MMMd().format(date);
  return isToday ? l10n.addTileTodayDate(formatted) : formatted;
}

/// The fixed-interval form: Title, Date, Starts | Duration, derived Ends, and
/// Location.
class FixedBlockForm extends StatelessWidget {
  const FixedBlockForm({
    super.key,
    required this.draft,
    required this.nameController,
    required this.nameFocus,
    required this.today,
    this.nameError,
    this.predicting = false,
    this.onNameChanged,
    this.onNameSubmitted,
    this.onDateTap,
    this.onStartTap,
    this.onDurationTap,
    this.onLocationTap,
    this.onNameLocationTap,
    this.onRepeatTap,
  });

  final AddTileDraft draft;
  final TextEditingController nameController;
  final FocusNode nameFocus;

  /// "Now" for the Today comparison on the date row.
  final DateTime today;

  final String? nameError;

  /// A name-driven prediction is in flight for this draft.
  final bool predicting;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onNameSubmitted;
  final VoidCallback? onDateTap;
  final VoidCallback? onStartTap;
  final VoidCallback? onDurationTap;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNameLocationTap;
  final VoidCallback? onRepeatTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final DateTime start = draft.startTime;
    final DateTime end = draft.calculatedEnd;
    final String? durationSummary = formatDurationSummary(l10n, draft.duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddTileSection(
          children: [
            AddTileTextFieldRow(
              key: const ValueKey('fixedTitleField'),
              icon: Icons.subject,
              label: l10n.addTileFieldTitle,
              required: true,
              controller: nameController,
              focusNode: nameFocus,
              hint: l10n.addTileBlockTitleHint,
              error: nameError,
              busy: predicting,
              onChanged: onNameChanged,
              onSubmitted: onNameSubmitted,
            ),
            AddTileFieldRow(
              key: const ValueKey('fixedDateRow'),
              icon: Icons.calendar_today_outlined,
              label: l10n.addTileFieldDate,
              required: true,
              value: formatBlockDate(l10n, start, today: today),
              onTap: onDateTap,
            ),
            // Starts and Duration share a row in the mockup. On a narrow
            // viewport or at large text scale the two columns would collide,
            // so they stack instead of overflowing (§4.2 revision 4).
            _StartAndDurationRow(
              start: start,
              durationSummary: durationSummary,
              onStartTap: onStartTap,
              onDurationTap: onDurationTap,
            ),
            AddTileFieldRow(
              key: const ValueKey('fixedEndRow'),
              icon: Icons.outlined_flag,
              label: l10n.addTileFieldEnds,
              value: formatClockTime(end),
              // No onTap: the end is derived, so it must not look editable.
              trailing: AddTileLockedPill(label: l10n.addTileAutoCalculated),
              semanticLabel: l10n.addTileEndsSemantics(formatClockTime(end)),
            ),
            AddTileFieldRow(
              key: const ValueKey('locationRow'),
              icon: Icons.location_on_outlined,
              label: l10n.addTileFieldLocation,
              value: locationSummary(draft.location) ?? l10n.addTileValueNotSet,
              valueIsPlaceholder: locationSummary(draft.location) == null,
              onTap: onLocationTap,
              // The name action never replaces the chevron: the row still
              // navigates (D35).
              trailing: locationSummary(draft.location) == null ||
                      onNameLocationTap == null
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

            // Step 3.2 — Repeat. The header above has always claimed
            // "Location and Repeat remain direct rows" and the constructor
            // has always taken an [onRepeatTap], but no row was ever built,
            // so a RECURRING BLOCK was unreachable in the redesign while the
            // legacy flow supported one.
            //
            // It opens the SAME picker the Flexible form uses. That is not
            // just convenience: `repeatSemanticsIdenticalAcrossModes` holds
            // because the mapper ships identical repetition fields for both
            // modes, so one picker is the honest representation of one
            // concept.
            //
            // The Block's own interval is unaffected. An enabled repetition
            // otherwise overrides `endTime` with the recurrence end, but the
            // mapper's rigid branch runs last and restores start + duration —
            // pinned in add_tile_fixed_secondary_test.dart, because a Block
            // whose end silently moved months out would be wrong on the
            // server with nothing on screen to reveal it.
            AddTileFieldRow(
              key: const ValueKey('repeatRow'),
              icon: Icons.repeat,
              label: l10n.addTileFieldRepeat,
              // "Does not repeat" is a real answer, not an unset field, so it
              // is not dimmed — the same call the Complete by row makes about
              // its "Anytime".
              value: repeatSummary(l10n, draft.repetitionData),
              onTap: onRepeatTap,
            ),
          ],
        ),
      ],
    );
  }
}

/// The two-column Starts / Duration row, which stacks when there is not enough
/// width for both columns to stay legible.
class _StartAndDurationRow extends StatelessWidget {
  const _StartAndDurationRow({
    required this.start,
    required this.durationSummary,
    required this.onStartTap,
    required this.onDurationTap,
  });

  final DateTime start;
  final String? durationSummary;
  final VoidCallback? onStartTap;
  final VoidCallback? onDurationTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Widget startCell = AddTileFieldRow(
      key: const ValueKey('fixedStartRow'),
      icon: Icons.schedule,
      label: l10n.addTileFieldStarts,
      required: true,
      value: formatClockTime(start),
      onTap: onStartTap,
    );
    final Widget durationCell = AddTileFieldRow(
      key: const ValueKey('fixedDurationRow'),
      icon: Icons.timer_outlined,
      label: l10n.addTileFieldDuration,
      required: true,
      value: durationSummary ?? l10n.addTileValueNotSet,
      valueIsPlaceholder: durationSummary == null,
      onTap: onDurationTap,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Below this width the two cells cannot both show a label, a value and
        // a chevron without clipping, so they stack.
        final bool stack = constraints.maxWidth < 380;
        if (stack) {
          return Column(children: [startCell, durationCell]);
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: startCell),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(context).dividerColor,
              ),
              Expanded(child: durationCell),
            ],
          ),
        );
      },
    );
  }
}
