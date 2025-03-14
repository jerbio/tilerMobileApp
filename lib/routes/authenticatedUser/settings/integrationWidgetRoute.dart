import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tiler_app/bloc/integrations/integrations_bloc.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/services/api/authorization.dart';
import 'package:tiler_app/services/api/integrationsApi.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IntegrationWidgetRoute extends StatefulWidget {
  static final String routeName = '/Integrations';
  @override
  State<StatefulWidget> createState() => _IntegrationWidgetRouteState();
}

class _IntegrationWidgetRouteState extends State<IntegrationWidgetRoute> {
  final String blocEventId = "IntegrationId";
  late final AuthorizationApi authorizationApi;
  late final IntegrationApi integrationApi;
  List<CalendarIntegration> integrations = [];
  static final String integrationCancelAndProceedRouteName =
      "integrationCancelAndProceedRouteName";
  @override
  void initState() {
    super.initState();
    integrationApi = IntegrationApi(
        getContextCallBack: () => this.context.read<IntegrationsBloc>());
    authorizationApi = AuthorizationApi(
        getContextCallBack: () => this.context.read<IntegrationsBloc>());
    emitGetIntegrations();
  }

  void emitGetIntegrations() {
    this
        .context
        .read<IntegrationsBloc>()
        .add(GetIntegrationsEvent(eventId: blocEventId));
  }

  void emitResetIntegrations() {
    this
        .context
        .read<IntegrationsBloc>()
        .add(ResetIntegrationsEvent(eventId: blocEventId));
  }

  Widget renderPending() {
    return Container(
      child: Text(AppLocalizations.of(this.context)!.loadingIntegrations),
    );
  }

  Widget renderAddNewIntegration() {
    return ElevatedButton(
        onPressed: () async {
          this.context.read<IntegrationsBloc>().add(PendingIntegrationsEvent(
              eventId: blocEventId, integrations: integrations));
          authorizationApi.addGoogleCalendar().then((value) {
            this
                .context
                .read<IntegrationsBloc>()
                .add(GetIntegrationsEvent(eventId: blocEventId));
          });
        },
        child: Text(AppLocalizations.of(context)!.addGoogleCalendar));
  }

  Widget renderEmpty() {
    return Container(
      child: Text(AppLocalizations.of(this.context)!.noThirdPartyIntegtions),
    );
  }

  void deleteIntegration(int index, List<CalendarIntegration> integrations) {
    CalendarIntegration integration = integrations[index];
    setState(() {
      integrations.removeAt(index);
    });
    this.context.read<IntegrationsBloc>().add(DeleteIntegrationsEvent(
        eventId: blocEventId,
        integration: integration,
        callBack: (bool? deletionResult) {
          this
              .context
              .read<IntegrationsBloc>()
              .add(GetIntegrationsEvent(eventId: blocEventId));
        }));
    String titleText =
        integration.email ?? integration.userId ?? integration.id ?? "";

    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(AppLocalizations.of(context)!.deletedCalendar(titleText))));
  }

  Widget renderIntegrations(List<CalendarIntegration> integrations) {
    if (integrations.isEmpty) {
      return renderEmpty();
    }
    double endOfRowButtonsWidth = 40.0;
    List<CalendarIntegration> orderedIntegrations = integrations;
    return ListView.builder(
      itemCount: orderedIntegrations.length,
      itemBuilder: (context, index) {
        final integration = orderedIntegrations[index];
        String titleText =
            integration.email ?? integration.userId ?? integration.id ?? "";
        return Dismissible(
          key: Key(integration.id ?? index.toString()),
          onDismissed: (direction) {
            deleteIntegration(index, orderedIntegrations);
          },
          child: ListTile(
            title: Container(
                child: Text(
              titleText,
              style: TextStyle(overflow: TextOverflow.ellipsis),
            )),
            trailing: Container(
              width: endOfRowButtonsWidth * 2,
              child: Stack(
                children: [
                  Container(
                    width: endOfRowButtonsWidth,
                    child: ElevatedButton(
                        style: TileStyles.onlyIcons,
                        onPressed: () {
                          Map<String, dynamic> locationParams = {
                            'location': integration.location,
                          };
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LocationRoute(
                                        disableNickName: true,
                                        hideHomeButton: true,
                                        hideWorkButton: true,
                                        locationArgs: locationParams,
                                      ))).whenComplete(() {
                            Location? populatedLocation =
                                locationParams['location'] as Location? ??
                                    Location.fromDefault();
                            AnalysticsSignal.send(
                                'INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
                            setState(() {
                              if (populatedLocation != null) {
                                if (integration.id != null) {
                                  integration.location = populatedLocation;
                                  integrationApi.addIntegrationLocation(
                                      populatedLocation, integration.id!);
                                }
                                // integration.location = populatedLocation;
                              }
                            });
                          });
                        },
                        child: Icon(Icons.location_pin)),
                  ),
                  Positioned(
                    left: endOfRowButtonsWidth,
                    child: Container(
                      width: endOfRowButtonsWidth,
                      child: ElevatedButton(
                          style: TileStyles.onlyIcons,
                          onPressed: () {
                            deleteIntegration(index, orderedIntegrations);
                          },
                          child: Icon(Icons.delete_outline_sharp)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget generateContent(IntegrationsState state) {
    if (state is IntegrationsInitial) {
      this
          .context
          .read<IntegrationsBloc>()
          .add(GetIntegrationsEvent(eventId: blocEventId));
      return renderPending();
    }
    if (state is IntegrationsLoading) {
      return renderPending();
    }

    if (state is IntegrationsLoaded) {
      if (state.integrations.isNotEmpty) {
        return renderIntegrations(state.integrations);
      }
    }

    return renderEmpty();
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      routeName: integrationCancelAndProceedRouteName,
      appBar: AppBar(
        backgroundColor: TileStyles.appBarColor,
        title: Text(
          AppLocalizations.of(this.context)!.integrations,
          style: TileStyles.titleBarStyle,
        ),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomWidget: renderAddNewIntegration(),
      onProceed: () {
        emitResetIntegrations();
      },
      onCancel: () {
        emitResetIntegrations();
      },
      child: MultiBlocListener(
        listeners: [
          BlocListener<IntegrationsBloc, IntegrationsState>(
              listener: (context, state) {
            if (state is IntegrationsLoaded) {
              setState(() {
                integrations = state.integrations;
              });
            }
          })
        ],
        child: BlocBuilder<IntegrationsBloc, IntegrationsState>(
            builder: (context, state) {
          return Container(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Center(
                child: generateContent(state),
              ));
        }),
      ),
    );
  }
}
