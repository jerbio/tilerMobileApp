part of 'notifications_bloc.dart';

abstract class NotificationPreferencesEvent extends Equatable {
  const NotificationPreferencesEvent();

  @override
  List<Object?> get props => [];
}

class FetchNotificationPreferences extends NotificationPreferencesEvent {}

class UpdateTileReminders extends NotificationPreferencesEvent {
  final bool value;

  const UpdateTileReminders(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateAppUpdates extends NotificationPreferencesEvent {
  final bool value;

  const UpdateAppUpdates(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateMarketingUpdates extends NotificationPreferencesEvent {
  final bool value;

  const UpdateMarketingUpdates(this.value);

  @override
  List<Object?> get props => [value];
}

class UpdateEmailNotifications extends NotificationPreferencesEvent {
  final bool value;

  const UpdateEmailNotifications(this.value);

  @override
  List<Object?> get props => [value];
}

class SaveNotificationPreferences extends NotificationPreferencesEvent {}
