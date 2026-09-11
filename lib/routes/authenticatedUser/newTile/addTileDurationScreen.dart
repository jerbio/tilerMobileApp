// Step 4.3c — the Duration picker.
//
// Replaces the legacy `/DurationDial` route for this flow. Built to the house
// picker pattern: Back rather than Close (D12), presets COMMIT on tap, and
// the one continuous control keeps a confirm because it cannot commit on
// every drag.
//
// THE ROTARY WHEEL IS KEPT (D43). An interim revision swapped it for a
// stepper on the grounds that its minute-level precision was theatre once it
// snapped to five. That was a misread: the wheel is FASTER for the large
// moves this control mostly makes — an hour is one gesture, not twelve taps —
// and it is what users of this app already know. It is retained and instead
// made consistent with the redesign: the vendored `DurationPicker` reads its
// accent from `ColorScheme.secondary` and its ground from
// `scaffoldBackgroundColor`, so it is wrapped in a local `Theme` that points
// both at the redesign's own tokens rather than forking the package.
//
// It also SNAPS AND CLICKS every five minutes: `snapToMins` quantises the
// value, and crossing a detent fires a selection haptic, so the step is felt
// as well as seen.
//
// WHY REPLACE THE DIAL AT ALL. Two defects, not a preference:
//
//   1. **It never seeded.** The dial reads `params['initialDuration']`, the
//      redesign's adapter wrote `params['duration']`. So it always opened at
//      ZERO regardless of the draft, and confirming without touching the dial
//      wrote a zero duration back — which fails validation and disables the
//      CTA with nothing on screen explaining why. The legacy Add Tile screen
//      passes the key the dial expects, so the bug is specific to the
//      redesign's adapter and invisible from the legacy flow.
//   2. **No bounds.** `setUserDuration` does not floor, so zero and absurd
//      values both reached the draft.
//
// The 5-minute step is carried over from the dial's `snapToMins: 5.0`, so a
// returning user cannot express a duration here that they could not express
// before.
//
// Speaks plain `Duration` values and knows nothing about the Add Tile draft,
// so the edit-tile flow can reuse it as-is (D29).
import 'dart:math' as math;

import 'package:duration_picker/duration_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDateTimeChoices.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Formats a [Duration] as a compact, locale-aware summary. Examples:
///   45 min  → "45 min"
///   2 hr    → "2 hr"
///   1 hr 30 → "1 hr 30 min"
///
/// Returns `null` when the duration is zero or negative, which the form rows
/// render as their "not set" placeholder.
///
/// Lives beside the picker rather than in the form, so the row and the screen
/// cannot disagree about how a duration reads (D41).
String? formatDurationSummary(AppLocalizations l10n, Duration d) {
  if (d.inMinutes <= 0) return null;
  final int hours = d.inHours;
  final int minutes = d.inMinutes.remainder(60);
  if (hours == 0) return l10n.addTileDurationMinutes(minutes);
  if (minutes == 0) return l10n.addTileDurationHours(hours);
  return l10n.addTileDurationHoursMinutes(hours, minutes);
}

/// The quick durations offered above the wheel.
///
/// Four, not the eight this started with. A shortcut row stops being a
/// shortcut once it has to be READ — eight chips took two rows and made the
/// common case a search. These four cover the bulk of real task lengths and
/// everything else is one gesture away on the wheel, which is the control
/// that is actually good at arbitrary values.
///
/// 45 min and 1 hr 30 min were the closest calls; they are one line to
/// restore if the walkthrough shows people reaching for them.
const List<Duration> addTileDurationPresets = <Duration>[
  Duration(minutes: 15),
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 2),
];

/// The smallest duration the picker can express, and the step the custom
/// control moves in. Carried over from the legacy dial's `snapToMins: 5.0`.
const Duration minAddTileDuration = Duration(minutes: 5);

/// The largest. A tile longer than a day is not a scheduling unit — the
/// engine splits long work into sessions instead (that is what Split into
/// sessions is for), so an unbounded control here would only let a user
/// express something the scheduler cannot honour.
const Duration maxAddTileDuration = Duration(hours: 24);

const int durationStepMinutes = 5;

/// Brings [d] inside the supported range.
Duration clampAddTileDuration(Duration d) {
  if (d < minAddTileDuration) return minAddTileDuration;
  if (d > maxAddTileDuration) return maxAddTileDuration;
  return d;
}

/// Rounds [d] to the nearest [durationStepMinutes], then clamps it.
///
/// Rounds rather than truncates: truncation always shortens, which over
/// repeated edits walks a duration downward.
Duration snapAddTileDuration(Duration d) {
  final int steps = (d.inMinutes / durationStepMinutes).round();
  return clampAddTileDuration(Duration(minutes: steps * durationStepMinutes));
}

/// Whether moving from [previous] to [next] crosses a detent, and so should
/// produce a tactile click.
///
/// The wheel reports continuously while a finger is down, so the haptic is
/// driven by the SNAPPED value changing rather than by the raw callback —
/// otherwise a single slow drag would buzz on every frame.
bool crossesDurationDetent(Duration previous, Duration next) =>
    snapAddTileDuration(previous) != snapAddTileDuration(next);

/// The duration implied by choosing a wall-clock END for a block that
/// starts at [start] (D61).
///
/// A clock time at or before the start reads as the FOLLOWING day: a block
/// from 2 PM cannot end at 1 PM today, and on a clock face an earlier time
/// means tomorrow. That also lets a late block run past midnight, and it
/// makes the same clock time a full day — the picker's ceiling. (The legacy
/// dial silently ignored such a pick.) The result is clamped and snapped
/// like every other input, so the Ends readout and the duration sent agree.
Duration durationForPickedEnd(DateTime start, TimeOfDay picked) {
  DateTime end = applyPickedTime(start, picked);
  if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
  return snapAddTileDuration(clampAddTileDuration(end.difference(start)));
}

/// The signature of the platform time picker, injectable by tests.
typedef PickTimeOfDay = Future<TimeOfDay?> Function(
    BuildContext context, TimeOfDay initialTime);

Future<TimeOfDay?> _showPlatformTimePicker(
        BuildContext context, TimeOfDay initialTime) =>
    showTimePicker(context: context, initialTime: initialTime);

class AddTileDurationScreen extends StatefulWidget {
  const AddTileDurationScreen({
    super.key,
    required this.initialDuration,
    this.startTime,
    this.onSelected,
    this.pickEndTime = _showPlatformTimePicker,
  });

  /// The duration in effect. An unset (zero) draft opens on the smallest
  /// supported value rather than on nothing, so the custom control always has
  /// a legible starting point.
  final Duration initialDuration;

  /// When the duration is a BLOCK's length, the time the block starts.
  ///
  /// With it the screen shows where the block will end and lets that end be
  /// edited directly, as the legacy `EndTimeDurationDial` did (D61). Without
  /// it — the Flexible flow, which has no fixed start — the screen is a
  /// plain duration picker. The picker stays shared either way.
  final DateTime? startTime;

  /// Invoked with the chosen duration. Injected by tests; in the app the
  /// screen pops with the value.
  final void Function(Duration)? onSelected;

  /// Opens the time picker for the Ends row. The platform picker by
  /// default (D42); a test seam otherwise.
  final PickTimeOfDay pickEndTime;

  @override
  State<AddTileDurationScreen> createState() => _AddTileDurationScreenState();
}

class _AddTileDurationScreenState extends State<AddTileDurationScreen> {
  late Duration _custom;

  /// True while a finger is down on the wheel.
  ///
  /// Circling the wheel is a pan, and a pan has a vertical component. Inside
  /// a scrolling list that component is contested: the list's drag
  /// recognizer and the dial's pan recognizer both enter the gesture arena,
  /// the list frequently wins, and the gesture becomes a scroll — which, on
  /// a page whose content already fits, surfaces as the rubber-band bounce
  /// rather than as rotation. The wheel is then genuinely hard to turn (D47).
  ///
  /// While this is true the list refuses to scroll, so the arena has a single
  /// contender and the whole gesture belongs to the dial.
  bool _wheelHeld = false;

  @override
  void initState() {
    super.initState();
    _custom = widget.initialDuration.inMinutes <= 0
        ? const Duration(minutes: 30)
        : snapAddTileDuration(widget.initialDuration);
  }

  /// Clamps as the wheel turns rather than only at commit, so it can never
  /// DISPLAY a duration it would silently rewrite on Done.
  void _onWheelChanged(Duration raw) {
    // Snapped HERE, not by the package: `DurationPicker` takes a
    // `snapToMins` and ignores it (its implementation is commented out
    // behind a `TODO: Fix snap to mins`), which is why the wheel could sit
    // on 3:49 while advertising a five-minute grid. Snapping on this side is
    // deterministic and testable, and avoids resurrecting package code that
    // was disabled for reasons not recorded.
    final Duration next = snapAddTileDuration(clampAddTileDuration(raw));
    if (next == _custom) return;
    if (crossesDurationDetent(_custom, next)) {
      HapticFeedback.selectionClick();
    }
    setState(() => _custom = next);
  }

  void _setWheelHeld(bool held) {
    if (_wheelHeld == held) return;
    setState(() => _wheelHeld = held);
  }

  /// Where the block ends at the PENDING duration.
  DateTime get _end => widget.startTime!.add(_custom);

  /// Edits the end, which edits the duration: the wheel follows the picked
  /// end exactly as the end follows the wheel.
  Future<void> _pickEnd() async {
    final DateTime start = widget.startTime!;
    final DateTime current = _end;
    final TimeOfDay? picked = await widget.pickEndTime(
      context,
      TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked == null || !mounted) return;
    final Duration next = durationForPickedEnd(start, picked);
    if (next == _custom) return;
    setState(() => _custom = next);
  }

  /// The Ends value. Says "next day" when start + duration crosses
  /// midnight, since 2 AM alone reads as a time BEFORE a 2 PM start.
  String _endLabel(AppLocalizations l10n) {
    final DateTime start = widget.startTime!;
    final DateTime end = _end;
    final String clock = formatClockTime(end);
    final bool sameDay = end.year == start.year &&
        end.month == start.month &&
        end.day == start.day;
    return sameDay ? clock : l10n.addTileDurationEndsNextDay(clock);
  }

  void _commit(Duration duration) {
    final Duration safe = snapAddTileDuration(duration);
    if (widget.onSelected != null) {
      widget.onSelected!(safe);
      return;
    }
    Navigator.of(context).pop(safe);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.duration),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              // See [_wheelHeld]. Suppressed rather than merely un-bounced:
              // clamping the physics would stop the rubber-band but leave
              // the list free to claim the drag and scroll away under the
              // finger whenever the content did overflow.
              physics: _wheelHeld ? const NeverScrollableScrollPhysics() : null,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                Text(
                  l10n.addTileDurationQuick,
                  style: textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  child: Wrap(
                    // Centred, not the default `start`. The chips size to
                    // their own text and "1 hr" is far narrower than
                    // "15 min", so left-aligned they left all the slack
                    // collected on the right and the row read as unfinished.
                    //
                    // Centring rather than stretching them to equal widths:
                    // at 320pt with large text the four already reflow onto
                    // two rows, and four forced columns would have to
                    // ellipsize "15 min" to fit. Centre stays tidy in both
                    // cases.
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (int index, Duration preset)
                          in addTileDurationPresets.indexed)
                        DurationPresetChip(
                          key: ValueKey('durationPreset_$index'),
                          label: formatDurationSummary(l10n, preset) ?? '',
                          // Tracks the PENDING value, not the committed one, so
                          // turning the wheel clears the highlight and the screen
                          // never shows two different current durations at once.
                          // Landing back on a preset re-selects it.
                          selected: preset == _custom,
                          onTap: () => _commit(preset),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.addTileDurationCustom,
                  style: textTheme.labelSmall?.copyWith(
                      color: tokens.textSecondary, letterSpacing: 0.6),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tokens.cardBorder),
                  ),
                  // A `Listener`, not a `GestureDetector`: raw pointer
                  // callbacks do not enter the gesture arena, so this can
                  // lock the list WITHOUT competing with the dial's own pan
                  // for the very gesture it is trying to protect.
                  child: Listener(
                    onPointerDown: (_) => _setWheelHeld(true),
                    onPointerUp: (_) => _setWheelHeld(false),
                    onPointerCancel: (_) => _setWheelHeld(false),
                    child: DurationWheel(
                      key: const ValueKey('durationWheel'),
                      value: _custom,
                      onChanged: _onWheelChanged,
                    ),
                  ),
                ),
                // Only when the duration is a block's length: where it
                // ends, measured from the start named in the heading, and
                // editable in its own right (D61).
                if (widget.startTime != null) ...[
                  const SizedBox(height: 18),
                  Text(
                    l10n.addTileDurationEndsFromStart(
                        formatClockTime(widget.startTime!)),
                    style: textTheme.labelSmall?.copyWith(
                        color: tokens.textSecondary, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 8),
                  AddTileSection(
                    children: [
                      AddTileFieldRow(
                        key: const ValueKey('durationEndRow'),
                        icon: Icons.outlined_flag,
                        label: l10n.addTileFieldEnds,
                        value: _endLabel(l10n),
                        onTap: _pickEnd,
                        semanticLabel: l10n.addTileDurationEndsSemantics(
                            _endLabel(l10n),
                            formatClockTime(widget.startTime!)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Pinned, like the shell's own CTA: Done commits whatever the
          // screen currently holds, so it belongs to the screen rather than
          // to the wheel it used to sit inside.
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: DurationDoneButton(
              key: const ValueKey('durationDone'),
              onTap: () => _commit(_custom),
            ),
          ),
        ],
      ),
    );
  }
}

/// One quick-duration chip. Commits on tap, like every other discrete choice
/// in the redesign.
class DurationPresetChip extends StatelessWidget {
  const DurationPresetChip({
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
          color: selected ? tokens.brandTint : tokens.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? tokens.brand : tokens.cardBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              // Neither `Center` nor `alignment` here: BOTH expand the box to
              // the incoming max, and a Wrap offers its children the whole
              // line — which turned eight chips into eight full-width rows.
              // The box hugs its text, and the 44pt tap height comes from the
              // vertical padding rather than a minHeight the child would then
              // sit off-centre inside.
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                label,
                style: textTheme.titleSmall?.copyWith(
                  color: selected ? tokens.brand : tokens.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The custom duration control: the rotary wheel, themed to the redesign.
///
/// The vendored `DurationPicker` takes its accent from
/// `ColorScheme.secondary` and its ground from `scaffoldBackgroundColor`,
/// which on this screen would have rendered it in colors belonging to neither
/// the picker nor the form. Rather than fork the package, the subtree gets a
/// `Theme` whose those two slots point at the redesign's own tokens.
/// The dial radius as a fraction of its box: the wheel paints exactly the
/// square it is laid out in.
///
/// The package's default is 0.75 — it paints 1.5x its box and never clips.
/// An earlier version of this screen worked around that by handing the
/// picker a box of painted/1.5, which fitted the DRAWING but left the ring
/// untouchable: hit-testing never extends past a widget's bounds, so the
/// outer third of the wheel, where the handle lives, took no gestures at
/// all (D60). With the ratio at 0.5 the box, the paint and the touch area
/// are the same square.
const double _wheelRadiusRatio = 0.5;

/// The largest the wheel is allowed to grow on a wide screen.
const double _maxWheelDiameter = 320;

class DurationWheel extends StatelessWidget {
  const DurationWheel({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Duration value;
  final ValueChanged<Duration> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: l10n.duration,
      value: formatDurationSummary(l10n, value) ?? '',
      child: Theme(
        data: theme.copyWith(
          colorScheme: theme.colorScheme.copyWith(secondary: tokens.brand),
          scaffoldBackgroundColor: tokens.surfaceSubtle,
        ),
        // The wheel is fitted to the card by its PAINTED diameter, and with
        // `_wheelRadiusRatio` at 0.5 that is also its layout box and its
        // touch area. (An earlier attempt used a FittedBox, which measures
        // LAYOUT size and so happily scaled a 300pt box while the painter
        // carried on drawing 450pt over the rest of the screen.)
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double painted = constraints.maxWidth.isFinite
                ? math.min(constraints.maxWidth, _maxWheelDiameter)
                : _maxWheelDiameter;
            return SizedBox(
              width: painted,
              height: painted,
              child: Center(
                child: DurationPicker(
                  duration: value,
                  onChange: onChanged,
                  width: painted,
                  height: painted,
                  dialSize: painted,
                  dialRadiusRatio: _wheelRadiusRatio,
                  // The captions inside the wheel, which the package
                  // otherwise renders in hardcoded English (D30).
                  hourLabel: l10n.addTileDurationHourLabel,
                  minuteLabel: l10n.addTileDurationMinuteLabel,
                  // Theming the ColorScheme only ever reached the arc —
                  // the knob, disc, shadow and markers were hardcoded, so
                  // the wheel kept a dark teal handle on a grey disc no
                  // matter what the app's palette said (D46).
                  // The unfilled ring. Hardcoded white in the package, which
                  // rendered the wheel as a white donut in dark mode (D46).
                  trackColor: tokens.surfaceSubtle,
                  trackEdgeColor: tokens.cardBorder,
                  handleColor: tokens.brand,
                  innerCircleColor: tokens.surface,
                  innerShadowColor: tokens.cardBorder,
                  markerColor: tokens.textSecondary,
                  // The readout is the value the whole screen is about, so
                  // it is sized as a heading rather than left at the
                  // package's body default.
                  fontStyle:
                      Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Confirms the custom value. The presets commit on tap; only the stepped
/// value needs an explicit "I am done adjusting".
class DurationDoneButton extends StatelessWidget {
  const DurationDoneButton({super.key, required this.onTap});

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
              constraints: const BoxConstraints(minHeight: 48),
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
