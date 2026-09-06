// Feature-flagged Add Tile redesign shell.
//
// Implements the shared frame:
//   Close            Add Tile / Add Block
//   [ Flexible Tile | Fixed Block ]      (one non-swipeable segmented control)
//   Mode explanation
//   Scrollable mode-specific form
//   Persistent primary CTA
//
// The shell owns the CHROME: the type selector (before any fields), dynamic
// title/explanation/CTA, an independently scrolling form area, a persistent
// keyboard/safe-area-safe CTA, and a single root Close. The CTA submits through
// the NewTileRequestMapper.
//
// The Flexible field set (Steps 2.1-2.3) is complete: FlexibleTileForm renders
// the primary decisions plus Preferred time, Location, and Repeat, and
// AddTileMoreOptions adds the advanced disclosure for both types. The FIXED
// field set (date / start / duration / calculated read-only end) lands in
// Phase 3; until then a minimal name/duration area keeps CTA gating and
// rigid-payload submission testable.
//
// The legacy AddTile carousel/toggle flow remains the default (flag off) until
// rollout. Every user-facing string in the redesign comes from
// app_en.arb/app_es.arb through AppLocalizations; label helpers take the
// AppLocalizations instance as a parameter rather than reading a BuildContext,
// so they stay pure, unit-testable, and reusable outside this flow (D29).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileAnalytics.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileColorScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePlaceEditor.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePredictionSource.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTilePriorityScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileMoreOptions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileRepeatScreen.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/fixedBlockForm.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/tileRouteAdapters.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Local, dependency-free feature flag (no remote-config coupling) so the new
/// shell can be validated in isolation. Remote/rollout gating arrives later.
class AddTileFeatureFlags {
  AddTileFeatureFlags._();

  static bool _addTileRedesignEnabled = false;

  /// `true` renders [AddTileRedesignScreen]; `false` renders the legacy flow.
  static bool get addTileRedesignEnabled => _addTileRedesignEnabled;
  static set addTileRedesignEnabled(bool value) =>
      _addTileRedesignEnabled = value;

  /// Analytics `flow_version` values.
  static const String redesignFlowVersion = addTileRedesignFlowVersion;
  static const String legacyFlowVersion = addTileLegacyFlowVersion;
}

/// Non-swipeable segmented type selector. One control for the
/// Flexible Tile / Fixed Block decision — the legacy carousel + toggle
/// duplication is removed. Selected state is exposed to assistive tech.
///
/// Drawn as ONE track holding two segments (D37), matching the header
/// mockup. An earlier revision was two separate rounded buttons with a gap,
/// which read as two independent toggles rather than as a single either/or
/// choice — the gap said "these are unrelated" about the one decision on the
/// screen that is strictly exclusive.
class AddTileTypeSelector extends StatelessWidget {
  const AddTileTypeSelector({
    super.key,
    required this.type,
    required this.onSelected,
  });

  final AddTileType type;
  final ValueChanged<AddTileType> onSelected;

  /// Decorative mode icons. Each segment states its mode in words, so the
  /// icon reinforces rather than carries (§11).
  static IconData iconFor(AddTileType type) => type == AddTileType.fixed
      ? Icons.calendar_today_outlined
      : Icons.auto_awesome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: l10n.addTileTypeSelectorLabel,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: tokens.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: AddTileTypeSegment(
                label: l10n.addTileTypeFlexible,
                icon: iconFor(AddTileType.flexible),
                selected: type == AddTileType.flexible,
                onTap: () => onSelected(AddTileType.flexible),
                selectedBackground: tokens.brandTint,
                selectedForeground: tokens.brand,
                textTheme: textTheme,
              ),
            ),
            Expanded(
              child: AddTileTypeSegment(
                label: l10n.addTileTypeFixed,
                icon: iconFor(AddTileType.fixed),
                selected: type == AddTileType.fixed,
                onTap: () => onSelected(AddTileType.fixed),
                selectedBackground: tokens.brandTint,
                selectedForeground: tokens.brand,
                textTheme: textTheme,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One segment of the type selector. [label] and [selected] are public so
/// widget tests can assert the assistive-tech-facing selected state through
/// the widget itself (the local SDK checkout does not expose SemanticsNode
/// flag getters); the `Semantics` node below mirrors these values to the
/// platform.
class AddTileTypeSegment extends StatelessWidget {
  const AddTileTypeSegment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.textTheme,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBackground;
  final Color selectedForeground;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final Color foreground = selected ? selectedForeground : tokens.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 18, color: foreground),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleSmall?.copyWith(
                            color: foreground,
                            fontWeight:
                                selected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
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

/// The mode explanation beneath the type selector: a leading mode icon and a
/// sentence with one phrase set in a heavier weight.
///
/// The sentence is ONE localized string carrying an `{emphasis}` placeholder,
/// not three concatenated fragments, so a translator controls word order and
/// may put the emphasised phrase anywhere in it — including first or last,
/// which several languages need.
///
/// The split is made on a SENTINEL rather than on the emphasis text, so an
/// emphasis phrase that also appears elsewhere in the sentence cannot be
/// bolded twice. If a translation drops the placeholder the sentinel never
/// appears, and the whole sentence renders unemphasised rather than throwing.
class AddTileModeExplanation extends StatelessWidget {
  const AddTileModeExplanation({
    super.key,
    required this.icon,
    required this.template,
    required this.emphasis,
  });

  final IconData icon;

  /// Produces the sentence with its argument substituted for `{emphasis}`.
  final String Function(String) template;

  /// The phrase to set in a heavier weight.
  final String emphasis;

  static const String _sentinel = '\u0000';

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final TextStyle base = (textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: tokens.textSecondary);

    final List<String> parts = template(_sentinel).split(_sentinel);
    final Widget sentence = parts.length == 2
        ? Text.rich(
            TextSpan(
              style: base,
              children: <InlineSpan>[
                TextSpan(text: parts.first),
                TextSpan(
                  text: emphasis,
                  style: base.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(text: parts.last),
              ],
            ),
            textAlign: TextAlign.center,
          )
        : Text(template(emphasis), style: base, textAlign: TextAlign.center);

    return Semantics(
      // The emphasis is visual only; assistive tech gets the plain sentence.
      label: template(emphasis),
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon, size: 16, color: tokens.brand),
            ),
            const SizedBox(width: 8),
            Flexible(child: sentence),
          ],
        ),
      ),
    );
  }
}

/// Persistent primary CTA. Solid brand color with a text
/// label (not an icon-only checkmark), loading + disabled states, and a guard
/// against duplicate submissions. Keyboard/safe-area insets are applied by the
/// shell wrapper so the button stays reachable above the keyboard.
class AddTileBottomAction extends StatelessWidget {
  const AddTileBottomAction({
    required this.type,
    required this.enabled,
    required this.submitting,
    required this.onTap,
    super.key,
  });

  final AddTileType type;
  final bool enabled;
  final bool submitting;
  final VoidCallback onTap;

  String _label(AppLocalizations l10n) => type == AddTileType.fixed
      ? l10n.addTileScreenTitleFixed
      : l10n.addTileFindTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool canSubmit = enabled && !submitting;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Semantics(
        button: true,
        // Raw draft validity (not `canSubmit`): the button stays tappable so
        // an invalid attempt surfaces the first invalid field's inline error
        // ("why creation is unavailable", not an inaccessible tooltip).
        // Double-fire while pending is guarded in the submit handler.
        enabled: enabled,
        label: submitting ? l10n.addTileSubmitting : _label(l10n),
        container: true,
        child: Material(
          color: canSubmit || submitting
              ? scheme.primary
              : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            // Always tappable: an invalid tap focuses the first invalid field
            // and announces its error; a pending tap is a guarded no-op.
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Center(
                child: submitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.onPrimary,
                        ),
                      )
                    : Text(
                        _label(l10n),
                        style: textTheme.titleMedium?.copyWith(
                          color:
                              canSubmit ? scheme.onPrimary : scheme.onSurface,
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

/// Redesigned Add Tile shell. Feature-flagged. Owns an
/// [AddTileDraft] and submits through [NewTileRequestMapper].
/// [draft], when supplied, is owned by the caller (used by tests);
/// otherwise the shell builds and owns one from [preTile].
class AddTileRedesignScreen extends StatefulWidget {
  const AddTileRedesignScreen({
    super.key,
    this.preTile,
    this.draft,
    this.onSubmitted,
    this.now,
    this.analytics,
    this.locationSource,
    this.predictionSource,
  });

  final PreTile? preTile;
  final AddTileDraft? draft;

  /// Submission seam: injected (stubbed in tests); wired to the
  /// existing orchestration when the redesign replaces the legacy flow.
  final Future<void> Function(NewTile)? onSubmitted;
  final DateTime? now;

  /// Funnel analytics for this Add flow. Supplied by tests with a recording
  /// sink; otherwise the shell builds one that emits through the app's
  /// existing signal service.
  final AddTileAnalytics? analytics;

  /// Data source for the redesigned Location picker. Null in bare widget
  /// tests, where tapping Location is a no-op rather than a crash.
  final AddTileLocationSource? locationSource;

  /// Name-driven prediction (legacy parity — see addTilePredictionSource.dart).
  /// Null disables prediction entirely, which is what most widget tests want.
  final AddTilePredictionSource? predictionSource;

  @override
  State<AddTileRedesignScreen> createState() => _AddTileRedesignScreenState();
}

class _AddTileRedesignScreenState extends State<AddTileRedesignScreen> {
  late final AddTileDraft _draft;
  late final bool _ownsDraft;
  bool _submitting = false;
  late final TextEditingController _nameController;
  late final AddTileAnalytics _analytics;
  final _nameFocus = FocusNode();

  /// Set when a submit attempt (CTA or keyboard) finds an invalid draft; the
  /// first invalid field's inline error is shown until addressed.
  bool _showValidationErrors = false;

  @override
  void initState() {
    super.initState();
    if (widget.draft != null) {
      _draft = widget.draft!;
      _ownsDraft = false;
    } else {
      _draft = AddTileDraft.flexible(
        now: widget.now ?? DateTime.now(),
        preTile: widget.preTile,
      );
      _ownsDraft = true;
    }
    _nameController = TextEditingController(text: _draft.name);
    _draft.addListener(_onDraftChanged);
    _analytics = widget.analytics ?? AddTileAnalytics();
    _analytics.opened(_draft.type, hasPrefill: draftHasPrefill(_draft));
  }

  void _onDraftChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    // Cancelled before the draft goes, so a debounce that fires during
    // teardown cannot reach a disposed draft.
    _predictionDebounce?.cancel();
    _draft.removeListener(_onDraftChanged);
    _nameController.dispose();
    _nameFocus.dispose();
    if (_ownsDraft) _draft.dispose();
    super.dispose();
  }

  void _onTypeSelected(AddTileType next) {
    if (next == _draft.type) return;
    final AddTileType from = _draft.type;
    // Read dirtiness BEFORE the switch: switchTo* can fill the Fixed default
    // duration, which would otherwise read as a user edit.
    final bool fieldsEdited = _draft.isDirty;
    if (next == AddTileType.fixed) {
      _draft.switchToFixed();
    } else {
      _draft.switchToFlexible();
    }
    _analytics.typeChanged(from: from, to: next, fieldsEdited: fieldsEdited);
  }

  void _onNameChanged(String value) {
    _draft.name = value;
    if (_showValidationErrors && value.trim().isNotEmpty) {
      setState(() => _showValidationErrors = false);
    }
    _schedulePrediction(value);
  }

  // ------------------------------------------------------------------
  // Name-driven prediction (legacy parity)
  // ------------------------------------------------------------------

  Timer? _predictionDebounce;
  bool _predicting = false;

  /// Guards against a slow prediction landing after a newer one — the same
  /// generation counter the Location picker uses, for the same reason: these
  /// responses have no request id, so ordering cannot be recovered from them.
  int _predictionGeneration = 0;

  /// Debounces, then asks. Mirrors legacy's cancel-and-reschedule: each
  /// keystroke replaces the pending request rather than queueing another.
  void _schedulePrediction(String name) {
    _predictionDebounce?.cancel();
    if (widget.predictionSource == null) return;
    if (!shouldRequestPrediction(name)) return;

    // Nothing to fill means nothing to ask. Legacy skipped only when duration
    // AND location were both manual, while still writing the restriction
    // profile it fetched — so it could overwrite a field it had not checked.
    // The condition here is the honest one: ask only while some field can
    // still accept an answer (D38).
    if (!_canAcceptAnyPrediction()) return;

    _predictionDebounce = Timer(predictionDebounce, () => _runPrediction(name));
  }

  bool _canAcceptAnyPrediction() =>
      _draft.canAcceptSuggestion(AddTileSuggestedField.duration) ||
      _draft.canAcceptSuggestion(AddTileSuggestedField.location) ||
      _draft.canAcceptSuggestion(AddTileSuggestedField.restrictionProfile);

  Future<void> _runPrediction(String name) async {
    final AddTilePredictionSource? source = widget.predictionSource;
    if (source == null) return;
    final int generation = ++_predictionGeneration;
    if (mounted) setState(() => _predicting = true);

    AddTilePrediction prediction = AddTilePrediction.empty;
    try {
      prediction = await source.predict(name);
    } catch (_) {
      // A prediction is a convenience layered on a form the user can always
      // fill in themselves, so a failure must be INVISIBLE — not a snackbar
      // on a screen where nothing they did has gone wrong.
      //
      // Caught here as well as inside ApiAddTilePredictionSource: the source
      // is an injectable seam, and a screen must not depend on every
      // implementation of it being well-behaved. Without this the busy
      // affordance below would also never clear.
      //
      // The exception is deliberately not logged — the request carries the
      // tile name the user typed, and its message can echo that back.
    }

    if (!mounted || generation != _predictionGeneration) return;
    setState(() => _predicting = false);

    // Each field is applied through the draft, which refuses any the user has
    // since edited — so a prediction in flight while the user picks a
    // duration cannot undo that pick.
    if (prediction.duration != null) {
      _draft.applySuggestedDuration(prediction.duration!);
    }
    if (prediction.location != null) {
      _draft.applySuggestedLocation(prediction.location!);
    }
    if (prediction.restrictionProfile != null) {
      _draft.applySuggestedRestrictionProfile(prediction.restrictionProfile);
    }
  }

  /// Opens the existing duration dial (legacy `/DurationDial` route with a
  /// by-reference argument map) so the returned semantics are unchanged. A
  /// cancelled picker leaves the draft untouched.
  Future<void> _openDurationPicker() async {
    final Map<String, dynamic> params = {'duration': _draft.duration};
    try {
      await Navigator.of(context).pushNamed('/DurationDial', arguments: params);
    } catch (_) {
      return; // route not registered (test harness) — no crash, no change.
    }
    final Duration? result = params['duration'] as Duration?;
    if (result != null && result != _draft.duration) {
      _draft.setUserDuration(result);
    }
  }

  /// Opens the platform date picker with the legacy +/-180-day window. Wire
  /// semantics are preserved: the deadline is the end (23:59) of the chosen
  /// day; cancelling leaves Complete by untouched (it may remain Anytime).
  Future<void> _openDeadlinePicker() async {
    final DateTime base = _draft.endTime ??
        DateTime(
          _draft.startTime.year,
          _draft.startTime.month,
          _draft.startTime.day,
          23,
          59,
        );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: base.subtract(const Duration(days: 180)),
      lastDate: base.add(const Duration(days: 180)),
    );
    if (picked == null || !mounted) return;
    _draft.endTime = DateTime(picked.year, picked.month, picked.day, 23, 59);
  }

  /// Applies a simple day-part choice. [applyPreferredTimeSelection] keeps an
  /// advanced/custom profile intact, so this can never silently discard one.
  void _onPreferredTimeSelected(PreferredTimeOfDay part) {
    final RestrictionProfile? next =
        applyPreferredTimeSelection(_draft.restrictionProfile, part);
    if (identical(next, _draft.restrictionProfile)) return;
    _draft.setRestrictionProfile(next);
  }

  /// Opens the legacy `/LocationRoute` through its typed adapter. A cancelled
  /// route returns `null` and the draft is left untouched (not dirtied).
  /// Opens the redesigned Location picker (Phase 4.1). A cancelled Back
  /// returns `null` and the draft is left untouched.
  ///
  /// [locationSource] is injected by tests; the app supplies the real API +
  /// geolocator source. The legacy `/LocationRoute` remains the destination
  /// for the "Add custom location" path inside the new screen and for the five
  /// non-redesign callers, until Phase 5.3 cleanup.
  Future<void> _openLocationPicker() async {
    final AddTileLocationSource? source = widget.locationSource;
    if (source == null) return; // no source wired (test harness) — no-op.
    final Location? picked = await Navigator.of(context).push<Location>(
      MaterialPageRoute<Location>(
        builder: (_) => AddTileLocationScreen(
          source: source,
          initialLocation: _draft.location,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    _draft.setLocation(picked);
  }

  /// Opens the legacy `/RepetitionRoute` through its typed adapter, which
  /// preserves the legacy apply/clear/unchanged result semantics.
  /// Opens the redesigned Repeat picker (Step 4.2).
  ///
  /// Replaces the legacy `/RepetitionRoute` for this flow. The result is
  /// wrapped so a confirmed "Does not repeat" (a null repetition) stays
  /// distinguishable from backing out, which must leave the draft alone.
  Future<void> _openRepeatPicker() async {
    final RepeatPickerResult? result =
        await Navigator.of(context).push<RepeatPickerResult>(
      MaterialPageRoute<RepeatPickerResult>(
        builder: (_) => AddTileRepeatScreen(
          now: widget.now ?? DateTime.now(),
          initialRepetition: _draft.repetitionData,
        ),
      ),
    );
    if (result == null || !mounted) return;
    _draft.setRepetitionData(result.repetition);
  }

  /// Fixed Block date. Only the CALENDAR DAY changes — the existing
  /// wall-clock start time is carried onto the new day, so picking a date
  /// never silently moves the block's time.
  Future<void> _openDatePicker() async {
    final DateTime start = _draft.startTime;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: start.subtract(const Duration(days: 180)),
      lastDate: start.add(const Duration(days: 180)),
    );
    if (picked == null || !mounted) return;
    _draft.setUserStartTime(
      DateTime(picked.year, picked.month, picked.day, start.hour, start.minute),
    );
  }

  /// Fixed Block start time. Only the wall-clock TIME changes; the calendar
  /// day is preserved. The end row re-derives itself from the draft.
  Future<void> _openStartTimePicker() async {
    final DateTime start = _draft.startTime;
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: start.hour, minute: start.minute),
    );
    if (picked == null || !mounted) return;
    _draft.setUserStartTime(
      DateTime(start.year, start.month, start.day, picked.hour, picked.minute),
    );
  }

  /// Names the chosen location.
  ///
  /// Naming lives HERE rather than in the picker: tapping a place there
  /// commits immediately, which keeps the common case one tap. Naming is the
  /// minority case, so it is an affordance on the chosen value instead of a
  /// step every selection pays for.
  Future<void> _nameLocation() async {
    final Location? current = _draft.location;
    final AddTileLocationSource? source = widget.locationSource;
    if (current == null || source == null) return;
    final Location? edited = await Navigator.of(context).push<Location>(
      MaterialPageRoute<Location>(
        builder: (_) => AddTilePlaceEditorScreen(
          source: source,
          initialName: (current.description ?? '').trim(),
          initialAddress: (current.address ?? '').trim(),
          original: current,
        ),
      ),
    );
    if (edited == null || !mounted) return;
    _draft.setLocation(edited);
  }

  /// Opens the Priority picker (Step 4.3a). Selection returns immediately —
  /// a three-way choice has nothing to confirm — and backing out leaves the
  /// draft's priority as it was.
  Future<void> _openPriorityPicker() async {
    final TilePriority? picked = await Navigator.of(context).push<TilePriority>(
      MaterialPageRoute<TilePriority>(
        builder: (_) => AddTilePriorityScreen(initial: _draft.priority),
      ),
    );
    if (picked == null || !mounted) return;
    _draft.setPriority(picked);
  }

  /// Opens the redesigned Color picker (Step 4.3b), replacing the legacy
  /// `/PickColor` route for this flow.
  ///
  /// A confirmed `null` is meaningful here — it means Automatic — so the
  /// result carries `made` rather than relying on nullability, and backing
  /// out leaves the draft's color untouched. The legacy `openColorRoute`
  /// adapter could not express "the user chose Automatic" at all, and now has
  /// no caller — the legacy Add Tile flow pushes `/PickColor` directly. It is
  /// left in `tileRouteAdapters.dart` with the other now-unreferenced route
  /// helpers, to be removed together at Phase 5.3.
  Future<void> _openColorPicker() async {
    final ColorChoice? choice = await Navigator.of(context).push<ColorChoice>(
      MaterialPageRoute<ColorChoice>(
        builder: (_) => AddTileColorScreen(initialColor: _draft.color),
      ),
    );
    if (choice == null || !choice.made || !mounted) return;
    _draft.setColor(choice.color);
  }

  /// Opens the advanced preferred-time profile editor. A confirmed `null` is
  /// meaningful here — it means Anytime — so the result carries `didWrite`
  /// rather than relying on nullability.
  Future<void> _openAdvancedPreferredTime() async {
    final AdvancedRestrictionResult result = await openAdvancedRestrictionRoute(
        context,
        current: _draft.restrictionProfile);
    if (!result.didWrite || !mounted) return;
    _draft.setRestrictionProfile(result.profile);
  }

  /// Root Close. Emits the dismissal signal, then pops.
  ///
  /// The D2 dirty-draft confirmation prompt is NOT implemented yet, so this
  /// still closes immediately; `dirty` is reported so the abandonment data
  /// exists before that prompt lands.
  void _onClosePressed() {
    _analytics.dismissed(_draft.type, dirty: _draft.isDirty);
    Navigator.of(context).maybePop();
  }

  Future<void> _attemptSubmit() async {
    if (_submitting) {
      _analytics.submitResult(_draft.type,
          outcome: 'cancelled', reasonCode: 'duplicate_submit_blocked');
      return;
    }
    final bool valid = _draft.isValid;
    _analytics.submitTapped(
      _draft.type,
      valid: valid,
      missingFieldIds: missingFieldsOf(_draft),
    );
    if (!valid) {
      // Surface the inline error on the first invalid field (name) and focus
      // it; the error text announces to assistive tech (not color-only).
      setState(() => _showValidationErrors = true);
      _nameFocus.requestFocus();
      return;
    }
    setState(() => _submitting = true);
    try {
      final NewTile tile = NewTileRequestMapper.buildFromSnapshot(
        _draft.snapshot,
        now: DateTime.now(),
      );
      if (widget.onSubmitted != null) {
        await widget.onSubmitted!.call(tile);
        _analytics.submitResult(_draft.type, outcome: 'success');
      } else {
        // Debug-only seam: the default /AddTileRedesign route has no backend
        // orchestrator yet (wired when the redesign replaces the legacy flow).
        // Surface the mapped payload so the draft -> mapper -> CTA path is
        // verifiable on-device without writing to the API. No analytics, no
        // side effects.
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Draft mapped (debug): ${tile.Name} | '
              '${tile.DurationMinute ?? '-'} min | Rigid=${tile.Rigid ?? 'null'}',
            ),
          ),
        );
      }
    } catch (_) {
      // Submission failure (API/network): the draft is preserved and the CTA
      // is re-enabled in `finally`. The real orchestration surfaces a
      // retryable message; tests inject onSubmitted and assert that the draft
      // survives the failure.
      //
      // The exception object is deliberately NOT inspected or logged: its
      // message can embed request content. Only the enumerated outcome and an
      // allow-listed reason code are emitted.
      _analytics.submitResult(_draft.type,
          outcome: 'api_error', reasonCode: 'api_rejected');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = _draft.type;
    final String title = type == AddTileType.fixed
        ? l10n.addTileScreenTitleFixed
        : l10n.addTileScreenTitleFlexible;

    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.close,
          onPressed: _onClosePressed,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AddTileTypeSelector(type: type, onSelected: _onTypeSelected),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
            child: AddTileModeExplanation(
              key: const ValueKey('modeExplanation'),
              icon: AddTileTypeSelector.iconFor(type),
              template: type == AddTileType.fixed
                  ? l10n.addTileExplanationFixed
                  : l10n.addTileExplanationFlexible,
              emphasis: type == AddTileType.fixed
                  ? l10n.addTileExplanationFixedEmphasis
                  : l10n.addTileExplanationFlexibleEmphasis,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildFormArea(type),
            ),
          ),
          // Persistent, keyboard-safe CTA: sits above the bottom safe area
          // (SafeArea in AddTileBottomAction) and above the keyboard (this
          // viewInsets padding).
          Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: AddTileBottomAction(
              key: const ValueKey('addTileCta'),
              type: type,
              enabled: _draft.isValid,
              submitting: _submitting,
              onTap: _attemptSubmit,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormArea(AddTileType type) {
    // The type-specific fields, then the shared More options disclosure
    // (collapsed by default, so it never competes with the primary
    // decisions). More options renders a different subset per type.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTypeForm(type),
        const SizedBox(height: 12),
        AddTileMoreOptions(
          draft: _draft,
          onColorTap: _openColorPicker,
          onPriorityTap: _openPriorityPicker,
          onExpanded: () => _analytics.advancedOpened(_draft.type),
        ),
      ],
    );
  }

  Widget _buildTypeForm(AddTileType type) {
    final l10n = AppLocalizations.of(context)!;
    if (type == AddTileType.flexible) {
      return FlexibleTileForm(
        draft: _draft,
        nameController: _nameController,
        nameFocus: _nameFocus,
        predicting: _predicting,
        nameError: _showValidationErrors && _draft.name.trim().isEmpty
            ? l10n.addTileNameRequired
            : null,
        onNameChanged: _onNameChanged,
        onNameSubmitted: (_) => _attemptSubmit(),
        onDurationTap: _openDurationPicker,
        onDeadlineTap: _openDeadlinePicker,
        onPreferredTimeSelected: _onPreferredTimeSelected,
        onAdvancedPreferredTimeTap: _openAdvancedPreferredTime,
        onLocationTap: _openLocationPicker,
        onNameLocationTap: _draft.location != null ? _nameLocation : null,
        onRepeatTap: _openRepeatPicker,
      );
    }
    // Fixed Block: a locked interval. Date / Starts / Duration are editable
    // and Ends is derived (Phase 3.1).
    return FixedBlockForm(
      draft: _draft,
      nameController: _nameController,
      nameFocus: _nameFocus,
      predicting: _predicting,
      today: widget.now ?? DateTime.now(),
      nameError: _showValidationErrors && _draft.name.trim().isEmpty
          ? l10n.addTileTitleRequired
          : null,
      onNameChanged: _onNameChanged,
      onNameSubmitted: (_) => _attemptSubmit(),
      onDateTap: _openDatePicker,
      onStartTap: _openStartTimePicker,
      onDurationTap: _openDurationPicker,
      onLocationTap: _openLocationPicker,
      onNameLocationTap: _draft.location != null ? _nameLocation : null,
      onRepeatTap: _openRepeatPicker,
    );
  }
}
