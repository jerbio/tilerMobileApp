part of 'device_setting_bloc.dart';

enum LoadingType { initialization, locationProfile, userProfile, none }

sealed class DeviceSettingEvent extends Equatable {
  final String id;
  final LoadingType loadingType;
  const DeviceSettingEvent(
      {required this.id, this.loadingType = LoadingType.none});

  @override
  List<Object> get props => [];
}

class InitializeDeviceSettingEvent extends DeviceSettingEvent {
  const InitializeDeviceSettingEvent({required String id})
      : super(
          id: id,
          loadingType: LoadingType.initialization,
        );

  @override
  List<Object> get props => [];
}

class LoadedDeviceSettingEvent extends DeviceSettingEvent {
  final SessionProfile sessionProfile;
  const LoadedDeviceSettingEvent(
      {required String id, required this.sessionProfile})
      : super(
          id: id,
          loadingType: LoadingType.initialization,
        );

  @override
  List<Object> get props => [];
}

sealed class GetUserProfileDeviceSettingEvent extends DeviceSettingEvent {
  final bool remoteCall;
  const GetUserProfileDeviceSettingEvent(
      {required String id, this.remoteCall = false})
      : super(id: id, loadingType: LoadingType.userProfile);

  @override
  List<Object> get props => [];
}

class GetLocationProfileDeviceSettingEvent extends DeviceSettingEvent {
  final bool showLocationPermissionWidget;
  final BuildContext context;
  final List<Function>? callBacks;
  GetLocationProfileDeviceSettingEvent(
      {required String id,
      required this.showLocationPermissionWidget,
      required this.context,
      this.callBacks})
      : super(id: id, loadingType: LoadingType.locationProfile);

  @override
  List<Object> get props => [];
}

class LoadedLocationProfileDeviceSettingEvent extends DeviceSettingEvent {
  final LocationProfile deviceLocationProfile;
  final List<Function>? callBacks;
  const LoadedLocationProfileDeviceSettingEvent(
      {required String id,
      required this.deviceLocationProfile,
      this.callBacks = null})
      : super(id: id, loadingType: LoadingType.locationProfile);

  @override
  List<Object> get props => [];
}

class LoadedUserProfileDeviceSettingEvent extends DeviceSettingEvent {
  final UserProfile userProfile;
  final List<Function>? callBacks;
  const LoadedUserProfileDeviceSettingEvent(
      {required String id, required this.userProfile, this.callBacks = null})
      : super(id: id, loadingType: LoadingType.userProfile);

  @override
  List<Object> get props => [];
}
