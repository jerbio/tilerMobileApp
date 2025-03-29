import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final String? navigationRoute;
  final String? errorMessage;


  const SettingsState({
    this.isDarkMode = false,
    this.navigationRoute,
    this.errorMessage,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? navigationRoute,
    String? errorMessage,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      navigationRoute: navigationRoute,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isDarkMode,
    navigationRoute, errorMessage];
}
