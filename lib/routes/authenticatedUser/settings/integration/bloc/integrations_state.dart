part of 'integrations_bloc.dart';

abstract class IntegrationsState extends Equatable {
  final String? requestId;
  const IntegrationsState({this.requestId});

  @override
  List<Object?> get props => [];
}

class IntegrationsInitial extends IntegrationsState {
  const IntegrationsInitial({String? requestId}) : super(requestId: requestId);
}

class IntegrationsLoading extends IntegrationsState {
  const IntegrationsLoading({String? requestId}) : super(requestId: requestId);
}

class IntegrationsLoaded extends IntegrationsState {
  final List<CalendarIntegration> integrations;

  const IntegrationsLoaded({required this.integrations, String? requestId})
      : super(requestId: requestId);

  @override
  List<Object> get props {
    if (integrations.isEmpty) {
      return List.empty();
    }
    List<String> calItemIds = [];
    List<String> isSelecteCalendarItems = [];
    for (var integration in integrations) {
      if (integration.calendarItems != null) {
        calItemIds.addAll(
          integration.calendarItems!.map((item) => item.id ?? '').toList(),
        );
        isSelecteCalendarItems.addAll(
          integration.calendarItems!.map((item) => ((item.id ?? '') + ((item.isSelected ?? false).toString()))),
        );
      }
    }

    var ddd = [
    ...integrations,
    ...isSelecteCalendarItems, 
    ...calItemIds
    ];

    return ddd;

    // print("result returned: ${ddd}");
    // return [
    // ...integrations, 
    // ...integrations.where((o) => o.id!=null) .map((o) => o.id!).toList(),
    // calItemIds,
    // ...isSelecteCalendarItems
    // ];
  }
}

class IntegrationAdded extends IntegrationsState {
  final String integrationId;

  const IntegrationAdded({required this.integrationId, String? requestId})
      : super(requestId: requestId);

  @override
  List<Object> get props => [integrationId];
}

class IntegrationDeleted extends IntegrationsState {
  final String integrationInfo;
  IntegrationDeleted({required this.integrationInfo, String? requestId})
      : super(requestId: requestId);
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