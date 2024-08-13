part of 'integrations_bloc.dart';

sealed class IntegrationsState extends Equatable {
  const IntegrationsState();

  @override
  List<Object> get props => [];
}

final class IntegrationsInitial extends IntegrationsState {
  final String? eventId;
  IntegrationsInitial({this.eventId});
}

final class IntegrationsLoading extends IntegrationsState {
  final String? eventId;
  final List<CalendarIntegration> previousIntegrations;
  IntegrationsLoading({required this.previousIntegrations, this.eventId});
}

final class IntegrationsLoaded extends IntegrationsState {
  final List<CalendarIntegration> integrations;
  final String? eventId;
  IntegrationsLoaded({required this.integrations, this.eventId});
}
