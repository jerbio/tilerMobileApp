import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/theme/tile_text_styles.dart';
import 'package:tiler_app/util.dart';

/// Day summary header that displays "Today" with day of week badge and date
class DaySummaryHeader extends StatelessWidget {
  final DateTime? date;

  const DaySummaryHeader({
    Key? key,
    this.date,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = date ?? Utility.currentTime();
    final dayOfWeek = DateFormat('EEEE').format(now); // e.g., "Monday"
    final monthDay = DateFormat('MMMM d').format(now); // e.g., "December 1"
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side - Date information
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.today,
                    style: TextStyle(
                      fontFamily: TileTextStyles.rubikFontName,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dayOfWeek,
                      style: TextStyle(
                        fontFamily: TileTextStyles.rubikFontName,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                monthDay,
                style: TextStyle(
                  fontFamily: TileTextStyles.rubikFontName,
                  fontSize: 15,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
