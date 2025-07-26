import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/styles.dart';

/// A timeline view that displays events for a single day
/// Distinguishes between rigid (blocks) and flexible (tiles) events
class DayTimelineView extends StatefulWidget {
  final List<TilerEvent> tilerEvents;
  final bool forecastMode;
  final DateTime? selectedDate;

  const DayTimelineView({
    Key? key,
    required this.tilerEvents,
    required this.forecastMode,
    this.selectedDate,
  }) : super(key: key);

  @override
  _DayTimelineViewState createState() => _DayTimelineViewState();
}

class _DayTimelineViewState extends State<DayTimelineView> {
  late Timer _timeUpdateTimer;
  DateTime _currentTime = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  // Timeline constants
  static const double _hourHeight = 80.0;
  static const int _startHour = 0; // 12:00 AM (midnight)
  static const int _endHour = 23; // 11:00 PM
  static const int _totalHours = _endHour - _startHour; // 23 hours of slots

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
      final currentHour = _currentTime.hour;
      final currentMinute = _currentTime.minute;

      // Calculate exact position including minutes
      final scrollPosition =
          (currentHour * _hourHeight) + (currentMinute / 60.0 * _hourHeight);

      // Offset to center the current time in view (subtract half screen height)
      final screenHeight = MediaQuery.of(context).size.height;
      final centeredPosition = scrollPosition - (screenHeight * 0.3);

      _scrollController.animateTo(
        math.max(0, centeredPosition), // Don't scroll above 0
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Container(
          height: (_endHour - _startHour + 1) *
              _hourHeight, // Include space for all hour markers
          child: Row(
            children: [
              // Time axis on the left (scrolls with content)
              TimelineAxis(
                startHour: _startHour,
                endHour: _endHour,
                hourHeight: _hourHeight,
                currentTime: _currentTime,
              ),
              // Events area
              Expanded(
                child: Stack(
                  children: [
                    // Hour divider lines
                    ..._buildHourDividers(),
                    // Current time indicator
                    NowIndicator(
                      currentTime: _currentTime,
                      startHour: _startHour,
                      hourHeight: _hourHeight,
                    ),
                    // Events
                    ..._buildEventCards(),
                    // Conflict overlays if in forecast mode
                    if (widget.forecastMode) ..._buildConflictOverlays(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHourDividers() {
    List<Widget> dividers = [];
    for (int i = 0; i <= _totalHours; i++) {
      dividers.add(
        Positioned(
          top: i * _hourHeight,
          left: 0,
          right: 0,
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      );
    }
    return dividers;
  }

  List<Widget> _buildEventCards() {
    List<Widget> eventCards = [];

    for (TilerEvent event in widget.tilerEvents) {
      if (_isEventOnSelectedDay(event)) {
        final card = _buildEventCard(event);
        if (card != null) {
          eventCards.add(card);
        }
      }
    }

    return eventCards;
  }

  bool _isEventOnSelectedDay(TilerEvent event) {
    final selectedDate = widget.selectedDate ?? DateTime.now();
    final eventStart = event.startTime;
    return eventStart.year == selectedDate.year &&
        eventStart.month == selectedDate.month &&
        eventStart.day == selectedDate.day;
  }

  Widget? _buildEventCard(TilerEvent event) {
    final startTime = event.startTime;
    final endTime = event.endTime;

    // Calculate position and height
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final timelineStartMinutes = _startHour * 60;
    final timelineEndMinutes =
        (_endHour + 1) * 60; // Include the last hour (23:59)

    // Check if event is within timeline bounds
    if (endMinutes <= timelineStartMinutes ||
        startMinutes >= timelineEndMinutes) {
      return null;
    }

    // Clamp to timeline bounds
    final clampedStartMinutes = math.max(startMinutes, timelineStartMinutes);
    final clampedEndMinutes = math.min(endMinutes, timelineEndMinutes);

    final topOffset =
        ((clampedStartMinutes - timelineStartMinutes) / 60.0) * _hourHeight;
    final height =
        ((clampedEndMinutes - clampedStartMinutes) / 60.0) * _hourHeight;

    return Positioned(
      top: topOffset,
      left: 8,
      right: 8,
      child: SizedBox(
        height: height,
        child: EventCard(
          event: event,
          isActive: _isEventActive(event),
          forecastMode: widget.forecastMode,
          progress: _calculateProgress(event),
        ),
      ),
    );
  }

  bool _isEventActive(TilerEvent event) {
    final now = _currentTime.millisecondsSinceEpoch;
    return event.start! <= now && event.end! > now;
  }

  double _calculateProgress(TilerEvent event) {
    if (!_isEventActive(event)) return 0.0;

    final now = _currentTime.millisecondsSinceEpoch;
    final start = event.start!;
    final end = event.end!;

    return (now - start) / (end - start);
  }

  List<Widget> _buildConflictOverlays() {
    List<Widget> overlays = [];

    final rigidEvents =
        widget.tilerEvents.where((e) => e.isRigid == true).toList();
    final flexibleEvents =
        widget.tilerEvents.where((e) => e.isRigid != true).toList();

    for (TilerEvent flexibleEvent in flexibleEvents) {
      for (TilerEvent rigidEvent in rigidEvents) {
        if (_eventsOverlap(flexibleEvent, rigidEvent) &&
            _isEventOnSelectedDay(rigidEvent)) {
          overlays.add(_buildConflictOverlay(rigidEvent, flexibleEvent));
        }
      }
    }

    return overlays;
  }

  bool _eventsOverlap(TilerEvent event1, TilerEvent event2) {
    return event1.start! < event2.end! && event2.start! < event1.end!;
  }

  Widget _buildConflictOverlay(
      TilerEvent rigidEvent, TilerEvent flexibleEvent) {
    final startTime = rigidEvent.startTime;
    final endTime = rigidEvent.endTime;

    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    final timelineStartMinutes = _startHour * 60;

    final topOffset =
        ((startMinutes - timelineStartMinutes) / 60.0) * _hourHeight;
    final height = ((endMinutes - startMinutes) / 60.0) * _hourHeight;

    return Positioned(
      top: topOffset,
      left: 8,
      right: 8,
      child: SizedBox(
        height: height,
        child: ConflictOverlay(),
      ),
    );
  }
}

/// Time axis widget showing hour markers
class TimelineAxis extends StatelessWidget {
  final int startHour;
  final int endHour;
  final double hourHeight;
  final DateTime currentTime;

  const TimelineAxis({
    Key? key,
    required this.startHour,
    required this.endHour,
    required this.hourHeight,
    required this.currentTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      child: Stack(
        children: [
          for (int hour = startHour; hour <= endHour; hour++)
            Positioned(
              top: (hour - startHour) * hourHeight,
              right: 8,
              child: Container(
                height: hourHeight,
                alignment: Alignment.topRight,
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  DateFormat.j().format(DateTime(2023, 1, 1, hour)),
                  style: TextStyle(
                    fontSize: 12,
                    color: hour == currentTime.hour
                        ? TileStyles.primaryColor
                        : Colors.grey.shade600,
                    fontWeight: hour == currentTime.hour
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Red line indicating current time
class NowIndicator extends StatelessWidget {
  final DateTime currentTime;
  final int startHour;
  final double hourHeight;

  const NowIndicator({
    Key? key,
    required this.currentTime,
    required this.startHour,
    required this.hourHeight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final timelineStartMinutes = startHour * 60;

    // Only show if current time is within timeline (always true for 24-hour view)
    final topOffset =
        ((currentMinutes - timelineStartMinutes) / 60.0) * hourHeight;

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.3),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget representing a single event (tile or block)
class EventCard extends StatelessWidget {
  final TilerEvent event;
  final bool isActive;
  final bool forecastMode;
  final double progress;

  const EventCard({
    Key? key,
    required this.event,
    required this.isActive,
    required this.forecastMode,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isRigid = event.isRigid == true;
    final color = _getEventColor();

    return Container(
      margin: EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isRigid ? color : color.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: isRigid
            ? null
            : Border.all(
                color: color,
                width: 1.5,
                style: BorderStyle.solid,
              ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Progress bar for active events
          if (isActive && progress > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8 * progress,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // Event content
          Padding(
            padding: EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  event.name ?? 'Unnamed Event',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isRigid ? FontWeight.bold : FontWeight.w500,
                    color: isRigid ? Colors.white : color,
                    fontFamily: TileStyles.rubikFontName,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (event.address?.isNotEmpty == true) ...[
                  SizedBox(height: 2),
                  Text(
                    event.address!,
                    style: TextStyle(
                      fontSize: 10,
                      color: isRigid ? Colors.white70 : color.withOpacity(0.7),
                      fontFamily: TileStyles.rubikFontName,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Rigid event indicator
          if (isRigid)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock,
                size: 12,
                color: Colors.white70,
              ),
            ),
          // Flexible event indicator
          if (!isRigid && forecastMode)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.schedule,
                size: 12,
                color: color,
              ),
            ),
        ],
      ),
    );
  }

  Color _getEventColor() {
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

/// Overlay showing conflicts between tiles and blocks
class ConflictOverlay extends StatelessWidget {
  const ConflictOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.warning,
          color: Colors.orange.shade700,
          size: 16,
        ),
      ),
    );
  }
}
