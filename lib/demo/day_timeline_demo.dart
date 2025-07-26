import 'package:flutter/material.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/widgets/day_timeline_view.dart';

/// Demo page showcasing the DayTimelineView widget
class DayTimelineDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mockEvents = _createMockEvents(now);

    return Scaffold(
      appBar: AppBar(
        title: Text('Day Timeline Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Toggle controls
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text('Forecast Mode Demo'),
                    Switch(
                      value: true,
                      onChanged: (value) {
                        // Toggle forecast mode in real implementation
                      },
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Timeline shows 8 AM - 6 PM. Scroll to see all events. Time axis scrolls with content.',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          // Timeline view
          Expanded(
            child: DayTimelineView(
              tilerEvents: mockEvents,
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

    // Late night flexible tile (bedtime routine)
    events.add(_createMockEvent(
      id: '0',
      name: 'Wind Down Time',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 22, 30),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 23, 0),
      isRigid: false,
      address: 'Home',
      colorRed: 63,
      colorGreen: 81,
      colorBlue: 181,
    ));

    // Early morning flexible tile (morning routine)
    events.add(_createMockEvent(
      id: '1',
      name: 'Morning Routine',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 7, 45),
      isRigid: false,
      address: 'Home',
      colorRed: 103,
      colorGreen: 58,
      colorBlue: 183,
    ));

    // Morning rigid block (breakfast meeting)
    events.add(_createMockEvent(
      id: '2',
      name: 'Breakfast Meeting',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 9, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 0),
      isRigid: true,
      address: 'Coffee Shop Downtown',
      colorRed: 255,
      colorGreen: 87,
      colorBlue: 87,
    ));

    // Mid-morning flexible tile (exercise)
    events.add(_createMockEvent(
      id: '3',
      name: 'Workout Session',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 10, 30),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 11, 30),
      isRigid: false,
      address: 'Local Gym',
      colorRed: 76,
      colorGreen: 175,
      colorBlue: 80,
    ));

    // Late night rigid block (movie night)
    events.add(_createMockEvent(
      id: '4',
      name: 'Movie Night',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 20, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 22, 0),
      isRigid: true,
      address: 'Home Theater',
      colorRed: 156,
      colorGreen: 39,
      colorBlue: 176,
    ));

    // Lunch rigid block
    events.add(_createMockEvent(
      id: '5',
      name: 'Team Lunch',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 12, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 13, 0),
      isRigid: true,
      address: 'Restaurant ABC',
      colorRed: 156,
      colorGreen: 39,
      colorBlue: 176,
    ));

    // Afternoon flexible tile (project work)
    events.add(_createMockEvent(
      id: '6',
      name: 'Project Development',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 14, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 16, 0),
      isRigid: false,
      colorRed: 33,
      colorGreen: 150,
      colorBlue: 243,
    ));

    // Late afternoon what-if event (forecast)
    events.add(_createMockEvent(
      id: '7',
      name: 'Client Call (Forecast)',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 15, 30),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 16, 30),
      isRigid: false,
      isWhatIf: true,
      colorRed: 255,
      colorGreen: 193,
      colorBlue: 7,
    ));

    // Evening rigid block (dinner appointment)
    events.add(_createMockEvent(
      id: '8',
      name: 'Dinner with Client',
      start: DateTime(baseDate.year, baseDate.month, baseDate.day, 18, 0),
      end: DateTime(baseDate.year, baseDate.month, baseDate.day, 20, 0),
      isRigid: true,
      address: 'Fine Dining Restaurant',
      colorRed: 121,
      colorGreen: 85,
      colorBlue: 72,
    ));

    return events;
  }

  TilerEvent _createMockEvent({
    required String id,
    required String name,
    required DateTime start,
    required DateTime end,
    bool isRigid = false,
    bool isWhatIf = false,
    String? address,
    int colorRed = 127,
    int colorGreen = 127,
    int colorBlue = 127,
  }) {
    final event = SubCalendarEvent(
      id: id,
      name: name,
      start: start.millisecondsSinceEpoch,
      end: end.millisecondsSinceEpoch,
      address: address,
    );

    // Set the properties using the private setters through reflection or direct assignment
    // Note: In a real implementation, you'd need proper access to these properties
    event.isWhatIf = isWhatIf;
    event.color = Color.fromARGB(
      255,
      colorRed.clamp(0, 255),
      colorGreen.clamp(0, 255),
      colorBlue.clamp(0, 255),
    );

    event.isRigid = isRigid;
    // event.colorBlue = colorBlue;
    // event.colorGreen = colorGreen;
    // event.colorRed = colorRed;

    return event;
  }
}
