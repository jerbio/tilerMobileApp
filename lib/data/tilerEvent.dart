import 'dart:convert';
import 'dart:math';
import 'package:tiler_app/data/noteData.dart';
import 'package:tiler_app/data/tileObject.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import '../util.dart';

class TilerEvent extends TilerObj with TimeRange {
  // String? id;
  String? name;
  String? address;
  String? addressDescription;
  String? thirdpartyType;
  String thirdpartyId = '';
  String thirdPartyUserId = '';
  String? searchdDescription;
  int? split;
  TilerEvent? calendarEvent;
  NoteData? noteData;
  bool _isReadOnly = false;
  bool _isProcrastinate = false;
  bool _isRigid = false;
  bool _isComplete = false;
  bool _isEnabled = true;

  // DateTime? _startTime;
  // DateTime? _endTime;

  // int? _startInMs;
  // // ignore: unnecessary_getters_setters
  // int? get start {
  //   return _startInMs;
  // }

  // // ignore: unnecessary_getters_setters
  // set start(int? value) {
  //   _startInMs = value;
  //   if (this._startInMs != null) {
  //     _startTime = DateTime.fromMillisecondsSinceEpoch(this._startInMs!.toInt(),
  //             isUtc: true)
  //         .toLocal();
  //   }
  // }

  // int? _endInMs;
  // // ignore: unnecessary_getters_setters
  // int? get end {
  //   return _endInMs;
  // }

  // ignore: unnecessary_getters_setters
  // set end(int? value) {
  //   _endInMs = value?.toInt();
  //   if (this._endInMs != null) {
  //     _endTime = DateTime.fromMillisecondsSinceEpoch(this._endInMs!.toInt(),
  //             isUtc: true)
  //         .toLocal();
  //   }
  // }

  // DateTime? get startTime {
  //   return _startTime;
  // }

  // DateTime? get endTime {
  //   return _endTime;
  // }

  bool? get isReadOnly {
    return _isReadOnly;
  }

  bool? get isProcrastinate {
    return _isProcrastinate;
  }

  bool? get isRigid {
    return _isRigid;
  }

  bool get isComplete {
    return _isComplete;
  }

  bool get isEnabled {
    return _isEnabled;
  }

  bool get isActive {
    return _isEnabled && !_isComplete;
  }

  bool? isRecurring = false;

  double? colorOpacity = 1;
  int? colorRed = 127;
  int? colorGreen = 127;
  int? colorBlue = 127;

  static T? cast<T>(x) => x is T ? x : null;

  TilerEvent(
      {this.name,
      int? start,
      int? end,
      this.address,
      this.addressDescription,
      String? id,
      String? userId})
      : super(id: id, userId: userId) {
    this.start = start;
    this.end = end;
  }
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
    if (json.containsKey('thirdpartyType')) {
      thirdpartyType = json['thirdpartyType'];
    }
    if (json.containsKey('thirdPartyUserId') &&
        json['thirdPartyUserId'] != null) {
      thirdPartyUserId = json['thirdPartyUserId'];
    }
    if (json.containsKey('searchdDescription')) {
      searchdDescription = json['searchdDescription'];
    }
    start = cast<int>(json['start'])!.toInt();
    end = cast<int>(json['end'])!.toInt();
    if (json.containsKey('colorOpacity')) {
      colorOpacity = cast<double>(json['colorOpacity']);
    }
    if (json.containsKey('colorRed')) {
      colorRed = cast<int>(json['colorRed']);
    }
    if (json.containsKey('colorGreen')) {
      colorGreen = cast<int>(json['colorGreen']);
    }
    if (json.containsKey('colorBlue')) {
      colorBlue = cast<int>(json['colorBlue']);
    }
    if (json.containsKey('isRecurring')) {
      isRecurring = json['isRecurring'];
    }
    if (json.containsKey('splitCount')) {
      split = json['splitCount'];
    }
    if (json.containsKey('blob')) {
      this.noteData = NoteData.fromJson(json['blob']);
    }
    if (json.containsKey('isReadOnly')) {
      _isReadOnly = json['isReadOnly'];
    }
    if (json.containsKey('isReadOnly')) {
      _isReadOnly = json['isReadOnly'];
    }
    if (json.containsKey('isProcrastinateEvent')) {
      _isProcrastinate = json['isProcrastinateEvent'];
    }
    if (json.containsKey('isRigid')) {
      _isRigid = json['isRigid'];
    }
    if (json.containsKey('isEnabled')) {
      _isEnabled = json['isEnabled'];
    }
    if (json.containsKey('isComplete')) {
      _isComplete = json['isComplete'];
    }
  }

  toString() {
    String retValue = "";
    if (this.name != null) {
      retValue += this.name! + ' ';
    }
    if (this.start != null && this.end != null) {
      retValue += (new DateTime.fromMillisecondsSinceEpoch(this.start!.toInt())
              .toString()) +
          ' - ' +
          (new DateTime.fromMillisecondsSinceEpoch(this.end!.toInt())
              .toString());
    }

    return retValue;
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
    retValue.colorBlue = Random().nextInt(255);
    retValue.colorGreen = Random().nextInt(255);
    retValue.colorRed = Random().nextInt(255);

    int timeSpanDifference = retValue.end! - retValue.start!;
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

    retValue.start = revisedStart.toInt();
    retValue.end = revisedEnd.toInt();

    Future<TilerEvent> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
    return retFuture;
  }
}
