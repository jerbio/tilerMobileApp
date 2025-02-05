part of 'device_setting_bloc.dart';

sealed class DeviceSettingState extends Equatable {
  const DeviceSettingState();

  @override
  List<Object> get props => [];
}

final class DeviceSettingInitial extends DeviceSettingState {}

final class DeviceLocationSettingLoading extends DeviceSettingState {
  final String? id;
  final bool? renderLoadingUI;
  final List<Function>? callBacks;
  DeviceLocationSettingLoading({this.renderLoadingUI, this.callBacks, this.id});
}

final class DeviceLocationSettingUIPending
    extends DeviceLocationSettingLoading {
  final String? id;
  final List<Function>? callBacks;
  DeviceLocationSettingUIPending({this.callBacks, this.id})
      : super(id: id, renderLoadingUI: true, callBacks: callBacks);

  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, renderLoadingUI ?? false, callBacks ?? []];
}

final class DeviceUserProfileSettingLoading extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceUserProfileSettingLoading({this.sessionProfile, this.id});

  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile()];
}

final class DeviceSettingLoaded extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceSettingLoaded({this.sessionProfile, this.id});
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile()];
}

final class DeviceSettingError extends DeviceSettingLoaded {
  final String? id;
  final SessionProfile? sessionProfile;
  final dynamic error;
  DeviceSettingError({required this.error, this.sessionProfile, this.id});
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), error];
}
