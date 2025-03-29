part of 'integrations_bloc.dart';

abstract class IntegrationsState extends Equatable {
  const IntegrationsState();

  @override
  List<Object?> get props => [];
}

class IntegrationsInitial extends IntegrationsState {}

class IntegrationsLoading extends IntegrationsState {}

class IntegrationsLoaded extends IntegrationsState {
  final List<CalendarIntegration> integrations;

  const IntegrationsLoaded({required this.integrations});

  @override
  List<Object> get props => [integrations];
}

class IntegrationAdded extends IntegrationsState {
  final String integrationId;

  const IntegrationAdded({required this.integrationId});

  @override
  List<Object> get props => [integrationId];
}

class IntegrationDeleted extends IntegrationsState {
  final String integrationInfo;
  IntegrationDeleted({required this.integrationInfo});
}
class IntegrationLocationUpdated extends IntegrationsState {
}

class IntegrationsError extends IntegrationsState {
  final List<CalendarIntegration> integrations;
  final String errorMessage;

  const IntegrationsError({required this.errorMessage, this.integrations=const []});

  @override
  List<Object> get props => [errorMessage,integrations];
}