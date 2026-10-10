import 'package:flutter/material.dart';

/// A place for something that comes and goes - a banner, an alert, a warning,
/// a row of buttons (redesign T11, no snapping). What arrives grows and fades
/// in from nothing; what leaves shrinks and fades out, still showing, so what
/// is below slides instead of jumping. Empty, it takes no space. A child that
/// changes but keeps its key updates in place; one with a new key replaces
/// the old one the same way. What is there when the slot is first built is
/// simply shown.
class RevealSlot extends StatelessWidget {
  final Widget? child;

  const RevealSlot({super.key, this.child});

  static const Duration duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      // The old and the new share the space; the slot is as tall as the
      // taller of the two while they cross.
      layoutBuilder: (current, previous) => Stack(
        fit: StackFit.passthrough,
        alignment: AlignmentDirectional.topStart,
        children: [...previous, if (current != null) current],
      ),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: child ??
          const SizedBox(
              key: ValueKey<String>('reveal_slot_empty'),
              width: double.infinity),
    );
  }
}
