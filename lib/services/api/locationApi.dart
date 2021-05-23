import 'package:tiler_app/data/tilerEvent.dart';

import 'package:tiler_app/util.dart';

import '../../constants.dart' as Constants;

class LocationApi {
  Future<List<TilerEvent>> getLocationsByName(String name) async {
    String tilerDomain = Constants.tilerDomain;
    String url = tilerDomain + 'api/Location/Name';
    List<TilerEvent> tilerEvents = [
      await TilerEvent.getAdHocTilerEventId(Utility.getUuid),
      await TilerEvent.getAdHocTilerEventId(Utility.getUuid)
    ];
    return tilerEvents;
  }
}
