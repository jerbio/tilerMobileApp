import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/ForecastResponse.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/restrictionProfile.dart';

abstract class ForecastState extends Equatable {
  final String? requestId;
  final String? name;
  final Duration? duration;
  final DateTime? endTime;
  final Location? location;
  final RestrictionProfile? restrictionProfile;

  const ForecastState({required this.duration, required this.endTime, this.location, this.name, this.restrictionProfile, this.requestId});

  @override
  List<Object?> get props => [duration, endTime, location];
}

class ForecastInitial extends ForecastState {
  ForecastInitial({Duration? duration, DateTime? endTime, Location? location, String? requestId})
      : super(duration: duration, endTime: endTime, location: location, requestId: requestId);
      @override
  List<Object?> get props => [duration, endTime,
  location?.address??"",
  location?.description??"",
  location?.longitude??Location.defaultLongitudeAndLatitude,
  location?.latitude??Location.defaultLongitudeAndLatitude,
  location?.isVerified??false,
  location?.isNull??false,
  location?.source??"",
  location?.thirdPartyId??"",
  location?.isDefault??false,
  location?.id??"",
  ];
}

class ForecastLoading extends ForecastState {
  const ForecastLoading(
      {required Duration duration, required DateTime? endTime, Location? location, String? requestId})
      : super(duration: duration, endTime: endTime, location: location, requestId: requestId);

  @override
  List<Object?> get props => [duration, endTime, 
  location?.address??"",
  location?.description??"",
  location?.longitude??Location.defaultLongitudeAndLatitude,
  location?.latitude??Location.defaultLongitudeAndLatitude,
  location?.isVerified??false,
  location?.isNull??false,
  location?.source??"",
  location?.thirdPartyId??"",
  location?.isDefault??false,
  location?.id??"",
  ];
}

class ForecastLoaded extends ForecastState {
  final bool isViable;
  final ForecastResponse foreCastResponse;

  const ForecastLoaded({
    required this.isViable,
    required this.foreCastResponse,
    required Duration duration,
    required DateTime? endTime,
    Location? location,
    String? requestId
  }) : super(duration: duration, endTime: endTime, location: location, requestId: requestId);

  @override
  List<Object?> get props => [isViable, foreCastResponse, duration, endTime
  
  , location?.address??"",
  location?.description??"",
  location?.longitude??Location.defaultLongitudeAndLatitude,
  location?.latitude??Location.defaultLongitudeAndLatitude,
  location?.isVerified??false,
  location?.isNull??false,
  location?.source??"",
  location?.thirdPartyId??"",
  location?.isDefault??false,
  location?.id??"",
  ];
}

class ForecastError extends ForecastState {
  final String error;

  const ForecastError(this.error,
      {required Duration duration, required DateTime? endTime})
      : super(duration: duration, endTime: endTime);

  @override
  List<Object?> get props => [error, duration, endTime];
}
