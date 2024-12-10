import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/noteData.dart';
import 'package:tiler_app/data/tileObject.dart';
import 'package:tiler_app/data/timeRangeMix.dart';
import '../util.dart';

enum TilePriority { low, medium, high }

enum TileSource { tiler, google, outlook }

class TilerEvent extends TilerObj with TimeRange {
  String? name;
  String? address;
  String? addressDescription;
  TileSource? thirdpartyType;
  String? thirdpartyId = '';
  String thirdPartyUserId = '';
  String? searchdDescription;
  String? locationId = '';
  String? tileShareDesignatedId = '';
  int? split;
  NoteData? noteData;
  bool _isReadOnly = false;
  bool _isProcrastinate = false;
  bool _isRigid = false;
  bool _isComplete = false;
  bool _isEnabled = true;
  TilePriority _tilePriority = TilePriority.medium;

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
    if (json.containsKey('thirdPartyType') && json['thirdPartyType'] != null) {
      try {
        thirdpartyType = TileSource.values.byName(json['thirdPartyType']);
      } catch (e) {
        thirdpartyType = null;
      }
    }
    if (json.containsKey('thirdPartyUserId') &&
        json['thirdPartyUserId'] != null) {
      thirdPartyUserId = json['thirdPartyUserId'];
    }

    if (json.containsKey('thirdPartyId') && json['thirdPartyId'] != null) {
      thirdpartyId = json['thirdPartyId'];
    }

    if (json.containsKey('searchdDescription')) {
      searchdDescription = json['searchdDescription'];
    }
    if (json['start'] != null) {
      start = cast<int>(json['start'])!.toInt();
    }
    if (json['end'] != null) {
      end = cast<int>(json['end'])!.toInt();
    }
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
    if (json.containsKey('locationId')) {
      locationId = json['locationId'];
    }
    if (json.containsKey('tileShareDesignatedId')) {
      tileShareDesignatedId = json['tileShareDesignatedId'];
    }
    if (json.containsKey('priority')) {
      TilePriority priority = TilePriority.medium;
      switch (json['priority']) {
        case "low":
          priority = TilePriority.low;
          break;
        case "medium":
          priority = TilePriority.medium;
          break;
        case "high":
          priority = TilePriority.high;
          break;
      }
      this._tilePriority = priority;
    }
  }

  Color? get color {
    if (this.colorRed != null &&
        this.colorGreen != null &&
        this.colorGreen != null) {
      return Color.fromRGBO(
          this.colorRed!, this.colorGreen!, this.colorGreen!, 1);
    }
    return null;
  }

  TilePriority get priority {
    return _tilePriority;
  }

  String get uniqueId {
    return (this.thirdpartyType == null ||
                this.thirdpartyType == TileSource.tiler ||
                (this.thirdpartyId != null && this.thirdpartyId!.isEmpty)
            ? this.id
            : this.thirdpartyId) ??
        "";
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

  bool get isFromTiler {
    return this.thirdpartyType == TileSource.tiler;
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

    retValue.start = revisedStart.toInt();
    retValue.end = revisedEnd.toInt();

    Future<TilerEvent> retFuture =
        new Future.delayed(const Duration(seconds: 0), () => retValue);
    return retFuture;
  }
}
