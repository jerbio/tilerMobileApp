import 'package:tiler_app/data/VibeChat/VibePreviewAction.dart';
import 'package:tiler_app/data/calendarEvent.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';
import 'package:tiler_app/data/tilerEvent.dart';

class VibePreviewSummary {
  final String? id;
  final String? vibeRequestId;
  final String? tilerUserId;
  final int? createdAt;
  final String? analysisId;
  final String? evaluationId;
  final String? previewId;
  final List<SubCalendarEvent>? subCalendarEvents;
  final List<CalendarEvent>? calendarEvents;
  final List<VibePreviewAction>? previewActions;

  VibePreviewSummary({
    this.id,
    this.vibeRequestId,
    this.tilerUserId,
    this.createdAt,
    this.analysisId,
    this.evaluationId,
    this.previewId,
    this.subCalendarEvents,
    this.calendarEvents,
    this.previewActions,
  });

  factory VibePreviewSummary.fromJson(Map<String, dynamic> json) {
    return VibePreviewSummary(
      id: json['previewId'] as String?,
      vibeRequestId: json['vibeRequestId'] as String?,
      tilerUserId: json['tilerUserId'] as String?,
      createdAt: json['createdAt'] as int?,
      analysisId: json['analysisId'] as String?,
      evaluationId: json['evaluationId'] as String?,
      previewId: json['previewId'] as String?,
      subCalendarEvents: json['subCalendarEvents'] != null &&
          (json['subCalendarEvents'] as List).isNotEmpty
          ? (json['subCalendarEvents'] as List)
          .map((e) => SubCalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      calendarEvents: json['calendarEvents'] != null &&
          (json['calendarEvents'] as List).isNotEmpty
          ? (json['calendarEvents'] as List)
          .map((e) => CalendarEvent.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
      previewActions: json['previewActions'] != null &&
          (json['previewActions'] as List).isNotEmpty
          ? (json['previewActions'] as List)
          .map((e) => VibePreviewAction.fromJson(e as Map<String, dynamic>))
          .toList()
          : null,
    );
  }
}