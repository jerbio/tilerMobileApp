import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/calendarItemsRoute.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:tiler_app/styles.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IntegrationWidgetRoute extends StatelessWidget {
  static final String routeName = '/Integrations';
  Widget renderPending() {
    List<Widget> centerElements = [
      Center(
          child: SizedBox(
        child: CircularProgressIndicator(),
        height: 200.0,
        width: 200.0,
      )),
      Center(
          child: Image.asset('assets/images/tiler_logo_black.png',
              fit: BoxFit.cover, scale: 7)),
    ];
    return Container(
      decoration: TileStyles.defaultBackground,
      child: Center(child: Stack(children: centerElements)),
    );
  }

  Widget renderAddNewIntegration(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: TileStyles.primaryColor,
        foregroundColor: TileStyles.primaryContrastTextColor,
      ),
      onPressed: () =>
          context.read<IntegrationsBloc>().add(AddIntegrationEvent()),
      // if(value !=null){
      //   Location defaultLocation = Location.fromDefault();
      //   Map<String, dynamic> locationParams = {
      //     'location': defaultLocation,
      //   };
      //   Navigator.push(
      //       context,
      //       MaterialPageRoute(
      //           builder: (context) => LocationRoute(
      //             disableNickName: true,
      //             hideHomeButton: true,
      //             hideWorkButton: true,
      //             locationArgs: locationParams,
      //           )
      //       )
      //   ).whenComplete(() {
      //     Location? populatedLocation = locationParams['location'] as Location? ?? Location.fromDefault();
      //     AnalysticsSignal.send('INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
      //     if (populatedLocation != null && value.containsKey('id')) {
      //       String integrationId = value['id'];
      //       integrationApi.addIntegrationLocation(populatedLocation, integrationId);
      //     }
      //   });
      // }
      // },
      child: Text(
        AppLocalizations.of(context)!.addGoogleCalendar,
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  Widget renderEmpty(BuildContext context) {
    return Container(
      child: Text(AppLocalizations.of(context)!.noThirdPartyIntegtions),
    );
  }
  Widget renderIntegrations(
      List<CalendarIntegration> integrations, BuildContext context) {
    if (integrations.isEmpty) {
      return renderEmpty(context);
    }
    List<CalendarIntegration> orderedIntegrations = integrations;
    
    // Calculate summary statistics
    int totalCalendars = 0;
    int selectedCalendars = 0;
    for (var integration in orderedIntegrations) {
      if (integration.calendarItems != null) {
        totalCalendars += integration.calendarItems!.length;
        selectedCalendars += integration.calendarItems!
            .where((item) => item.isSelected == true)
            .length;
      }
    }
    
    return Column(
      children: [
        // Summary Card
        Container(
          margin: EdgeInsets.only(bottom: 16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TileStyles.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: TileStyles.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.integration_instructions,
                color: TileStyles.primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [Text(
                      AppLocalizations.of(context)!.integrationCount(orderedIntegrations.length),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: TileStyles.primaryColor,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context)!.calendarsActive(selectedCalendars, totalCalendars),
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Integration List
        Expanded(
          child: ListView.separated(
            itemCount: orderedIntegrations.length,
            separatorBuilder: (context, index) => SizedBox(height: 8),
            itemBuilder: (context, index) {
              final integration = orderedIntegrations[index];
              return _IntegrationItem(integration: integration);
            },
          ),
        ),
      ],
    );
  }

  Widget generateContent(IntegrationsState state, BuildContext context) {
    if (state is IntegrationsInitial) {
      context.read<IntegrationsBloc>().add(GetIntegrationsEvent());
      return renderPending();
    }
    if (state is IntegrationsLoading) {
      return renderPending();
    }
    if (state is IntegrationsLoaded) {
      if (state.integrations.isNotEmpty) {
        return renderIntegrations(state.integrations, context);
      }
    }
    if (state is IntegrationsError) {
      if (state.integrations.isNotEmpty) {
        return renderIntegrations(state.integrations, context);
      }
    }
    return renderEmpty(context);
  }

  @override
  Widget build(BuildContext context) {
    return CancelAndProceedTemplateWidget(
      routeName: routeName,
      appBar: TileStyles.CancelAndProceedAppBar(
          AppLocalizations.of(context)!.googleCalender),
      child: BlocConsumer<IntegrationsBloc, IntegrationsState>(
        listener: (context, state) {
          NotificationOverlayMessage notificationOverlayMessage =
              NotificationOverlayMessage();
          if (state is IntegrationAdded) {
            //_handleNewIntegration(context, state.integrationId);
          } else if (state is IntegrationDeleted) {
            notificationOverlayMessage.showToast(
              context,
              AppLocalizations.of(context)!
                  .deletedCalendar(state.integrationInfo),
              NotificationOverlayMessageType.success,
            );
          } else if (state is IntegrationsError) {
            notificationOverlayMessage.showToast(
              context,
              state.errorMessage,
              NotificationOverlayMessageType.error,
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Center(
                    child: generateContent(state, context),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(50.0),
                child: renderAddNewIntegration(context),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _IntegrationItem extends StatelessWidget {
  final CalendarIntegration integration;
  const _IntegrationItem({
    required this.integration,
  });

  String _getCityFromLocation(Location? location, BuildContext context) {
    String _capitalize(String text) {
      if (text.isEmpty) return text;
      return text[0].toUpperCase() + text.substring(1);
    }    String? _extractCity(String? text) {
      if (text != null && text.isNotEmpty) {
        List<String> parts = text.split(',').map((e) => e.trim()).toList();
        if (parts.length == 1) {
          return _capitalize(parts.first);
        }
        return _capitalize(parts[parts.length - 2]);
      }
      return null;
    }

    return _extractCity(location?.address) ??
        _extractCity(location?.description) ??
        AppLocalizations.of(context)!.integrationsSetLocation;
  }

  void _updateLocation(BuildContext context, CalendarIntegration integration) {
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
        ),
      ),    ).whenComplete(() {
      Location? populatedLocation =
          locationParams['location'] as Location? ?? Location.fromDefault();
      AnalysticsSignal.send('INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
      if (integration.id != null) {
        integration.location = populatedLocation;
        context.read<IntegrationsBloc>().add(UpdateIntegrationLocationEvent(
            integrationId: integration.id!, location: populatedLocation));
      }
    });
  }  void _navigateToCalendarItems(BuildContext context, CalendarIntegration integration) {
    IntegrationsBloc integrationsBloc = context.read<IntegrationsBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => integrationsBloc,
          child: CalendarItemsRoute(integration: integration),
        ),
      ),
    );
    }

  @override
  Widget build(BuildContext context) {
    String titleText = integration.email ?? integration.userId ?? integration.id ?? "";
    String providerText = integration.calendarType ?? AppLocalizations.of(context)!.unknownProvider;
    int calendarCount = integration.calendarItems?.length ?? 0;
    int selectedCount = integration.calendarItems?.where((item) => item.isSelected == true).length ?? 0;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TileStyles.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: TileStyles.primaryColor,
            size: 20,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titleText,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            Text(
              providerText.toUpperCase(),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/settings/MyLocations.svg',
                width: 14,
                height: 14,
                color: Colors.grey[500],
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () => _updateLocation(context, integration),
                child: Text(
                  _getCityFromLocation(integration.location, context),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedCount > 0 ? TileStyles.greenApproval.withOpacity(0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selectedCount > 0 ? TileStyles.greenApproval.withOpacity(0.3) : Colors.grey[300]!,
                  ),
                ),
                child: Text(
                    AppLocalizations.of(context)!.calendarsActive(selectedCount, calendarCount),
                  style: TextStyle(
                    color: selectedCount > 0 ? TileStyles.greenApproval : Colors.grey[600],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_right, color: Colors.grey[400]),
              onPressed: () => _navigateToCalendarItems(context, integration),
              tooltip: AppLocalizations.of(context)!.manageCalendars,
            ),
            SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.red.withOpacity(0.5)),
                ),
                minimumSize: Size(0, 32),
              ),
              onPressed: () => context
                  .read<IntegrationsBloc>()
                  .add(DeleteIntegrationEvent(integration: integration)),
              child: Text(
                AppLocalizations.of(context)!.disconnect,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        onTap: () => _navigateToCalendarItems(context, integration),
      ),
    );
  }
}
