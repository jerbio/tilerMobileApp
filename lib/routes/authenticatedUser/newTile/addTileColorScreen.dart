// Step 4.3b — the Color picker.
//
// Built to the house picker pattern established by Priority and Location:
// Back rather than Close (D12), and a TAP COMMITS. Choosing a color has
// nothing to confirm, so the legacy `/PickColor` route's bottom
// Cancel/Proceed pair is dropped — the only control that still needs a
// confirm is the continuous custom wheel, which cannot commit on every drag.
//
// WHAT THIS ADDS OVER THE LEGACY ROUTE.
//
//   1. Automatic is REACHABLE AND REVERSIBLE. Decision D7 keeps the
//      random-color fallback for v1: a tile with no color is assigned one at
//      submit. The legacy picker could only ever ASSIGN a color — once set
//      there was no way back to "let Tiler choose", because its result slot
//      could not express `null`. Automatic is now the first row.
//   2. The chosen color is VISIBLE on the row that opens this screen, so
//      "Custom" is no longer the whole answer to what color a tile is.
//
// WHY A [ColorChoice] AND NOT A `Color?`. `null` is a real, choosable answer
// here — it means Automatic — so a nullable return could not tell "the user
// chose Automatic" from "the user backed out". Same shape problem, and same
// resolution, as `openAdvancedRestrictionRoute`: report whether a choice was
// made separately from what it was.
//
// This screen speaks plain `Color` values and knows nothing about
// `AddTileDraft`, so the edit-tile flow can reuse it as-is (D29).
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/addTileFormKit.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// The preset palette, carried over from the legacy `/PickColor` route so a
/// returning user's familiar swatches do not silently change.
///
/// The legacy route's first slot was a shuffling random swatch; that role is
/// now filled by Automatic, which says what it actually does.
const List<Color> addTileColorPresets = <Color>[
  Color.fromRGBO(255, 255, 0, 1),
  Color.fromRGBO(135, 255, 221, 1),
  Color.fromRGBO(110, 201, 255, 1),
  Color.fromRGBO(255, 71, 49, 1),
  Color.fromRGBO(61, 230, 107, 1),
  Color.fromRGBO(210, 79, 210, 1),
  Color.fromRGBO(145, 73, 245, 1),
  Color.fromRGBO(255, 128, 231, 1),
  Color.fromRGBO(255, 99, 56, 1),
];

/// The result of the Color picker.
///
/// [made] distinguishes a confirmed choice from a dismissal; [color] carries
/// the chosen value, and a `null` color on a made choice means Automatic.
@immutable
class ColorChoice {
  const ColorChoice.chosen(this.color) : made = true;
  const ColorChoice.automatic()
      : color = null,
        made = true;
  const ColorChoice.none()
      : color = null,
        made = false;

  final Color? color;
  final bool made;

  @override
  bool operator ==(Object other) =>
      other is ColorChoice && other.color == color && other.made == made;

  @override
  int get hashCode => Object.hash(color, made);
}

/// Summary for the row that opens this screen.
///
/// Deliberately does NOT name the color: color names are a translation and
/// perception problem (is `#6EC9FF` "blue" or "sky"?), and the row shows the
/// actual swatch beside this text, which answers the question better than any
/// word would.
String colorChoiceSummary(AppLocalizations l10n, Color? color) =>
    color == null ? l10n.addTileColorAutomatic : l10n.addTileColorCustom;

/// Whether [candidate] is the color currently in effect.
///
/// Automatic is represented by `null`, so it reads as selected exactly when no
/// color is set — never by comparing against a freshly rolled random value,
/// which would flicker between builds.
bool colorIsSelected(Color? current, Color? candidate) => current == candidate;

class AddTileColorScreen extends StatefulWidget {
  const AddTileColorScreen({
    super.key,
    this.initialColor,
    this.onSelected,
  });

  /// The color in effect, or `null` for Automatic.
  final Color? initialColor;

  /// Invoked with the confirmed choice. Injected by tests; in the app the
  /// screen pops with the value.
  final void Function(ColorChoice)? onSelected;

  @override
  State<AddTileColorScreen> createState() => _AddTileColorScreenState();
}

class _AddTileColorScreenState extends State<AddTileColorScreen> {
  /// The wheel is a CONTINUOUS control — it fires on every drag — so unlike a
  /// swatch it cannot commit on change. It gets a Done, and only while open.
  bool _customOpen = false;
  late Color _wheelColor;

  @override
  void initState() {
    super.initState();
    _wheelColor = widget.initialColor ?? _randomColor();
  }

  static Color _randomColor() {
    final Random rng = Random();
    return HSLColor.fromAHSL(
      1,
      rng.nextDouble() * 360,
      rng.nextDouble(),
      1 - (rng.nextDouble() * 0.35),
    ).toColor();
  }

  void _commit(ColorChoice choice) {
    if (widget.onSelected != null) {
      widget.onSelected!(choice);
      return;
    }
    Navigator.of(context).pop(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final Color? current = widget.initialColor;

    return Scaffold(
      backgroundColor: tokens.background,
      appBar: AppBar(
        title: Text(l10n.color),
        // D12: secondary screens go Back to the preserved draft.
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          AddTileSection(
            children: [
              ColorOptionRow(
                key: const ValueKey('colorAutomatic'),
                icon: Icons.auto_awesome_outlined,
                title: l10n.addTileColorAutomatic,
                subtitle: l10n.addTileColorAutomaticHelper,
                selected: current == null,
                onTap: () => _commit(const ColorChoice.automatic()),
              ),
              ColorOptionRow(
                key: const ValueKey('colorCustomRow'),
                icon: Icons.colorize_outlined,
                title: l10n.addTileColorCustom,
                subtitle: l10n.addTileColorCustomHelper,
                // Opening the wheel is not itself a choice, so this row never
                // reads as selected — the swatch grid owns selection.
                selected: false,
                swatch: _customOpen ? _wheelColor : null,
                onTap: () => setState(() => _customOpen = !_customOpen),
              ),
            ],
          ),
          if (_customOpen) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: tokens.cardBorder),
              ),
              child: Column(
                children: [
                  ColorPicker(
                    pickerColor: _wheelColor,
                    onColorChanged: (c) => setState(() => _wheelColor = c),
                    enableAlpha: false,
                    labelTypes: const <ColorLabelType>[],
                    portraitOnly: true,
                  ),
                  ColorDoneButton(
                    key: const ValueKey('colorCustomDone'),
                    onTap: () => _commit(ColorChoice.chosen(_wheelColor)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l10n.addTileColorPresets,
            style: textTheme.labelSmall
                ?.copyWith(color: tokens.textSecondary, letterSpacing: 0.6),
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
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (int index, Color preset)
                    in addTileColorPresets.indexed)
                  ColorSwatchButton(
                    key: ValueKey('colorPreset_$index'),
                    color: preset,
                    // Presets are NUMBERED, not named: a color name is a
                    // translation and perception problem, and the swatch
                    // itself is the information.
                    label: l10n.addTileColorSwatch(index + 1),
                    selected: colorIsSelected(current, preset),
                    onTap: () => _commit(ColorChoice.chosen(preset)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: tokens.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.addTileColorHelper,
                  style: textTheme.bodySmall
                      ?.copyWith(color: tokens.textSecondary),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A named color choice (Automatic / Custom). Mirrors `PriorityOptionRow`'s
/// shape so the two pickers do not drift apart.
class ColorOptionRow extends StatelessWidget {
  const ColorOptionRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.swatch,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// Shown in place of the selection mark while the wheel is open, so the row
  /// previews what Done would commit.
  final Color? swatch;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: selected ? tokens.brandTint : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 68),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    AddTileIconChip(icon: icon),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: textTheme.titleMedium?.copyWith(
                              color: tokens.textPrimary,
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: textTheme.bodySmall
                                ?.copyWith(color: tokens.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (swatch != null)
                      ColorDot(color: swatch!, size: 24)
                    else
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: selected ? tokens.brand : tokens.textSecondary,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One preset swatch. Selection is a ring PLUS a check mark, never color
/// alone — the control is made of colors, so color cannot also be the signal
/// that one is chosen (§11).
class ColorSwatchButton extends StatelessWidget {
  const ColorSwatchButton({
    super.key,
    required this.color,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: ExcludeSemantics(
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? tokens.brand : tokens.cardBorder,
                    width: selected ? 3 : 1,
                  ),
                ),
                child: selected
                    ? Icon(Icons.check, size: 20, color: onColorOf(color))
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Black or white, whichever the swatch can actually carry. The presets run
  /// from near-yellow to deep purple, so a fixed mark color would vanish at
  /// one end of the palette.
  static Color onColorOf(Color background) =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
          ? Colors.white
          : Colors.black;
}

/// A plain color dot, for previews and summaries.
class ColorDot extends StatelessWidget {
  const ColorDot({super.key, required this.color, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: tokens.cardBorder),
        ),
      ),
    );
  }
}

/// Confirms the wheel's current value. Present only while the wheel is open —
/// every other control on the screen commits on tap.
class ColorDoneButton extends StatelessWidget {
  const ColorDoneButton({super.key, required this.onTap});

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
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
      ),
    );
  }
}
