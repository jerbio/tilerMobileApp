import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/connetions.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/integrationWidgetRoute.dart';
import 'package:tiler_app/routes/authenticatedUser/tileShare/tileShareDetailWidget.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';

/// The outcomes the server appends to the calendar-connect return deep link
/// (see `RedirectTargetValidator.AppendCallbackResult` on the server).
enum CalendarConnectOutcome { success, declined, error, unknown }

/// Parsed calendar-connect return deep link. Only the three result markers
/// (`calendarConnect`, `integrationId` on success, `reason` on error) are
/// read; every other query param is dropped.
class CalendarConnectReturn {
  final CalendarConnectOutcome outcome;

  /// The raw `calendarConnect` marker value.
  final String rawValue;
  final String? integrationId;
  final String? reason;

  const CalendarConnectReturn({
    required this.outcome,
    required this.rawValue,
    this.integrationId,
    this.reason,
  });
}

class RedirectHandler {
  static const String redirectPrefix = "rerouteapp";
  static const String paramDelimiter = "&";
  static const String calendarConnectMarker = "calendarConnect";
  static const String integrationIdMarker = "integrationId";
  static const String reasonMarker = "reason";

  static routePage(BuildContext context, Uri? remoteUri) {
    if (remoteUri != null) {
      // Calendar-connect returns (P4-2) land on the tilerapp:// deep link
      // with a `calendarConnect=` marker appended by the server. This check
      // is independent of the legacy `rerouteapp` gate below — the connect
      // return deep link never carries that prefix.
      final CalendarConnectReturn? calendarReturn =
          parseCalendarConnectReturn(remoteUri);
      if (calendarReturn != null) {
        _routeToCalendarConnectReturn(context, calendarReturn);
        return;
      }
      if (remoteUri.toString().isNotEmpty &&
          remoteUri.toString().contains(redirectPrefix)) {
        if (remoteUri.toString().toLowerCase().contains("tileshareid")) {
          _routeToTileShare(context, remoteUri.toString());
        }
      }
    }
  }

  /// Parses the calendar-connect return markers from [uri]:
  /// `calendarConnect=success|declined|error` (any other value is
  /// [CalendarConnectOutcome.unknown]), plus `integrationId` on success and
  /// `reason` on error.
  ///
  /// Returns null when the link carries no `calendarConnect` query param —
  /// i.e. it is not a calendar-connect return.
  static CalendarConnectReturn? parseCalendarConnectReturn(Uri? uri) {
    if (uri == null) return null;
    String? rawValue = uri.queryParameters[calendarConnectMarker];
    if (rawValue == null || rawValue.isEmpty) return null;

    CalendarConnectOutcome outcome;
    switch (rawValue) {
      case 'success':
        outcome = CalendarConnectOutcome.success;
        break;
      case 'declined':
        outcome = CalendarConnectOutcome.declined;
        break;
      case 'error':
        outcome = CalendarConnectOutcome.error;
        break;
      default:
        outcome = CalendarConnectOutcome.unknown;
    }

    String? integrationId = uri.queryParameters[integrationIdMarker];
    String? reason = uri.queryParameters[reasonMarker];
    return CalendarConnectReturn(
      outcome: outcome,
      rawValue: rawValue,
      integrationId: (integrationId == null || integrationId.isEmpty)
          ? null
          : integrationId,
      reason: (reason == null || reason.isEmpty) ? null : reason,
    );
  }

  static void _routeToCalendarConnectReturn(
      BuildContext context, CalendarConnectReturn calendarReturn) {
    AppLocalizations? localization = AppLocalizations.of(context);
    NotificationOverlayMessage notification = NotificationOverlayMessage();
    switch (calendarReturn.outcome) {
      case CalendarConnectOutcome.success:
        if (localization != null) {
          notification.showToast(context, localization.calendarConnected,
              NotificationOverlayMessageType.success);
        }
        // Navigate to the integrations page for the provider that owns the
        // new integration; the fresh bloc triggers the list refresh.
        _navigateToConnectedIntegration(
            context, calendarReturn.integrationId);
        break;
      case CalendarConnectOutcome.declined:
        if (localization != null) {
          notification.showToast(context,
              localization.calendarConnectionDeclined,
              NotificationOverlayMessageType.warning);
        }
        break;
      case CalendarConnectOutcome.error:
        if (localization != null) {
          notification.showToast(context,
              localization.calendarConnectionError,
              NotificationOverlayMessageType.error);
        }
        break;
      case CalendarConnectOutcome.unknown:
        // Unrecognized marker value — ignore rather than alert the user.
        debugPrint('Calendar connect return with unknown marker value: '
            '${calendarReturn.rawValue}');
        break;
    }
  }

  /// Navigates to the integrations page for the provider that owns
  /// [integrationId] (resolved via `GET api/integrations?integrationId=`).
  /// A fresh [IntegrationsBloc] starts in [IntegrationsInitial], so the page
  /// immediately re-fetches the list — the post-connect refresh. Falls back
  /// to the provider list page ([Connections.routeName]) when the
  /// integration cannot be resolved.
  static Future<void> _navigateToConnectedIntegration(
      BuildContext context, String? integrationId) async {
    IntegrationType integrationType = IntegrationType.googleCalendar;
    bool resolved = integrationId != null && integrationId.isNotEmpty;
    if (resolved) {
      try {
        IntegrationApi integrationApi =
            IntegrationApi(getContextCallBack: () => context);
        List<CalendarIntegration>? integrations =
            await integrationApi.getIntegrations(integrationId: integrationId);
        if (integrations == null || integrations.isEmpty) {
          resolved = false;
        } else {
          integrationType =
              _integrationTypeFromProvider(integrations.first.calendarType);
        }
      } catch (e) {
        resolved = false;
        debugPrint('Failed to resolve calendar integration $integrationId '
            'on connect return: $e');
      }
    }
    if (!context.mounted) return;
    if (!resolved) {
      Navigator.pushNamed(context, Connections.routeName);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => IntegrationsBloc(
            getContextCallBack: () => context,
            integrationType: integrationType,
          ),
          child: IntegrationWidgetRoute(),
        ),
      ),
    );
  }

  static IntegrationType _integrationTypeFromProvider(String? provider) {
    switch (provider?.toLowerCase()) {
      case 'microsoft':
        return IntegrationType.microsoft;
      default:
        return IntegrationType.googleCalendar;
    }
  }

  static void _routeToTileShare(BuildContext context, String uriString) {
    var decodedString = Uri.decodeFull(uriString);
    debugPrint('decoded by id ' + decodedString);
    String uriString_lower = decodedString.toLowerCase();
    String tileShareByIdLookupString = "tileshareid=";
    if (uriString_lower.contains(tileShareByIdLookupString)) {
      int beginIndex = uriString_lower.indexOf(tileShareByIdLookupString);
      if (beginIndex > 0) {
        String paramsTileShareUri = decodedString.substring(beginIndex);
        int delimiterIndex = paramsTileShareUri.indexOf(paramDelimiter);
        if (delimiterIndex >= 0) {
          paramsTileShareUri = paramsTileShareUri.substring(delimiterIndex);
        }
        String tileShareId =
            paramsTileShareUri.substring(tileShareByIdLookupString.length);
        if (tileShareId.isNotEmpty) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      TileShareDetailWidget.byId(tileShareId: tileShareId)));
          return;
        }

        Navigator.pushNamed(context, '/TileShare');
      }
    }
  }
}
