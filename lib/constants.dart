import 'dart:io';
const bool isProduction = true;
const bool isDebug = !isProduction;
// const bool isDebug = true;
const bool isStaging = false;
const bool isRemote = true;
const prodDomain = 'tiler.app';
const stagingDomain = 'localhost-44322-tiler-prod.conveyor.cloud';
const devDomain = 'localhost-44388-x-if7.conveyor.cloud';
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
final RegExp emojiRegex = RegExp(
    r'(\ud83c[\udf00-\udfff]|'
    r'\ud83d[\udc00-\ude4f]|'
    r'\ud83d[\ude80-\udeff]|'
    r'\ud83e[\udd00-\uddff]|'
    r'\u2600-\u26FF|'
    r'\u2700-\u27BF|'
    r'[\u2B50\u2B06\u2B05\u2B07]|'
    r'\u231A|\u231B|\u23EA|\u23E9|'
    r'\u1F004|\u1F0CF|\u1F170-\u1F251|'
    r'\u1F600-\u1F64F|'
    r'\u1F900-\u1F9FF|'
    r'\u1F300-\u1F5FF|'
    r'\u1F680-\u1F6FF|'
    r'\u1F700-\u1F77F|'
    r'\u1F780-\u1F7FF|'
    r'\u1F800-\u1F8FF|'
    r'\u1F9C0-\u1F9FF|'
    r'[\u1F1E6-\u1F1FF]{1,2})'
);
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
