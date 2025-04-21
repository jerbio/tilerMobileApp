import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/data/locationProfile.dart';
import 'package:tiler_app/data/sessionProfile.dart';
import 'package:tiler_app/data/userProfile.dart';
import 'package:tiler_app/routes/authenticatedUser/locationAccess.dart';
import 'package:tiler_app/util.dart';

part 'device_setting_event.dart';
part 'device_setting_state.dart';

class DeviceSettingBloc extends Bloc<DeviceSettingEvent, DeviceSettingState> {
  Function getContextCallBack;
  SessionProfile sessionProfile = SessionProfile();
  DeviceSettingBloc({required this.getContextCallBack})
      : super(DeviceSettingInitial()) {
    on<InitializeDeviceSettingEvent>(_onInitializeSessionProfile);
    on<LoadedDeviceSettingEvent>(_onLoadedSessionProfile);
    on<LoadedLocationProfileDeviceSettingEvent>(_onLoadedLocationProfile);
    on<LoadedUserProfileDeviceSettingEvent>(_onLoadedUserProfile);
    on<GetLocationProfileDeviceSettingEvent>(_onGetLocationProfile);
    on<GetUserProfileDeviceSettingEvent>(_onGetUserProfile);
  }

  Future<void> _onInitializeSessionProfile(InitializeDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceUserProfileSettingLoading(
        id: event.id, sessionProfile: sessionProfile));
        getContextCallBack = event.getContextCallBack;
    await sessionProfile.initialize().then((value) {
      emit(DeviceSettingLoaded(id: event.id, sessionProfile: sessionProfile));
    }).catchError((error) {
      emit(DeviceSettingError(
          id: event.id, sessionProfile: sessionProfile, error: error));
    });
  }

  Future<void> _onLoadedSessionProfile(
      LoadedDeviceSettingEvent event, Emitter<DeviceSettingState> emit) async {
    emit(DeviceSettingLoaded(
        id: event.id, sessionProfile: event.sessionProfile));
  }

  Future<void> _onLoadedLocationProfile(
      LoadedLocationProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    sessionProfile.locationProfile = event.deviceLocationProfile;
    if (state is DeviceLocationSettingLoading) {
      callPendingCallBacks((state as DeviceLocationSettingLoading).callBacks,
          sessionProfile.locationProfile);
    }

    emit(DeviceSettingLoaded(sessionProfile: sessionProfile));
  }

  Future<void> _onLoadedUserProfile(LoadedUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    sessionProfile.userProfile = event.userProfile;
    emit(DeviceSettingLoaded(sessionProfile: sessionProfile));
  }

  Future<void> _onGetUserProfile(GetUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceUserProfileSettingLoading(
        id: event.id, sessionProfile: sessionProfile));
    if (event.remoteCall) {
      emit(DeviceUserProfileSettingLoading(
          id: event.id, sessionProfile: sessionProfile));
      sessionProfile.getUserProfile().then((value) {
        if (value != null) {
          sessionProfile.userProfile = value;
        }
      }).whenComplete(() {
        emit(DeviceSettingLoaded(id: event.id, sessionProfile: sessionProfile));
      });
      return;
    }
    emit(DeviceSettingLoaded(id: event.id, sessionProfile: sessionProfile));
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
    emit(DeviceLocationSettingLoading(
        id: event.id,
        renderLoadingUI: event.showLocationPermissionWidget,
        callBacks: event.callBacks));
    try {
      if (sessionProfile.locationProfile != null) {
        if (sessionProfile.locationProfile!.isGranted) {
          await sessionProfile.getLatestLocation();
          emit(DeviceSettingLoaded(
            id: event.id,
            sessionProfile: sessionProfile,
          ));
          callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
        } else {
          if (sessionProfile.locationProfile!.canRecheckPermission()) {
            emit(DeviceLocationSettingUIPending(
              id: event.id,
              callBacks: event.callBacks,
            ));

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
                id: event.id, sessionProfile: sessionProfile));
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
          id: event.id, sessionProfile: sessionProfile, error: e));
      callPendingCallBacks(event.callBacks, sessionProfile.locationProfile);
    }
  }
}
