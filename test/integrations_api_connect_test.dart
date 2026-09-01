import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/services/api/retryHttpClient.dart';

/// Regression test for the connect-start request (P4-2).
///
/// `GET api/Integrations/connect` answers with a 302 whose `Location` header
/// holds the provider authorization URL. On device the app's http client
/// followed that 302 all the way to the provider's consent page and received
/// the final 200 HTML body — so `Location` was gone and the launch failed with
/// "Calendar connect response missing Location header". These tests pin the
/// fixed behavior against a local server: the raw 302 must be read, not
/// followed.
void main() {
  group('getCalendarConnectAuthorizationUrl', () {
    late HttpServer server;
    late RetryHttpClient client;

    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      client = RetryHttpClient();
    });

    tearDown(() async {
      await server.close(force: true);
      client.close();
    });

    test('reads the 302 Location header without following the redirect',
        () async {
      // The connect endpoint 302s to a "consent page" on the same server —
      // if the client followed redirects it would land here (a 200 with no
      // Location header), exactly like landing on accounts.google.com.
      server.listen((HttpRequest request) {
        if (request.uri.path == '/api/Integrations/connect') {
          request.response.statusCode = HttpStatus.found;
          request.response.headers.set(
              'Location', 'http://${server.address.host}:${server.port}/consent');
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.html;
          request.response.write('<html>provider consent page</html>');
        }
        request.response.close();
      });

      final url = await getCalendarConnectAuthorizationUrl(
        client,
        Uri.parse('http://${server.address.host}:${server.port}/api/Integrations/connect'),
        {'Authorization': 'Bearer test-token'},
      );

      expect(url, 'http://${server.address.host}:${server.port}/consent');
    });

    test('throws TilerError when the response has no Location header',
        () async {
      // Mirrors an auth failure: a plain 200 JSON body, no redirect.
      server.listen((HttpRequest request) {
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"Error": {"Code": "1"}}');
        request.response.close();
      });

      await expectLater(
        getCalendarConnectAuthorizationUrl(
          client,
          Uri.parse('http://${server.address.host}:${server.port}/api/Integrations/connect'),
          {'Authorization': 'Bearer test-token'},
        ),
        throwsA(isA<TilerError>()),
      );
    });
  });
}