const bool isProduction = false;
const bool isDebug = true;
const String remoteDomain = isDebug ? '192.168.1.4:45456' : 'www.tiler.app';
// const String remoteDomain =
//     isDebug ? 'tilerfront.conveyor.cloud' : 'www.tiler.app';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int onTextChangeDelatInMs = 1000;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
