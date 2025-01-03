import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tiler_app/data/deviceLocationProfile.dart';
import 'package:tiler_app/data/deviceProfile.dart';
import 'package:tiler_app/data/userProfile.dart';

part 'device_setting_event.dart';
part 'device_setting_state.dart';

class DeviceSettingBloc extends Bloc<DeviceSettingEvent, DeviceSettingState> {
  Function getContextCallBack;
  DeviceSettingBloc({required this.getContextCallBack})
      : super(DeviceSettingInitial()) {
    on<GetLocationProfileDeviceSettingEvent>(_onGetLocationProfile);
    on<LoadedProfileDeviceSettingEvent>(_onLoadedLocationProfile);
    on<GetUserProfileDeviceSettingEvent>(_onGetUserProfile);
  }

  Future<void> _onGetLocationProfile(GetLocationProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceLocationSettingLoading(
        renderLoadingUI: event.showLocationPermissionWidget,
        callBacks: event.callBacks));
  }

  Future<void> _onLoadedLocationProfile(LoadedProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    DeviceSettingState priorState = this.state;
    DeviceProfile deviceProfile = DeviceProfile();
    deviceProfile.locationProfile = event.deviceLocationProfile;
    emit(DeviceSettingLoaded(deviceProfile: deviceProfile));
    if (priorState is DeviceLocationSettingLoading) {
      if (priorState.callBacks != null) {
        priorState.callBacks!.forEach((element) {
          element();
        });
      }
    }
  }

  Future<void> _onGetUserProfile(GetUserProfileDeviceSettingEvent event,
      Emitter<DeviceSettingState> emit) async {
    emit(DeviceUserProfileSettingLoading());
  }

  // void getLocationPermssions() {
  //   this.add(GetLocationProfileDeviceSettingEvent)
  // }
}
