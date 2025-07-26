import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/components/pendingWidget.dart';
import 'package:tiler_app/components/template/cancelAndProceedTemplate.dart';
import 'package:tiler_app/routes/authenticatedUser/settings/integration/bloc/integrations_bloc.dart';
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
        style: TextStyle(
          fontSize: 16
        ),
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
    return ListView.builder(
      itemCount: orderedIntegrations.length,
      itemBuilder: (context, index) {
        final integration = orderedIntegrations[index];
        return _IntegrationItem(integration: integration);
      },
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

    String? _extractCity(String? text, ) {
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
      if (populatedLocation != null) {
        if (integration.id != null) {
          integration.location = populatedLocation;
          context.read<IntegrationsBloc>().add(UpdateIntegrationLocationEvent(
              integrationId: integration.id!, location: populatedLocation));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String titleText =
        integration.email ?? integration.userId ?? integration.id ?? "";
    final theme=Theme.of(context);
    final colorScheme=theme.colorScheme;
    final tileThemeExtension=theme.extension<TileThemeExtension>()!;
    return ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 0),
        subtitle: Row(
          children: [
            SvgPicture.asset(
                'assets/icons/settings/MyLocations.svg',
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(
                  tileThemeExtension.onSurfaceVariantSecondary,
                  BlendMode.srcIn,
                )
            ),
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => _updateLocation(context, integration),
              child: SizedBox(
                width: 150,
                child: Text(
                  _getCityFromLocation(integration.location, context),
                  style: TextStyle(color: tileThemeExtension.onSurfaceVariantSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ],
        ),
        title: Container(
          child: Text(
            titleText,
            style: TextStyle(overflow: TextOverflow.ellipsis),
          ),
        ),
        trailing: IntrinsicWidth(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor:colorScheme.onSurface,
              padding: EdgeInsets.symmetric(horizontal: 30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: colorScheme.primary),
              ),
            ),
            onPressed: () => context
                .read<IntegrationsBloc>()
                .add(DeleteIntegrationEvent(integration: integration)),
            child: Text(AppLocalizations.of(context)!.disconnect),
          ),
        ));
  }
}