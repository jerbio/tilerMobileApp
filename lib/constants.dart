const bool isProduction = false;
const bool isDebug = true;
const String remoteDomain =
    isDebug ? 'cff7-73-95-66-159.ngrok.io' : 'www.tiler.app';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int autoScrollBuffer = 50;
