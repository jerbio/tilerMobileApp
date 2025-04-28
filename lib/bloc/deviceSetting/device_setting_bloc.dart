import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/sessionProfile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/services/storageManager.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'package:tiler_app/util.dart';

part 'device_setting_event.dart';
part 'device_setting_state.dart';

class DeviceSettingBloc extends Bloc<DeviceSettingEvent, DeviceSettingState> {
  Function getContextCallBack;
  SessionProfile sessionProfile = SessionProfile();
  final Authentication authentication = Authentication();
  late AuthorizationApi authorizationApi;
  final SecureStorageManager secureStorageManager = SecureStorageManager();
  DeviceSettingBloc({
    required this.getContextCallBack,
    required bool initialIsDarkMode,
  }) : super(DeviceSettingInitial(isDarkMode: initialIsDarkMode)) {
    on<InitializeDeviceSettingEvent>(_onInitializeSessionProfile);
    on<LoadedDeviceSettingEvent>(_onLoadedSessionProfile);
    on<LoadedLocationProfileDeviceSettingEvent>(_onLoadedLocationProfile);
    on<LoadedUserProfileDeviceSettingEvent>(_onLoadedUserProfile);
    on<GetLocationProfileDeviceSettingEvent>(_onGetLocationProfile);
    on<GetUserProfileDeviceSettingEvent>(_onGetUserProfile);
    on<UpdateUserProfileDateOfBirthSettingEvent>(
        _onUpdateUserProfileDateOfBirth);
    on<UpdateUserProfileDeviceSettingEvent>(_onUpdateUserProfile);
    on<UpdateDarkModeMainSettingDeviceSettingEvent>(
        _onUpdateDarkModeMainSetting);
    on<LogOutMainSettingDeviceSettingEvent>(_onLogOutMainSetting);
    on<DeleteAccountMainSettingDeviceSettingEvent>(_onDeleteAccountMainSetting);
    authorizationApi = AuthorizationApi(getContextCallBack: getContextCallBack);
    ThemeManager.getThemeMode().then((isDark) => add(
        UpdateDarkModeMainSettingDeviceSettingEvent(
            isDarkMode: isDark, id: Utility.getUuid)));
  }

  Future<void> _onInitializeSessionProfile(InitializeDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceUserProfileSettingLoading(
        id: event.id,
        sessionProfile: sessionProfile,
        isDarkMode: state.isDarkMode));

    getContextCallBack = event.getContextCallBack;
    await sessionProfile.initialize().then((value) {
      emit(DeviceSettingLoaded(
          id: event.id,
          sessionProfile: sessionProfile,
          isDarkMode: state.isDarkMode));
    }).catchError((error) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: error,
          isDarkMode: state.isDarkMode));
    });
  }

  Future<void> _onLoadedSessionProfile(
      LoadedDeviceSettingEvent event, Emitter<DeviceSettingState> emit) async {
    emit(DeviceSettingLoaded(
        id: event.id,
        sessionProfile: event.sessionProfile,
        isDarkMode: state.isDarkMode));
  }

  Future<void> _onLoadedLocationProfile(
      LoadedLocationProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    sessionProfile.locationProfile = event.deviceLocationProfile;
    if (state is DeviceLocationSettingLoading) {
      callPendingCallBacks((state as DeviceLocationSettingLoading).callBacks,
          sessionProfile.locationProfile);
    }

    emit(DeviceSettingLoaded(
        sessionProfile: sessionProfile, isDarkMode: state.isDarkMode));
  }

  Future<void> _onLoadedUserProfile(LoadedUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    sessionProfile.userProfile = event.userProfile;
    emit(DeviceSettingLoaded(
        sessionProfile: sessionProfile, isDarkMode: state.isDarkMode));
  }

  Future<void> _onGetUserProfile(GetUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(
      DeviceUserProfileSettingLoading(
          id: event.id,
          sessionProfile: sessionProfile,
          isDarkMode: state.isDarkMode),
    );
    try {
      final userProfile = await sessionProfile.getUserProfile();
      if (userProfile != null) {
        sessionProfile.userProfile = userProfile;
      }
      emit(DeviceSettingLoaded(
          id: event.id,
          sessionProfile: sessionProfile,
          isDarkMode: state.isDarkMode));
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          isDarkMode: state.isDarkMode));
    }
  }

  Future<void> _onUpdateUserProfileDateOfBirth(
      UpdateUserProfileDateOfBirthSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    try {
      if (sessionProfile.userProfile != null) {
        String formattedDate =
            DateFormat('yyyy-MM-dd').format(event.dateOfBirth);
        sessionProfile.userProfile!.dateOfBirth = formattedDate;
      }
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          isDarkMode: state.isDarkMode));
    }
  }

  Future<void> _onUpdateUserProfile(UpdateUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    try {
      if (sessionProfile.userProfile != null) {
        await sessionProfile.updateUserProfile(sessionProfile!.userProfile!);
        emit(DeviceSettingSaved(
            id: event.id,
            sessionProfile: sessionProfile,
            isDarkMode: state.isDarkMode));
      }
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          isDarkMode: state.isDarkMode));
    }
  }

  void callPendingCallBacks(
      List<Function>? callBacks, LocationProfile? locationProfile) {
    if (callBacks != null) {
      callBacks.forEach((element) {
        element(locationProfile);
      });
    }
  }

  Future<void> _onGetLocationProfile(GetLocationProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    DeviceSettingState currentState = state;
    if (currentState is DeviceLocationSettingUIPending) {
      return;
    }
    emit(
      DeviceLocationSettingLoading(
          id: event.id,
          renderLoadingUI: event.showLocationPermissionWidget,
          callBacks: event.callBacks,
          isDarkMode: state.isDarkMode),
    );
    try {
      if (sessionProfile.locationProfile != null) {
        if (sessionProfile.locationProfile!.isGranted) {
          await sessionProfile.getLatestLocation();
          emit(DeviceSettingLoaded(
              id: event.id,
              sessionProfile: sessionProfile,
              isDarkMode: state.isDarkMode));
          callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
        } else {
          if (sessionProfile.locationProfile!.canRecheckPermission()) {
            emit(DeviceLocationSettingUIPending(
                id: event.id,
                callBacks: event.callBacks,
                isDarkMode: state.isDarkMode));

            showGeneralDialog(
                context: event.context,
                pageBuilder: (ctx, anim1, anim2) => Container(),
                barrierDismissible: false,
                barrierColor: Colors.black.withOpacity(0.5),
                barrierLabel: '',
                transitionDuration: Duration(milliseconds: 400),
                transitionBuilder: (ctx, anim1, anim2, child) {
                  final curvedValue =
                      Curves.easeInOutBack.transform(anim1.value) - 1.0;
                  return Transform(
                    transform:
                        Matrix4.translationValues(0.0, curvedValue * 200, 0.0),
                    child: Opacity(
                        opacity: anim1.value,
                        child: LocationAccessWidget(null, (_) {
                          if (Navigator.of(ctx).canPop()) {
                            Navigator.of(ctx).pop();
                          }
                        })),
                  );
                });
          } else {
            emit(DeviceSettingLoaded(
                id: event.id,
                sessionProfile: sessionProfile,
                isDarkMode: state.isDarkMode));
            callPendingCallBacks(
                event.callBacks, sessionProfile.locationProfile);
          }
        }
      } else {
        sessionProfile.locationProfile = LocationProfile.empty();
        throw Exception('sessionProfile LocationProfile not initialized');
      }
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          isDarkMode: state.isDarkMode));
      callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
    }
  }

  void _onUpdateDarkModeMainSetting(
      UpdateDarkModeMainSettingDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceSettingLoaded(
      id: event.id,
      isDarkMode: event.isDarkMode,
      sessionProfile: sessionProfile,
    ));
  }

  Future<void> _onLogOutMainSetting(LogOutMainSettingDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    try {
      AnalysticsSignal.send('SETTINGS_LOG_OUT_USER');
      await OneSignal.logout().then((_) {
        Utility.debugPrint("Successfully logged out of OneSignal");
      }).catchError((error) {
        Utility.debugPrint("Failed to log out of OneSignal: $error");
      });

      await authentication.deauthenticateCredentials();
      await secureStorageManager.deleteAllStorageData();

      emit(DeviceSettingLoaded(
        id: event.id,
        isDarkMode: state.isDarkMode,
        shouldLogout: true,
        sessionProfile: SessionProfile(),
      ));
    } catch (e) {
      emit(DeviceSettingError(
          isDarkMode: state.isDarkMode,
          id: event.id,
          error: e,
          sessionProfile: sessionProfile));
    }
  }

  Future<void> _onDeleteAccountMainSetting(
      DeleteAccountMainSettingDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    try {
      bool result = await authorizationApi.deleteTilerAccount();
      if (result) {
        add(LogOutMainSettingDeviceSettingEvent(id: event.id));
      }
    } catch (e) {
      emit(DeviceSettingError(
        id: event.id,
        isDarkMode: state.isDarkMode,
        sessionProfile: sessionProfile,
        error: e,
      ));
    }
  }
}
