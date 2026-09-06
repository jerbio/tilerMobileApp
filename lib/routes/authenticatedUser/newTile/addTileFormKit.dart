// Shared Add Tile form components — the mockup visual language.
//
// Both the Flexible and Fixed forms are built from these, so the two modes
// cannot drift apart visually and a spacing/typography change lands in one
// place.
//
// The mockups draw the Flexible fields as separate floating cards and the
// Fixed fields as one grouped card with dividers. Plan §4.1 resolves that
// disagreement explicitly — "do not reproduce every field as an isolated
// elevated card; use grouped, unframed rows or restrained surfaces" — so the
// GROUPED pattern (as drawn in the Add Block mockup) is the house pattern for
// both modes.
//
// Colors come from the shared scheme and TodayStatusTokens, never from
// literals, so light/dark both work through semantic tokens (§7.1).
import 'package:flutter/material.dart';
import 'package:tiler_app/theme/today_status_tokens.dart';

/// A grouped card of related rows, separated by hairline dividers.
///
/// This is the only surface in the form that carries elevation, keeping
/// §4.1's "hierarchy from content and spacing, not repeated shadows".
class AddTileSection extends StatelessWidget {
  const AddTileSection({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          indent: 68, // clears the icon chip, so dividers align to the text
          color: tokens.cardBorder,
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(mainAxisSize: MainAxisSize.min, children: rows),
    );
  }
}

/// The tinted rounded-square icon that leads every row in the mockups.
///
/// Decorative: the row's own semantics carry the meaning, so the icon is
/// hidden from assistive technology (§4.2 cross-revision 6).
class AddTileIconChip extends StatelessWidget {
  const AddTileIconChip({super.key, required this.icon, this.muted = false});

  final IconData icon;

  /// Neutral treatment for secondary rows (Repeat, Color, More options in the
  /// mockups) versus the brand tint used by primary fields.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final Color foreground = muted ? tokens.textSecondary : tokens.brand;
    return ExcludeSemantics(
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: muted ? tokens.surfaceSubtle : tokens.brandTint,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: foreground),
      ),
    );
  }
}

/// A labelled field row: icon chip, small uppercase label, value, and an
/// optional trailing affordance.
///
/// A trailing chevron appears ONLY when [onTap] is provided, so a row that
/// navigates is visually distinct from one that does not (§7.1). Read-only
/// rows such as the Fixed Block end pass [trailing] instead.
class AddTileFieldRow extends StatelessWidget {
  const AddTileFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    this.trailing,
    this.required = false,
    this.valueIsPlaceholder = false,
    this.error,
    this.mutedIcon = false,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  /// Replaces the chevron. Used for the locked "Auto-calculated" pill.
  final Widget? trailing;

  final bool required;

  /// Dims the value when it stands in for an unset field.
  final bool valueIsPlaceholder;

  /// Inline error, announced with the row rather than conveyed by color.
  final String? error;
  final bool mutedIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AddTileIconChip(icon: icon, muted: mutedIcon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  required ? '$label *' : label,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: textTheme.titleMedium?.copyWith(
                    color: valueIsPlaceholder
                        ? tokens.textSecondary
                        : tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    error!,
                    style: textTheme.bodySmall?.copyWith(color: scheme.error),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null)
            trailing!
          else if (onTap != null)
            Icon(Icons.chevron_right, color: tokens.textSecondary),
        ],
      ),
    );

    return Semantics(
      button: onTap != null,
      label: semanticLabel ??
          '$label${required ? ', required' : ''}, $value'
              '${error != null ? ', $error' : ''}',
      child: ExcludeSemantics(
        child: onTap == null
            ? ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: content,
              )
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: content,
                  ),
                ),
              ),
      ),
    );
  }
}

/// A secondary navigation row: icon chip, single title, trailing affordance
/// (Location / Repeat / More options in the mockups).
class AddTileNavRow extends StatelessWidget {
  const AddTileNavRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.mutedIcon = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool mutedIcon;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: onTap != null,
      label: subtitle == null ? title : '$title, $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    AddTileIconChip(icon: icon, muted: mutedIcon),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: tokens.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    if (trailing != null)
                      trailing!
                    else if (onTap != null)
                      Icon(Icons.chevron_right, color: tokens.textSecondary),
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

/// The "name this place" affordance on a chosen location row.
///
/// Naming a place is the minority case — the Location picker commits on tap —
/// so it is a small trailing action on the value rather than a step in the
/// selection flow.
class NameLocationButton extends StatelessWidget {
  const NameLocationButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    return Semantics(
      button: true,
      label: 'Name this place',
      child: ExcludeSemantics(
        child: IconButton(
          key: const ValueKey('nameLocationAction'),
          onPressed: onTap,
          tooltip: 'Name this place',
          icon: Icon(Icons.drive_file_rename_outline,
              size: 20, color: tokens.textSecondary),
        ),
      ),
    );
  }
}

/// The small locked status pill beside the Fixed Block's derived end.
///
/// Status, not a control: it is inert and its meaning reaches assistive tech
/// through the row's semantics (§11 requires the end to read as calculated).
class AddTileLockedPill extends StatelessWidget {
  const AddTileLockedPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: textTheme.labelMedium?.copyWith(color: tokens.textSecondary),
          ),
          const SizedBox(width: 4),
          Icon(Icons.lock_outline, size: 14, color: tokens.textSecondary),
        ],
      ),
    );
  }
}

/// An editable text field styled as a form row (the mockups' Title / Task
/// name rows).
class AddTileTextFieldRow extends StatelessWidget {
  const AddTileTextFieldRow({
    super.key,
    required this.icon,
    required this.label,
    required this.controller,
    required this.focusNode,
    this.fieldKey,
    this.hint,
    this.error,
    this.required = false,
    this.onChanged,
    this.onSubmitted,
  });

  /// Key on the inner [TextField], for rows whose row-key is already taken.
  final Key? fieldKey;

  final IconData icon;
  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hint;
  final String? error;
  final bool required;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = TodayStatusTokens.of(context);
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: AddTileIconChip(icon: Icons.edit_outlined),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Text(
                  required ? '$label *' : label,
                  style: textTheme.labelSmall?.copyWith(
                    color: tokens.textSecondary,
                    letterSpacing: 0.6,
                  ),
                ),
                TextField(
                  key: fieldKey,
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: TextInputAction.done,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  style: textTheme.titleMedium?.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: textTheme.titleMedium
                        ?.copyWith(color: tokens.textSecondary),
                    errorText: error,
                    errorStyle:
                        textTheme.bodySmall?.copyWith(color: scheme.error),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
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
