import 'dart:io';

const bool isProduction = true;
const bool isDebug = !isProduction;
const bool isRemote = true;
const prodDomain = 'localhost-44322-tiler-prod.conveyor.cloud';
// const String devDomain = 'localhost-44388-x-if7.conveyor.cloud';
const String devDomain = isRemote
    ? 'localhost-44388-x-if7.conveyor.cloud'
    : 'tilerfront.conveyor.cloud';
const String tilerDomain = isProduction ? prodDomain : devDomain;
const int stateRetrievalRetry = 100;
const int onTextChangeDelayInMs = 500;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
const int autoHideInMs = 3000;
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

final List<String> googleApiScopes = [
  'https://www.googleapis.com/auth/userinfo.profile',
  'https://www.googleapis.com/auth/calendar',
  'https://www.googleapis.com/auth/calendar.events.readonly',
  "https://www.googleapis.com/auth/calendar.readonly",
  "https://www.googleapis.com/auth/calendar.events",
  'https://www.googleapis.com/auth/userinfo.email'
];
