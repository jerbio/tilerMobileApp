import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/themerHelper.dart';
import 'settings_event.dart';
import 'settings_state.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import 'package:tiler_app/services/storageManager.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final Authentication authentication = Authentication();
  late AuthorizationApi authorizationApi ;
  final SecureStorageManager secureStorageManager = SecureStorageManager();

  SettingsBloc({required Function getContextCallBack}) : super( SettingsState()) {
    on<ToggleDarkModeEvent>(_handelScreenMode);
    on<NavigateEvent>(_handelNavigation);
    on<LogOutEvent>(_handleLogOut);
    on<DeleteAccountEvent>(_handleDeleteAccount);
    on<ErrorEvent>(_handelError);
    on<ResetSettingsEvent>(_resetSettings);
    authorizationApi= AuthorizationApi(getContextCallBack: getContextCallBack);
    ThemeManager.getThemeMode().then((isDark) => add(ToggleDarkModeEvent(isDark)));
  }

  void _handelScreenMode(ToggleDarkModeEvent event, Emitter<SettingsState> emit)async{
    // if (state.isDarkMode != event.isDarkMode) {
    //   await ThemeManager.setThemeMode(event.isDarkMode);
      emit(state.copyWith(isDarkMode: event.isDarkMode));
    //}
  }
  void _handelNavigation(NavigateEvent event, Emitter<SettingsState> emit){
    emit(state.copyWith(navigationRoute: event.route));
    emit(state.copyWith(navigationRoute: null));
  }
  void _handelError(ErrorEvent event, Emitter<SettingsState> emit){
    emit(state.copyWith(errorMessage: event.message));
  }
  Future<void> _resetSettings(ResetSettingsEvent event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
        navigationRoute: null,
        errorMessage: null
    ));
  }

  Future<void> _handleLogOut(LogOutEvent event, Emitter<SettingsState> emit) async {
    try {
      AnalysticsSignal.send('SETTINGS_LOG_OUT_USER');
      await OneSignal.logout().then((_) {
        print("Successfully logged out of OneSignal");
      }).catchError((error) {
        print("Failed to log out of OneSignal: $error");
      });
      await authentication.deauthenticateCredentials();
      await secureStorageManager.deleteAllStorageData();
      emit(state.copyWith(navigationRoute: '/LoggedOut'));
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }

  Future<void> _handleDeleteAccount(DeleteAccountEvent event, Emitter<SettingsState> emit) async {
    try {
      bool result = await authorizationApi.deleteTilerAccount();
      if (result) {
        add(LogOutEvent());
      }
      // else {
      //   emit(state.copyWith(errorMessage: "Account deletion failed."));
      // }
    } catch (e) {
      emit(state.copyWith(errorMessage: e.toString()));
    }
  }
}
