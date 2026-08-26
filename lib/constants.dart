import 'dart:io';

const bool isProduction = false;
const bool isDebug = !isProduction;
// const bool isDebug = true;
const bool isStaging = true;
const bool isRemote = true;
const prodDomain = 'tiler.app';
const stagingDomain = 'tiler-stage.conveyor.cloud';
const devDomain = 'tiler-dev.conveyor.cloud';
const String tilerDomain =
    isProduction ? prodDomain : (isStaging ? stagingDomain : devDomain);

/// Public privacy policy URL surfaced in the AI data-sharing disclosure. Must
/// describe what data is collected, how it is collected, how it is used, and
/// that it may be shared with a third-party AI service.
const String privacyPolicyUrl = 'https://tiler.app/privacy';

/// Public terms of service URL surfaced in the sign-in footer.
const String termsOfServiceUrl = 'https://tiler.app/TOS';

const int stateRetrievalRetry = 100;
const int onTextChangeDelayInMs = 700;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
const int autoHideInMs = 3000;
const int autoRefreshSubEventDurationInMinutes = 4;
const int animationDuration = 200;
const String requestDelimiter = ',';
const String cannotVerifyError = 'Cannot verify error';
String adhocToken = '';

const Duration retryLoginDuration = Duration(seconds: 2);
const int retryLoginCount = 150;
String googleClientDefaultKey = 'GOOGLE_CLIENT_ID_DEFAULT';
String googleClientIdKey =
    Platform.isIOS ? 'GOOGLE_CLIENT_ID_IOS' : 'GOOGLER_CLIENT_ID_DEFAULT';
String googleClientSecretKey = 'GOOGLE_CLIENT_SECRET';
String oneSignalAppIdKey =
    isProduction ? 'ONE_SIGNAL_APP_ID' : 'ONE_SIGNAL_APP_ID_DEV';
String googleMapsApiKey =
    isProduction ? 'GOOGLE_MAPS_API_KEY' : 'GOOGLE_MAPS_API_KEY_DEV';

/// Apple "Services ID" — the OAuth client id for Apple's *web* sign-in flow.
///
/// Android has no native Sign in with Apple SDK, so the Android app runs the same
/// web flow as TilerWeb (Chrome Custom Tab -> appleid.apple.com -> our callback).
/// That means Android identity tokens are audienced to this Services ID rather
/// than the iOS bundle id, which is why the client tells the server which surface
/// it is (see `appleClientType`). iOS never uses these values — it goes native.
const String appleServicesId = 'app.tiler.web.signin';

/// Server endpoint registered with Apple as a Return URL for the Android flow. It
/// relays Apple's `form_post` back into the app via an `intent://` redirect.
final Uri appleAndroidRedirectUri =
    Uri.https(tilerDomain, '/Account/AppleAndroidCallback');

/// Microsoft (Entra) native sign-in — identity-only, via flutter_appauth (AppAuth).
///
/// This is the mobile counterpart of the web OpenID Connect flow. The app performs
/// an interactive Entra sign-in, obtains an `id_token` audienced to this client id,
/// and forwards it to the Tiler server, which does the authoritative verification
/// (signature, per-tenant issuer, audience, nonce) — see the portable
/// `MicrosoftIdentityService`. No calendar/Graph access is requested: Microsoft is
/// wired for identity only, exactly like Apple.
///
/// By default this reuses the existing Entra app registration (the same id used by
/// the web flow in `Web.config`). If a separate mobile (public-client) app is
/// registered instead, update this value AND add that id to the server's
/// `microsoftClientIds` allow-list.
const String microsoftClientId = '6d9f8ba1-1980-4a28-9516-7a8af2227bd2';

/// Entra multi-tenant + personal-account endpoints (`/common`). The endpoints are
/// specified explicitly (rather than via OIDC discovery) so AppAuth skips its
/// client-side issuer check — the `/common` discovery document advertises a
/// templated `{tenantid}` issuer that would otherwise fail AppAuth's validation.
/// The Tiler server performs the real per-tenant issuer validation.
const String microsoftAuthorizationEndpoint =
    'https://login.microsoftonline.com/common/oauth2/v2.0/authorize';
const String microsoftTokenEndpoint =
    'https://login.microsoftonline.com/common/oauth2/v2.0/token';

/// AppAuth redirect. The scheme is registered natively (Android
/// `appAuthRedirectScheme` manifest placeholder + iOS `CFBundleURLSchemes`) and
/// must also be added as a "Mobile and desktop applications" redirect URI on the
/// Entra app registration. Uses the `msal<clientId>://auth` shape the portal
/// pre-offers as a checkbox (its manual custom-scheme box rejects hand-typed
/// schemes). The "MSAL only" portal label is just a naming hint — Entra honors
/// this redirect for any OAuth client, including AppAuth.
const String microsoftRedirectScheme =
    'msal6d9f8ba1-1980-4a28-9516-7a8af2227bd2';
const String microsoftRedirectUri =
    'msal6d9f8ba1-1980-4a28-9516-7a8af2227bd2://auth';

/// Identity-only scopes: no `offline_access` (we never refresh) and no Graph
/// scopes (no calendar sync). `openid` yields the id_token; `email`/`profile`
/// populate the email/name claims the server reads.
const List<String> microsoftScopes = ['openid', 'profile', 'email'];

final List<String> googleApiScopes = [
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  "https://www.googleapis.com/auth/calendar.readonly",
  "https://www.googleapis.com/auth/calendar.events",
  'https://www.googleapis.com/auth/userinfo.email'
];

final String workLocationNickName = "work";
final String homeLocationNickName = "home";
final String workProfileNickName = "work";
final String homeProfileNickName = "personal";
final List<String> invalidLocationNames = ["anywhere"];
final int autoCompleteMinCharLength = 3;
final int numberOfDaysToLoad = 8;
String? userId = "";
String? userName = "";
final Duration retryPermissionCheck = Duration(minutes: 60);
