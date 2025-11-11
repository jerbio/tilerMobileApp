import 'package:flutter/material.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class OnboardingPillTag extends StatelessWidget {
  final String text;
  final bool isEnabled;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const OnboardingPillTag({
    Key? key,
    required this.text,
    this.isEnabled = true,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;

    final bool hasDelete = onDelete != null;
    final Color backgroundColor = isEnabled
        ? colorScheme.primary
        : tileThemeExtension.disabledOnboardingPill;
    final Color textColor = isEnabled
        ? colorScheme.onPrimary
        : tileThemeExtension.onDisabledOnboardingPill;

    return GestureDetector(
      onTap: hasDelete ? null : onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasDelete) ...[
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: EdgeInsets.all(
                 9
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),
            SizedBox(width: 8),
          ],
          Container(

            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(200),
            ),
            child: Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}