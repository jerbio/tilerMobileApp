import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

/// A custom HTTP client that automatically retries GET requests on transient
/// network failures (SocketException, ClientException).
///
/// For non-idempotent requests (POST, PUT, PATCH), it does not automatically
/// retry but provides [executeWithFreshClient] for manual retry control.
class RetryHttpClient extends http.BaseClient {
  static const int defaultMaxRetries = 3;
  static const Duration defaultRetryDelay = Duration(seconds: 1);

  http.Client _innerClient;
  final int maxRetries;
  final Duration retryDelay;

  RetryHttpClient({
    this.maxRetries = defaultMaxRetries,
    this.retryDelay = defaultRetryDelay,
  }) : _innerClient = http.Client();

  /// Refreshes the underlying HTTP client.
  /// Call this when you suspect stale connections (e.g., after app resumes).
  void refreshClient() {
    try {
      _innerClient.close();
    } catch (e) {
      // Ignore errors when closing
    }
    _innerClient = http.Client();
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only retry for idempotent methods (GET, HEAD, OPTIONS)
    if (_isIdempotent(request.method)) {
      return _sendWithRetry(request);
    } else {
      // For non-idempotent requests, attempt once but refresh client on failure
      return _sendNonIdempotent(request);
    }
  }

  bool _isIdempotent(String method) {
    final upperMethod = method.toUpperCase();
    return upperMethod == 'GET' ||
        upperMethod == 'HEAD' ||
        upperMethod == 'OPTIONS';
  }

  Future<http.StreamedResponse> _sendWithRetry(http.BaseRequest request) async {
    int attempts = 0;

    while (true) {
      attempts++;
      try {
        // We need to copy the request for retries since StreamedRequest can only be sent once
        final requestCopy = _copyRequest(request);
        return await _innerClient.send(requestCopy);
      } on SocketException catch (e) {
        if (attempts >= maxRetries) {
          print(
              'RetryHttpClient: GET request failed after $maxRetries attempts (SocketException)');
          rethrow;
        }
        print(
            'RetryHttpClient: SocketException on attempt $attempts, retrying: ${e.message}');
        refreshClient();
        await Future.delayed(retryDelay * attempts);
      } on http.ClientException catch (e) {
        if (attempts >= maxRetries) {
          print(
              'RetryHttpClient: GET request failed after $maxRetries attempts (ClientException)');
          rethrow;
        }
        print(
            'RetryHttpClient: ClientException on attempt $attempts, retrying: ${e.message}');
        refreshClient();
        await Future.delayed(retryDelay * attempts);
      }
    }
  }

  Future<http.StreamedResponse> _sendNonIdempotent(
      http.BaseRequest request) async {
    try {
      return await _innerClient.send(request);
    } on SocketException catch (e) {
      print(
          'RetryHttpClient: Non-idempotent request failed (SocketException): ${e.message}');
      // Refresh client for next request, but don't retry this one
      refreshClient();
      rethrow;
    } on http.ClientException catch (e) {
      print(
          'RetryHttpClient: Non-idempotent request failed (ClientException): ${e.message}');
      // Refresh client for next request, but don't retry this one
      refreshClient();
      rethrow;
    }
  }

  /// Creates a copy of the request for retry purposes.
  /// This is necessary because a request can only be sent once.
  http.BaseRequest _copyRequest(http.BaseRequest request) {
    http.BaseRequest requestCopy;

    if (request is http.Request) {
      requestCopy = http.Request(request.method, request.url)
        ..encoding = request.encoding
        ..bodyBytes = request.bodyBytes;
    } else if (request is http.MultipartRequest) {
      requestCopy = http.MultipartRequest(request.method, request.url)
        ..fields.addAll(request.fields)
        ..files.addAll(request.files);
    } else if (request is http.StreamedRequest) {
      throw UnsupportedError('Cannot retry StreamedRequest');
    } else {
      throw UnsupportedError(
          'Cannot copy request of type ${request.runtimeType}');
    }

    requestCopy
      ..headers.addAll(request.headers)
      ..persistentConnection = request.persistentConnection
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects;

    return requestCopy;
  }

  /// Execute a non-idempotent request with fresh client.
  /// Use this when you want to manually retry a POST/PUT after a failure.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   response = await client.post(uri, headers: headers, body: body);
  /// } on SocketException {
  ///   // Ask user if they want to retry
  ///   if (userConfirmsRetry) {
  ///     response = await client.executeWithFreshClient(() =>
  ///       client.post(uri, headers: headers, body: body));
  ///   }
  /// }
  /// ```
  Future<T> executeWithFreshClient<T>(Future<T> Function() request) async {
    refreshClient();
    return await request();
  }

  @override
  void close() {
    _innerClient.close();
  }
}
