import 'package:flutter/widgets.dart';
import 'package:riverpod/riverpod.dart';
import 'package:tuple/tuple.dart';

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/services/api/scheduleApi.dart';
import 'package:tiler_app/util.dart';
import 'package:tiler_app/data/timeline.dart';

class TimelineNotifier extends Notifier<Timeline> {
  @override
  Timeline build() {
    var time = Utility.currentTime();
    return Timeline(time.millisecondsSinceEpoch.toDouble(),
        time.millisecondsSinceEpoch.toDouble());
  }

  void updateTimeline(Timeline timeline) {
    state = timeline;
  }
}

final timelineNotifierProvider =
    NotifierProvider<TimelineNotifier, Timeline>(() {
  return TimelineNotifier();
});

class SubEventNotifier extends Notifier<
    Tuple2<Tuple2<List<Timeline>, List<SubCalendarEvent>>, ConnectionState>> {
  @override
  Tuple2<Tuple2<List<Timeline>, List<SubCalendarEvent>>, ConnectionState>
      build() {
    return Tuple2(Tuple2([], []), ConnectionState.none);
  }

  void updateTimeline(
      Tuple2<Tuple2<List<Timeline>, List<SubCalendarEvent>>, ConnectionState>
          timeline) {
    state = timeline;
  }
}

final subEventNotifierProvider = NotifierProvider<
    SubEventNotifier,
    Tuple2<Tuple2<List<Timeline>, List<SubCalendarEvent>>,
        ConnectionState>>(() {
  return SubEventNotifier();
});

final listOfSubCalendarEventProvider = FutureProvider.family<
    Tuple2<List<Timeline>, List<SubCalendarEvent>>,
    Timeline>((ref, timeline) async {
  return ref.read(scheduleApiProvider).getSubEvents(timeline);
});
