import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_colors.dart';

/// Circular initials avatar with a background colour that is a **stable hash
/// of the user id** into the app's fixed palette. Up to two initials are used;
/// `?` when the name is missing (deleted account). [size] should be larger
/// for root comments than for replies.
class CommentAvatar extends StatelessWidget {
  final String userId;
  final String? displayName;
  final double size;

  const CommentAvatar({
    Key? key,
    required this.userId,
    this.displayName,
    this.size = 36,
  }) : super(key: key);

  Color get _color {
    // Stable FNV-1a hash of the id → palette index.
    var hash = 0xcbf29ce484222325;
    for (final unit in userId.codeUnits) {
      hash = (hash ^ unit) * 0x100000001b3;
    }
    return TileColors.randomDefaultHues[
        hash % TileColors.randomDefaultHues.length];
  }

  String get _initials {
    final name = displayName?.trim() ?? '';
    if (name.isEmpty) {
      return '?';
    }
    final words =
        name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    }
    return name.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: colorScheme.onSurface,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
      ),
    );
  }
}