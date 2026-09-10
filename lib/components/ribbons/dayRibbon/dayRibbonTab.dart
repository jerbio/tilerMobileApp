// Today's day ribbon becomes a collapsed
// tap-to-expand tab instead of the hard hide (SizedBox.shrink) that
// AuthorizedRoute._ribbonCarousel applied when viewing today.
//
// The tab renders a slim handle (chevron + label); tapping it expands the
// full DayRibbonCarousel in place. It collapses again on re-tap or as soon
// a day is selected — any UiDateManagerBloc date change routes through the
// same path as the ribbon's day buttons, so the tab folds back automatically.
// It renders identically in list and grid modes; list-mode today keeps its
// embedded EnhancedWithinNowBatch summary and grid mode the now-line.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/uiDateManager/ui_date_manager_bloc.dart';
import 'package:tiler_app/components/ribbons/dayRibbon/dayRibbonCarousel.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

/// The expanded ribbon's visible footprint in the app: its 50px top margin +
/// 130px banner (see DayRibbonCarousel). The expanded tab clamps the ribbon
/// to this height so the banner overlays the day view instead of stretching
/// it (in the app the ribbon is a Stack overlay and never pushes content).
const double _expandedRibbonHeight = 180;

/// Collapsed tap-to-expand wrapper around [DayRibbonCarousel] for today.
class DayRibbonTab extends StatefulWidget {
  /// The date the ribbon should anchor on — today, per the parent contract.
  final DateTime dayRibbonDate;

  const DayRibbonTab({
    super.key,
    required this.dayRibbonDate,
  });

  @override
  State<DayRibbonTab> createState() => _DayRibbonTabState();
}

class _DayRibbonTabState extends State<DayRibbonTab> {
  bool _expanded = false;
  StreamSubscription<UiDateManagerState>? _dateSubscription;

  @override
  void initState() {
    super.initState();
    // Collapse on selection: the day buttons, swipe pages, and go-to-today
    // all route DateChangeEvent through UiDateManagerBloc, so a date change
    // while the ribbon is open means the user picked a day and the ribbon
    // is no longer needed. (Selecting the same day is a no-op in the bloc,
    // matching the existing ribbon behavior.)
    _dateSubscription = context.read<UiDateManagerBloc>().stream.listen((_) {
      if (!mounted || !_expanded) return;
      setState(() => _expanded = false);
    });
  }

  @override
  void dispose() {
    _dateSubscription?.cancel();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
    if (_expanded) {
      AnalysticsSignal.send('daygrid_ribbon_expanded');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final tileThemeExtension =
        Theme.of(context).extension<TileThemeExtension>()!;

    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The handle stays mounted in both states so re-tap collapses.
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: tileThemeExtension.shadowSecondary
                      .withValues(alpha: 0.08),
                  blurRadius: 7,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: InkWell(
              key: const Key('dayRibbonTabHandle'),
              borderRadius: BorderRadius.circular(16),
              onTap: _toggleExpanded,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                      color: colorScheme.onSurface.withAlpha(153),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.openDayRibbon,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withAlpha(204),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded)
            SizedBox(
              height: _expandedRibbonHeight,
              width: double.infinity,
              child: DayRibbonCarousel(
                widget.dayRibbonDate,
                autoUpdateAnchorDate: false,
              ),
            ),
        ],
      ),
    );
  }
}