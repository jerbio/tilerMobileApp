// D19 — the place editor.
//
// A place is a NAME and an ADDRESS, and for somewhere search cannot find, the
// user may need both: "my Walmart near work" AT a particular street is what
// distinguishes it from "Walmart near Boulder". One editor serves both entry
// points — the picker's "Use what you typed", and the Add form's edit
// affordance on an already-chosen location — so there is a single way to
// describe a place rather than a naming path and an addressing path that never
// meet.
//
// WHY THE WARNING EXISTS. The backend keys places by NAME and upserts: saving
// a name that already exists MOVES that name onto the new address, and the old
// association is gone (D19/D20/D21). So the editor looks the name up as it is
// typed and, on a match, says which address is about to be replaced. It does
// not block — moving a name is legitimate once understood — but it must never
// be silent.
//
// PREFILL. The picker seeds the ADDRESS, not the name. The backend copies
// whichever field is present into the other, so an address-only save still
// produces a name; seeding the address means "bike shop" behaves exactly as it
// did before, while a typed street address lands in the right slot instead of
// becoming a place name.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileLocationSource.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// Builds the [Location] a place editor should return.
///
/// Pure so the wire rules are testable without a widget:
///   * a CHANGED name clears the id — legacy `LocationRoute.onProceed` parity.
///     With the backend keying on name this is probably vestigial, but it is
///     harmless and dropping it is not this slice's decision;
///   * a hand-edited address clears `isVerified`, which means "came from a
///     provider" — typing it by hand means it did not. An untouched address
///     keeps whatever verification it arrived with;
///   * a place built from nothing is unverified.
Location buildEditedPlace({
  required String name,
  required String address,
  Location? original,
}) {
  final String trimmedName = name.trim();
  final String trimmedAddress = address.trim();
  final Location result = original ?? Location.fromDefault();

  final bool nameChanged = trimmedName != (original?.description ?? '').trim();
  final bool addressChanged =
      trimmedAddress != (original?.address ?? '').trim();

  result.description = trimmedName;
  result.address = trimmedAddress;
  if (nameChanged) result.id = '';
  if (addressChanged || original == null) result.isVerified = false;
  if (trimmedName.isNotEmpty || trimmedAddress.isNotEmpty) {
    result.isDefault = false;
    result.isNull = false;
  }
  return result;
}

/// Name + address editor for a place.
class AddTilePlaceEditorScreen extends StatefulWidget {
  const AddTilePlaceEditorScreen({
    super.key,
    required this.source,
    this.initialName,
    this.initialAddress,
    this.original,
    this.onSaved,
  });

  final AddTileLocationSource source;
  final String? initialName;
  final String? initialAddress;

  /// The place being edited, when there is one. Used to tell a rename from a
  /// fresh creation, and to recognise "the match is myself" during the
  /// collision check.
  final Location? original;

  /// Invoked with the saved place. Injected by tests; in the app the screen
  /// pops with the value.
  final void Function(Location)? onSaved;

  @override
  State<AddTilePlaceEditorScreen> createState() =>
      _AddTilePlaceEditorScreenState();
}

class _AddTilePlaceEditorScreenState extends State<AddTilePlaceEditorScreen> {
  late final TextEditingController _nameController =
      TextEditingController(text: (widget.initialName ?? '').trim());
  late final TextEditingController _addressController =
      TextEditingController(text: (widget.initialAddress ?? '').trim());

  Timer? _debounce;

  /// The saved place currently colliding with the typed name, if any.
  Location? _collision;

  /// Discards a lookup that lands after the name has moved on, so a stale
  /// response cannot resurrect a warning the user has already typed past.
  int _lookupGeneration = 0;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    _debounce?.cancel();
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      _lookupGeneration++;
      if (_collision != null) setState(() => _collision = null);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _check(name));
  }

  Future<void> _check(String name) async {
    final int generation = ++_lookupGeneration;
    try {
      final Location? match = await widget.source.findByName(name);
      if (!mounted || generation != _lookupGeneration) return;
      setState(() => _collision = _isSelf(match) ? null : match);
    } catch (_) {
      if (!mounted || generation != _lookupGeneration) return;
      // A failed lookup must not block the save; it only means we cannot warn.
      setState(() => _collision = null);
    }
  }

  /// True when the matched place IS the one being edited — renaming `home` to
  /// `home` is not a collision.
  bool _isSelf(Location? match) {
    if (match == null) return true;
    final Location? original = widget.original;
    if (original == null) return false;
    if (original.id != null &&
        original.id!.isNotEmpty &&
        original.id == match.id) {
      return true;
    }
    return (original.description ?? '').trim().toLowerCase() ==
        (match.description ?? '').trim().toLowerCase();
  }

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty ||
      _addressController.text.trim().isNotEmpty;

  void _save() {
    if (!_canSave) return;
    final Location result = buildEditedPlace(
      name: _nameController.text,
      address: _addressController.text,
      original: widget.original,
    );
    if (widget.onSaved != null) {
      widget.onSaved!(result);
      return;
    }
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(widget.original == null ? 'Add place' : 'Edit place'),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                AddTileSection(
                  children: [
                    AddTileTextFieldRow(
                      key: const ValueKey('placeNameFieldRow'),
                      fieldKey: const ValueKey('placeNameField'),
                      icon: Icons.sell_outlined,
                      label: 'NAME',
                      controller: _nameController,
                      focusNode: FocusNode(),
                      hint: "e.g. Walmart near work",
                    ),
                    AddTileTextFieldRow(
                      key: const ValueKey('placeAddressFieldRow'),
                      fieldKey: const ValueKey('placeAddressField'),
                      icon: Icons.location_on_outlined,
                      label: 'ADDRESS',
                      controller: _addressController,
                      focusNode: FocusNode(),
                      hint: 'Street, city, state',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_collision != null)
                  _CollisionWarning(
                    key: const ValueKey('placeNameCollision'),
                    name: (_collision!.description ?? '').trim(),
                    address: (_collision!.address ?? '').trim(),
                  ),
                const SizedBox(height: 12),
                Text(
                  'A name is how you find this place again. Naming two places '
                  'the same thing keeps only the newest address.',
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: const ValueKey('placeCancel'),
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PlaceEditorSaveButton(
                    key: const ValueKey('placeSave'),
                    enabled: _canSave,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains that saving will move an existing name onto this address, naming
/// the address about to be replaced — "you are about to update a name" would
/// not tell the user what they stand to lose.
class _CollisionWarning extends StatelessWidget {
  const _CollisionWarning({
    super.key,
    required this.name,
    required this.address,
  });

  final String name;
  final String address;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.attentionTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.attention.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: tokens.attention, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              address.isEmpty
                  ? 'You already have a place called "$name". Saving will move '
                      'that name to this address.'
                  : 'You already have a place called "$name" at $address. '
                      'Saving will move that name to this address.',
              style: textTheme.bodySmall?.copyWith(color: tokens.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The editor's primary action. Disabled until at least one field has content
/// — either alone is enough, because the backend copies one into the other.
class PlaceEditorSaveButton extends StatelessWidget {
  const PlaceEditorSaveButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      enabled: enabled,
      label: 'Save place',
      child: ExcludeSemantics(
        child: Material(
          color: enabled ? tokens.brand : tokens.surfaceSubtle,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Center(
                child: Text(
                  'Save place',
                  style: textTheme.titleMedium?.copyWith(
                    color: enabled ? scheme.onPrimary : tokens.textSecondary,
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
