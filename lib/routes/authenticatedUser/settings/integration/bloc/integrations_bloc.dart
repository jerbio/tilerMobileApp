import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

part 'integrations_event.dart';
part 'integrations_state.dart';

/// Provider for the settings integrations pages.
///
/// Single source of truth for the provider names the server uses — the
/// `provider` field on `GET api/Integrations` rows and the `Provider=` query
/// parameter of `GET api/Integrations/connect`. To add a provider, add one
/// enum entry with its server name; the per-provider list filter in
/// `IntegrationsBloc` and the deep-link return routing
/// (`IntegrationType.fromProviderName`) pick it up automatically.
enum IntegrationType {
  googleCalendar('google'),
  microsoft('microsoft');

  const IntegrationType(this.providerName);

  /// The provider name sent to and expected from the server.
  final String providerName;

  /// Reverse lookup of [providerName] (case-insensitive). Returns `null` for
  /// unknown or missing providers, so a row for a provider the app does not
  /// know about is shown on no page (and a deep-link return falls back to
  /// the connections list).
  static IntegrationType? fromProviderName(String? providerName) {
    final String? normalized = providerName?.toLowerCase();
    for (final IntegrationType type in IntegrationType.values) {
      if (type.providerName == normalized) {
        return type;
      }
    }
    return null;
  }
}

/// Default connect seam: delegates to [IntegrationApi.startCalendarConnect].
Future<String> _defaultStartCalendarConnect(
    IntegrationApi api, String provider) {
  return api.startCalendarConnect(provider: provider);
}

class IntegrationsBloc extends Bloc<IntegrationsEvent, IntegrationsState> {
  final IntegrationApi _integrationApi;
  final IntegrationType integrationType;

  /// Starts the backend-driven calendar-connect flow for [provider] and
  /// returns the provider authorization URL. Injectable for tests.
  final Future<String> Function(String provider) _startCalendarConnect;

  /// Opens a URL in the external browser. Injectable for tests.
  final Future<void> Function(Uri url) _launchAuthorizationUrl;

  /// True while a connect flow is being started (the `api/Integrations/connect`
  /// call plus the external-browser launch). Repeat taps on the add button are
  /// ignored while set, so one tap starts exactly one consent round-trip.
  bool _connectInProgress = false;

  IntegrationsBloc._({
    required IntegrationApi integrationApi,
    required IntegrationType integrationType,
    required Future<String> Function(String provider) startCalendarConnect,
    required Future<void> Function(Uri url) launchAuthorizationUrl,
  })  : _integrationApi = integrationApi,
        integrationType = integrationType,
        _startCalendarConnect = startCalendarConnect,
        _launchAuthorizationUrl = launchAuthorizationUrl,
        super(IntegrationsInitial()) {
    on<GetIntegrationsEvent>(_getIntegrations);
    on<DeleteIntegrationEvent>(_deleteIntegration);
    on<AddIntegrationEvent>(_addIntegration);
    on<UpdateIntegrationLocationEvent>(_updateIntegrationLocation);
    on<UpdateCalendarItemEvent>(_updateCalendarItem);
    on<ResetIntegrationsEvent>((event, emit) => emit(IntegrationsInitial()));
  }

  factory IntegrationsBloc({
    required Function getContextCallBack,
    required IntegrationType integrationType,
    IntegrationApi? integrationApi,
    Future<String> Function(String provider)? startCalendarConnect,
    Future<void> Function(Uri url)? launchAuthorizationUrl,
  }) {
    final api =
        integrationApi ?? IntegrationApi(getContextCallBack: getContextCallBack);
    return IntegrationsBloc._(
      integrationApi: api,
      integrationType: integrationType,
      startCalendarConnect:
          startCalendarConnect ?? (provider) => _defaultStartCalendarConnect(api, provider),
      launchAuthorizationUrl:
          launchAuthorizationUrl ?? _launchInExternalBrowser,
    );
  }

  

  static Future<void> _launchInExternalBrowser(Uri authorizationUrl) async {
    final bool launched =
        await launchUrl(authorizationUrl, mode: LaunchMode.externalApplication);
    if (!launched) {
      throw Exception(
          'Failed to open external browser for calendar connect: $authorizationUrl');
    }
  }

  void _getIntegrations(
      GetIntegrationsEvent event, Emitter<IntegrationsState> emit) async {
    emit(IntegrationsLoading());
    try {
      final integrations = await _integrationApi.getIntegrations(
          integrationId: event.integrationId);
      // P4-2 fix: the server list endpoint (GET api/Integrations without an
      // integrationId) returns ALL of the user's third-party rows — google
      // AND microsoft. This page is per-provider (one bloc per provider), so
      // keep only this bloc's provider rows. Case-insensitive match on the
      // `provider` field (`CalendarIntegration.calendarType`).
      final integrationsForProvider = (integrations ?? [])
          .where((integration) =>
              IntegrationType.fromProviderName(integration.calendarType) ==
                  integrationType)
          .toList();
      emit(IntegrationsLoaded(integrations: integrationsForProvider));
    } catch (e) {
      emit(IntegrationsError(
          errorMessage: e.toString(),
          integrations: (state is IntegrationsLoaded)
              ? (state as IntegrationsLoaded).integrations
              : []));
    }
  }

  void _deleteIntegration(
      DeleteIntegrationEvent event, Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
      try {
        final success =
            await _integrationApi.deleteIntegration(event.integration);

        if (success!) {
          final index = currentIntegrations
              .indexWhere((index) => index.id == event.integration.id);
          String integrationInfo = currentIntegrations[index].email ??
              currentIntegrations[index].userId ??
              currentIntegrations[index].id ??
              "";
          if (index != -1) currentIntegrations.removeAt(index);
          emit(IntegrationDeleted(integrationInfo: integrationInfo));
          emit(IntegrationsLoaded(integrations: currentIntegrations));
        } else {
          emit(IntegrationsError(
            errorMessage: "Failed to delete integration",
            integrations: currentIntegrations,
          ));
        }
      } catch (e) {
        emit(IntegrationsError(
          errorMessage: "Failed to delete integration: ${e.toString()}",
          integrations: currentIntegrations,
        ));
      }
    }
  }

  void _addIntegration(
      AddIntegrationEvent event, Emitter<IntegrationsState> emit) async {
    List<CalendarIntegration> currentIntegrations = [];
    if (state is IntegrationsLoaded) {
      currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
    }
    if (_connectInProgress) {
      // A connect flow is already in flight — ignore the repeat tap. The
      // in-flight flow (or its tilerapp:// deep-link return) refreshes the
      // page; starting a second consent round-trip would only open a second
      // consent screen (both providers force consent: prompt=consent).
      debugPrint(
          'AddIntegrationEvent ignored: connect flow already in flight (provider=${integrationType.providerName})');
      return;
    }
    _connectInProgress = true;
    try {
      // P4-2: both Google and Microsoft connect through the backend-driven
      // flow. The app calls `api/Integrations/connect` with its Bearer token
      // and opens the returned provider authorization URL in the external
      // browser (the browser cannot carry the mobile token). No local state
      // changes here — the connected calendar appears when the provider
      // redirects back via the tilerapp:// deep link, which `RedirectHandler`
      // routes into the integrations page with a fresh bloc (the refresh).
      final authorizationUrl =
          await _startCalendarConnect(integrationType.providerName);
      await _launchAuthorizationUrl(Uri.parse(authorizationUrl));
    } catch (e) {
      BuildContext? context = null;
      if (this._integrationApi.getContextCallBack != null) {
        context = this._integrationApi.getContextCallBack!();
      }

      String errorMessage = "Failed to add integration: ${e.toString()}";
      if (context != null) {
        errorMessage = AppLocalizations.of(context)!.failedToAddIntegration;
      }
      emit(IntegrationsError(
          errorMessage: errorMessage, integrations: currentIntegrations));
    } finally {
      _connectInProgress = false;
    }
  }

  void _updateIntegrationLocation(UpdateIntegrationLocationEvent event,
      Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
      final index = currentIntegrations
          .indexWhere((element) => element.id == event.integrationId);
      if (index != -1) {
        try {
          emit(IntegrationsLoading());
          await _integrationApi.addIntegrationLocation(
              event.location, event.integrationId);
          currentIntegrations[index].location = event.location;
          emit(IntegrationsLoaded(integrations: currentIntegrations));
        } catch (e) {
          emit(IntegrationsError(
              errorMessage: "Failed to update location: ${e.toString()}",
              integrations: currentIntegrations));
          add(GetIntegrationsEvent());
        }
      } else {
        try {
          await _integrationApi.addIntegrationLocation(
              event.location, event.integrationId);
          add(GetIntegrationsEvent());
        } catch (e) {
          emit(IntegrationsError(
              errorMessage: "Failed to update location: ${e.toString()}",
              integrations: currentIntegrations));
        }
      }
    }
  }

  void _updateCalendarItem(
      UpdateCalendarItemEvent event, Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);

      // Find the integration
      final integrationIndex = currentIntegrations
          .indexWhere((integration) => integration.id == event.integrationId);

      if (integrationIndex != -1) {
        final integration = currentIntegrations[integrationIndex];

        // Find the calendar item
        if (integration.calendarItems != null) {
          final calendarItemIndex = integration.calendarItems!
              .indexWhere((item) => item.id == event.calendarItemId);
          if (calendarItemIndex != -1) {
            try {
              // Update the calendar item on the server
              final updatedCalendarItem =
                  await _integrationApi.updateCalendarItem(
                calendarId: event.calendarItemId,
                calendarName: event.calendarName,
                isSelected: event.isSelected,
                integrationId: event.integrationId,
                calendarItemId: event.calendarItemId,
              );

              if (updatedCalendarItem != null) {
                // Update the local state with the server response
                integration.calendarItems![calendarItemIndex] =
                    updatedCalendarItem;
                print(
                    "Updated calendar item from server: ${updatedCalendarItem.name} - Selected: ${updatedCalendarItem.isSelected}");
                emit(IntegrationsLoaded(
                    integrations: [], requestId: event.requestId));
                // the double emit is intentional to ensure the UI updates correctly.
                // We first emit an empty list to clear the previous state,
                // then emit the updated integrations list.
                // This is a workaround because we are using the same integration reference object pre and post update,
                // so referencing the same object does not trigger a UI update in the integration state diff/equatable checker.
                emit(IntegrationsLoaded(
                    integrations: currentIntegrations,
                    requestId: event.requestId));
              } else {
                emit(IntegrationsError(
                    errorMessage: "Failed to update calendar item",
                    integrations: currentIntegrations,
                    requestId: event.requestId));
              }
            } catch (e) {
              emit(IntegrationsError(
                  errorMessage:
                      "Failed to update calendar item: ${e.toString()}",
                  integrations: currentIntegrations,
                  requestId: event.requestId));
            }
          } else {
            emit(IntegrationsError(
              errorMessage: "Calendar item not found",
              integrations: currentIntegrations,
              requestId: event.requestId,
            ));
          }
        }
      } else {
        emit(IntegrationsError(
          errorMessage: "Integration not found",
          integrations: currentIntegrations,
          requestId: event.requestId,
        ));
      }
    }
  }
}
