import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';
import 'package:tiler_app/data/scheduleStatus.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

/// Generates dummy [SubCalendarEvent] tiles for the onboarding tutorial
/// so new users see a populated schedule instead of an empty day.
class TutorialDummyData {
  TutorialDummyData._();

  /// Sample tile definitions: (name, durationMinutes, colorR, colorG, colorB).
  static const List<(String, int, int, int, int)> _sampleTiles = [
    ('Morning Workout 🏋️', 60, 66, 133, 244),
    ('Team Standup 📞', 30, 255, 152, 0),
    ('Deep Work — Project Alpha 💻', 120, 76, 175, 80),
    ('Lunch Break 🍜', 45, 233, 30, 99),
    ('Review Design Docs 📝', 60, 156, 39, 176),
  ];

  /// Builds a list of dummy [SubCalendarEvent] tiles spread across today.
  static List<SubCalendarEvent> buildDummyTiles() {
    final now = DateTime.now();
    // Start tiles from 2 hours ago so some feel "current", but keep them on
    // the current day when the tutorial runs near midnight.
    final startHour = (now.hour - 2).clamp(0, 23).toInt();
    var cursor = DateTime(now.year, now.month, now.day, startHour);

    final List<SubCalendarEvent> tiles = [];
    for (int i = 0; i < _sampleTiles.length; i++) {
      final (name, durationMin, r, g, b) = _sampleTiles[i];
      final start = cursor;
      final end = cursor.add(Duration(minutes: durationMin));

      final tile = SubCalendarEvent.fromJson({
        'id': 'tutorial-tile-$i',
        'name': name,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
        'colorRed': r,
        'colorGreen': g,
        'colorBlue': b,
        'colorOpacity': 1.0,
        'thirdPartyType': 'tiler',
        'isRigid': false,
        'isComplete': false,
        'isEnabled': true,
        'isViable': true,
        'isPaused': false,
      });

      tiles.add(tile);

      // 15-minute gap between tiles
      cursor = end.add(const Duration(minutes: 15));
    }

    return tiles;
  }

  /// Injects dummy tiles into the [ScheduleBloc] so the daily view
  /// renders them during the tutorial.
  static void injectDummyTiles(BuildContext context) {
    final scheduleBloc = context.read<ScheduleBloc>();
    // Prevent real API fetches from overwriting our dummy tiles.
    scheduleBloc.tutorialMode = true;

    final todayTimeline = Utility.todayTimeline();
    scheduleBloc.add(
      ReloadLocalScheduleEvent(
        subEvents: buildDummyTiles(),
        timelines: <Timeline>[],
        lookupTimeline: todayTimeline,
        previousLookupTimeline: todayTimeline,
        scheduleStatus: ScheduleStatus(),
      ),
    );
  }

  /// Restores the real schedule by re-fetching from the API.
  static void restoreRealSchedule(BuildContext context) {
    final scheduleBloc = context.read<ScheduleBloc>();
    // Re-enable real schedule fetches.
    scheduleBloc.tutorialMode = false;
    scheduleBloc.add(
      GetScheduleEvent(forceRefresh: true),
    );
  }
}
