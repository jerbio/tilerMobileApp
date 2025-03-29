import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ToggleDarkModeEvent extends SettingsEvent {
  final bool isDarkMode;
  ToggleDarkModeEvent(this.isDarkMode);
}

class NavigateEvent extends SettingsEvent {
  final String route;
  NavigateEvent(this.route);
}

class LogOutEvent extends SettingsEvent {}

class DeleteAccountEvent extends SettingsEvent {}

class ErrorEvent extends SettingsEvent {
  final String message;
  ErrorEvent(this.message);
}

class ResetSettingsEvent extends SettingsEvent {}

