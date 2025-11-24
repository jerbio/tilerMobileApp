part of 'device_setting_bloc.dart';

sealed class DeviceSettingState extends Equatable {
  final bool isDarkMode;

  const DeviceSettingState({this.isDarkMode = false});
  @override
  List<Object> get props => [isDarkMode];
}

final class DeviceSettingInitial extends DeviceSettingState {
  final bool shouldLogout;
  const DeviceSettingInitial(
      {required bool isDarkMode, this.shouldLogout = false})
      : super(isDarkMode: isDarkMode);
}

final class DeviceLocationSettingLoading extends DeviceSettingState {
  final String? id;
  final bool? renderLoadingUI;
  final List<Function>? callBacks;
  DeviceLocationSettingLoading(
      {required bool isDarkMode, this.renderLoadingUI, this.callBacks, this.id})
      : super(isDarkMode: isDarkMode);
}

final class DeviceLocationSettingUIPending
    extends DeviceLocationSettingLoading {
  final String? id;
  final List<Function>? callBacks;
  DeviceLocationSettingUIPending({
    this.callBacks,
    this.id,
    required bool isDarkMode,
  }) : super(
            id: id,
            renderLoadingUI: true,
            callBacks: callBacks,
            isDarkMode: isDarkMode);

  @override
  List<Object> get props => [
        id ?? Utility.getUuid,
        renderLoadingUI ?? false,
        callBacks ?? [],
        isDarkMode
      ];
}

final class DeviceUserProfileSettingLoading extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceUserProfileSettingLoading(
      {required isDarkMode, this.sessionProfile, this.id})
      : super(isDarkMode: isDarkMode);

  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), isDarkMode];
}

final class DeviceSettingLoaded extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;

  DeviceSettingLoaded({this.sessionProfile, this.id, required isDarkMode})
      : super(isDarkMode: isDarkMode);
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), isDarkMode];
}

final class DeviceSettingSaved extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceSettingSaved({this.sessionProfile, this.id, required isDarkMode})
      : super(isDarkMode: isDarkMode);
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), isDarkMode];
}

final class DeviceSettingError extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  final dynamic error;
  DeviceSettingError({
    required this.error,
    this.sessionProfile,
    this.id,
    required isDarkMode,
  }) : super(isDarkMode: isDarkMode);
  @override
  List<Object> get props => [
        id ?? Utility.getUuid,
        sessionProfile ?? SessionProfile(),
        error,
        isDarkMode
      ];
}
