// day_plan_view_model_test.dart
//
// Phase 1 of the Today Status screen rebuild
// (docs/today-status-screen-implementation-plan.md).
//
// Locks in the presentation-layer contract from the design spec
// (docs/today-status-screen-engineering-ui-spec.md):
//   - §8.1 display state matrix
//   - §2.2 copy consistency rules (notably: "Everything else is on track")
//   - §8.3 ordering rules
//   - §17 edge cases (missing title / date / duration)
//
// These are pure unit tests: no widgets, no network, no theme.

import 'package:flutter_test/flutter_test.dart';

import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';
import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/data/timelineSummary.dart';
import 'package:tiler_app/data/todayStatus/dayPlanViewModel.dart';
import 'package:tiler_app/data/todayStatus/planItemViewModel.dart';

/// Minutes-since-epoch helper so tests read as wall-clock offsets.
int _ms(int hourOfDay) =>
    DateTime(2026, 9, 1, hourOfDay).millisecondsSinceEpoch;

SubCalendarEvent _event({
  required String id,
  String? name,
  int? startHour,
  int? endHour,
  bool isViable = true,
  bool isTardy = false,
  String? priority,
}) {
  final Map<String, dynamic> json = {
    'id': id,
    'name': name,
    'isViable': isViable,
    'isTardy': isTardy,
  };
  if (startHour != null) {
    json['start'] = _ms(startHour);
  }
  if (endHour != null) {
    json['end'] = _ms(endHour);
  }
  if (priority != null) {
    json['priority'] = priority;
  }
  return SubCalendarEvent.fromJson(json);
}

TimelineSummary _summary({
  List<TilerEvent>? complete,
  List<TilerEvent>? nonViable,
  List<TilerEvent>? tardy,
}) {
  final TimelineSummary summary = TimelineSummary();
  summary.complete = complete;
  summary.nonViable = nonViable;
  summary.tardy = tardy;
  return summary;
}

Timeline _today() => Timeline.fromDateTime(
      DateTime(2026, 9, 1),
      DateTime(2026, 9, 1, 23, 59),
    );

DayPlanViewModel _model({
  int placed = 0,
  int attention = 0,
  int late = 0,
  bool canPreviewPlan = true,
}) {
  return DayPlanViewModel.fromTimelineSummary(
    timeline: _today(),
    summary: _summary(
      complete: List.generate(
        placed,
        (i) => _event(id: 'p$i', name: 'placed $i', startHour: 8 + i),
      ),
      nonViable: List.generate(
          attention, (i) => _event(id: 'a$i', name: 'attention $i')),
      tardy: List.generate(late, (i) => _event(id: 'l$i', name: 'late $i')),
    ),
    canPreviewPlan: canPreviewPlan,
  );
}

void main() {
  group('§8.1 display state matrix', () {
    test('0 placed / 0 attention / 0 late => clear day, nothing else shown',
        () {
      final model = _model();

      expect(model.displayState, TodayStatusDisplayState.clearDay);
      expect(model.showPlacedCard, isFalse);
      expect(model.showAttentionCard, isFalse);
      expect(model.showLateCard, isFalse);
      expect(model.showTrackStatusCard, isFalse);
      expect(model.showPreviewCta, isFalse);
    });

    test('>0 placed / 0 attention / 0 late => on track, no CTA', () {
      final model = _model(placed: 10);

      expect(model.displayState, TodayStatusDisplayState.allPlaced);
      expect(model.showPlacedCard, isTrue);
      expect(model.showAttentionCard, isFalse);
      expect(model.showTrackStatusCard, isTrue);
      expect(model.trackStatusCopy, TrackStatusCopy.everythingOnTrack);
      expect(model.showPreviewCta, isFalse);
    });

    test('>0 placed / >0 attention / 0 late => attention + "everything else"',
        () {
      final model = _model(placed: 4, attention: 6);

      expect(model.displayState, TodayStatusDisplayState.attentionNeeded);
      expect(model.showPlacedCard, isTrue);
      expect(model.showAttentionCard, isTrue);
      expect(model.showLateCard, isFalse);
      expect(model.showTrackStatusCard, isTrue);
      expect(model.trackStatusCopy, TrackStatusCopy.everythingElseOnTrack);
      expect(model.showPreviewCta, isTrue);
      expect(model.attentionLeadsContent, isFalse);
    });

    test('late > 0 => recovery state suppresses the on-track card', () {
      final model = _model(placed: 4, attention: 2, late: 1);

      expect(model.displayState, TodayStatusDisplayState.recovery);
      expect(model.showLateCard, isTrue);
      expect(model.showTrackStatusCard, isFalse,
          reason: 'on-track messaging must never mask lateCount > 0');
      expect(model.showPreviewCta, isTrue);
    });

    test('0 placed / >0 attention / 0 late => attention leads the content', () {
      final model = _model(attention: 6);

      expect(model.displayState, TodayStatusDisplayState.attentionNeeded);
      expect(model.showPlacedCard, isFalse);
      expect(model.attentionLeadsContent, isTrue);
      expect(model.placedCount, 0,
          reason: 'summary strip still reports 0 placed rather than hiding');
    });
  });

  group('§2.2 copy consistency', () {
    test('"Everything is on track" only when nothing needs attention', () {
      expect(
          _model(placed: 3).trackStatusCopy, TrackStatusCopy.everythingOnTrack);
      expect(_model(placed: 3, attention: 1).trackStatusCopy,
          TrackStatusCopy.everythingElseOnTrack);
    });
  });

  group('preview CTA visibility (§5.6)', () {
    test('hidden when the plan cannot be previewed even with attention items',
        () {
      expect(
          _model(attention: 3, canPreviewPlan: false).showPreviewCta, isFalse);
    });

    test('hidden when there is nothing needing attention', () {
      expect(_model(placed: 3).showPreviewCta, isFalse);
    });
  });

  group('placed derivation', () {
    test('placed items are the day\'s completed sub-events', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(complete: [
          _event(id: 'done', name: 'Morning prep', startHour: 9),
        ]),
      );

      expect(model.placedItems.map((e) => e.id), ['done']);
      expect(model.placedItems.single.status, PlanItemStatus.placed);
    });

    test('a day with no completed sub-events has an empty placed list', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(nonViable: [_event(id: 'a')]),
      );

      expect(model.placedItems, isEmpty);
      expect(model.attentionCount, 1);
    });
  });

  group('§8.3 ordering', () {
    test('placed items are chronological by scheduled start', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(complete: [
          _event(id: 'noon', startHour: 12),
          _event(id: 'morning', startHour: 8),
          _event(id: 'evening', startHour: 18),
        ]),
      );

      expect(
          model.placedItems.map((e) => e.id), ['morning', 'noon', 'evening']);
    });

    test('attention items put high priority first and are otherwise stable',
        () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(nonViable: [
          _event(id: 'first', priority: 'medium'),
          _event(id: 'second', priority: 'medium'),
          _event(id: 'urgent', priority: 'high'),
          _event(id: 'third', priority: 'low'),
        ]),
      );

      expect(model.attentionItems.map((e) => e.id),
          ['urgent', 'first', 'second', 'third']);
    });
  });

  group('§17 edge cases', () {
    test('a null title is surfaced as null rather than an empty row', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(nonViable: [_event(id: 'untitled')]),
      );

      expect(model.attentionItems.single.title, isNull,
          reason: 'the widget layer owns the localized "Untitled tile" copy');
    });

    test('a zero-length item reports a null duration rather than 0 min', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: _summary(nonViable: [_event(id: 'nodur')]),
      );

      expect(model.attentionItems.single.durationMinutes, isNull);
    });

    test('duration is derived in whole minutes from the time range', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary:
            _summary(complete: [_event(id: 'p', startHour: 9, endHour: 10)]),
      );

      expect(model.placedItems.single.durationMinutes, 60);
    });

    test('a null summary renders as a clear day rather than throwing', () {
      final model = DayPlanViewModel.fromTimelineSummary(
        timeline: _today(),
        summary: null,
      );

      expect(model.displayState, TodayStatusDisplayState.clearDay);
    });
  });

  group('PlanItemViewModel', () {
    test('carries the source event through for navigation and completion', () {
      final source = _event(id: 'src', name: 'Morning prep', startHour: 9);
      final item = PlanItemViewModel.fromTilerEvent(
        source,
        status: PlanItemStatus.placed,
      );

      expect(item.id, 'src');
      expect(item.title, 'Morning prep');
      expect(item.status, PlanItemStatus.placed);
      expect(identical(item.source, source), isTrue);
    });

    test('reason codes map from the backend string, defaulting to unknown', () {
      expect(AttentionReasonCode.fromCode('DURATION_EXCEEDS_GAP'),
          AttentionReasonCode.durationExceedsGap);
      expect(AttentionReasonCode.fromCode('not_a_real_code'),
          AttentionReasonCode.unknown);
      expect(AttentionReasonCode.fromCode(null), isNull,
          reason: 'absent reason data must stay absent, not become "Couldn\'t '
              'fit" — the chip is omitted instead');
    });
  });
}
