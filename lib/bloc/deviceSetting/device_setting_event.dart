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
  final Function getContextCallBack;
  const InitializeDeviceSettingEvent(
      {required String id, required this.getContextCallBack})
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

class GetUserProfileDeviceSettingEvent extends DeviceSettingEvent {
  const GetUserProfileDeviceSettingEvent({required String id})
      : super(id: id, loadingType: LoadingType.userProfile);

  @override
  List<Object> get props => [];
}

class UpdateUserProfileDateOfBirthSettingEvent extends DeviceSettingEvent {
  final DateTime dateOfBirth;
  final String id;

  const UpdateUserProfileDateOfBirthSettingEvent({
    required this.id,
    required this.dateOfBirth,
  }) : super(id: id, loadingType: LoadingType.userProfile);

  @override
  List<Object> get props => [id, dateOfBirth];
}

class UpdateUserProfileDeviceSettingEvent extends DeviceSettingEvent {
  final String id;

  const UpdateUserProfileDeviceSettingEvent({
    required this.id,
  }) : super(id: id, loadingType: LoadingType.userProfile);

  @override
  List<Object> get props => [id];
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

class UpdateDarkModeMainSettingDeviceSettingEvent extends DeviceSettingEvent {
  final bool isDarkMode;
  UpdateDarkModeMainSettingDeviceSettingEvent(
      {required this.isDarkMode, required String id})
      : super(id: id, loadingType: LoadingType.none);

  @override
  List<Object> get props => [id, loadingType, isDarkMode];
}

class LogOutMainSettingDeviceSettingEvent extends DeviceSettingEvent {
  final BuildContext context;
  LogOutMainSettingDeviceSettingEvent(
      {required String id, required this.context})
      : super(id: id, loadingType: LoadingType.none);
}

class DeleteAccountMainSettingDeviceSettingEvent extends DeviceSettingEvent {
  final BuildContext context;
  DeleteAccountMainSettingDeviceSettingEvent(
      {required String id, required this.context})
      : super(id: id, loadingType: LoadingType.none);
}
