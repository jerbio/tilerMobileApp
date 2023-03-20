const bool isProduction = false;
const bool isDebug = !isProduction;
const bool isRemote = true;
const prodDomain = 'localhost-44322-tiler-prod.conveyor.cloud';
const String devDomain =
    isRemote ? 'localhost-44388-x-if7.conveyor.cloud' : '192.168.1.4:45459';
// const String devDomain = isDebug ? '10.0.2.2:44322' : 'www.tiler.app';
const String tilerDomain = isProduction ? prodDomain : devDomain;
const int stateRetrievalRetry = 100;
const int onTextChangeDelayInMs = 500;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
const int autoHideInMs = 3000;
const String requestDelimiter = ',';
