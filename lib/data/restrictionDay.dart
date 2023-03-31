// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:tiler_app/data/request/RestrictionWeekConfig.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:tiler_app/data/tileObject.dart';
import 'package:tiler_app/util.dart';
import 'package:timezone/timezone.dart';

class RestrictionTimeLine extends TilerObj {
  TimeOfDay? _start;
  Duration? _duration;
  int? weekDay; // sunday - 0, Monday  - 1 ... Saturday - 6
  RestrictionTimeLine({
    start,
    duration,
    this.weekDay,
  }) {
    this._start = start;
    this._duration = duration;
  }
  static T? cast<T>(x) => x is T ? x : null;

  set start(TimeOfDay? value) {
    this._start = value;
  }

  set duration(Duration? value) {
    this._duration = value;
  }

  TimeOfDay? get start {
    return _start;
  }

  Duration? get duration {
    return _duration;
  }

  bool get isValid {
    if (_duration == null) {
      return false;
    }
    return _duration!.inMilliseconds > 0;
  }

  RestrictionTimeLine copyWith({
    TimeOfDay? start,
    Duration? duration,
    int? weekDay,
  }) {
    return RestrictionTimeLine(
      start: _start ?? this._start,
      duration: _duration ?? this._duration,
      weekDay: weekDay ?? this.weekDay,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'start': this.start,
      'duration': this.duration,
      'weekDay': weekDay,
    };
  }

  factory RestrictionTimeLine.fromMap(Map<String, dynamic> map) {
    String timzeZone = 'utc';
    if (map.containsKey('timeZone') &&
        map['timeZone'] != null &&
        map['timeZone'].isNotEmpty) {
      timzeZone = map['timeZone'];
    }
    TZDateTime? start;
    if (map['start'] != null) {
      final tzLocation = getLocation(timzeZone);
      DateTime startTime =
          DateTime.fromMillisecondsSinceEpoch(map['start'] as int).toUtc();
      start = TZDateTime.from(startTime, tzLocation);
    }
    return RestrictionTimeLine(
      start: start != null
          ? TimeOfDay(hour: start.hour, minute: start.minute)
          : null,
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'].toInt() as int)
          : null,
      weekDay: map['weekDay'] != null ? map['weekDay'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RestrictionTimeLine.fromJson(String source) =>
      RestrictionTimeLine.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'RestrictionTimeLine(_start: $_start, _duration: $_duration, weekDay: $weekDay)';

  @override
  bool operator ==(covariant RestrictionTimeLine other) {
    if (identical(this, other)) return true;

    return other._start == _start &&
        other._duration == _duration &&
        other.weekDay == weekDay;
  }

  @override
  int get hashCode => _start.hashCode ^ _duration.hashCode ^ weekDay.hashCode;
}

class RestrictionDay extends TilerObj {
  RestrictionTimeLine? _restrictionTimeLine;
  int? _weekday;
  static T? cast<T>(x) => x is T ? x : null;

  RestrictionDay({restrictionTimeLine, weekday}) {
    this._restrictionTimeLine = restrictionTimeLine;
    this._weekday = weekday;
  }

  RestrictionTimeLine? get restrictionTimeLine {
    return _restrictionTimeLine;
  }

  set restrictionTimeLine(RestrictionTimeLine? value) {
    this._restrictionTimeLine = value;
  }

  int? get weekday {
    return _weekday;
  }

  set weekday(int? value) {
    this._weekday = value;
  }

  RestrictionDay.fromJson(Map<String, dynamic> json) : super.fromJson(json) {
    if (json.containsKey('restrictionTimeLine')) {
      _restrictionTimeLine =
          RestrictionTimeLine.fromMap(json['restrictionTimeLine']);
    }

    if (json.containsKey('weekday')) {
      weekday = cast<int>(json['weekday'])!;
    }
  }

  RestrictionWeekDayConfig toRestrictionWeekDayConfig() {
    RestrictionWeekDayConfig retValue = RestrictionWeekDayConfig();
    retValue.Start = _restrictionTimeLine!.start!.formatTimeOfDay;

    DateTime endTime = DateTime(
            Utility.currentTime().year,
            1,
            1,
            _restrictionTimeLine!.start!.hour,
            _restrictionTimeLine!.start!.minute)
        .add(_restrictionTimeLine!.duration!);
    retValue.End = TimeOfDay.now().toString();
    retValue.End = TimeOfDay.fromDateTime(endTime).formatTimeOfDay;
    retValue.Index = this._weekday.toString();
    return retValue;
  }
}
