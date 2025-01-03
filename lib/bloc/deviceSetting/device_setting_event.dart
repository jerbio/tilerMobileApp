part of 'device_setting_bloc.dart';

sealed class DeviceSettingEvent extends Equatable {
  const DeviceSettingEvent();

  @override
  List<Object> get props => [];
}

sealed class GetUserProfileDeviceSettingEvent extends DeviceSettingEvent {
  const GetUserProfileDeviceSettingEvent();

  @override
  List<Object> get props => [];
}

class GetLocationProfileDeviceSettingEvent extends DeviceSettingEvent {
  final bool showLocationPermissionWidget;
  final List<Function>? callBacks;
  const GetLocationProfileDeviceSettingEvent(
      {required this.showLocationPermissionWidget, this.callBacks})
      : super();

  @override
  List<Object> get props => [];
}

class LoadedProfileDeviceSettingEvent extends DeviceSettingEvent {
  final DeviceLocationProfile deviceLocationProfile;
  const LoadedProfileDeviceSettingEvent({required this.deviceLocationProfile})
      : super();

  @override
  List<Object> get props => [];
}
