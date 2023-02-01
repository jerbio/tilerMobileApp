const bool isProduction = true;
const bool isDebug = !isProduction;
const prodDomain = 'tilerfront.conveyor.cloud';
const String remoteDomain = isDebug ? '192.168.1.4:45457' : 'www.tiler.app';
// const String remoteDomain = isDebug ? '10.0.2.2:44322' : 'www.tiler.app';
// const String remoteDomain =
//     isDebug ? 'tilerfront.conveyor.cloud' : 'www.tiler.app';
const String tilerDomain = isProduction ? prodDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int onTextChangeDelayInMs = 500;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
const int autoHideInMs = 3000;
