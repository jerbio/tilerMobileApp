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
// rollout. Strings are English constants for now; they migrate to
// app_en.arb/app_es.arb when the content system lands.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/data/restrictionProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileAnalytics.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileMoreOptions.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/flexibleTileForm.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/preferredTimeOfDay.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/tileRouteAdapters.dart';

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
class AddTileTypeSelector extends StatelessWidget {
  const AddTileTypeSelector({
    super.key,
    required this.type,
    required this.onSelected,
  });

  final AddTileType type;
  final ValueChanged<AddTileType> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Tile type',
      child: Row(
        children: [
          Expanded(
            child: AddTileTypeSegment(
              label: 'Flexible Tile',
              selected: type == AddTileType.flexible,
              onTap: () => onSelected(AddTileType.flexible),
              selectedBackground: scheme.primaryContainer,
              selectedForeground: scheme.primary,
              textTheme: textTheme,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AddTileTypeSegment(
              label: 'Fixed Block',
              selected: type == AddTileType.fixed,
              onTap: () => onSelected(AddTileType.fixed),
              selectedBackground: scheme.primaryContainer,
              selectedForeground: scheme.primary,
              textTheme: textTheme,
            ),
          ),
        ],
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
    required this.selected,
    required this.onTap,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.textTheme,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBackground;
  final Color selectedForeground;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? selectedBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Center(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: textTheme.titleSmall?.copyWith(
                    color: selected ? selectedForeground : onSurface,
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

  String get _label => type == AddTileType.fixed ? 'Add Block' : 'Find time';

  @override
  Widget build(BuildContext context) {
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
        label: submitting ? 'Submitting' : _label,
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
                        _label,
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
  Future<void> _openLocationPicker() async {
    final Location? picked = await openLocationRoute(
      context,
      currentLocation: _draft.location,
    );
    if (picked == null || !mounted) return;
    _draft.setLocation(picked);
  }

  /// Opens the legacy `/RepetitionRoute` through its typed adapter, which
  /// preserves the legacy apply/clear/unchanged result semantics.
  Future<void> _openRepeatPicker() async {
    final RepeatRouteResult result = await openRepeatRoute(
      context,
      current: _draft.repetitionData,
      deadline: _draft.endTime,
    );
    if (!mounted) return;
    applyRepeatRouteResult(_draft, result);
  }

  /// Opens the legacy `/PickColor` route. Legacy applied the result only when
  /// non-null, so a cancel leaves the draft's color (and the random-color
  /// fallback, decision D7) untouched.
  Future<void> _openColorPicker() async {
    final Color? picked = await openColorRoute(context, current: _draft.color);
    if (picked == null || !mounted) return;
    _draft.setColor(picked);
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
    final type = _draft.type;
    final String title = type == AddTileType.fixed ? 'Add Block' : 'Add Tile';
    final String explanation = type == AddTileType.fixed
        ? 'Blocks happen at a fixed time.'
        : 'Tiler will find the best time for this.';
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: _onClosePressed,
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AddTileTypeSelector(type: type, onSelected: _onTypeSelected),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              explanation,
              style: Theme.of(context).textTheme.bodyMedium,
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
          onExpanded: () => _analytics.advancedOpened(_draft.type),
          onAdvancedPreferredTimeTap: _openAdvancedPreferredTime,
        ),
      ],
    );
  }

  Widget _buildTypeForm(AddTileType type) {
    if (type == AddTileType.flexible) {
      return FlexibleTileForm(
        draft: _draft,
        nameController: _nameController,
        nameFocus: _nameFocus,
        nameError: _showValidationErrors && _draft.name.trim().isEmpty
            ? 'Name is required'
            : null,
        onNameChanged: _onNameChanged,
        onNameSubmitted: (_) => _attemptSubmit(),
        onDurationTap: _openDurationPicker,
        onDeadlineTap: _openDeadlinePicker,
        onPreferredTimeSelected: _onPreferredTimeSelected,
        onLocationTap: _openLocationPicker,
        onRepeatTap: _openRepeatPicker,
      );
    }
    // The Fixed form (date / start / duration / calculated read-only end)
    // lands in Phase 3. A minimal name/duration area keeps CTA gating and
    // rigid-payload submission testable in this slice.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.done,
          onChanged: (value) {
            _draft.name = value;
            if (_showValidationErrors && value.trim().isNotEmpty) {
              setState(() => _showValidationErrors = false);
            }
          },
          onSubmitted: (_) => _attemptSubmit(),
          decoration: const InputDecoration(
            labelText: 'Title',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text('Duration *', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          _draft.duration.inMinutes > 0
              ? '${_draft.duration.inMinutes} min'
              : 'Duration not set',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
