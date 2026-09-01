import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';

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

  group('IntegrationsBloc GetIntegrationsEvent (P4-2 provider filter)', () {
    /// The server list endpoint (GET api/Integrations without integrationId)
    /// returns ALL of the user's third-party rows — google AND microsoft.
    /// Each bloc page is per-provider, so the bloc must filter to its own
    /// provider; these tests pin that filter.
    test('a microsoft bloc hides google rows from the loaded list', () async {
      final loaded = Completer<List<CalendarIntegration>>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        integrationApi: _FakeIntegrationApi([
          CalendarIntegration.fromJson(
              {'id': 'g1', 'provider': 'google', 'email': 'g@gmail.com'}),
          CalendarIntegration.fromJson(
              {'id': 'm1', 'provider': 'microsoft', 'email': 'm@outlook.com'}),
        ]),
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsLoaded && !loaded.isCompleted) {
          loaded.complete(state.integrations);
        }
      });

      bloc.add(GetIntegrationsEvent());
      List<CalendarIntegration> integrations =
          await loaded.future.timeout(const Duration(seconds: 5));

      expect(integrations.length, 1);
      expect(integrations.single.id, 'm1');
    });

    test('a google bloc hides microsoft rows from the loaded list', () async {
      final loaded = Completer<List<CalendarIntegration>>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.googleCalendar,
        integrationApi: _FakeIntegrationApi([
          CalendarIntegration.fromJson(
              {'id': 'g1', 'provider': 'google', 'email': 'g@gmail.com'}),
          CalendarIntegration.fromJson(
              {'id': 'm1', 'provider': 'microsoft', 'email': 'm@outlook.com'}),
        ]),
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsLoaded && !loaded.isCompleted) {
          loaded.complete(state.integrations);
        }
      });

      bloc.add(GetIntegrationsEvent());
      List<CalendarIntegration> integrations =
          await loaded.future.timeout(const Duration(seconds: 5));

      expect(integrations.length, 1);
      expect(integrations.single.id, 'g1');
    });

    test('provider matching is case-insensitive', () async {
      final loaded = Completer<List<CalendarIntegration>>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        integrationApi: _FakeIntegrationApi([
          CalendarIntegration.fromJson(
              {'id': 'm1', 'provider': 'MICROSOFT', 'email': 'm@outlook.com'}),
          CalendarIntegration.fromJson(
              {'id': 'g1', 'provider': 'Google', 'email': 'g@gmail.com'}),
        ]),
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsLoaded && !loaded.isCompleted) {
          loaded.complete(state.integrations);
        }
      });

      bloc.add(GetIntegrationsEvent());
      List<CalendarIntegration> integrations =
          await loaded.future.timeout(const Duration(seconds: 5));

      expect(integrations.length, 1);
      expect(integrations.single.id, 'm1');
    });

    test('a null list from the api loads an empty list', () async {
      final loaded = Completer<List<CalendarIntegration>>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        integrationApi: _FakeIntegrationApi(null),
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsLoaded && !loaded.isCompleted) {
          loaded.complete(state.integrations);
        }
      });

      bloc.add(GetIntegrationsEvent());
      List<CalendarIntegration> integrations =
          await loaded.future.timeout(const Duration(seconds: 5));

      expect(integrations, isEmpty);
    });
  });

  group('IntegrationType provider mapping (P4-2 extensibility)', () {
    test('each type maps to its server provider name', () {
      expect(IntegrationType.googleCalendar.providerName, 'google');
      expect(IntegrationType.microsoft.providerName, 'microsoft');
    });

    test('fromProviderName matches case-insensitively', () {
      expect(IntegrationType.fromProviderName('Google'),
          IntegrationType.googleCalendar);
      expect(IntegrationType.fromProviderName('MICROSOFT'),
          IntegrationType.microsoft);
    });

    test('fromProviderName returns null for unknown or missing providers',
        () {
      expect(IntegrationType.fromProviderName('apple'), isNull);
      expect(IntegrationType.fromProviderName(null), isNull);
    });

    test('a bloc drops rows for providers it does not recognize', () async {
      final loaded = Completer<List<CalendarIntegration>>();
      IntegrationsBloc bloc = IntegrationsBloc(
        getContextCallBack: () => null,
        integrationType: IntegrationType.microsoft,
        integrationApi: _FakeIntegrationApi([
          CalendarIntegration.fromJson(
              {'id': 'm1', 'provider': 'microsoft', 'email': 'm@outlook.com'}),
          CalendarIntegration.fromJson(
              {'id': 'a1', 'provider': 'apple', 'email': 'a@icloud.com'}),
        ]),
      );
      addTearDown(bloc.close);

      bloc.stream.listen((IntegrationsState state) {
        if (state is IntegrationsLoaded && !loaded.isCompleted) {
          loaded.complete(state.integrations);
        }
      });

      bloc.add(GetIntegrationsEvent());
      List<CalendarIntegration> integrations =
          await loaded.future.timeout(const Duration(seconds: 5));

      expect(integrations.length, 1);
      expect(integrations.single.id, 'm1');
    });
  });
}

/// Returns [rows] for `GET api/Integrations` without hitting the network —
/// reproduces the server's unfiltered, all-providers response.
class _FakeIntegrationApi extends IntegrationApi {
  _FakeIntegrationApi(this.rows) : super(getContextCallBack: () => null);

  final List<CalendarIntegration>? rows;

  @override
  Future<List<CalendarIntegration>?> getIntegrations(
      {String? integrationId}) async {
    return rows;
  }
}