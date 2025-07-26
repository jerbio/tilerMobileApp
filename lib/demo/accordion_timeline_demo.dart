import 'package:flutter/material.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/widgets/accordion_timeline_view.dart';
import 'package:tiler_app/styles.dart';

class AccordionTimelineDemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Accordion Timeline Demo',
          style: TextStyle(
            fontFamily: TileStyles.rubikFontName,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TileStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Header info
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                Text(
                  'Accordion Timeline View Demo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: TileStyles.rubikFontName,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'This accordion-style timeline clearly separates:\n'
                  '🔒 Rigid blocks (fixed appointments)\n'
                  '📋 Flexible tiles (grouped in accordions)\n'
                  '🆓 Free time blocks (collapsible available periods)\n'
                  '🔗 Connecting lines between timeline blocks\n'
                  '⏰ Synchronized time axis with threading line\n'
                  '⏱️ Travel time information\n'
                  '⚠️ Visual conflict indicators (borders, icons, shadows)\n'
                  '✨ Current time highlighting\n'
                  '📍 Time components scroll with main content\n'
                  '🧵 Continuous threading line through all times',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: TileStyles.rubikFontName,
                  ),
                ),
              ],
            ),
          ),
          // Timeline
          Expanded(
            child: AccordionTimelineView(
              tilerEvents: _createMockEvents(now),
              forecastMode: true,
              selectedDate: now,
            ),
          ),
        ],
      ),
    );
  }

  List<TilerEvent> _createMockEvents(DateTime baseDate) {
    final events = <TilerEvent>[];

    // Early morning tiles group
    events.add(_createMockEvent(
      id: '1',
      name: 'Morning Meditation',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 6, 30),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0),
      isRigid: false,
      address: 'Home',
      colorRed: 103,
      colorGreen: 58,
      colorBlue: 183,
    ));

    events.add(_createMockEvent(
      id: '2',
      name: 'Exercise Routine',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 15),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 8, 15),
      isRigid: false,
      address: 'Home Gym',
      colorRed: 76,
      colorGreen: 175,
      colorBlue: 80,
    ));

    // Rigid block - Morning meeting
    events.add(_createMockEvent(
      id: '4',
      name: 'Team Standup Meeting',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 30),
      isRigid: true,
      address: 'Conference Room A',
      colorRed: 255,
      colorGreen: 87,
      colorBlue: 87,
    ));

    // Mid-morning tiles group
    events.add(_createMockEvent(
      id: '5',
      name: 'Email Review',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 30),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 11, 0),
      isRigid: false,
      colorRed: 33,
      colorGreen: 150,
      colorBlue: 243,
    ));

    // Rigid block - Lunch appointment
    events.add(_createMockEvent(
      id: '7',
      name: 'Client Lunch Meeting',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 13, 30),
      isRigid: true,
      address: 'Downtown Restaurant',
      colorRed: 156,
      colorGreen: 39,
      colorBlue: 176,
    ));

    return events;
  }

  TilerEvent _createMockEvent({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
    required bool isRigid,
    String? address,
    int? colorRed,
    int? colorGreen,
    int? colorBlue,
  }) {
    // Create a mock TilerEvent
    final event = TilerEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      address: address,
    );

    // Set rigid flag and color using the available setters
    event.isRigid = isRigid;
    if (colorRed != null && colorGreen != null && colorBlue != null) {
      event.color = Color.fromRGBO(colorRed, colorGreen, colorBlue, 1.0);
    }

    return event;
  }
}
