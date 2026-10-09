import 'package:flutter/material.dart';

/// A person in TileShare's rosters: the first letter of how they are shown,
/// in a circle - the same on Participants, the board and the tilette sheet.
class PersonAvatar extends StatelessWidget {
  final String label;
  final double radius;

  const PersonAvatar({super.key, required this.label, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      child: Text(label.isEmpty ? '?' : label[0].toUpperCase()),
    );
  }
}
