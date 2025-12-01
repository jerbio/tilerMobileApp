import 'package:flutter/material.dart';
import 'package:tiler_app/components/tileUI/enhancedTileCard.dart';
import 'package:tiler_app/components/tilelist/proactiveAlertBanner.dart';
import 'package:tiler_app/components/tilelist/travelConnector.dart';
import 'package:tiler_app/components/tilelist/timelineHourMarker.dart';
import 'package:tiler_app/components/tilelist/trafficAlertWidget.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/routes/authenticatedUser/analysis/daySummary.dart';
import 'package:tiler_app/util.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Timeline view that displays tiles alongside hour markers,
/// similar to a calendar day view with travel time between events.
class TimelineView extends StatefulWidget {
  final List<TilerEvent>? tiles;
  final TimelineSummary? dayData;
  final int? dayIndex;
  final Function(TilerEvent)? onTileTap;
  final VoidCallback? onAddWithAI;

  const TimelineView({
    Key? key,
    this.tiles,
    this.dayData,
    this.dayIndex,
    this.onTileTap,
    this.onAddWithAI,
  }) : super(key: key);

  @override
  State<TimelineView> createState() => _TimelineViewState();
}

class _TimelineViewState extends State<TimelineView> {
  final ScrollController _scrollController = ScrollController();
  late ThemeData theme;
  late ColorScheme colorScheme;

  // Traffic alert state (can be driven by real data)
  bool _showTrafficAlert = false;
  String? _trafficAlertMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTime();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    colorScheme = theme.colorScheme;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool get _isToday =>
      widget.dayIndex == Utility.currentTime().universalDayIndex;

  void _scrollToCurrentTime() {
    if (!_isToday || !mounted) return;

    final now = Utility.currentTime();
    final hourOffset = now.hour - 6; // Start from 6 AM
    if (hourOffset > 0) {
      final scrollOffset = hourOffset * 100.0; // Each hour row is ~100 pixels
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          scrollOffset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  SubCalendarEvent? _getNextDepartureTile() {
    if (widget.tiles == null) return null;

    final now = Utility.currentTime().millisecondsSinceEpoch;
    final orderedTiles = Utility.orderTiles(widget.tiles!);

    for (var tile in orderedTiles) {
      if (tile is SubCalendarEvent &&
          tile.start != null &&
          tile.start! > now &&
          (tile.travelTimeBefore ?? 0) > 0) {
        return tile;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final viableTiles = widget.tiles
            ?.whereType<SubCalendarEvent>()
            .where((t) => t.isViable ?? true)
            .toList() ??
        [];

    final orderedTilesList = Utility.orderTiles(viableTiles);
    final orderedSubEvents =
        orderedTilesList.whereType<SubCalendarEvent>().toList();
    final nextDepartureTile = _getNextDepartureTile();

    // Default traffic message
    const defaultTrafficMessage = 'Traffic detected - rerouting suggested';

    return Stack(
      children: [
        Column(
          children: [
            // Day summary header
            if (widget.dayData != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: DaySummary(dayTimelineSummary: widget.dayData!),
              ),

            // Proactive alert banner
            if (_isToday && nextDepartureTile != null)
              ProactiveAlertBanner(
                nextTileWithTravel: nextDepartureTile,
                onDismiss: () {},
              ),

            // Traffic alert
            if (_showTrafficAlert)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TrafficAlertWidget(
                  message: _trafficAlertMessage ?? defaultTrafficMessage,
                  type: TrafficAlertType.warning,
                  onTap: () {
                    // Open maps or reroute
                  },
                  onDismiss: () {
                    setState(() {
                      _showTrafficAlert = false;
                    });
                  },
                ),
              ),

            // Timeline content
            Expanded(
              child: RefreshIndicator(
                color: colorScheme.tertiary,
                onRefresh: () async {
                  // Trigger schedule refresh via bloc
                },
                child: orderedSubEvents.isEmpty
                    ? _buildEmptyState()
                    : _buildTimelineContent(orderedSubEvents),
              ),
            ),
          ],
        ),

        // Floating "Add with AI" button
        if (widget.onAddWithAI != null)
          Positioned(
            bottom: 24,
            right: 24,
            child: _buildAddWithAIButton(),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: colorScheme.outline.withOpacity(0.5),
          ),
          SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noTilesPreview,
            style: TextStyle(
              color: colorScheme.outline,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineContent(List<SubCalendarEvent> orderedTiles) {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.fromLTRB(0, 8, 0, 100),
      child: Column(
        children: _buildTimelineItems(orderedTiles),
      ),
    );
  }

  List<Widget> _buildTimelineItems(List<SubCalendarEvent> orderedTiles) {
    List<Widget> items = [];

    for (int i = 0; i < orderedTiles.length; i++) {
      final tile = orderedTiles[i];
      final tileStartTime = tile.startTime;

      // Add hour marker before tile if it's the first tile of that hour
      if (i == 0 || _isDifferentHour(orderedTiles[i - 1], tile)) {
        items.add(
          TimelineRow(
            startTime: tileStartTime,
            isCurrentHour: _isCurrentHour(tileStartTime),
            child: SizedBox.shrink(),
          ),
        );
      }

      // Add the tile card with timeline marker
      items.add(
        _buildTileRow(tile),
      );

      // Add travel connector between tiles
      if (i < orderedTiles.length - 1) {
        final nextTile = orderedTiles[i + 1];
        final hasTravelTime = (nextTile.travelTimeBefore ?? 0) > 0;

        if (hasTravelTime) {
          items.add(
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: TravelConnector(
                fromTile: tile,
                toTile: nextTile,
              ),
            ),
          );
        }
      }
    }

    return items;
  }

  Widget _buildTileRow(SubCalendarEvent tile) {
    final tileStartTime = tile.startTime;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 52,
            child: Text(
              _formatTime(tileStartTime),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: colorScheme.outline,
              ),
            ),
          ),

          // Timeline line with dot
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(tile.colorRed ?? 0xFF6B7AED),
                  border: Border.all(
                    color: colorScheme.surface,
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: colorScheme.outline.withOpacity(0.2),
              ),
            ],
          ),

          SizedBox(width: 8),

          // Tile card
          Expanded(
            child: GestureDetector(
              onTap: () => widget.onTileTap?.call(tile),
              child: EnhancedTileCard(subEvent: tile),
            ),
          ),
        ],
      ),
    );
  }

  bool _isDifferentHour(SubCalendarEvent prev, SubCalendarEvent current) {
    final prevStart = prev.startTime;
    final currStart = current.startTime;
    return prevStart.hour != currStart.hour;
  }

  bool _isCurrentHour(DateTime time) {
    if (!_isToday) return false;
    final now = Utility.currentTime();
    return now.hour == time.hour;
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    if (minute == 0) {
      return '$displayHour $period';
    }
    return '$displayHour:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildAddWithAIButton() {
    // Fallback text if localization not available
    const addWithAIText = 'Add with AI';

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(28),
      color: colorScheme.primary,
      child: InkWell(
        onTap: widget.onAddWithAI,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                color: colorScheme.onPrimary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                addWithAIText,
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
