part of 'integrations_bloc.dart';

abstract class IntegrationsEvent extends Equatable {
  final String? requestId;
  const IntegrationsEvent({this.requestId});

  @override
  List<Object?> get props => [requestId];
}

class GetIntegrationsEvent extends IntegrationsEvent {
  final String? integrationId;

  const GetIntegrationsEvent({this.integrationId, String? requestId})
      : super(requestId: requestId);

  @override
  List<Object?> get props => [integrationId, requestId];
}

class ResetIntegrationsEvent extends IntegrationsEvent {}

class DeleteIntegrationEvent extends IntegrationsEvent {
  final CalendarIntegration integration;

  const DeleteIntegrationEvent({required this.integration});

  @override
  List<Object> get props => [integration];
}

class AddIntegrationEvent extends IntegrationsEvent {}

class UpdateIntegrationLocationEvent extends IntegrationsEvent {
  final String integrationId;
  final Location location;

  const UpdateIntegrationLocationEvent(
      {required this.integrationId, required this.location, String? requestId})
      : super(requestId: requestId);

  @override
  List<Object> get props => [integrationId, location, requestId ?? ''];
}

class UpdateCalendarItemEvent extends IntegrationsEvent {
  final String integrationId;
  final String calendarItemId;
  final String calendarName;
  final bool isSelected;

  const UpdateCalendarItemEvent(
      {required this.integrationId,
      required this.calendarItemId,
      required this.calendarName,
      required this.isSelected,
      String? requestId})
      : super(requestId: requestId);

  @override
  List<Object> get props => [
        integrationId,
        calendarItemId,
        calendarName,
        isSelected,
        requestId ?? ''
      ];
}
