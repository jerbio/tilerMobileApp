import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/data/appThemeMode.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/sessionProfile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/data/userSettings.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/api/settingsApi.dart';
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
  late SettingsApi settingsApi;
  final SecureStorageManager secureStorageManager = SecureStorageManager();
  DeviceSettingBloc({
    required this.getContextCallBack,
    required ThemeMode initialThemeMode,
  }) : super(DeviceSettingInitial(themeMode: initialThemeMode)) {
    on<InitializeDeviceSettingEvent>(_onInitializeSessionProfile);
    on<LoadedDeviceSettingEvent>(_onLoadedSessionProfile);
    on<LoadedLocationProfileDeviceSettingEvent>(_onLoadedLocationProfile);
    on<LoadedUserProfileDeviceSettingEvent>(_onLoadedUserProfile);
    on<GetLocationProfileDeviceSettingEvent>(_onGetLocationProfile);
    on<GetUserProfileDeviceSettingEvent>(_onGetUserProfile);
    on<UpdateUserProfileDateOfBirthSettingEvent>(
        _onUpdateUserProfileDateOfBirth);
    on<UpdateUserProfileDeviceSettingEvent>(_onUpdateUserProfile);
    on<LoadThemeModeFromBackendEvent>(_onLoadThemeModeFromBackend);
    on<UpdateThemeModeDeviceSettingEvent>(_onUpdateThemeMode);
    on<LogOutMainSettingDeviceSettingEvent>(_onLogOutMainSetting);
    on<DeleteAccountMainSettingDeviceSettingEvent>(_onDeleteAccountMainSetting);
    authorizationApi = AuthorizationApi(getContextCallBack: getContextCallBack);
    settingsApi = SettingsApi(getContextCallBack: getContextCallBack);
    add(LoadThemeModeFromBackendEvent(id: Utility.getUuid));
  }

  Future<void> _onInitializeSessionProfile(InitializeDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceUserProfileSettingLoading(
        id: event.id,
        sessionProfile: sessionProfile,
        themeMode: state.themeMode));

    getContextCallBack = event.getContextCallBack;
    await sessionProfile.initialize().then((value) {
      print("Session Profile initialized successfully");
      print(value);
      emit(DeviceSettingLoaded(
          id: event.id,
          sessionProfile: sessionProfile,
          themeMode: state.themeMode));
    }).catchError((error) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: error,
          themeMode: state.themeMode));
    });
  }

  Future<void> _onLoadedSessionProfile(
      LoadedDeviceSettingEvent event, Emitter<DeviceSettingState> emit) async {
    emit(DeviceSettingLoaded(
        id: event.id,
        sessionProfile: event.sessionProfile,
        themeMode: state.themeMode));
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
        sessionProfile: sessionProfile, themeMode: state.themeMode));
  }

  Future<void> _onLoadedUserProfile(LoadedUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    sessionProfile.userProfile = event.userProfile;

    emit(DeviceSettingLoaded(
        sessionProfile: sessionProfile, themeMode: state.themeMode));
  }

  Future<void> _onGetUserProfile(GetUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(
      DeviceUserProfileSettingLoading(
          id: event.id,
          sessionProfile: sessionProfile,
          themeMode: state.themeMode),
    );
    try {
      final userProfile = await sessionProfile.getUserProfile();
      if (userProfile != null) {
        sessionProfile.userProfile = userProfile;
      }
      emit(DeviceSettingLoaded(
          id: event.id,
          sessionProfile: sessionProfile,
          themeMode: state.themeMode));
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          themeMode: state.themeMode));
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
          themeMode: state.themeMode));
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
            themeMode: state.themeMode));
      }
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          themeMode: state.themeMode));
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
          themeMode: state.themeMode),
    );
    try {
      if (sessionProfile.locationProfile != null) {
        if (sessionProfile.locationProfile!.isGranted) {
          await sessionProfile.getLatestLocation();
          emit(DeviceSettingLoaded(
              id: event.id,
              sessionProfile: sessionProfile,
              themeMode: state.themeMode));
          callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
        } else {
          if (sessionProfile.locationProfile!.canRecheckPermission()) {
            emit(DeviceLocationSettingUIPending(
                id: event.id,
                callBacks: event.callBacks,
                themeMode: state.themeMode));

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
                themeMode: state.themeMode));
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
          themeMode: state.themeMode));
      callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
    }
  }

  Future<void> _onLoadThemeModeFromBackend(
      LoadThemeModeFromBackendEvent event,
      Emitter<DeviceSettingState> emit) async {
    final localMode = await ThemeManager.getThemeMode();
    emit(DeviceSettingLoaded(
      id: event.id,
      sessionProfile: sessionProfile,
      themeMode: ThemeManager.toFlutterThemeMode(localMode),
    ));
    try {
      final userSettings = await settingsApi.getUserSettings();
      final backendMode = userSettings.mobileUiScheme?.themeMode;
      if (backendMode != null) {
        await ThemeManager.setThemeMode(backendMode);
        emit(DeviceSettingLoaded(
          id: event.id,
          sessionProfile: sessionProfile,
          themeMode: ThemeManager.toFlutterThemeMode(backendMode),
        ));
      }
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          themeMode: state.themeMode));
    }
  }

  Future<void> _onUpdateThemeMode(UpdateThemeModeDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    await ThemeManager.setThemeMode(event.themeMode);
    emit(DeviceThemeUpdatingSetting(
      id: event.id,
      themeMode: ThemeManager.toFlutterThemeMode(event.themeMode),
      sessionProfile: sessionProfile,
    ));
    try {
      final current = await settingsApi.getUserSettings();
      final updated = UserSettings(
        userPreference: current.userPreference,
        marketingPreference: current.marketingPreference,
        scheduleProfile: current.scheduleProfile,
        mobileUiScheme: current.mobileUiScheme?.copyWith(themeMode: event.themeMode),
        desktopUiScheme: current.desktopUiScheme?.copyWith(themeMode: event.themeMode),
      );
      await settingsApi.updateUserSettings(updated);
      emit(DeviceSettingLoaded(
        id: event.id,
        themeMode: ThemeManager.toFlutterThemeMode(event.themeMode),
        sessionProfile: sessionProfile,
      ));
    } catch (e) {
      emit(DeviceSettingError(
          id: event.id,
          sessionProfile: sessionProfile,
          error: e,
          themeMode: state.themeMode));
    }
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

      this.sessionProfile = SessionProfile();

      emit(DeviceSettingInitial(
        themeMode: state.themeMode,
        shouldLogout: true,
      ));
    } catch (e) {
      emit(DeviceSettingError(
          themeMode: state.themeMode,
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
        add(LogOutMainSettingDeviceSettingEvent(
            id: event.id, context: event.context));
      }
    } catch (e) {
      emit(DeviceSettingError(
        id: event.id,
        themeMode: state.themeMode,
        sessionProfile: sessionProfile,
        error: e,
      ));
    }
  }
}
