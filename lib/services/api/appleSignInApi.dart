import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../constants.dart' as Constants;

/// Thin wrapper around the native "Sign in with Apple" credential request.
///
/// Apple identity-only sign-in relies on a one-time nonce to bind the returned
/// identity token to this specific sign-in attempt (replay protection). The
/// client generates a random raw nonce, sends the SHA-256 hash of it to Apple
/// (Apple embeds that hash in the token's `nonce` claim), and forwards the
/// *raw* nonce to Tiler's server, which re-hashes and compares. See the server
/// verifier in TilerIntegrations and the AppleAuthentication OAuth grant.
class AppleSignInApi {
  /// Generates a cryptographically random URL-safe nonce.
  static String generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// SHA-256 hex digest of [input] — the value passed to Apple as the `nonce`.
  static String sha256OfString(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  /// Identifies the surface to the Tiler server so it can pick the expected
  /// `aud` claim: iOS tokens carry the app bundle id, Android tokens carry the
  /// Services ID (because Android runs Apple's web flow).
  static String get clientType => Platform.isAndroid ? 'android' : 'ios';

  /// Apple has no native Android SDK, so on Android the plugin opens Apple's web
  /// OAuth flow in a Chrome Custom Tab and *requires* these options; passing them
  /// on iOS would wrongly force the web flow, so they are Android-only.
  static WebAuthenticationOptions? get _webAuthenticationOptions =>
      Platform.isAndroid
          ? WebAuthenticationOptions(
              clientId: Constants.appleServicesId,
              redirectUri: Constants.appleAndroidRedirectUri,
            )
          : null;

  /// Requests an Apple ID credential. [hashedNonce] must be the SHA-256 hash of
  /// the raw nonce that is later sent to the Tiler server.
  ///
  /// [state] is round-tripped unmodified by Apple. On Android the response comes
  /// back through a browser redirect rather than a native callback, so the caller
  /// compares the returned state to detect a response that did not originate from
  /// the request it started (CSRF / injected-response defense).
  static Future<AuthorizationCredentialAppleID> login(String hashedNonce,
      {String? state}) {
    return SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
      state: state,
      webAuthenticationOptions: _webAuthenticationOptions,
    );
  }
}
