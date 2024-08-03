import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';

part 'integrations_event.dart';
part 'integrations_state.dart';

class IntegrationsBloc extends Bloc<IntegrationsEvent, IntegrationsState> {
  IntegrationApi integrationApi = IntegrationApi();
  IntegrationsBloc() : super(IntegrationsInitial()) {
    on<GetIntegrationsEvent>(_getIntegrations);
    on<DeleteIntegrationsEvent>(_deleteIntegration);
    on<PendingIntegrationsEvent>(_updateIntegrationEvent);
    on<ResetIntegrationsEvent>(_resetIntegration);
  }

  void _getIntegrations(
      GetIntegrationsEvent getEvent, Emitter<IntegrationsState> emit) async {
    var integrations = await integrationApi.integrations(
        integrationId: getEvent.integrationId);
    emit(IntegrationsLoaded(
        integrations: integrations ?? [], eventId: getEvent.eventId));
  }

  void _deleteIntegration(DeleteIntegrationsEvent deleteIntegrationsEvent,
      Emitter<IntegrationsState> emit) async {
    bool? deletionStatus = await integrationApi
        .deleteIntegration(deleteIntegrationsEvent.integration);

    if (deleteIntegrationsEvent.callBack != null) {
      deleteIntegrationsEvent.callBack!(deletionStatus);
    }
  }

  void _resetIntegration(ResetIntegrationsEvent deleteIntegrationsEvent,
      Emitter<IntegrationsState> emit) async {
    emit(IntegrationsInitial(eventId: deleteIntegrationsEvent.eventId));
  }

  void _updateIntegrationEvent(
      PendingIntegrationsEvent pendingIntegrationsEvent,
      Emitter<IntegrationsState> emit) async {
    emit(IntegrationsLoading(
        eventId: pendingIntegrationsEvent.eventId,
        previousIntegrations: pendingIntegrationsEvent.integrations));
  }
}
