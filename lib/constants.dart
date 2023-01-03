import 'package:tiler_app/data/timeline.dart';
import 'package:tiler_app/util.dart';

const bool isProduction = false;
const bool isDebug = true;
// const String remoteDomain = isDebug ? '192.168.1.4:45456' : 'www.tiler.app';
// const String remoteDomain = isDebug ? '10.0.2.2:45456' : 'www.tiler.app';
const String remoteDomain =
    isDebug ? 'tilerfront.conveyor.cloud' : 'www.tiler.app';
const String tilerDomain = isProduction ? remoteDomain : remoteDomain;
const int stateRetrievalRetry = 100;
const int onTextChangeDelayInMs = 500;
const int autoCompleteTriggerCharacterCount = 3;
const int autoScrollBuffer = 50;
const int autoHideInMs = 3000;
final Timeline initialScheduleTimeline = Timeline.fromDateTimeAndDuration(
    Utility.currentTime().add(Duration(days: -3)), Duration(days: 7));
