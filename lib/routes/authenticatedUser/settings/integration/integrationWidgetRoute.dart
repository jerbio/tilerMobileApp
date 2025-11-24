import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/calendarItemsRoute.dart';
import 'package:tiler_app/data/calendarIntegration.dart';
import 'package:tiler_app/data/location.dart';
import 'package:tiler_app/routes/authenticatedUser/newTile/locationRoute.dart';
import 'package:tiler_app/services/analyticsSignal.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/theme/tile_theme_extension.dart';

class IntegrationWidgetRoute extends StatelessWidget {
  static final String routeName = '/Integrations';


  Widget renderAddNewIntegration(BuildContext context,ColorScheme colorScheme) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      onPressed: () =>
          context.read<IntegrationsBloc>().add(AddIntegrationEvent()),
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

    return Column(
      children: [
        SizedBox(height: 12),
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
      return PendingWidget();
    }
    if (state is IntegrationsLoading) {
      return PendingWidget();
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
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;

    return CancelAndProceedTemplateWidget(
      routeName: routeName,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.googleCalender,),
        automaticallyImplyLeading: false,
      ),
      child: BlocConsumer<IntegrationsBloc, IntegrationsState>(
        listener: (context, state) {
          NotificationOverlayMessage notificationOverlayMessage =
              NotificationOverlayMessage();
          print("IntegrationWidgetRoute: state: $state");
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
                child: renderAddNewIntegration(context,colorScheme),
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
    }

    String? _extractCity(String? text) {
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
      ),
    ).whenComplete(() {
      Location? populatedLocation =
          locationParams['location'] as Location? ?? Location.fromDefault();
      AnalysticsSignal.send('INTEGRATION_GOOGLE_LOCATION_NAVIGATION');
      if (integration.id != null) {
        integration.location = populatedLocation;
        context.read<IntegrationsBloc>().add(UpdateIntegrationLocationEvent(
            integrationId: integration.id!, location: populatedLocation));
      }
    });
  }

  void _navigateToCalendarItems(
      BuildContext context, CalendarIntegration integration) {
    IntegrationsBloc integrationsBloc = context.read<IntegrationsBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => integrationsBloc,
          child: CalendarItemsRoute(integration: integration),
        ),
      ),
    ).whenComplete(() {
      // Refresh the integrations list after returning from CalendarItemsRoute
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlocProvider(
            create: (context) => IntegrationsBloc(
              getContextCallBack: () => context,
              integrationType: integrationsBloc.integrationType,
            ),
            child: IntegrationWidgetRoute(),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    String titleText =
        integration.email ?? integration.userId ?? integration.id ?? "";
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    String providerText = integration.calendarType ??
        AppLocalizations.of(context)!.unknownProvider;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:tileThemeExtension.integrationBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
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
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: colorScheme.primary,
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
                color: tileThemeExtension.onSurfaceMonthlyIntegration,
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
                color: tileThemeExtension.onSurfaceVariantSecondary,
              ),
              SizedBox(width: 4),
              GestureDetector(
                onTap: () => _updateLocation(context, integration),
                child: Text(
                  _getCityFromLocation(integration.location, context),
                  style: TextStyle(
                    color: tileThemeExtension.onSurfaceMonthlyIntegration,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_right, color: tileThemeExtension.onSurfaceVariantSecondary,),
              onPressed: () => _navigateToCalendarItems(context, integration),
              tooltip: AppLocalizations.of(context)!.manageCalendars,
            ),
            SizedBox(width: 8),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onError,
                padding: EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: colorScheme.onError.withValues(alpha: 0.5)),
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
