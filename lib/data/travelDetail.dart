import 'dart:convert';

import 'package:tiler_app/data/location.dart';

/// Represents a single travel leg within a travel detail.
class TravelLeg {
  final String? description;
  final String? travelMedium;
  final Location? startLocation;
  final Location? endLocation;
  final int? durationInMs;
  final String? durationText;

  const TravelLeg({
    this.description,
    this.travelMedium,
    this.startLocation,
    this.endLocation,
    this.durationInMs,
    this.durationText,
  });

  factory TravelLeg.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TravelLeg();
    return TravelLeg(
      description: json['description'],
      travelMedium: json['travelMedium'],
      startLocation: json['startLocation'] != null
          ? Location.fromJson(jsonDecode(json['startLocation']))
          : null,
      endLocation: json['endLocation'] != null
          ? Location.fromJson(jsonDecode(json['endLocation']))
          : null,
      durationInMs: json['durationInMs'] != null
          ? int.tryParse(json['durationInMs'].toString())
          : null,
      durationText: json['durationText'],
    );
  }

  Map<String, dynamic> toJson() => {
        'description': description,
        'travelMedium': travelMedium,
        'startLocation': startLocation?.toJson(),
        'endLocation': endLocation?.toJson(),
        'durationInMs': durationInMs?.toString(),
        'durationText': durationText,
      };
}

/// Represents travel details including start, end, locations, and travel legs.
class TravelData {
  final int? start;
  final int? end;
  final Location? startLocation;
  final Location? endLocation;
  final bool? isRigid;
  final List<TravelLeg>? travelLegs;
  final String? travelMedium;
  final bool? isEnabled;
  final bool? isTardy;
  final double? duration;

  const TravelData({
    this.start,
    this.end,
    this.startLocation,
    this.endLocation,
    this.isRigid,
    this.travelLegs,
    this.travelMedium,
    this.isEnabled,
    this.isTardy,
    this.duration,
  });

  factory TravelData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TravelData();
    return TravelData(
      start: json['start'],
      end: json['end'],
      startLocation: json['startLocation'] != null
          ? Location.fromJson(json['startLocation'])
          : null,
      endLocation: json['endLocation'] != null
          ? Location.fromJson(json['endLocation'])
          : null,
      isRigid: json['isRigid'],
      travelLegs: (json['travelLegs'] as List<dynamic>?)
          ?.map((leg) => TravelLeg.fromJson(leg))
          .toList(),
      travelMedium: json['travelMedium'],
      isEnabled: json['isEnabled'],
      isTardy: json['isTardy'],
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'startLocation': startLocation?.toJson(),
        'endLocation': endLocation?.toJson(),
        'isRigid': isRigid,
        'travelLegs': travelLegs?.map((leg) => leg.toJson()).toList(),
        'travelMedium': travelMedium,
        'isEnabled': isEnabled,
        'isTardy': isTardy,
        'duration': duration,
      };
}

/// Wrapper class to hold `before` and `after` travel details.
class TravelDetail {
  final TravelData? before;
  final TravelData? after;

  const TravelDetail({
    this.before,
    this.after,
  });

  factory TravelDetail.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TravelDetail();
    return TravelDetail(
      before:
          json['before'] != null ? TravelData.fromJson(json['before']) : null,
      after: json['after'] != null ? TravelData.fromJson(json['after']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'before': before?.toJson(),
        'after': after?.toJson(),
      };
}
