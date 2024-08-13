part of 'integrations_bloc.dart';

sealed class IntegrationsEvent extends Equatable {
  const IntegrationsEvent();

  @override
  List<Object> get props => [];
}

class GetIntegrationsEvent extends IntegrationsEvent {
  final String? eventId;
  final String? integrationId;
  const GetIntegrationsEvent({this.eventId, this.integrationId});

  @override
  List<Object> get props => [];
}

class ResetIntegrationsEvent extends IntegrationsEvent {
  final String? eventId;
  const ResetIntegrationsEvent({this.eventId});

  @override
  List<Object> get props => [];
}

class PendingIntegrationsEvent extends IntegrationsEvent {
  final String? eventId;
  final List<CalendarIntegration> integrations;
  const PendingIntegrationsEvent({this.eventId, required this.integrations});

  @override
  List<Object> get props => [];
}

class DeleteIntegrationsEvent extends IntegrationsEvent {
  final String? eventId;
  final CalendarIntegration integration;
  final Function? callBack;
  const DeleteIntegrationsEvent(
      {this.eventId, required this.integration, this.callBack});

  @override
  List<Object> get props => [];
}

sealed class LoadIntegrationsEvent extends IntegrationsEvent {
  final String? eventId;
  final List<CalendarIntegration> integrations;
  const LoadIntegrationsEvent({this.eventId, required this.integrations});

  @override
  List<Object> get props => [];
}
