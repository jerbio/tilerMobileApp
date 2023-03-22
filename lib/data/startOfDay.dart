import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:tiler_app/util.dart';

part 'startOfDay.g.dart';

class StartOfDay {
  TimeOfDay? timeOfDay;
  Duration? timeZoneOffSet;
  String? timeZone;

  StartOfDayConfig generateStartOfDayConfig() {
    StartOfDayConfig retValue = StartOfDayConfig();
    retValue.TimeOfDay = timeOfDay?.toString();
    retValue.TimeZoneOffSet = timeZoneOffSet?.inMinutes.toString();
    retValue.TimeZone = timeZone;
    return retValue;
  }
}

@JsonSerializable(explicitToJson: true)
class StartOfDayConfig {
  String? TimeOfDay;
  String? TimeZoneOffSet;
  String? TimeZone;
  StartOfDayConfig();

  StartOfDay toStartOfDay() {
    StartOfDay retValue = StartOfDay();
    if (this.TimeOfDay != null && this.TimeOfDay!.isNotEmpty) {
      int? timeInMs = int.tryParse(this.TimeOfDay!);
      if (timeInMs != null) {
        retValue.timeOfDay =
            Utility.timeOfDayFromTime((Utility.localDateTimeFromMs(timeInMs)));
      }
    }

    if (this.TimeZoneOffSet != null && this.TimeZoneOffSet!.isNotEmpty) {
      int? minutes = int.tryParse(this.TimeZoneOffSet!);
      if (minutes != null) {
        retValue.timeZoneOffSet = Duration(minutes: minutes);
      }
    }
    if (this.TimeZone != null && this.TimeZone!.isNotEmpty) {
      retValue.timeZone = this.TimeZone;
    }

    return retValue;
  }

  factory StartOfDayConfig.fromJson(Map<String, dynamic> json) =>
      _$StartOfDayConfigFromJson(json);

  Map<String, dynamic> toJson() => _$StartOfDayConfigToJson(this);
}
