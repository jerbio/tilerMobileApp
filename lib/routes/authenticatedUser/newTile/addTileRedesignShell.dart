// Feature-flagged Add Tile redesign shell.
//
// Implements the shared frame:
//   Close            Add Tile / Add Block
//   [ Flexible Tile | Fixed Block ]      (one non-swipeable segmented control)
//   Mode explanation
//   Scrollable mode-specific form
//   Persistent primary CTA
//
// This slice covers the CHROME: the type selector (before any fields), dynamic
// title/explanation/CTA, an independently scrolling form area, a persistent
// keyboard/safe-area-safe CTA, and a single root Close. The CTA submits through
// the NewTileRequestMapper. The redesigned form FIELDS land in later work
// (Flexible and Fixed); this slice keeps a minimal name/duration area so the
// CTA gating and submission wiring are testable without the field redesign.
//
// The legacy AddTile carousel/toggle flow remains the default (flag off) until
// rollout. Strings are English constants for now; they migrate to
// app_en.arb/app_es.arb when the content system lands.
import 'package:flutter/material.dart';
import 'package:tiler_app/data/adHoc/preTile.dart';
import 'package:tiler_app/data/request/NewTile.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileDraft.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/newTileRequestMapper.dart';

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
  static const String redesignFlowVersion = 'redesign-v1';
  static const String legacyFlowVersion = 'legacy';
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
        enabled: canSubmit,
        label: submitting ? 'Submitting' : _label,
        container: true,
        child: Material(
          color: canSubmit || submitting
              ? scheme.primary
              : scheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: canSubmit ? onTap : null,
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
  });

  final PreTile? preTile;
  final AddTileDraft? draft;

  /// Submission seam: injected (stubbed in tests); wired to the
  /// existing orchestration when the redesign replaces the legacy flow.
  final Future<void> Function(NewTile)? onSubmitted;
  final DateTime? now;

  @override
  State<AddTileRedesignScreen> createState() => _AddTileRedesignScreenState();
}

class _AddTileRedesignScreenState extends State<AddTileRedesignScreen> {
  late final AddTileDraft _draft;
  late final bool _ownsDraft;
  bool _submitting = false;
  late final TextEditingController _nameController;
  final _nameFocus = FocusNode();

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
    if (next == AddTileType.fixed) {
      _draft.switchToFixed();
    } else {
      _draft.switchToFlexible();
    }
  }

  Future<void> _onSubmitTap() async {
    if (!_draft.isValid || _submitting) {
      // Focus the first invalid field (name) and announce to assistive tech.
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
          onPressed: () => Navigator.of(context).maybePop(),
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
              onTap: _onSubmitTap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormArea(AddTileType type) {
    // Minimal chrome for now. The full Flexible/Fixed field sets arrive in
    // later work. The CTA is already gated by AddTileDraft.isValid (name +
    // duration), which proves the submission wiring end-to-end.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          textInputAction: TextInputAction.done,
          onChanged: (value) => _draft.name = value,
          decoration: const InputDecoration(
            labelText: 'What do you want to do?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Text('How long? *', style: Theme.of(context).textTheme.titleSmall),
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
