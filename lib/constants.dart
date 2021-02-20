const bool isProduction = false;
const bool isDebug = true;
const String remoteDomain = isDebug
    ? 'https://mytilerkid.azurewebsites.net/'
    : 'https://www.tiler.app/';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
