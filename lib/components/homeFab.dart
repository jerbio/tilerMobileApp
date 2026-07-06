import 'package:flutter/material.dart';
import 'package:tiler_app/components/tutorial/tutorialKeys.dart';
import 'package:tiler_app/l10n/app_localizations.dart';

/// Floating action button used on the home screen.
///
/// Always shows the chat icon and fires [onPressed] when tapped.
/// The previous dual-state logic (Tiler logo ↔ chat icon based on
/// VibeChatStep) has been replaced by this simpler, single-purpose widget.
class HomeFab extends StatelessWidget {
  final VoidCallback onPressed;

  const HomeFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return FloatingActionButton(
      key: TutorialKeys.fabKey,
      backgroundColor: colorScheme.surface,
      shape: const CircleBorder(),
      onPressed: onPressed,
      tooltip: AppLocalizations.of(context)!.openChat,
      child: Icon(Icons.chat_outlined, color: colorScheme.primary),
    );
  }
}
