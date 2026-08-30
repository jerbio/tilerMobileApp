part of 'device_setting_bloc.dart';

sealed class DeviceSettingState extends Equatable {
  final ThemeMode themeMode;

  const DeviceSettingState({this.themeMode = ThemeMode.system});
  @override
  List<Object> get props => [themeMode];
}

final class DeviceSettingInitial extends DeviceSettingState {
  final bool shouldLogout;
  const DeviceSettingInitial(
      {required ThemeMode themeMode, this.shouldLogout = false})
      : super(themeMode: themeMode);
}

final class DeviceLocationSettingLoading extends DeviceSettingState {
  final String? id;
  final bool? renderLoadingUI;
  final List<Function>? callBacks;
  DeviceLocationSettingLoading(
      {required ThemeMode themeMode, this.renderLoadingUI, this.callBacks, this.id})
      : super(themeMode: themeMode);
}

final class DeviceLocationSettingUIPending
    extends DeviceLocationSettingLoading {
  final String? id;
  final List<Function>? callBacks;
  DeviceLocationSettingUIPending({
    this.callBacks,
    this.id,
    required ThemeMode themeMode,
  }) : super(
            id: id,
            renderLoadingUI: true,
            callBacks: callBacks,
            themeMode: themeMode);

  @override
  List<Object> get props => [
        id ?? Utility.getUuid,
        renderLoadingUI ?? false,
        callBacks ?? [],
        themeMode
      ];
}

final class DeviceUserProfileSettingLoading extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceUserProfileSettingLoading(
      {required themeMode, this.sessionProfile, this.id})
      : super(themeMode: themeMode);

  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), themeMode];
}

final class DeviceThemeUpdatingSetting extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceThemeUpdatingSetting(
      {required themeMode, this.sessionProfile, this.id})
      : super(themeMode: themeMode);

  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), themeMode];
}

final class DeviceSettingLoaded extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;

  DeviceSettingLoaded({this.sessionProfile, this.id, required themeMode})
      : super(themeMode: themeMode);
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), themeMode];
}

final class DeviceSettingSaved extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  DeviceSettingSaved({this.sessionProfile, this.id, required themeMode})
      : super(themeMode: themeMode);
  @override
  List<Object> get props =>
      [id ?? Utility.getUuid, sessionProfile ?? SessionProfile(), themeMode];
}

final class DeviceSettingError extends DeviceSettingState {
  final String? id;
  final SessionProfile? sessionProfile;
  final dynamic error;
  DeviceSettingError({
    required this.error,
    this.sessionProfile,
    this.id,
    required themeMode,
  }) : super(themeMode: themeMode);
  @override
  List<Object> get props => [
        id ?? Utility.getUuid,
        sessionProfile ?? SessionProfile(),
        error,
        themeMode
      ];
}
