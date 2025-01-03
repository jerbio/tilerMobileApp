part of 'device_setting_bloc.dart';

sealed class DeviceSettingState extends Equatable {
  const DeviceSettingState();

  @override
  List<Object> get props => [];
}

final class DeviceSettingInitial extends DeviceSettingState {}

final class DeviceLocationSettingLoading extends DeviceSettingState {
  final bool? renderLoadingUI;
  final List<Function>? callBacks;
  DeviceLocationSettingLoading({this.renderLoadingUI, this.callBacks});
}

final class DeviceUserProfileSettingLoading extends DeviceSettingState {}

final class DeviceSettingLoaded extends DeviceSettingState {
  final DeviceProfile? deviceProfile;
  DeviceSettingLoaded({this.deviceProfile});
}
