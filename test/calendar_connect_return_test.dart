import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authentication/redirectHandler.dart';

/// P4-2: pure parsing tests for the calendar-connect return deep link.
///
/// The server appends exactly these markers to the validated `redirectTarget`
/// (TilerFront `RedirectTargetValidator.AppendCallbackResult`):
/// `calendarConnect=success|declined|error`, `integrationId` on success and
/// `reason` on failure. The client must read only those three params.
void main() {
  group('RedirectHandler.parseCalendarConnectReturn', () {
    test('parses a success return with an integrationId', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?calendarConnect=success&integrationId=UUID_TCA_123');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.outcome, CalendarConnectOutcome.success);
      expect(result.rawValue, 'success');
      expect(result.integrationId, 'UUID_TCA_123');
      expect(result.reason, isNull);
    });

    test('parses a declined return without an integrationId', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?calendarConnect=declined');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.outcome, CalendarConnectOutcome.declined);
      expect(result.rawValue, 'declined');
      expect(result.integrationId, isNull);
      expect(result.reason, isNull);
    });

    test('parses an error return with a reason', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?calendarConnect=error&reason=state_mismatch');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.outcome, CalendarConnectOutcome.error);
      expect(result.rawValue, 'error');
      expect(result.reason, 'state_mismatch');
      expect(result.integrationId, isNull);
    });

    test('classifies an unrecognized marker value as unknown', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?calendarConnect=bogus');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.outcome, CalendarConnectOutcome.unknown);
      expect(result.rawValue, 'bogus');
    });

    test('returns null when the calendarConnect marker is missing', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?integrationId=UUID_TCA_123');

      expect(RedirectHandler.parseCalendarConnectReturn(uri), isNull);
    });

    test('returns null when the calendarConnect marker is empty', () {
      final Uri uri = Uri.parse(
          'tilerapp://app.tiler.app/integrations?calendarConnect=');

      expect(RedirectHandler.parseCalendarConnectReturn(uri), isNull);
    });

    test('returns null for a null uri', () {
      expect(RedirectHandler.parseCalendarConnectReturn(null), isNull);
    });

    test('reads only the three markers and drops every other query param', () {
      final Uri uri = Uri.parse('tilerapp://app.tiler.app/integrations'
          '?calendarConnect=success'
          '&integrationId=UUID_TCA_456'
          '&state=forged-payload'
          '&code=abc'
          '&evil=1');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.outcome, CalendarConnectOutcome.success);
      expect(result.integrationId, 'UUID_TCA_456');
      // The parse result surfaces exactly the three markers and nothing else.
      expect(result.reason, isNull);
    });

    test('normalizes empty integrationId/reason values to null', () {
      final Uri uri = Uri.parse('tilerapp://app.tiler.app/integrations'
          '?calendarConnect=success&integrationId=&reason=');

      final CalendarConnectReturn? result =
          RedirectHandler.parseCalendarConnectReturn(uri);

      expect(result, isNotNull);
      expect(result!.integrationId, isNull);
      expect(result.reason, isNull);
    });
  });
}