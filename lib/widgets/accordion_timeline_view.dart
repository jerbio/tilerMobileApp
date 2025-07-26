import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';

// =============================================================================
// TIME UI COMPONENTS - Easily identifiable time-related widgets
// =============================================================================
// 1. TimeDisplayWidget - For showing start/end times with consistent formatting
// 2. DurationDisplayWidget - For showing duration in minutes with visual styling
// 3. TravelTimeIndicatorWidget - For showing travel time with icons and context
// 4. _buildTimeAxisMarker - Inline time axis markers with threading line
// These widgets provide:
// - Consistent visual styling across all time displays
// - Easy identification and modification of time-related UI elements
// - Reusable components that can be styled based on context (active, conflicts, etc.)
// - Centralized time formatting and display logic
// - Synchronized scrolling of time axis with main content
// =============================================================================

/// A reusable time display widget that can be easily identified and styled consistently
class TimeDisplayWidget extends StatelessWidget {
  final DateTime startTime;
  final DateTime? endTime;
  final Color primaryColor;
  final Color? secondaryColor;
  final double primaryFontSize;
  final double secondaryFontSize;
  final FontWeight fontWeight;
  final double? width;
  final bool isActive;

  const TimeDisplayWidget({
    Key? key,
    required this.startTime,
    this.endTime,
    required this.primaryColor,
    this.secondaryColor,
    this.primaryFontSize = 12,
    this.secondaryFontSize = 10,
    this.fontWeight = FontWeight.bold,
    this.width = 60,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveSecondaryColor = secondaryColor ??
        (primaryColor == Colors.white ? Colors.white70 : Colors.grey.shade600);

    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 2),
      decoration: isActive
          ? BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.jm().format(startTime),
            style: TextStyle(
              fontSize: primaryFontSize,
              fontWeight: fontWeight,
              color: primaryColor,
              fontFamily: TileStyles.rubikFontName,
            ),
          ),
          if (endTime != null)
            Text(
              DateFormat.jm().format(endTime!),
              style: TextStyle(
                fontSize: secondaryFontSize,
                color: effectiveSecondaryColor,
                fontFamily: TileStyles.rubikFontName,
              ),
            ),
        ],
      ),
    );
  }
}

/// A reusable duration display widget for showing time durations in a consistent format
class DurationDisplayWidget extends StatelessWidget {
  final Duration duration;
  final Color color;
  final double fontSize;
  final FontWeight fontWeight;
  final double? width;
  final bool isActive;

  const DurationDisplayWidget({
    Key? key,
    required this.duration,
    required this.color,
    this.fontSize = 10,
    this.fontWeight = FontWeight.w500,
    this.width = 50,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: isActive
          ? BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            )
          : null,
      child: Text(
        '${duration.inMinutes}min',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          fontFamily: TileStyles.rubikFontName,
        ),
      ),
    );
  }
}

/// A reusable travel time indicator widget for showing travel durations
class TravelTimeIndicatorWidget extends StatelessWidget {
  final int minutes;
  final bool isBefore;
  final Color color;
  final double fontSize;
  final double iconSize;

  const TravelTimeIndicatorWidget({
    Key? key,
    required this.minutes,
    required this.isBefore,
    this.color = const Color(0xFFFFFFFF),
    this.fontSize = 10,
    this.iconSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color == Colors.white ? Colors.white70 : color.withOpacity(0.7);

    return Container(
      padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: effectiveColor.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBefore ? Icons.departure_board : Icons.directions_car,
            size: iconSize,
            color: effectiveColor,
          ),
          SizedBox(width: 4),
          Text(
            '${isBefore ? 'Travel to' : 'Travel from'}: ${minutes}min',
            style: TextStyle(
              fontSize: fontSize,
              color: effectiveColor,
              fontFamily: TileStyles.rubikFontName,
            ),
          ),
        ],
      ),
    );
  }
}

/// An accordion-style timeline view that clearly separates rigid blocks from flexible tiles
/// Blocks are shown as fixed time slots, tiles are shown as expandable accordions
class AccordionTimelineView extends StatefulWidget {
  final List<TilerEvent> tilerEvents;
  final bool forecastMode;
  final DateTime? selectedDate;

  const AccordionTimelineView({
    Key? key,
    required this.tilerEvents,
    required this.forecastMode,
    this.selectedDate,
  }) : super(key: key);

  @override
  _AccordionTimelineViewState createState() => _AccordionTimelineViewState();
}

class _AccordionTimelineViewState extends State<AccordionTimelineView> {
  late Timer _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();
  final ScrollController _scrollController = ScrollController();
  final Set<String> _expandedTiles = <String>{};

  @override
  void initState() {
    super.initState();
    _setupTimeUpdater();
    _scrollToCurrentTime();
  }

  @override
  void dispose() {
    _timeUpdateTimer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupTimeUpdater() {
    _timeUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  void _scrollToCurrentTime() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Find the current time block and scroll to it
      final timelineItems = _buildTimelineItems();
      double scrollPosition = 0;

      for (int i = 0; i < timelineItems.length; i++) {
        final item = timelineItems[i];
        if (item.isCurrentTime) {
          scrollPosition = i * 120.0; // Approximate item height
          break;
        }
      }

      _scrollController.animateTo(
        math.max(0, scrollPosition - 200), // Center with offset
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineItems = _buildTimelineItems();

    return Container(
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: timelineItems.length,
        itemBuilder: (context, index) {
          final item = timelineItems[index];
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // External time axis marker for this item
                _buildTimeAxisMarker(item, index == timelineItems.length - 1),
                SizedBox(width: 8),
                // Main timeline content
                Expanded(
                  child: _buildTimelineItem(item),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<TimelineItem> _buildTimelineItems() {
    final selectedDate = widget.selectedDate ?? DateTime.now();
    final items = <TimelineItem>[];

    // Get events for the selected day
    final dayEvents = widget.tilerEvents
        .where((event) => _isEventOnSelectedDay(event))
        .toList();

    // Separate and sort all events by start time
    final allEvents = dayEvents
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (allEvents.isEmpty) {
      // No events - add single free time block for active hours
      items.add(TimelineItem(
        type: TimelineItemType.freeTimeBlock,
        timeSlot: DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, 6),
        endTime: DateTime(
            selectedDate.year, selectedDate.month, selectedDate.day, 22),
        isCurrentTime: _isCurrentTimeInRange(
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6),
          DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22),
        ),
      ));
      return items;
    }

    DateTime dayStart =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 6);
    DateTime dayEnd =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 22);

    // Add free time before first event if needed
    if (allEvents.first.startTime.isAfter(dayStart)) {
      items.add(TimelineItem(
        type: TimelineItemType.freeTimeBlock,
        timeSlot: dayStart,
        endTime: allEvents.first.startTime,
        isCurrentTime:
            _isCurrentTimeInRange(dayStart, allEvents.first.startTime),
      ));
    }

    // Process each event and gaps between them
    for (int i = 0; i < allEvents.length; i++) {
      final event = allEvents[i];

      // Add the event (rigid block or tile group)
      if (event.isRigid == true) {
        items.add(TimelineItem(
          type: TimelineItemType.rigidBlock,
          event: event,
          timeSlot: event.startTime,
          isCurrentTime: _isTimeWithinEvent(event, _currentTime),
        ));
      } else {
        // Group consecutive flexible tiles
        final tileGroup = [event];
        DateTime groupEndTime = event.endTime;

        // Look ahead for consecutive tiles
        int j = i + 1;
        while (j < allEvents.length &&
            allEvents[j].isRigid != true &&
            allEvents[j].startTime.difference(groupEndTime).inMinutes <= 30) {
          tileGroup.add(allEvents[j]);
          groupEndTime = allEvents[j].endTime.isAfter(groupEndTime)
              ? allEvents[j].endTime
              : groupEndTime;
          j++;
        }

        items.add(TimelineItem(
          type: TimelineItemType.tileGroup,
          tiles: tileGroup,
          timeSlot: event.startTime,
          endTime: groupEndTime,
          isCurrentTime:
              tileGroup.any((tile) => _isTimeWithinEvent(tile, _currentTime)),
        ));

        // Skip the processed tiles
        i = j - 1;
      }

      // Add free time gap to next event if exists and significant
      if (i < allEvents.length - 1) {
        final currentEventEnd = event.isRigid == true
            ? event.endTime
            : (items.last.endTime ?? event.endTime);
        final nextEventStart = allEvents[i + 1].startTime;

        final gapDuration = nextEventStart.difference(currentEventEnd);
        if (gapDuration.inMinutes > 15) {
          // Only show gaps > 15 minutes
          items.add(TimelineItem(
            type: TimelineItemType.freeTimeBlock,
            timeSlot: currentEventEnd,
            endTime: nextEventStart,
            isCurrentTime:
                _isCurrentTimeInRange(currentEventEnd, nextEventStart),
          ));
        }
      }
    }

    // Add free time after last event if needed
    final lastEventEnd = allEvents.last.endTime;
    if (lastEventEnd.isBefore(dayEnd)) {
      items.add(TimelineItem(
        type: TimelineItemType.freeTimeBlock,
        timeSlot: lastEventEnd,
        endTime: dayEnd,
        isCurrentTime: _isCurrentTimeInRange(lastEventEnd, dayEnd),
      ));
    }

    return items;
  }

  Widget _buildTimeAxisMarker(TimelineItem item, bool isLast) {
    final isActive = item.isCurrentTime;
    final startTime = item.timeSlot;
    final endTime = item.endTime ?? item.event?.endTime;

    return Container(
      width: 80,
      child: Column(
        children: [
          // Time display container
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            margin: EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? TileStyles.primaryColor.withOpacity(0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isActive ? TileStyles.primaryColor : Colors.grey.shade300,
                width: isActive ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat.jm().format(startTime),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? TileStyles.primaryColor
                        : Colors.grey.shade700,
                    fontFamily: TileStyles.rubikFontName,
                  ),
                ),
                if (endTime != null && endTime != startTime) ...[
                  Container(
                    width: 20,
                    height: 1,
                    color: Colors.grey.shade400,
                    margin: EdgeInsets.symmetric(vertical: 2),
                  ),
                  Text(
                    DateFormat.jm().format(endTime),
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                      fontFamily: TileStyles.rubikFontName,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Threading line and dot
          if (!isLast)
            Expanded(
              child: Stack(
                children: [
                  // Continuous threading line
                  Positioned(
                    left: 38,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            TileStyles.primaryColor.withOpacity(0.6),
                            TileStyles.primaryColor.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Connection dot
                  Positioned(
                    left: 37,
                    top: 8,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? TileStyles.primaryColor
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                  // Current time indicator
                  if (isActive)
                    Positioned(
                      left: 30,
                      top: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: TileStyles.primaryColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.schedule,
                          size: 12,
                          color: TileStyles.primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isEventOnSelectedDay(TilerEvent event) {
    final selectedDate = widget.selectedDate ?? DateTime.now();
    final eventStart = event.startTime;
    return eventStart.year == selectedDate.year &&
        eventStart.month == selectedDate.month &&
        eventStart.day == selectedDate.day;
  }

  bool _isTimeWithinEvent(TilerEvent event, DateTime time) {
    return time.isAfter(event.startTime.subtract(Duration(minutes: 1))) &&
        time.isBefore(event.endTime);
  }

  bool _isCurrentTimeInRange(DateTime startTime, DateTime endTime) {
    return _currentTime.isAfter(startTime.subtract(Duration(minutes: 1))) &&
        _currentTime.isBefore(endTime);
  }

  // Conflict detection methods
  bool _hasConflicts(TilerEvent event) {
    if (!widget.forecastMode) return false;

    final conflictingEvents = widget.tilerEvents
        .where((otherEvent) =>
            otherEvent.id != event.id && _eventsOverlap(event, otherEvent))
        .toList();

    return conflictingEvents.isNotEmpty;
  }

  bool _eventsOverlap(TilerEvent event1, TilerEvent event2) {
    return event1.startTime.isBefore(event2.endTime) &&
        event2.startTime.isBefore(event1.endTime);
  }

  List<TilerEvent> _getConflictingEvents(TilerEvent event) {
    return widget.tilerEvents
        .where((otherEvent) =>
            otherEvent.id != event.id && _eventsOverlap(event, otherEvent))
        .toList();
  }

  ConflictSeverity _getConflictSeverity(TilerEvent event) {
    final conflicts = _getConflictingEvents(event);
    if (conflicts.isEmpty) return ConflictSeverity.none;

    final hasRigidConflict = conflicts.any((e) => e.isRigid == true);
    return hasRigidConflict ? ConflictSeverity.high : ConflictSeverity.medium;
  }

  String _getConflictDescription(TilerEvent event) {
    final conflicts = _getConflictingEvents(event);
    if (conflicts.isEmpty) return '';

    final rigidConflicts = conflicts.where((e) => e.isRigid == true).length;
    final flexibleConflicts = conflicts.where((e) => e.isRigid != true).length;

    if (rigidConflicts > 0 && flexibleConflicts > 0) {
      return '${rigidConflicts} rigid + ${flexibleConflicts} flexible conflicts';
    } else if (rigidConflicts > 0) {
      return '$rigidConflicts rigid conflict${rigidConflicts > 1 ? 's' : ''}';
    } else {
      return '$flexibleConflicts flexible conflict${flexibleConflicts > 1 ? 's' : ''}';
    }
  }

  Color _getConflictBorderColor(ConflictSeverity severity, int conflictCount) {
    switch (severity) {
      case ConflictSeverity.high:
        // More intense red for multiple high-severity conflicts
        return conflictCount > 2 ? Colors.red.shade800 : Colors.red.shade600;
      case ConflictSeverity.medium:
        // More intense orange for multiple medium-severity conflicts
        return conflictCount > 2
            ? Colors.deepOrange.shade700
            : Colors.orange.shade600;
      default:
        return Colors.transparent;
    }
  }

  Widget _buildTimelineItem(TimelineItem item) {
    switch (item.type) {
      case TimelineItemType.rigidBlock:
        return _buildRigidBlockCard(item);
      case TimelineItemType.tileGroup:
        return _buildTileGroupAccordion(item);
      case TimelineItemType.freeTimeBlock:
        return _buildFreeTimeBlockAccordion(item);
      case TimelineItemType.emptySlot:
        return _buildEmptySlotCard(item);
    }
  }

  Widget _buildRigidBlockCard(TimelineItem item) {
    final event = item.event!;
    final isActive = item.isCurrentTime;
    final color = _getEventColor(event);
    final hasConflicts = _hasConflicts(event);
    final conflictSeverity = _getConflictSeverity(event);
    final conflictingEvents = _getConflictingEvents(event);
    final conflictCount = conflictingEvents.length;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: hasConflicts
            ? Border.all(
                color: _getConflictBorderColor(conflictSeverity, conflictCount),
                width: conflictCount > 2
                    ? 4
                    : 3, // Thicker border for multiple conflicts
              )
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : hasConflicts
                ? [
                    BoxShadow(
                      color: _getConflictBorderColor(
                              conflictSeverity, conflictCount)
                          .withOpacity(0.4),
                      blurRadius: conflictCount > 2
                          ? 12
                          : 8, // More blur for multiple conflicts
                      spreadRadius: conflictCount > 2 ? 3 : 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
      ),
      child: Stack(
        children: [
          // Main content
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                // Event details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.name ?? 'Unnamed Block',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: TileStyles.rubikFontName,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (event.address?.isNotEmpty == true) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.white70,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.address!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                  fontFamily: TileStyles.rubikFontName,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Travel time if available
                      if (event.travelTimeBefore != null &&
                          event.travelTimeBefore! > 0) ...[
                        SizedBox(height: 8),
                        TravelTimeIndicatorWidget(
                          minutes: event.travelTimeBefore!,
                          isBefore: true,
                          color: Colors.white,
                        ),
                      ],
                      if (event.travelTimeAfter != null &&
                          event.travelTimeAfter! > 0) ...[
                        SizedBox(height: 4),
                        TravelTimeIndicatorWidget(
                          minutes: event.travelTimeAfter!,
                          isBefore: false,
                          color: Colors.white,
                        ),
                      ],
                    ],
                  ),
                ),
                // Progress indicator for active events
                if (isActive)
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
          // Conflict indicator icon with count and tooltip
          if (hasConflicts)
            Positioned(
              top: 8,
              right: 8,
              child: Tooltip(
                message: _getConflictDescription(event),
                child: Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getConflictBorderColor(
                            conflictSeverity, conflictCount),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        conflictSeverity == ConflictSeverity.high
                            ? Icons.warning
                            : Icons.info,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    // Show conflict count for multiple conflicts
                    if (conflictCount > 1)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: conflictSeverity == ConflictSeverity.high
                                ? Colors.red.shade800
                                : Colors.deepOrange.shade800,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            conflictCount > 9 ? '9+' : conflictCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTileGroupAccordion(TimelineItem item) {
    final tiles = item.tiles!;
    final groupId = 'group_${item.timeSlot.millisecondsSinceEpoch}';
    final isExpanded = _expandedTiles.contains(groupId);
    final isActive = item.isCurrentTime;

    // Check if any tiles in the group have conflicts and count total conflicts
    final hasGroupConflicts = tiles.any((tile) => _hasConflicts(tile));
    final groupConflictSeverity = tiles
        .map((tile) => _getConflictSeverity(tile))
        .reduce((current, next) => next.index > current.index ? next : current);

    // Count total conflicts in the group
    final totalGroupConflicts = tiles
        .map((tile) => _getConflictingEvents(tile).length)
        .fold(0, (sum, count) => sum + count);

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasGroupConflicts
              ? _getConflictBorderColor(
                  groupConflictSeverity, totalGroupConflicts)
              : TileStyles.primaryColor.withOpacity(0.3),
          width: hasGroupConflicts ? (totalGroupConflicts > 3 ? 3 : 2) : 1,
        ),
        boxShadow: hasGroupConflicts
            ? [
                BoxShadow(
                  color: _getConflictBorderColor(
                          groupConflictSeverity, totalGroupConflicts)
                      .withOpacity(0.3),
                  blurRadius: totalGroupConflicts > 3 ? 8 : 6,
                  spreadRadius: totalGroupConflicts > 3 ? 2 : 1,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          // Accordion header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedTiles.remove(groupId);
                } else {
                  _expandedTiles.add(groupId);
                }
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? TileStyles.primaryColor.withOpacity(0.1)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  // Tiles summary
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: TileStyles.primaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${tiles.length} Flexible Tile${tiles.length > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: TileStyles.primaryColor,
                                fontFamily: TileStyles.rubikFontName,
                              ),
                            ),
                            // Conflict indicator for tile group with count
                            if (hasGroupConflicts) ...[
                              SizedBox(width: 8),
                              Stack(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: _getConflictBorderColor(
                                          groupConflictSeverity,
                                          totalGroupConflicts),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      groupConflictSeverity ==
                                              ConflictSeverity.high
                                          ? Icons.warning
                                          : Icons.info,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                  // Show total conflict count for the group
                                  if (totalGroupConflicts > 1)
                                    Positioned(
                                      top: -2,
                                      right: -2,
                                      child: Container(
                                        padding: EdgeInsets.all(1),
                                        decoration: BoxDecoration(
                                          color: groupConflictSeverity ==
                                                  ConflictSeverity.high
                                              ? Colors.red.shade800
                                              : Colors.deepOrange.shade800,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white, width: 1),
                                        ),
                                        constraints: BoxConstraints(
                                          minWidth: 14,
                                          minHeight: 14,
                                        ),
                                        child: Text(
                                          totalGroupConflicts > 9
                                              ? '9+'
                                              : totalGroupConflicts.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          tiles.map((t) => t.name ?? 'Unnamed').join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: TileStyles.rubikFontName,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: TileStyles.primaryColor,
                  ),
                ],
              ),
            ),
          ),
          // Accordion content
          if (isExpanded)
            Container(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: tiles.map((tile) => _buildTileCard(tile)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFreeTimeBlockAccordion(TimelineItem item) {
    final freeTimeId = 'free_${item.timeSlot.millisecondsSinceEpoch}';
    final isExpanded = _expandedTiles.contains(freeTimeId);
    final isActive = item.isCurrentTime;
    final duration = item.endTime!.difference(item.timeSlot);

    return Container(
          margin: EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.green.shade300 : Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Accordion header
              InkWell(
                onTap: () {
                  setState(() {
                    if (isExpanded) {
                      _expandedTiles.remove(freeTimeId);
                    } else {
                      _expandedTiles.add(freeTimeId);
                    }
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        isActive ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Free time summary
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.free_breakfast,
                                  size: 16,
                                  color: isActive
                                      ? Colors.green.shade600
                                      : Colors.grey.shade500,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Free Time (${_formatDuration(duration)})',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? Colors.green.shade700
                                        : Colors.grey.shade600,
                                    fontFamily: TileStyles.rubikFontName,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Available for new tasks or break time',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontFamily: TileStyles.rubikFontName,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Expand/collapse icon
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: isActive
                            ? Colors.green.shade600
                            : Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
              // Accordion content
              if (isExpanded)
                Container(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 16,
                              color: Colors.blue.shade600,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perfect time to schedule flexible tasks, take breaks, or handle unexpected items.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                  fontFamily: TileStyles.rubikFontName,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildTileCard(TilerEvent tile) {
    final color = _getEventColor(tile);
    final isActive = _isTimeWithinEvent(tile, _currentTime);
    final hasConflicts = _hasConflicts(tile);
    final conflictSeverity = _getConflictSeverity(tile);
    final conflictingEvents = _getConflictingEvents(tile);
    final conflictCount = conflictingEvents.length;

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(
          color: hasConflicts
              ? _getConflictBorderColor(conflictSeverity, conflictCount)
              : color.withOpacity(0.3),
          width: hasConflicts ? (conflictCount > 2 ? 3 : 2) : 1,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: hasConflicts
            ? [
                BoxShadow(
                  color:
                      _getConflictBorderColor(conflictSeverity, conflictCount)
                          .withOpacity(0.3),
                  blurRadius: conflictCount > 2 ? 6 : 4,
                  spreadRadius: conflictCount > 2 ? 2 : 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Duration
          DurationDisplayWidget(
            duration: tile.endTime.difference(tile.startTime),
            color: color,
            isActive: isActive,
          ),
          SizedBox(width: 12),
          // Tile details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tile.name ?? 'Unnamed Tile',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontFamily: TileStyles.rubikFontName,
                        ),
                      ),
                    ),
                    // Conflict indicator with count
                    if (hasConflicts) ...[
                      SizedBox(width: 8),
                      Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: _getConflictBorderColor(
                                  conflictSeverity, conflictCount),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              conflictSeverity == ConflictSeverity.high
                                  ? Icons.warning
                                  : Icons.info,
                              size: 10,
                              color: Colors.white,
                            ),
                          ),
                          // Show conflict count for multiple conflicts
                          if (conflictCount > 1)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                padding: EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color:
                                      conflictSeverity == ConflictSeverity.high
                                          ? Colors.red.shade800
                                          : Colors.deepOrange.shade800,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 0.5),
                                ),
                                constraints: BoxConstraints(
                                  minWidth: 12,
                                  minHeight: 12,
                                ),
                                child: Text(
                                  conflictCount > 9
                                      ? '9+'
                                      : conflictCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
                if (tile.address?.isNotEmpty == true) ...[
                  SizedBox(height: 2),
                  Text(
                    tile.address!,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontFamily: TileStyles.rubikFontName,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Active indicator
          if (isActive)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotCard(TimelineItem item) {
    final isActive = item.isCurrentTime;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? Colors.blue.shade200 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Available slot indicator
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Available for scheduling',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                      fontFamily: TileStyles.rubikFontName,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getEventColor(TilerEvent event) {
    if (event.colorRed != null &&
        event.colorGreen != null &&
        event.colorBlue != null) {
      return Color.fromRGBO(
        event.colorRed!,
        event.colorGreen!,
        event.colorBlue!,
        1.0,
      );
    }
    return TileStyles.primaryColor;
  }
}

// Data models for timeline items
enum TimelineItemType {
  rigidBlock,
  tileGroup,
  freeTimeBlock, // New type for contiguous free time
  emptySlot,
}

enum ConflictSeverity {
  none,
  medium, // Flexible tiles overlapping
  high, // Rigid blocks conflicting
}

class TimelineItem {
  final TimelineItemType type;
  final TilerEvent? event; // For rigid blocks
  final List<TilerEvent>? tiles; // For tile groups
  final DateTime timeSlot;
  final DateTime? endTime; // For free time blocks and tile groups
  final bool isCurrentTime;

  TimelineItem({
    required this.type,
    this.event,
    this.tiles,
    required this.timeSlot,
    this.endTime,
    this.isCurrentTime = false,
  });
}

// Extension to add travel time properties
// Note: These should be added to the actual TilerEvent model when available
extension TilerEventTravel on TilerEvent {
  // For now, return null until travel time is added to the model
  // You can replace these with actual properties when they're available
  int? get travelTimeBefore => null;
  int? get travelTimeAfter => null;
}
