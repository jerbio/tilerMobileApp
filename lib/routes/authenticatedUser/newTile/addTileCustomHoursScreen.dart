// Step 6.4 — the Custom hours editor (D67–D71).
//
// Seven day rows (switch, start, end, copy/paste) over a `RestrictionHoursDraft`,
// four quick presets that rewrite the rows (D69), platform time pickers
// (D42), an end that must follow its start (D70), and two modes:
//
//   * AD-HOC — Done returns the tile's own hours (D68); every day off is
//     Anytime (a null profile);
//   * PROFILE — Done saves the SHARED Work or Personal profile through the
//     source (D67), sweeping the form while the request is in flight, and
//     returns the server's copy; a failure shows a callout with Retry and
//     keeps the form. Every day off saves the profile DISABLED, keeping its
//     id — what Tile Preferences does for "anytime".
//
// Back (D12) returns nothing at all.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

typedef PickTimeOfDay = Future<TimeOfDay?> Function(
    BuildContext context, TimeOfDay initial);

Future<TimeOfDay?> _platformTimePicker(
        BuildContext context, TimeOfDay initial) =>
    showTimePicker(context: context, initialTime: initial);

/// Sunday-first day names.
String hoursDayName(AppLocalizations l10n, int day) => switch (day) {
      0 => l10n.sunday,
      1 => l10n.monday,
      2 => l10n.tuesday,
      3 => l10n.wednesday,
      4 => l10n.thursday,
      5 => l10n.friday,
      _ => l10n.saturday,
    };

/// The preset chip's first line.
String hoursPresetName(AppLocalizations l10n, RestrictionHoursPreset p) =>
    switch (p) {
      RestrictionHoursPreset.weekdays9to6 ||
      RestrictionHoursPreset.weekdays9to5 =>
        l10n.addTileHoursPresetWeekdays,
      RestrictionHoursPreset.evenings6to10 => l10n.addTileHoursPresetEvenings,
      RestrictionHoursPreset.weekends10to4 => l10n.addTileHoursPresetWeekends,
    };

class AddTileCustomHoursScreen extends StatefulWidget {
  const AddTileCustomHoursScreen({
    super.key,
    required this.request,
    required this.source,
    this.onDone,
    this.pickTime = _platformTimePicker,
    this.persist = true,
  });

  final HoursEditorRequest request;

  /// Profile mode saves through [source] by default (D67). Tile
  /// Preferences passes false: it keeps its own Save, so the editor hands
  /// the edited profile back — id kept, disabled when every day is off —
  /// and the page's bloc persists it.
  final bool persist;

  /// Saves in profile mode (D67). Unused in ad-hoc mode.
  final AddTileRestrictionProfileSource source;

  /// Invoked by Done with the result. Injected by tests; in the app the
  /// screen pops with the value.
  final void Function(HoursEditorResult)? onDone;

  /// The time picker. Platform by default (D42); injected by tests.
  final PickTimeOfDay pickTime;

  @override
  State<AddTileCustomHoursScreen> createState() =>
      AddTileCustomHoursScreenState();
}

class AddTileCustomHoursScreenState extends State<AddTileCustomHoursScreen> {
  late final RestrictionHoursDraft draft;
  bool _saving = false;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    draft = RestrictionHoursDraft.fromProfile(widget.request.seed);
    draft.addListener(_onDraft);
  }

  @override
  void dispose() {
    draft.removeListener(_onDraft);
    draft.dispose();
    super.dispose();
  }

  void _onDraft() => setState(() {});

  NamedRestrictionProfileType? get _profileType => widget.request.profileType;

  String _profileName(AppLocalizations l10n) => switch (_profileType) {
        NamedRestrictionProfileType.work => l10n.addTileRestrictionWork,
        NamedRestrictionProfileType.personal => l10n.addTileRestrictionPersonal,
        null => l10n.addTileCustomHoursTitle,
      };

  bool get _doneEnabled => draft.isValid && !_saving;

  Future<void> _pick(int day, {required bool start}) async {
    final RestrictionHoursDay row = draft.days[day];
    if (!row.enabled || _saving) return;
    final TimeOfDay? picked =
        await widget.pickTime(context, start ? row.start : row.end);
    if (picked == null || !mounted) return;
    if (start) {
      draft.setStart(day, picked);
    } else {
      draft.setEnd(day, picked);
    }
  }

  void _copyOrPaste(int day) {
    final int? copied = draft.copiedDay;
    if (copied == null || copied == day) {
      draft.copyDay(day);
    } else {
      draft.pasteTo(day);
    }
  }

  Future<void> _done() async {
    if (!_doneEnabled) return;
    final NamedRestrictionProfileType? type = _profileType;
    if (type == null) {
      _finish(HoursEditorResult(draft.toProfile()));
      return;
    }
    // Profile mode: every day off is the profile switched OFF, not deleted —
    // the id survives, as Tile Preferences does for "anytime".
    RestrictionProfile? profile = draft.toProfile();
    if (profile == null) {
      profile = RestrictionProfile.noRestriction();
      final RestrictionProfile? seed = widget.request.seed;
      if (seed != null) {
        profile.id = seed.id;
        profile.timeZone = seed.timeZone;
        profile.userId = seed.userId;
      }
    }
    if (!widget.persist) {
      _finish(HoursEditorResult(profile));
      return;
    }
    setState(() {
      _saving = true;
      _saveFailed = false;
    });
    try {
      final RestrictionProfile saved = await widget.source.save(profile, type);
      if (!mounted) return;
      _finish(HoursEditorResult(saved));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveFailed = true;
      });
    }
  }

  void _finish(HoursEditorResult result) {
    if (widget.onDone != null) {
      widget.onDone!(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final MaterialLocalizations material = MaterialLocalizations.of(context);
    final NamedRestrictionProfileType? type = _profileType;
    final String name = _profileName(l10n);

    final Widget list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        Text(name,
            style: textTheme.headlineSmall?.copyWith(
                color: tokens.textPrimary, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
            type == null
                ? l10n.addTileCustomHoursSubtitle
                : l10n.addTileCustomHoursProfileSubtitle(name),
            style: textTheme.bodyMedium?.copyWith(color: tokens.textSecondary)),
        const SizedBox(height: 16),
        _presets(l10n, tokens, textTheme, material),
        const SizedBox(height: 12),
        for (int d = 0; d < 7; d++) ...[
          _dayRow(d, l10n, tokens, textTheme, material),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        AddTileCallout(
          icon: Icons.info_outline,
          text: type == null
              ? l10n.addTileCustomHoursFooter
              : l10n.addTileCustomHoursProfileFooter(name),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.addTileTimeRestrictionTitle),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Read-only while the save is in flight (D50's rule).
                AbsorbPointer(absorbing: _saving, child: list),
                if (_saving)
                  const Positioned.fill(
                    child: AddTilePendingSweep(key: ValueKey('hoursSaving')),
                  ),
              ],
            ),
          ),
          // Pinned, not in the list: the user is at Done when a save fails.
          if (_saveFailed)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: AddTileCallout(
                key: const ValueKey('hoursSaveFailed'),
                icon: Icons.cloud_off_outlined,
                text: l10n.addTileHoursSaveFailed(name),
                action: AddTileCalloutAction(
                  key: const ValueKey('hoursRetry'),
                  label: l10n.addTileRetry,
                  onTap: _done,
                ),
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AddTileDoneButton(
              key: const ValueKey('hoursDone'),
              enabled: _doneEnabled,
              label: _saving ? l10n.addTileHoursSaving : null,
              onTap: _done,
            ),
          ),
        ],
      ),
    );
  }

  Widget _presets(AppLocalizations l10n, TodayStatusTokens tokens,
      TextTheme textTheme, MaterialLocalizations material) {
    final RestrictionHoursPreset? matching = draft.matchingPreset;
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
          Text(l10n.addTileCustomHoursPresets,
              style: textTheme.titleSmall?.copyWith(
                  color: tokens.textPrimary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final RestrictionHoursPreset p
                  in RestrictionHoursPreset.values)
                HoursPresetChip(
                  key: ValueKey('hoursPreset_${p.name}'),
                  title: hoursPresetName(l10n, p),
                  window: l10n.addTileHoursPresetWindow(
                      material.formatTimeOfDay(p.start),
                      material.formatTimeOfDay(p.end)),
                  selected: matching == p,
                  onTap: () => draft.applyPreset(p),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dayRow(int day, AppLocalizations l10n, TodayStatusTokens tokens,
      TextTheme textTheme, MaterialLocalizations material) {
    final RestrictionHoursDay row = draft.days[day];
    final String dayName = hoursDayName(l10n, day);
    final bool invalid = draft.invalidDays.contains(day);
    final int? copied = draft.copiedDay;
    final bool isSource = copied == day;
    final bool canPaste = copied != null && !isSource;
    final String copyTooltip = isSource
        ? l10n.addTileHoursClearCopy
        : canPaste
            ? l10n.addTileHoursPaste(dayName)
            : l10n.addTileHoursCopy(dayName);

    return Container(
      key: ValueKey('hoursDay_$day'),
      padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: invalid ? tokens.danger : tokens.cardBorder,
            width: invalid ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (BuildContext context, BoxConstraints c) {
            final Widget toggle = Semantics(
              // The row's one toggle: named by its day, toggled state
              // from the switch itself.
              label: dayName,
              child: Switch(
                key: ValueKey('hoursSwitch_$day'),
                value: row.enabled,
                onChanged:
                    _saving ? null : (bool v) => draft.setEnabled(day, v),
              ),
            );
            final Widget name = Text(dayName,
                style: textTheme.titleSmall?.copyWith(
                    color:
                        row.enabled ? tokens.textPrimary : tokens.textSecondary,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis);
            // A Wrap, never a Row: under a wide font or a long locale the
            // end pill drops to a second line instead of overflowing.
            final Widget times =
                Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
              _TimeButton(
                key: ValueKey('hoursStart_$day'),
                text: material.formatTimeOfDay(row.start),
                semanticLabel: l10n.addTileHoursStartSemantics(
                    dayName, material.formatTimeOfDay(row.start)),
                enabled: row.enabled && !_saving,
                onTap: () => _pick(day, start: true),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text('–',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: tokens.textSecondary)),
              ),
              _TimeButton(
                key: ValueKey('hoursEnd_$day'),
                text: material.formatTimeOfDay(row.end),
                semanticLabel: l10n.addTileHoursEndSemantics(
                    dayName, material.formatTimeOfDay(row.end)),
                enabled: row.enabled && !_saving,
                onTap: () => _pick(day, start: false),
              ),
            ]);
            final Widget copy = IconButton(
              key: ValueKey('hoursCopy_$day'),
              tooltip: copyTooltip,
              visualDensity: VisualDensity.compact,
              icon: Icon(
                canPaste ? Icons.content_paste_outlined : Icons.copy_outlined,
                size: 18,
                color: isSource || canPaste
                    ? tokens.brand
                    : (row.enabled ? tokens.textSecondary : tokens.border),
              ),
              onPressed: _saving ? null : () => _copyOrPaste(day),
            );
            // One line when it fits (the mockup); otherwise the times drop
            // under the name rather than overflow (320 pt, large text).
            final double scale = MediaQuery.textScalerOf(context).scale(1);
            final bool oneLine = c.maxWidth >= 300 * scale + 60;
            if (oneLine) {
              return Row(children: [
                toggle,
                const SizedBox(width: 4),
                Expanded(child: name),
                times,
                copy,
              ]);
            }
            return Column(children: [
              Row(children: [
                toggle,
                const SizedBox(width: 4),
                Expanded(child: name),
                copy,
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 0, 6),
                child: Align(alignment: Alignment.centerLeft, child: times),
              ),
            ]);
          }),
          // D74: equal start and end is the whole day — say so, since two
          // identical times read as a mistake otherwise.
          if (row.enabled && !invalid && row.isAllDay)
            Padding(
              key: ValueKey('hoursAllDay_$day'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text(l10n.addTileRestrictionAllDay,
                  style: textTheme.bodySmall?.copyWith(
                      color: tokens.brand, fontWeight: FontWeight.w500)),
            ),
          if (invalid)
            Padding(
              key: ValueKey('hoursInvalid_$day'),
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: Text(l10n.addTileHoursEndBeforeStart,
                  style: textTheme.bodySmall?.copyWith(color: tokens.danger)),
            ),
        ],
      ),
    );
  }
}

/// A quick-preset chip: name over its window. [selected] is public for
/// tests; it is derived from the rows, never stored (D69).
class HoursPresetChip extends StatelessWidget {
  const HoursPresetChip({
    super.key,
    required this.title,
    required this.window,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String window;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $window',
      onTap: onTap,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brandTint : tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: selected ? tokens.brand : Colors.transparent,
                    width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      style: textTheme.labelLarge?.copyWith(
                          color: selected ? tokens.brand : tokens.textPrimary,
                          fontWeight: FontWeight.w600)),
                  Text(window,
                      style: textTheme.bodySmall?.copyWith(
                          color:
                              selected ? tokens.brand : tokens.textSecondary)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A start or end time as a small pill button; muted and inert on a
/// disabled day.
class _TimeButton extends StatelessWidget {
  const _TimeButton({
    super.key,
    required this.text,
    required this.semanticLabel,
    required this.enabled,
    required this.onTap,
  });

  final String text;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? onTap : null,
      child: ExcludeSemantics(
        child: Material(
          color: tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Text(text,
                  style: textTheme.bodyMedium?.copyWith(
                      color:
                          enabled ? tokens.textPrimary : tokens.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ),
    );
  }
}
