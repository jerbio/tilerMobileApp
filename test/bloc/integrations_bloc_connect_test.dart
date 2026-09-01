import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';

/// P4-2: `AddIntegrationEvent` now routes both providers through the
/// backend-driven connect flow — the bloc calls `api/Integrations/connect`
/// (via the injectable seam) and opens the returned provider authorization
/// URL in the external browser. The legacy no-op `_addIntegration` stub is
/// gone, so the provider name sent to the connect endpoint and the launched
/// URL are the observable behaviors under test.
void main() {
  group('IntegrationsBloc AddIntegrationEvent (P4-2 connect flow)', () {
    test(
        'Microsoft connect calls the connect API with provider "microsoft" '
        'and launches the returned authorization URL', () async {
      String? capturedProvider;
      Uri? launchedUrl;
      final Completer<void> launched = Completer<void>();
      const String authorizationUrl =
          'https://login.microsoftonline.com/common/oauth2/v2.0/authorize?state=s1gn3d';

      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        startCalendarConnect: (String provider) async {
          capturedProvider = provider;
          return authorizationUrl;
        },
        launchAuthorizationUrl: (Uri url) async {
          launchedUrl = url;
          if (!launched.isCompleted) launched.complete();
        },
      );
      addTearDown(bloc.close);

      bloc.add(AddIntegrationEvent());
      await launched.future.timeout(const Duration(seconds: 5));

      expect(capturedProvider, 'microsoft');
      expect(launchedUrl, Uri.parse(authorizationUrl));
    });

    test(
        'Google connect calls the connect API with provider "google" '
        'and launches the returned authorization URL', () async {
      String? capturedProvider;
      Uri? launchedUrl;
      final Completer<void> launched = Completer<void>();
      const String authorizationUrl =
          'https://accounts.google.com/o/oauth2/v2/auth?state=s1gn3d';

      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.googleCalendar,
        startCalendarConnect: (String provider) async {
          capturedProvider = provider;
          return authorizationUrl;
        },
        launchAuthorizationUrl: (Uri url) async {
          launchedUrl = url;
          if (!launched.isCompleted) launched.complete();
        },
      );
      addTearDown(bloc.close);

      bloc.add(AddIntegrationEvent());
      await launched.future.timeout(const Duration(seconds: 5));

      expect(capturedProvider, 'google');
      expect(launchedUrl, Uri.parse(authorizationUrl));
    });

    test('a failed connect start emits IntegrationsError', () async {
      final Completer<String> errorReceived = Completer<String>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        startCalendarConnect: (String provider) async {
          throw Exception('connect endpoint unreachable');
        },
        launchAuthorizationUrl: (Uri url) async {},
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsError && !errorReceived.isCompleted) {
          errorReceived.complete(state.errorMessage);
        }
      });

      bloc.add(AddIntegrationEvent());
      String message =
          await errorReceived.future.timeout(const Duration(seconds: 5));

      expect(message, contains('Failed to add integration'));
    });

    test('a failed browser launch emits IntegrationsError', () async {
      final Completer<String> errorReceived = Completer<String>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        startCalendarConnect: (String provider) async =>
            'https://login.microsoftonline.com/common/oauth2/v2.0/authorize',
        launchAuthorizationUrl: (Uri url) async {
          throw Exception('no external browser available');
        },
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsError && !errorReceived.isCompleted) {
          errorReceived.complete(state.errorMessage);
        }
      });

      bloc.add(AddIntegrationEvent());
      String message =
          await errorReceived.future.timeout(const Duration(seconds: 5));

      expect(message, contains('Failed to add integration'));
    });
  });
}