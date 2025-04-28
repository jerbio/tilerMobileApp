part of 'notifications_bloc.dart';

abstract class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState();

  @override
  List<Object?> get props => [];
}

class NotificationPreferencesInitial extends NotificationPreferencesState {}

class NotificationPreferencesLoading extends NotificationPreferencesState {}

class NotificationPreferencesLoaded extends NotificationPreferencesState {
  final UserSettings userSettings;
  final bool tileReminders;
  final bool appUpdates;
  final bool marketingUpdates;
  final bool emailNotifications;
  final bool hasChanges;

  const NotificationPreferencesLoaded({
    required this.userSettings,
    required this.tileReminders,
    required this.appUpdates,
    required this.marketingUpdates,
    required this.emailNotifications,
    this.hasChanges = false,
  });

  NotificationPreferencesLoaded copyWith({
    UserSettings? userSettings,
    bool? tileReminders,
    bool? appUpdates,
    bool? marketingUpdates,
    bool? emailNotifications,
    bool? isDirty,
  }) {
    return NotificationPreferencesLoaded(
      userSettings: userSettings ?? this.userSettings,
      tileReminders: tileReminders ?? this.tileReminders,
      appUpdates: appUpdates ?? this.appUpdates,
      marketingUpdates: marketingUpdates ?? this.marketingUpdates,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      hasChanges: isDirty ?? this.hasChanges,
    );
  }

  @override
  List<Object?> get props => [
    userSettings,
    tileReminders,
    appUpdates,
    marketingUpdates,
    emailNotifications,
    hasChanges,
  ];
}


class NotificationPreferencesSaved extends NotificationPreferencesState {}

class NotificationPreferencesError extends NotificationPreferencesState {
  final String message;

  const NotificationPreferencesError(this.message);

  @override
  List<Object?> get props => [message];
}
