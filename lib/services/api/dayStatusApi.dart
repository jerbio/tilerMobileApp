import 'dart:math';

import 'package:tiler_app/data/dayStatus.dart';
import 'package:tiler_app/services/api/subCalendarEventApi.dart';
import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class DayStatusApi {
  Future<DayStatus?> getDayStatus(int dayInMs) {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain + 'api/DayStatus';
    return getAdHocDayStatus(dayInMs);
  }

  Future<DayStatus> getAdHocDayStatus(int dayInMs) async {
    DayStatus retValue = new DayStatus();
    retValue.dayDate = DateTime.fromMillisecondsSinceEpoch((dayInMs));
    SubCalendarEventApi subCalendarEventApi =
        new SubCalendarEventApi(getContextCallBack: () => null);
    retValue.completedSubEvents = [
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid)),
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid)),
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid))
    ];
    retValue.warningSubEvents = [
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid)),
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid))
    ];
    retValue.errorSubEvents = [
      await subCalendarEventApi.getAdHocSubEventId((Utility.getUuid))
    ];

    retValue.sleepHours = Random().nextDouble() * 9;
    Future<DayStatus> retFuture =
        new Future.delayed(const Duration(seconds: 1), () => retValue);
    return retFuture;
  }
}
