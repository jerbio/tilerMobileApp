import 'package:flutter/material.dart';

/// The pieces the TileShare lists (Attention, Clusters) share, so both look and
/// behave the same.

/// A horizontally scrolling row of filter chips. Each chip is keyed
/// `<keyPrefix>_chip_<name>` and its text `<keyPrefix>_chip_label_<name>`.
class TileShareChipBar<T extends Enum> extends StatelessWidget {
  final String keyPrefix;
  final List<T> values;
  final T selected;
  final String Function(T value) labelOf;

  /// Optional count shown after the label.
  final int? Function(T value)? countOf;
  final ValueChanged<T> onSelected;

  const TileShareChipBar({
    super.key,
    required this.keyPrefix,
    required this.values,
    required this.selected,
    required this.labelOf,
    this.countOf,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (final T value in values) ...[
            ChoiceChip(
              key: Key('${keyPrefix}_chip_${value.name}'),
              label: Text(
                countOf == null
                    ? labelOf(value)
                    : '${labelOf(value)} ${countOf!(value) ?? 0}',
                key: Key('${keyPrefix}_chip_label_${value.name}'),
              ),
              selected: value == selected,
              onSelected: (_) => onSelected(value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// A failure shown above rows that are still on screen.
class TileShareErrorBanner extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const TileShareErrorBanner({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
          TextButton(
            onPressed: onRetry,
            // The default (primary red) is nearly invisible on the dark
            // theme's dark-red banner; this colour is made for it.
            style: TextButton.styleFrom(foregroundColor: scheme.onErrorContainer),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}

/// A failure with nothing to show: the whole story, with Retry.
class TileShareErrorState extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  const TileShareErrorState({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 8),
          FilledButton.tonal(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

/// An empty list: an icon, a title, a line of text, and optionally an action.
class TileShareEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const TileShareEmptyState({
    super.key,
    this.icon = Icons.task_alt_outlined,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(title,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

/// Placeholder cards while the first load is in flight.
class TileShareSkeleton extends StatelessWidget {
  final double cardHeight;

  const TileShareSkeleton({super.key, this.cardHeight = 128});

  @override
  Widget build(BuildContext context) {
    final Color fill = Theme.of(context).colorScheme.surfaceContainerHigh;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
            Container(
              height: cardHeight,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
        ],
      ),
    );
  }
}
