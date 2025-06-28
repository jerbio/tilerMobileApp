import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'integrations_event.dart';
part 'integrations_state.dart';

enum IntegrationType { googleCalendar, microsoft }

class IntegrationsBloc extends Bloc<IntegrationsEvent, IntegrationsState> {
  final IntegrationApi _integrationApi;
  final AuthorizationApi _authorizationApi;
  final IntegrationType integrationType;

  IntegrationsBloc({
    required Function getContextCallBack,
    required this.integrationType,
  })  : _integrationApi =
            IntegrationApi(getContextCallBack: getContextCallBack),
        _authorizationApi =
            AuthorizationApi(getContextCallBack: getContextCallBack),        super(IntegrationsInitial()) {
    on<GetIntegrationsEvent>(_getIntegrations);
    on<DeleteIntegrationEvent>(_deleteIntegration);
    on<AddIntegrationEvent>(_addIntegration);
    on<UpdateIntegrationLocationEvent>(_updateIntegrationLocation);
    on<UpdateCalendarItemEvent>(_updateCalendarItem);
    on<ResetIntegrationsEvent>((event, emit) => emit(IntegrationsInitial()));
  }

  void _getIntegrations(
      GetIntegrationsEvent event, Emitter<IntegrationsState> emit) async {
    emit(IntegrationsLoading());
    try {
      final integrations = await _integrationApi.getIntegrations(
          integrationId: event.integrationId);
      emit(IntegrationsLoaded(integrations: integrations ?? []));
    } catch (e) {
      emit(IntegrationsError(
          errorMessage: e.toString(),
          integrations: (state is IntegrationsLoaded)
              ? (state as IntegrationsLoaded).integrations
              : []));
    }
  }

  void _deleteIntegration(
      DeleteIntegrationEvent event, Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
      try {
        final success =
            await _integrationApi.deleteIntegration(event.integration);

        if (success!) {
          final index = currentIntegrations
              .indexWhere((index) => index.id == event.integration.id);
          String integrationInfo = currentIntegrations[index].email ??
              currentIntegrations[index].userId ??
              currentIntegrations[index].id ??
              "";
          if (index != -1) currentIntegrations.removeAt(index);
          emit(IntegrationDeleted(integrationInfo: integrationInfo));
          emit(IntegrationsLoaded(integrations: currentIntegrations));
        } else {
          emit(IntegrationsError(
            errorMessage: "Failed to delete integration",
            integrations: currentIntegrations,
          ));
        }
      } catch (e) {
        emit(IntegrationsError(
          errorMessage: "Failed to delete integration: ${e.toString()}",
          integrations: currentIntegrations,
        ));
      }
    }
  }

  void _addIntegration(
      AddIntegrationEvent event, Emitter<IntegrationsState> emit) async {
    List<CalendarIntegration> currentIntegrations = [];
    if (state is IntegrationsLoaded) {
      currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
    }
    try {
      Map<String, dynamic>? result;
      switch (integrationType) {
        case IntegrationType.googleCalendar:
          result = await _authorizationApi.addGoogleCalendar();
          break;
        case IntegrationType.microsoft:
          result = {};
      }
      if (result != null) {
        add(GetIntegrationsEvent());
      } else {
        BuildContext? context = null;
        if (this._integrationApi.getContextCallBack != null) {
          context = this._integrationApi.getContextCallBack!();
        }

        if (context != null) {
          emit(IntegrationsError(
              errorMessage:
                  AppLocalizations.of(context)!.failedToAddIntegration,
              integrations: currentIntegrations));
          return;
        }

        emit(IntegrationsError(
            errorMessage: "Failed to add integration",
            integrations: currentIntegrations));
      }
    } catch (e) {
      emit(IntegrationsError(
          errorMessage: "Failed to add integration: ${e.toString()}",
          integrations: currentIntegrations));
    }
  }

  void _updateIntegrationLocation(UpdateIntegrationLocationEvent event,
      Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
      final index = currentIntegrations
          .indexWhere((element) => element.id == event.integrationId);
      if (index != -1) {
        try {
          emit(IntegrationsLoading());
          await _integrationApi.addIntegrationLocation(
              event.location, event.integrationId);
          currentIntegrations[index].location = event.location;
          emit(IntegrationsLoaded(integrations: currentIntegrations));
        } catch (e) {
          emit(IntegrationsError(
              errorMessage: "Failed to update location: ${e.toString()}",
              integrations: currentIntegrations));
          add(GetIntegrationsEvent());
        }
      } else {
        try {
          await _integrationApi.addIntegrationLocation(
              event.location, event.integrationId);
          add(GetIntegrationsEvent());
        } catch (e) {
          emit(IntegrationsError(
              errorMessage: "Failed to update location: ${e.toString()}",
              integrations: currentIntegrations));
        }
      }
    }
  }

  void _updateCalendarItem(
      UpdateCalendarItemEvent event, Emitter<IntegrationsState> emit) async {
    if (state is IntegrationsLoaded) {
      final currentIntegrations = List<CalendarIntegration>.from(
          (state as IntegrationsLoaded).integrations);
      
      // Find the integration
      final integrationIndex = currentIntegrations
          .indexWhere((integration) => integration.id == event.integrationId);
      
      if (integrationIndex != -1) {
        final integration = currentIntegrations[integrationIndex];
        
        // Find the calendar item
        if (integration.calendarItems != null) {
          final calendarItemIndex = integration.calendarItems!
              .indexWhere((item) => item.id == event.calendarItemId);
          
          if (calendarItemIndex != -1) {
            try {
              // Update the calendar item on the server
              final success = await _integrationApi.updateCalendarItem(
                calendarId: event.calendarItemId,
                calendarName: event.calendarName,
                isSelected: event.isSelected,
                integrationId: event.integrationId,
                calendarItemId: event.calendarItemId,
              );

              if (success == true) {
                // Update the local state
                integration.calendarItems![calendarItemIndex].isSelected = event.isSelected;
                emit(IntegrationsLoaded(integrations: currentIntegrations));
              } else {
                emit(IntegrationsError(
                  errorMessage: "Failed to update calendar item",
                  integrations: currentIntegrations,
                ));
              }
            } catch (e) {
              emit(IntegrationsError(
                errorMessage: "Failed to update calendar item: ${e.toString()}",
                integrations: currentIntegrations,
              ));
            }
          } else {
            emit(IntegrationsError(
              errorMessage: "Calendar item not found",
              integrations: currentIntegrations,
            ));
          }
        }
      } else {
        emit(IntegrationsError(
          errorMessage: "Integration not found",
          integrations: currentIntegrations,
        ));
      }
    }
  }
}
