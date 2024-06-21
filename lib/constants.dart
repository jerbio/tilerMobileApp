import 'dart:io';

const bool isProduction = false;
const bool isDebug = !isProduction;
const bool isRemote = true;
const prodDomain = 'localhost-44322-tiler-prod.conveyor.cloud';
const String devDomain =
    isRemote ? 'localhost-44388-x-if7.conveyor.cloud' : '10.0.2.2:44322';
const String tilerDomain = isProduction ? prodDomain : devDomain;
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
