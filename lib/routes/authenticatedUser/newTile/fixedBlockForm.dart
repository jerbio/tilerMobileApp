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
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';

/// Wall-clock time for the Starts / Ends rows, e.g. `2:00 PM`.
String formatClockTime(DateTime time) => DateFormat.jm().format(time);

/// Date row summary. The current day reads as `Today, Sep 5`; any other date
/// uses the plain localized form. [today] is injected so the "is it today?"
/// comparison is testable without a clock.
String formatBlockDate(DateTime date, {required DateTime today}) {
  final bool isToday = date.year == today.year &&
      date.month == today.month &&
      date.day == today.day;
  final String formatted = DateFormat.MMMd().format(date);
  return isToday ? 'Today, $formatted' : formatted;
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
    final DateTime start = draft.startTime;
    final DateTime end = draft.calculatedEnd;
    final String? durationSummary = formatDurationSummary(draft.duration);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AddTileSection(
          children: [
            AddTileTextFieldRow(
              key: const ValueKey('fixedTitleField'),
              icon: Icons.subject,
              label: 'TITLE',
              required: true,
              controller: nameController,
              focusNode: nameFocus,
              hint: 'What is this block?',
              error: nameError,
              onChanged: onNameChanged,
              onSubmitted: onNameSubmitted,
            ),
            AddTileFieldRow(
              key: const ValueKey('fixedDateRow'),
              icon: Icons.calendar_today_outlined,
              label: 'DATE',
              required: true,
              value: formatBlockDate(start, today: today),
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
              label: 'ENDS',
              value: formatClockTime(end),
              // No onTap: the end is derived, so it must not look editable.
              trailing: const AddTileLockedPill(label: 'Auto-calculated'),
              semanticLabel: 'Ends at ${formatClockTime(end)}, '
                  'calculated from start and duration',
            ),
            AddTileFieldRow(
              key: const ValueKey('locationRow'),
              icon: Icons.location_on_outlined,
              label: 'LOCATION',
              value: locationSummary(draft.location) ?? 'Add location',
              valueIsPlaceholder: locationSummary(draft.location) == null,
              onTap: onLocationTap,
              trailing: onNameLocationTap == null
                  ? null
                  : NameLocationButton(onTap: onNameLocationTap!),
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
    final Widget startCell = AddTileFieldRow(
      key: const ValueKey('fixedStartRow'),
      icon: Icons.schedule,
      label: 'STARTS',
      required: true,
      value: formatClockTime(start),
      onTap: onStartTap,
    );
    final Widget durationCell = AddTileFieldRow(
      key: const ValueKey('fixedDurationRow'),
      icon: Icons.timer_outlined,
      label: 'DURATION',
      required: true,
      value: durationSummary ?? 'Not set',
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
