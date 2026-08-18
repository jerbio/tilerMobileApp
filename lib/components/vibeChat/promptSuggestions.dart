import 'package:flutter/material.dart';
import 'package:tiler_app/data/VibeChat/VibeAutoSuggestions.dart';

/// Tap-to-send prompt pills shown above the message input while it is empty.
class PromptSuggestions extends StatelessWidget {
  final VibeAutoSuggestions suggestions;
  final bool isLoading;
  final ValueChanged<String> onPromptTap;

  const PromptSuggestions({
    Key? key,
    required this.suggestions,
    required this.isLoading,
    required this.onPromptTap,
  }) : super(key: key);

  static const int _skeletonCount = 4;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading && suggestions.isEmpty) {
      return _SuggestionStrip(
        children: List.generate(
          _skeletonCount,
          (index) => _SkeletonPill(colorScheme: colorScheme),
        ),
      );
    }

    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return _SuggestionStrip(
      children: suggestions.entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                backgroundColor: colorScheme.surfaceContainerHighest,
                side: BorderSide(color: colorScheme.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onPressed: () => onPromptTap(entry.value),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  final List<Widget> children;

  const _SuggestionStrip({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        // Keyed so a rebuild that swaps skeletons for pills cannot inherit the
        // wrong PageStorage scroll offset.
        key: const PageStorageKey<String>('vibe-prompt-suggestions'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: children,
      ),
    );
  }
}

class _SkeletonPill extends StatefulWidget {
  final ColorScheme colorScheme;

  const _SkeletonPill({required this.colorScheme});

  @override
  State<_SkeletonPill> createState() => _SkeletonPillState();
}

class _SkeletonPillState extends State<_SkeletonPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.35, end: 0.8).animate(_controller),
        child: Container(
          width: 110,
          height: 32,
          decoration: BoxDecoration(
            color: widget.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
