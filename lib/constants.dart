import 'dart:io';

const bool isProduction = true;
const bool isDebug = !isProduction;
// const bool isDebug = true;
const bool isStaging = true;
const bool isRemote = true;
const prodDomain = 'tiler.app';
const stagingDomain = 'tiler-stage.conveyor.cloud';
const devDomain = 'tiler-dev.conveyor.cloud';
const String tilerDomain =
    isProduction ? prodDomain : (isStaging ? stagingDomain : devDomain);
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
    Platform.isIOS ? 'GOOGLE_CLIENT_ID_IOS' : 'GOOGLE_CLIENT_ID_DEFAULT';
String googleClientSecretKey = 'GOOGLE_CLIENT_SECRET';
String oneSignalAppIdKey =
    isProduction ? 'ONE_SIGNAL_APP_ID' : 'ONE_SIGNAL_APP_ID_DEV';
String googleMapsApiKey =
    isProduction ? 'GOOGLE_MAPS_API_KEY' : 'GOOGLE_MAPS_API_KEY_DEV';
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
