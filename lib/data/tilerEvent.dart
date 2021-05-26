import 'dart:convert';
import 'package:tiler_app/data/tileObject.dart';
import '../util.dart';

class TilerEvent extends TilerObj {
  // String? id;
  String? name;
  String? address;
  String? addressDescription;
  String? thirdpartyType;
  String? searchdDescription;

  double? start;
  double? end;

  bool? isRecurring;
  double? colorOpacity;
  int? colorRed;
  int? colorGreen;
  int? colorBlue;

  bool? isAllDay = false;

  static T? cast<T>(x) => x is T ? x : null;

  TilerEvent.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('name')) {
      name = json['name'];
    }
    if (json.containsKey('address')) {
      address = json['address'];
    }
    if (json.containsKey('addressDescription')) {
      addressDescription = json['addressDescription'];
    }
    thirdpartyType = json['thirdpartyType'];
    searchdDescription = json['searchdDescription'];
    start = cast<int>(json['start'])!.toDouble();
    end = cast<int>(json['end'])!.toDouble();
    colorOpacity = cast<double>(json['colorOpacity']);
    colorRed = cast<int>(json['colorRed']);
    colorGreen = cast<int>(json['colorGreen']);
    colorBlue = cast<int>(json['colorBlue']);
    isRecurring = json['isRecurring'];
  }

  static Future<TilerEvent> getAdHocTilerEventId(String id) {
//     {
//     "Error": {
//         "code": "0",
//         "Message": ""
//     },
//     "Content": {
//         "id": "0a78ae5d-2858-4842-94b5-cb60edd1d65e_7_07d5f9b3-a71a-4eb9-bd33-096c4ff51b00_22bf7ae0-1299-4de0-b49d-8897edcb69ef",
//         "start": 1615306440000,
//         "end": 1615313640000,
//         "name": "Morning 203 plans",
//         "travelTimeBefore": 600000.0,
//         "travelTimeAfter": 0.0,
//         "address": "1240 hover st #200, longmont, co 80501, united states",
//         "addressDescription": "1240 hover st #200, longmont, co 80501, united states",
//         "searchdDescription": "gym",
//         "rangeStart": 1615118400000,
//         "rangeEnd": 1615118400000,
//         "thirdpartyType": "tiler",
//         "colorOpacity": 1.0,
//         "colorRed": 38,
//         "colorGreen": 255,
//         "colorBlue": 128,
//         "isPaused": false,
//         "isComplete": true,
//         "isRecurring": true
//     }
// }

    String subEventString =
        "{\"Error\":{\"code\":\"0\",\"Message\":\"\"},\"Content\":{\"id\":\"0a78ae5d-2858-4842-94b5-cb60edd1d65e_7_07d5f9b3-a71a-4eb9-bd33-096c4ff51b00_22bf7ae0-1299-4de0-b49d-8897edcb69ef\",\"start\":1615306440000,\"end\":1615313640000,\"name\":\"Morning 203 plans\",\"travelTimeBefore\":600000,\"travelTimeAfter\":0,\"address\":\"1240 hover st #200, longmont, co 80501, united states\",\"addressDescription\":\"1240 hover st #200, longmont, co 80501, united states\",\"searchdDescription\":\"gym\",\"rangeStart\":1615118400000,\"rangeEnd\":1615118400000,\"thirdpartyType\":\"tiler\",\"colorOpacity\":1,\"colorRed\":38,\"colorGreen\":255,\"colorBlue\":128,\"isPaused\":false,\"isComplete\":true,\"isRecurring\":true}}";

    Map<String, dynamic> subEventMap = jsonDecode(subEventString);
    subEventMap['Content']['id'] = id;

    TilerEvent retValue = TilerEvent.fromJson(subEventMap['Content']);

    double timeSpanDifference = retValue.end! - retValue.start!;
    int currentTime = Utility.msCurrentTime;

    // currentTile
    int revisedStart = currentTime - Utility.oneHour.inMilliseconds;
    int revisedEnd = currentTime + Utility.fifteenMin.inMilliseconds;

    // nextTile
    // int revisedStart = currentTime + Utility.fifteenMin.inMilliseconds;
    // int revisedEnd = currentTime + Utility.oneHour.inMilliseconds;

    // elapsedTile
    // int revisedStart = currentTime - Utility.oneHour.inMilliseconds;
    // int revisedEnd = currentTime - Utility.fifteenMin.inMilliseconds;

    retValue.start = revisedStart.toDouble();
    retValue.end = revisedEnd.toDouble();

    Future<TilerEvent> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
    return retFuture;
  }
}
