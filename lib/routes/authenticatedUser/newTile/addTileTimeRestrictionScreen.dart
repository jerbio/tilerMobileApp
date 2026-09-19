// Step 6.3 — the Time restrictions screen (D67–D73).
//
// Anytime / Work hours / Personal hours / Custom hours, to the mockup:
//   * the row SELECTS (radio); the trailing arrow EDITS — the shared Work or
//     Personal profile (D67), or the tile's own Custom hours (D68);
//   * Work and Personal come from the user's named profiles through
//     `AddTileRestrictionProfileSource`; while they load, two skeleton rows
//     stand in; if they fail, a callout with Retry — Anytime and Custom never
//     wait on the network (D73);
//   * a profile that is missing, disabled or empty reads "Not set up" and
//     cannot be selected, because the mapper would send nothing for it and
//     the tile would silently be Anytime (D73);
//   * Done confirms with a typed `TimeRestrictionResult`; Back (D12) returns
//     nothing and leaves the draft alone.
//
// The hours editor itself is Step 6.4; this screen reaches it through the
// `openHoursEditor` seam so the two can be tested apart.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileCustomHoursScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRestrictionProfileSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

export 'package:tiler_app/routes/authenticatedUser/newTile/restrictionHoursDraft.dart'
    show HoursEditorRequest, HoursEditorResult, OpenHoursEditor;

/// What Done hands back. [profile] is null for Anytime, the loaded (or just
/// saved) named profile for Work/Personal — the object with the server id,
/// so the mapper sends `RestrictionProfileId` — and the ad-hoc profile for
/// Custom.
class TimeRestrictionResult {
  const TimeRestrictionResult(this.choice, this.profile);

  final TimeRestrictionChoice choice;
  final RestrictionProfile? profile;
}

/// "Mon – Fri · 9:00 AM – 6:00 PM", one part per group of consecutive days
/// sharing a window. Empty for a profile the mapper would not send.
String restrictionProfileSummary(
    BuildContext context, RestrictionProfile? profile) {
  final List<RestrictionHoursGroup> groups =
      describeRestrictionProfile(profile);
  if (groups.isEmpty) return '';
  final AppLocalizations l10n = AppLocalizations.of(context)!;
  final MaterialLocalizations material = MaterialLocalizations.of(context);
  // The same idiom the Repeat summary uses: intl's abbreviated weekday for
  // the app's locale, anchored on a known Sunday.
  final DateFormat day = DateFormat.E(l10n.localeName);
  final DateTime sunday = DateTime(2023, 1, 1);
  String name(int i) => day.format(sunday.add(Duration(days: i)));
  return groups.map((RestrictionHoursGroup g) {
    final String days = g.days.length == 1
        ? name(g.days.single)
        : l10n.addTileRestrictionDayRange(
            name(g.days.first), name(g.days.last));
    if (g.isAllDay) {
      return l10n.addTileRestrictionAllDayWindow(
          days, l10n.addTileRestrictionAllDay);
    }
    // D75: an overnight window says so, or "Sun – Mon · 9 PM – 2 AM" reads
    // as one stretch from Sunday evening to Monday morning.
    if (g.wrapsToNextDay) {
      return l10n.addTileRestrictionWindowNextDay(days,
          material.formatTimeOfDay(g.start), material.formatTimeOfDay(g.end));
    }
    return l10n.addTileRestrictionWindow(days,
        material.formatTimeOfDay(g.start), material.formatTimeOfDay(g.end));
  }).join(', ');
}

/// User-facing name of a row.
String timeRestrictionChoiceName(
        AppLocalizations l10n, TimeRestrictionChoice c) =>
    switch (c) {
      TimeRestrictionChoice.anytime => l10n.anytime,
      TimeRestrictionChoice.work => l10n.addTileRestrictionWork,
      TimeRestrictionChoice.personal => l10n.addTileRestrictionPersonal,
      TimeRestrictionChoice.custom => l10n.addTileRestrictionCustom,
    };

class AddTileTimeRestrictionScreen extends StatefulWidget {
  const AddTileTimeRestrictionScreen({
    super.key,
    required this.initial,
    required this.source,
    this.onDone,
    this.openHoursEditor,
  });

  /// The tile's current profile (null = Anytime).
  final RestrictionProfile? initial;
  final AddTileRestrictionProfileSource source;

  /// Invoked by Done. Injected by tests; in the app the screen pops with the
  /// result.
  final void Function(TimeRestrictionResult)? onDone;

  /// Opens the Custom hours editor (Step 6.4). Injected by tests; by
  /// default the screen pushes [AddTileCustomHoursScreen] over its own
  /// source.
  final OpenHoursEditor? openHoursEditor;

  @override
  State<AddTileTimeRestrictionScreen> createState() =>
      _AddTileTimeRestrictionScreenState();
}

enum _LoadState { loading, loaded, failed }

class _AddTileTimeRestrictionScreenState
    extends State<AddTileTimeRestrictionScreen> {
  _LoadState _load = _LoadState.loading;
  NamedRestrictionProfiles _named = const NamedRestrictionProfiles();
  late TimeRestrictionChoice _choice;

  /// The tile's own hours (D68); seeds the editor when Custom is re-entered.
  RestrictionProfile? _custom;

  @override
  void initState() {
    super.initState();
    // Before the named profiles arrive, a profile can only be Custom.
    _choice = isUsableRestrictionProfile(widget.initial)
        ? TimeRestrictionChoice.custom
        : TimeRestrictionChoice.anytime;
    _custom = _choice == TimeRestrictionChoice.custom ? widget.initial : null;
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _load = _LoadState.loading);
    try {
      final NamedRestrictionProfiles named = await widget.source.load();
      if (!mounted) return;
      setState(() {
        _named = named;
        _load = _LoadState.loaded;
        // Now the initial profile can be recognised as Work or Personal.
        final TimeRestrictionChoice resolved = TimeRestrictionChoice.of(
            widget.initial,
            work: named.work,
            personal: named.personal);
        if (_choice == TimeRestrictionChoice.custom &&
            resolved != TimeRestrictionChoice.custom) {
          _choice = resolved;
          _custom = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _load = _LoadState.failed);
    }
  }

  RestrictionProfile? _profileFor(TimeRestrictionChoice c) => switch (c) {
        TimeRestrictionChoice.anytime => null,
        TimeRestrictionChoice.work => _named.work,
        TimeRestrictionChoice.personal => _named.personal,
        TimeRestrictionChoice.custom => _custom,
      };

  void _select(TimeRestrictionChoice c) {
    if (c != TimeRestrictionChoice.anytime &&
        !isUsableRestrictionProfile(_profileFor(c))) {
      return; // D73: nothing to select.
    }
    setState(() => _choice = c);
  }

  /// D68: the current custom hours, else the Weekdays 9–6 preset.
  RestrictionProfile _customSeed() {
    final RestrictionProfile? have = _custom;
    if (have != null) return have;
    return (RestrictionHoursDraft.fromProfile(null)
          ..applyPreset(RestrictionHoursPreset.weekdays9to6))
        .toProfile()!;
  }

  /// The production editor: a pushed route that pops with its result.
  Future<HoursEditorResult?> _pushEditor(
          BuildContext context, HoursEditorRequest request) =>
      Navigator.of(context).push<HoursEditorResult>(MaterialPageRoute(
          builder: (_) => AddTileCustomHoursScreen(
              request: request, source: widget.source)));

  OpenHoursEditor get _open => widget.openHoursEditor ?? _pushEditor;

  Future<void> _editCustom() async {
    final HoursEditorResult? answer =
        await _open(context, HoursEditorRequest(seed: _customSeed()));
    if (answer == null || !mounted) return;
    setState(() {
      _custom = answer.profile;
      // No days is Anytime.
      _choice = answer.profile == null
          ? TimeRestrictionChoice.anytime
          : TimeRestrictionChoice.custom;
    });
  }

  Future<void> _editNamed(NamedRestrictionProfileType type) async {
    final HoursEditorResult? answer = await _open(
        context, HoursEditorRequest(seed: _named[type], profileType: type));
    if (answer == null || !mounted) return;
    // The editor saved through the source (D67); this is the server's copy.
    setState(() {
      _named = _named.withProfile(type, answer.profile);
      final TimeRestrictionChoice row = switch (type) {
        NamedRestrictionProfileType.work => TimeRestrictionChoice.work,
        NamedRestrictionProfileType.personal => TimeRestrictionChoice.personal,
      };
      if (isUsableRestrictionProfile(answer.profile)) {
        _choice = row;
      } else if (_choice == row) {
        _choice = TimeRestrictionChoice.anytime;
      }
    });
  }

  void _done() {
    final TimeRestrictionResult result =
        TimeRestrictionResult(_choice, _profileFor(_choice));
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

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.addTileTimeRestrictionTitle),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              children: [
                Text(l10n.addTileTimeRestrictionHeading,
                    style: textTheme.headlineSmall?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(l10n.addTileTimeRestrictionSubtitle,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: tokens.textSecondary)),
                const SizedBox(height: 16),
                TimeRestrictionChoiceRow(
                  key: const ValueKey('restrictionChoice_anytime'),
                  icon: Icons.schedule_outlined,
                  title: l10n.anytime,
                  helper: l10n.addTileRestrictionAnytimeHelper,
                  selected: _choice == TimeRestrictionChoice.anytime,
                  onTap: () => _select(TimeRestrictionChoice.anytime),
                ),
                const SizedBox(height: 12),
                ..._namedRows(l10n, tokens),
                const SizedBox(height: 12),
                TimeRestrictionChoiceRow(
                  key: const ValueKey('restrictionChoice_custom'),
                  icon: Icons.tune,
                  title: l10n.addTileRestrictionCustom,
                  helper: l10n.addTileRestrictionCustomHelper,
                  summary: restrictionProfileSummary(context, _custom),
                  selected: _choice == TimeRestrictionChoice.custom,
                  // Tapping the row of hours that do not exist yet can only
                  // mean "go set them".
                  onTap: _editCustom,
                  editKey: const ValueKey('restrictionEdit_custom'),
                  onEdit: _editCustom,
                ),
                const SizedBox(height: 20),
                AddTileCallout(
                  icon: Icons.lightbulb_outline,
                  text: l10n.addTileRestrictionTip,
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: AddTileDoneButton(
              key: const ValueKey('restrictionDone'),
              onTap: _done,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _namedRows(AppLocalizations l10n, TodayStatusTokens tokens) {
    switch (_load) {
      case _LoadState.loading:
        return <Widget>[
          const _SkeletonRow(key: ValueKey('restrictionProfilesLoading')),
          const SizedBox(height: 12),
          const _SkeletonRow(),
        ];
      case _LoadState.failed:
        return <Widget>[
          AddTileCallout(
            key: const ValueKey('restrictionLoadFailed'),
            icon: Icons.cloud_off_outlined,
            text: l10n.addTileRestrictionLoadFailed,
            action: AddTileCalloutAction(
              key: const ValueKey('restrictionRetry'),
              label: l10n.addTileRetry,
              onTap: _fetch,
            ),
          ),
        ];
      case _LoadState.loaded:
        return <Widget>[
          _namedRow(l10n, NamedRestrictionProfileType.work,
              TimeRestrictionChoice.work, Icons.work_outline),
          const SizedBox(height: 12),
          _namedRow(l10n, NamedRestrictionProfileType.personal,
              TimeRestrictionChoice.personal, Icons.home_outlined),
        ];
    }
  }

  Widget _namedRow(AppLocalizations l10n, NamedRestrictionProfileType type,
      TimeRestrictionChoice choice, IconData icon) {
    final RestrictionProfile? profile = _named[type];
    final bool usable = isUsableRestrictionProfile(profile);
    final String title = timeRestrictionChoiceName(l10n, choice);
    return TimeRestrictionChoiceRow(
      key: ValueKey('restrictionChoice_${choice.name}'),
      icon: icon,
      title: title,
      helper: type == NamedRestrictionProfileType.work
          ? l10n.addTileRestrictionWorkHelper
          : l10n.addTileRestrictionPersonalHelper,
      summary: usable
          ? restrictionProfileSummary(context, profile)
          : l10n.addTileRestrictionNotSetUp,
      selected: _choice == choice,
      selectable: usable,
      onTap: () => _select(choice),
      editKey: ValueKey('restrictionEdit_${type.name}'),
      onEdit: () => _editNamed(type),
    );
  }
}

/// One choice row: radio, icon chip, title, helper, optional hours summary,
/// and an optional trailing arrow that is its OWN semantics node (K1) so
/// "select" and "edit" are two controls to assistive tech as they are to
/// the eye. [selected] and [selectable] are public for tests.
class TimeRestrictionChoiceRow extends StatelessWidget {
  const TimeRestrictionChoiceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.helper,
    required this.selected,
    required this.onTap,
    this.summary = '',
    this.selectable = true,
    this.editKey,
    this.onEdit,
  });

  final IconData icon;
  final String title;
  final String helper;
  final String summary;
  final bool selected;

  /// False for a profile that is not set up (D73): the row still reads and
  /// its arrow still edits, but the radio is disabled.
  final bool selectable;
  final VoidCallback onTap;
  final Key? editKey;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final Color titleColor =
        selectable ? tokens.textPrimary : tokens.textSecondary;

    final VoidCallback? edit = onEdit;
    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      child: Row(
        children: [
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: selected
                ? tokens.brand
                : (selectable ? tokens.textSecondary : tokens.border),
          ),
          const SizedBox(width: 12),
          AddTileIconChip(icon: icon, muted: !selected),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: textTheme.titleMedium?.copyWith(
                        color: titleColor,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500)),
                Text(helper,
                    style: textTheme.bodySmall
                        ?.copyWith(color: tokens.textSecondary)),
                if (summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(summary,
                      style: textTheme.bodySmall?.copyWith(
                          color: selectable
                              ? tokens.textPrimary
                              : tokens.textSecondary,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    // The tappable body. Excluded from semantics: the row's own node above
    // carries the label and the tap (D62).
    final Widget body = ExcludeSemantics(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: content,
          ),
        ),
      ),
    );

    // The row's node is the ROOT, so the keyed widget owns it; the arrow is
    // an explicit child node beside it (K1) — "select" and "edit" are two
    // controls to assistive tech as they are to the eye.
    return Semantics(
      container: true,
      explicitChildNodes: edit != null,
      button: true,
      selected: selected,
      enabled: selectable,
      label: summary.isEmpty ? '$title, $helper' : '$title, $helper, $summary',
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? tokens.brandTint : tokens.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? tokens.brand : tokens.cardBorder,
              width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: edit == null
            ? body
            : Row(children: [
                Expanded(child: body),
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: IconButton(
                    key: editKey,
                    tooltip: l10n.addTileRestrictionEdit(title),
                    icon:
                        Icon(Icons.chevron_right, color: tokens.textSecondary),
                    onPressed: edit,
                  ),
                ),
              ]),
      ),
    );
  }
}

/// A shimmering stand-in for a named row while the profiles load. The card
/// itself shimmers, not the page behind it.
class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: AddTilePendingSweep(baseColor: tokens.surface),
    );
  }
}
