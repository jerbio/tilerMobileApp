import 'dart:convert';
import 'dart:math';

import 'package:flutter_appauth/flutter_appauth.dart';
import '../../constants.dart' as Constants;

/// Result of a native Microsoft (Entra) sign-in.
///
/// [identityToken] is the Entra `id_token` (AppAuth has already checked its
/// signature, audience, expiry and nonce); [rawNonce] is the value this client
/// generated. Both are forwarded to the Tiler server, which performs the
/// authoritative verification — the server accepts the raw or hashed nonce, and
/// Entra echoes the raw nonce into the token's `nonce` claim.
///
/// [firstName]/[lastName]/[email] are decoded locally from the id_token payload
/// purely to seed a *new* user record (the server derives the trusted email/name
/// for existing users from the verified token itself).
class MicrosoftSignInResult {
  MicrosoftSignInResult({
    required this.identityToken,
    required this.rawNonce,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.providerKey,
  });

  final String identityToken;
  final String rawNonce;
  final String firstName;
  final String lastName;
  final String? email;
  final String? providerKey;
}

/// Thin wrapper around flutter_appauth for Microsoft/Entra identity-only sign-in.
///
/// This is the mobile counterpart of the web OpenID Connect flow. It launches the
/// system browser (Chrome Custom Tab / ASWebAuthenticationSession), performs the
/// authorization-code + PKCE exchange as a public client (no secret), and returns
/// the resulting `id_token`. No calendar/Graph scopes are requested — Microsoft is
/// wired for identity only, mirroring Apple.
class MicrosoftSignInApi {
  static const FlutterAppAuth _appAuth = FlutterAppAuth();

  /// Entra endpoints are provided explicitly (no OIDC discovery) so AppAuth does
  /// not reject the `/common` templated `{tenantid}` issuer. The Tiler server does
  /// the real per-tenant issuer validation.
  static const AuthorizationServiceConfiguration _serviceConfiguration =
      AuthorizationServiceConfiguration(
    authorizationEndpoint: Constants.microsoftAuthorizationEndpoint,
    tokenEndpoint: Constants.microsoftTokenEndpoint,
  );

  /// Generates a cryptographically random URL-safe nonce (replay protection —
  /// same scheme as the Apple flow, but Entra echoes it back unhashed).
  static String generateRawNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Launches the interactive Entra sign-in and returns the id_token + raw nonce.
  ///
  /// Returns `null` when the user cancels (so callers can quietly abort). Any
  /// other AppAuth failure is rethrown for the caller to surface.
  static Future<MicrosoftSignInResult?> login() async {
    final String rawNonce = generateRawNonce();

    try {
      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Constants.microsoftClientId,
          Constants.microsoftRedirectUri,
          serviceConfiguration: _serviceConfiguration,
          scopes: Constants.microsoftScopes,
          // Supplying our own nonce makes AppAuth set it on the authorization
          // request and validate it on the token response; Entra returns it raw
          // in the id_token `nonce` claim, which the Tiler server also checks.
          nonce: rawNonce,
          // Always let the user choose an account rather than silently reusing a
          // cached session.
          promptValues: const ['select_account'],
        ),
      );

      final String? idToken = result?.idToken;
      if (idToken == null || idToken.isEmpty) {
        return null;
      }

      final Map<String, dynamic> claims = _decodeJwtClaims(idToken);
      final String? email = _firstNonEmpty([
        claims['email'] as String?,
        claims['preferred_username'] as String?,
        claims['upn'] as String?,
      ]);
      final (String first, String last) = _resolveName(claims);

      return MicrosoftSignInResult(
        identityToken: idToken,
        rawNonce: rawNonce,
        firstName: first,
        lastName: last,
        email: email,
        providerKey: claims['sub'] as String?,
      );
    } on FlutterAppAuthUserCancelledException {
      return null;
    }
  }

  /// Decodes the (untrusted) JWT payload. Used only to pre-fill display fields
  /// for a brand-new account; the server re-verifies everything.
  static Map<String, dynamic> _decodeJwtClaims(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      return const {};
    }
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      final decoded = json.decode(payload);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  /// Splits Entra's name claims into first/last, preferring the discrete
  /// `given_name`/`family_name` and falling back to splitting `name`.
  static (String, String) _resolveName(Map<String, dynamic> claims) {
    final given = (claims['given_name'] as String?)?.trim();
    final family = (claims['family_name'] as String?)?.trim();
    if ((given != null && given.isNotEmpty) ||
        (family != null && family.isNotEmpty)) {
      return (given ?? '', family ?? '');
    }

    final fullName = (claims['name'] as String?)?.trim();
    if (fullName == null || fullName.isEmpty) {
      return ('', '');
    }
    final segments = fullName.split(RegExp(r'\s+'));
    if (segments.length == 1) {
      return (segments.first, '');
    }
    return (segments.first, segments.sublist(1).join(' '));
  }

  static String? _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }
}
