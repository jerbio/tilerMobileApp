part of 'integrations_bloc.dart';

abstract class IntegrationsEvent extends Equatable {
  const IntegrationsEvent();

  @override
  List<Object?> get props => [];
}

class GetIntegrationsEvent extends IntegrationsEvent {
  final String? integrationId;

  const GetIntegrationsEvent({this.integrationId});

  @override
  List<Object?> get props => [integrationId];
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

  const UpdateIntegrationLocationEvent({
    required this.integrationId,
    required this.location
  });

  @override
  List<Object> get props => [integrationId, location];
}
