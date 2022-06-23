const bool isProduction = false;
const bool isDebug = true;
const String remoteDomain =
    isDebug ? 'tilerfront.conveyor.cloud' : 'www.tiler.app';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int autoScrollBuffer = 50;
