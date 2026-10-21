import 'dart:convert';

import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/data/subCalendarEvent.dart';

class ScheduleEventResponseError extends TilerError {
  ScheduleEventResponseError()
      : super(
            Code: 'unexpected_event_response',
            Message:
                'Tiler returned an unexpected response while creating your tile or block. Check your schedule before trying again.');
}

bool _isText(Object? value) => value is String && value.trim().isNotEmpty;

bool _isTimestamp(Object? value) =>
    value is int && value.abs() <= 8640000000000000;

/// Supports both the legacy event and the MobileApp schedule-result wrapper.
/// Never let a partial model or a deserializer TypeError reach the UI.
SubCalendarEvent parseCreatedScheduleEvent(String body, {required int status}) {
  try {
    final Object? response = jsonDecode(body);
    if (response is! Map<String, dynamic> || response['Error'] is! Map) {
      throw ScheduleEventResponseError();
    }
    final Map error = response['Error'];
    final code = error['Code'];
    if (code is! String && code is! num) {
      throw ScheduleEventResponseError();
    }
    if (code != '0' && code != 0) {
      throw TilerError(
          Code: code.toString(),
          Message: _isText(error['Message'])
              ? error['Message'] as String
              : 'Tiler could not create your tile or block.');
    }
    if (status < 200 || status >= 300) {
      throw TilerError(Message: 'Tiler could not create your tile or block.');
    }
    final content = response['Content'];
    final event = content is Map && content.containsKey('tilerEvent')
        ? content['tilerEvent']
        : content;
    if (event is! Map<String, dynamic> ||
        !_isText(event['id']) ||
        !_isText(event['name']) ||
        !_isTimestamp(event['start']) ||
        !_isTimestamp(event['end']) ||
        (event['end'] as int) < (event['start'] as int)) {
      throw ScheduleEventResponseError();
    }
    final parent = event['calendarEvent'];
    if (parent != null &&
        (parent is! Map<String, dynamic> || !_isText(parent['id']))) {
      throw ScheduleEventResponseError();
    }
    return SubCalendarEvent.fromJson(event);
  } on TilerError {
    rethrow;
  } catch (_) {
    // Includes invalid JSON and changed types in optional/nested model fields.
    throw ScheduleEventResponseError();
  }
}
